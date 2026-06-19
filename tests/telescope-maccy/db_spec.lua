local db = require("telescope-maccy.db")

describe("telescope-maccy.db.build_sql", function()
	local base = {
		limit = 500,
		pin_to_top = false,
		large_text = { enabled = true, threshold = 102400 },
	}

	it("filters to plain-text content and orders by recency", function()
		local sql = db.build_sql(base)
		assert.is_truthy(sql:find("WHERE c.ZTYPE = 'public.utf8%-plain%-text'"))
		assert.is_truthy(sql:find("ORDER BY item.ZLASTCOPIEDAT DESC"))
		assert.is_truthy(sql:find("LIMIT 500;"))
	end)

	it("puts pinned rows first when pin_to_top is set", function()
		local sql = db.build_sql(vim.tbl_extend("force", base, { pin_to_top = true }))
		assert.is_truthy(sql:find("ORDER BY item.ZPIN DESC, item.ZLASTCOPIEDAT DESC"))
	end)

	it("guards large entries with a threshold when large_text is enabled", function()
		local sql = db.build_sql(base)
		assert.is_truthy(sql:find("CASE WHEN LENGTH%(c.ZVALUE%) > 102400 THEN NULL"))
		assert.is_truthy(sql:find("CAST%(c.ZVALUE AS TEXT%)"))
	end)

	it("loads every body in full when large_text is disabled", function()
		local sql = db.build_sql(vim.tbl_extend("force", base, { large_text = { enabled = false, threshold = 1 } }))
		assert.is_nil(sql:find("CASE WHEN"))
		assert.is_truthy(sql:find("CAST%(c.ZVALUE AS TEXT%)"))
	end)
end)

describe("telescope-maccy.db.build_command", function()
	it("opens the db read-only (not immutable, so the WAL is honoured), expanding ~", function()
		local cmd = db.build_command({
			db_path = "~/x.sqlite",
			limit = 1,
			pin_to_top = false,
			large_text = { enabled = true, threshold = 1 },
		})
		assert.are.equal("sqlite3", cmd[1])
		assert.are.equal("-json", cmd[2])
		local expected = "file:" .. vim.fn.expand("~") .. "/x.sqlite?mode=ro"
		assert.are.equal(expected, cmd[3])
		assert.is_nil(cmd[3]:find("immutable"))
		assert.is_truthy(cmd[4]:find("SELECT"))
	end)
end)

describe("telescope-maccy.db.query", function()
	local function create_db()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		local path = dir .. "/Storage.sqlite"
		local sql = [[
CREATE TABLE ZHISTORYITEM (Z_PK INTEGER PRIMARY KEY, ZLASTCOPIEDAT REAL, ZPIN VARCHAR);
CREATE TABLE ZHISTORYITEMCONTENT (Z_PK INTEGER PRIMARY KEY, ZITEM INTEGER, ZTYPE VARCHAR, ZVALUE BLOB);
INSERT INTO ZHISTORYITEM VALUES (1, 300.0, NULL);
INSERT INTO ZHISTORYITEM VALUES (2, 100.0, 'a');
INSERT INTO ZHISTORYITEM VALUES (3, 200.0, NULL);
INSERT INTO ZHISTORYITEM VALUES (4, 400.0, NULL);
INSERT INTO ZHISTORYITEMCONTENT VALUES (1, 1, 'public.utf8-plain-text', CAST('newest' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (2, 2, 'public.utf8-plain-text', CAST('pinned older' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (3, 3, 'public.utf8-plain-text', CAST('this body is long enough' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (4, 4, 'public.tiff', CAST('imgdata' AS BLOB));
]]
		local res = vim.system({ "sqlite3", path }, { stdin = sql }):wait()
		assert.are.equal(0, res.code, res.stderr)
		return path
	end

	local function run(opts)
		local result, err, done
		db.query(opts, function(r, e)
			result, err, done = r, e, true
		end)
		vim.wait(5000, function()
			return done
		end, 10)
		return result, err
	end

	local function opts(overrides)
		return vim.tbl_deep_extend("force", {
			db_path = create_db(),
			limit = 500,
			pin_to_top = false,
			large_text = { enabled = true, threshold = 102400 },
		}, overrides or {})
	end

	it("returns plain-text rows newest first and excludes images", function()
		local rows, err = run(opts())
		assert.is_nil(err)
		assert.are.equal(3, #rows)
		assert.are.equal("newest", rows[1].value)
		assert.are.equal("this body is long enough", rows[2].value)
		assert.are.equal("pinned older", rows[3].value)
	end)

	it("nulls the value of entries over the large-text threshold", function()
		local rows, err = run(opts({ large_text = { enabled = true, threshold = 10 } }))
		assert.is_nil(err)
		-- the 24-byte body (t=200) is now large; its value is dropped but byte_len stays
		assert.is_nil(rows[2].value)
		assert.are.equal(24, rows[2].byte_len)
		assert.are.equal("newest", rows[1].value)
	end)

	it("honours the row limit", function()
		local rows = run(opts({ limit = 1 }))
		assert.are.equal(1, #rows)
		assert.are.equal("newest", rows[1].value)
	end)

	it("floats pinned rows to the top when pin_to_top is set", function()
		local rows = run(opts({ pin_to_top = true }))
		assert.are.equal("pinned older", rows[1].value)
	end)

	it("returns an empty list when there is no matching history", function()
		local rows, err = run(opts({ limit = 0 }))
		assert.is_nil(err)
		assert.are.same({}, rows)
	end)

	it("reads rows that live in an uncheckpointed WAL (Maccy keeps the db open)", function()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		local path = dir .. "/Storage.sqlite"

		-- Write into a WAL-mode db and keep the connection open, then SIGKILL it
		-- so the WAL is never checkpointed into the main file — exactly how Maccy
		-- leaves its store while running.
		local flushed = false
		local writer = vim.system({ "sqlite3", path }, {
			stdin = true,
			stdout = function(_, data)
				if data and data:find("FLUSHED") then
					flushed = true
				end
			end,
		})
		writer:write(table.concat({
			"PRAGMA journal_mode=WAL;",
			"CREATE TABLE ZHISTORYITEM (Z_PK INTEGER PRIMARY KEY, ZLASTCOPIEDAT REAL, ZPIN VARCHAR);",
			"CREATE TABLE ZHISTORYITEMCONTENT (Z_PK INTEGER PRIMARY KEY, ZITEM INTEGER, ZTYPE VARCHAR, ZVALUE BLOB);",
			"INSERT INTO ZHISTORYITEM VALUES (1, 100.0, NULL);",
			"INSERT INTO ZHISTORYITEMCONTENT VALUES (1, 1, 'public.utf8-plain-text', CAST('lives in wal' AS BLOB));",
			"SELECT 'FLUSHED';",
			"",
		}, "\n"))
		vim.wait(5000, function()
			return flushed
		end, 10)
		assert.is_true(flushed, "writer did not execute its statements")
		writer:kill(9)

		local rows, err = run(opts({ db_path = path }))
		assert.is_nil(err)
		assert.are.equal("lives in wal", rows[1].value)
	end)

	it("reads a database whose path contains spaces (the default path does)", function()
		local dir = vim.fn.tempname() .. "/Application Support/Maccy"
		vim.fn.mkdir(dir, "p")
		local path = dir .. "/Storage.sqlite"
		local sql = [[
CREATE TABLE ZHISTORYITEM (Z_PK INTEGER PRIMARY KEY, ZLASTCOPIEDAT REAL, ZPIN VARCHAR);
CREATE TABLE ZHISTORYITEMCONTENT (Z_PK INTEGER PRIMARY KEY, ZITEM INTEGER, ZTYPE VARCHAR, ZVALUE BLOB);
INSERT INTO ZHISTORYITEM VALUES (1, 100.0, NULL);
INSERT INTO ZHISTORYITEMCONTENT VALUES (1, 1, 'public.utf8-plain-text', CAST('spaced' AS BLOB));
]]
		assert.are.equal(0, vim.system({ "sqlite3", path }, { stdin = sql }):wait().code)

		local rows, err = run(opts({ db_path = path }))
		assert.is_nil(err)
		assert.are.equal("spaced", rows[1].value)
	end)
end)

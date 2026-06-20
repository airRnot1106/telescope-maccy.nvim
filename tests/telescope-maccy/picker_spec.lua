local picker = require("telescope-maccy.picker")
local item = require("telescope-maccy.item")

describe("telescope-maccy.picker.make_entry_maker", function()
	local now = item.CORE_DATA_EPOCH + 120

	it("keeps the raw value and body-only ordinal", function()
		local make = picker.make_entry_maker({ pin_to_top = false }, now)
		local entry = make({ last_copied_at = 0, pin = nil, byte_len = 11, value = "hello\nworld" })
		assert.are.equal("hello\nworld", entry.value)
		assert.are.equal("hello↵world", entry.ordinal)
		assert.are.equal("hello↵world", entry.body)
		assert.is_function(entry.display)
	end)

	it("exposes is_large and pinned so on_select can read them", function()
		local make = picker.make_entry_maker({ pin_to_top = false }, now)
		local entry = make({ last_copied_at = 0, pin = "a", byte_len = 1, value = "x" })
		assert.is_true(entry.pinned)
		assert.is_false(entry.is_large)
	end)
end)

describe("telescope-maccy.picker.display_columns", function()
	local function entry(pinned)
		return { time = "2m ago", pinned = pinned, body = "snippet" }
	end

	it("renders [time, body] without a marker by default", function()
		assert.are.same({ "2m ago", "snippet" }, picker.display_columns(entry(true), { pin_to_top = false }))
	end)

	it("prefixes pinned rows with a marker only when pin_to_top is set", function()
		assert.are.same({ "📌 2m ago", "snippet" }, picker.display_columns(entry(true), { pin_to_top = true }))
		assert.are.same({ "2m ago", "snippet" }, picker.display_columns(entry(false), { pin_to_top = true }))
	end)
end)

describe("telescope-maccy.picker.precheck", function()
	it("fails with the resolved path when the database is missing", function()
		local ok, err = picker.precheck({ db_path = "/no/such/maccy.sqlite" })
		assert.is_false(ok)
		assert.is_truthy(err:find("/no/such/maccy.sqlite", 1, true))
	end)

	it("passes when sqlite3 and the database are present", function()
		local tmp = vim.fn.tempname()
		vim.fn.writefile({ "" }, tmp)
		local ok = picker.precheck({ db_path = tmp })
		assert.is_true(ok)
	end)
end)

describe("telescope-maccy.picker.copy_entry", function()
	it("loads the raw value into the unnamed register", function()
		local copied = picker.copy_entry({ value = "payload" })
		assert.is_true(copied)
		assert.are.equal("payload", vim.fn.getreg('"'))
	end)

	it("does nothing for large entries with no value", function()
		vim.fn.setreg('"', "previous")
		local copied = picker.copy_entry({ value = nil })
		assert.is_false(copied)
		assert.are.equal("previous", vim.fn.getreg('"'))
	end)
end)

describe("telescope-maccy.picker.default_on_select", function()
	it("copies the raw value into the unnamed register", function()
		vim.fn.setreg('"', "previous")
		picker.default_on_select({ value = "payload" })
		assert.are.equal("payload", vim.fn.getreg('"'))
	end)

	it("leaves the register untouched for large entries with no value", function()
		vim.fn.setreg('"', "previous")
		picker.default_on_select({ value = nil })
		assert.are.equal("previous", vim.fn.getreg('"'))
	end)

	it("warns differently for large versus empty entries", function()
		local msgs = {}
		local orig = vim.notify
		vim.notify = function(msg)
			table.insert(msgs, msg)
		end
		local ok, err = pcall(function()
			picker.default_on_select({ value = nil, is_large = true })
			picker.default_on_select({ value = nil, is_large = false })
		end)
		vim.notify = orig
		assert.is_true(ok, err)
		assert.is_truthy(msgs[1]:find("too large", 1, true))
		assert.is_truthy(msgs[2]:find("no text", 1, true))
	end)
end)

describe("telescope-maccy.picker.resolve_on_select", function()
	it("uses the default action when none is configured", function()
		assert.are.equal(picker.default_on_select, picker.resolve_on_select({}))
	end)

	it("uses a user-provided on_select callback", function()
		local custom = function() end
		assert.are.equal(custom, picker.resolve_on_select({ on_select = custom }))
	end)
end)

describe("telescope-maccy.picker.preview_lines", function()
	it("splits the raw value into buffer lines", function()
		assert.are.same({ "a", "b", "c" }, picker.preview_lines({ value = "a\nb\nc" }))
	end)

	it("shows the body label for large entries", function()
		assert.are.same(
			{ "(large text, 200 KB)" },
			picker.preview_lines({ value = nil, body = "(large text, 200 KB)" })
		)
	end)
end)

local M = {}

--- Build the SELECT statement for the resolved options.
---@param opts table resolved config (limit, pin_to_top, large_text)
---@return string
function M.build_sql(opts)
	local order = opts.pin_to_top and "item.ZPIN DESC, item.ZLASTCOPIEDAT DESC" or "item.ZLASTCOPIEDAT DESC"

	local value_expr
	if opts.large_text and opts.large_text.enabled then
		value_expr = string.format(
			"CASE WHEN LENGTH(c.ZVALUE) > %d THEN NULL ELSE CAST(c.ZVALUE AS TEXT) END",
			opts.large_text.threshold
		)
	else
		value_expr = "CAST(c.ZVALUE AS TEXT)"
	end

	return string.format(
		[[SELECT
  item.ZLASTCOPIEDAT AS last_copied_at,
  item.ZPIN          AS pin,
  LENGTH(c.ZVALUE)   AS byte_len,
  %s AS value
FROM ZHISTORYITEMCONTENT c
JOIN ZHISTORYITEM item ON item.Z_PK = c.ZITEM
WHERE c.ZTYPE = 'public.utf8-plain-text'
ORDER BY %s
LIMIT %d;]],
		value_expr,
		order,
		opts.limit
	)
end

--- Expand a configured db path (handles a leading ~).
---@param path string
---@return string
function M.expand_path(path)
	return vim.fn.expand(path)
end

--- Build the argv for the sqlite3 invocation. No shell is involved, so the
--- file URI and SQL are passed verbatim.
---
--- Opened read-only (`mode=ro`) rather than `immutable=1`: Maccy keeps live
--- history in the WAL (`Storage.sqlite-wal`), and `immutable=1` ignores the
--- WAL, so it would read an empty/stale snapshot. A read-only connection
--- respects the WAL and, in WAL journal mode, never blocks Maccy's writes.
---@param opts table resolved config (must include db_path)
---@return string[]
function M.build_command(opts)
	local uri = string.format("file:%s?mode=ro", M.expand_path(opts.db_path))
	return { "sqlite3", "-json", uri, M.build_sql(opts) }
end

--- Run the query asynchronously. The callback always runs on the main loop.
---@param opts table resolved config
---@param on_done fun(rows: table[]|nil, err: string|nil)
function M.query(opts, on_done)
	local function finish(rows, err)
		vim.schedule(function()
			on_done(rows, err)
		end)
	end

	local ok, sys_err = pcall(vim.system, M.build_command(opts), { text = true }, function(res)
		if res.code ~= 0 then
			local msg = (res.stderr and res.stderr ~= "") and res.stderr
				or ("sqlite3 exited with code " .. tostring(res.code))
			return finish(nil, vim.trim(msg))
		end

		-- Zero rows: sqlite3 -json prints nothing. Check for any non-whitespace
		-- without copying the (potentially large) output via vim.trim.
		local out = res.stdout or ""
		if not out:find("%S") then
			return finish({}, nil)
		end

		local decoded_ok, decoded = pcall(vim.json.decode, out, { luanil = { object = true, array = true } })
		if not decoded_ok then
			return finish(nil, "failed to parse sqlite3 output: " .. tostring(decoded))
		end
		return finish(decoded, nil)
	end)

	if not ok then
		finish(nil, tostring(sys_err))
	end
end

return M

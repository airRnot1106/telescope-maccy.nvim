local M = {}

--- Default configuration. Overridden per the Telescope extension table:
---   require("telescope").setup({ extensions = { maccy = { ... } } })
M.defaults = {
	-- Maccy's Core Data store (GitHub build, non-sandboxed container).
	db_path = "~/Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy/Storage.sqlite",
	-- Maximum number of history entries fetched per picker launch.
	limit = 500,
	-- Pin Maccy-pinned entries to the top of the list.
	pin_to_top = false,
	-- Skip loading the body of very large entries to keep the picker snappy.
	large_text = {
		enabled = true,
		threshold = 102400, -- 100 KiB
	},
}

--- Merge user options over the defaults, returning a fresh table.
---@param user_opts table|nil
---@return table
function M.resolve(user_opts)
	return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_opts or {})
end

return M

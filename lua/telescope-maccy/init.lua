local config = require("telescope-maccy.config")
local picker = require("telescope-maccy.picker")

local M = {
	-- Resolved options; replaced by setup() when the extension loads.
	_opts = config.resolve(),
}

--- Called by Telescope with the `extensions.maccy` table.
---@param ext_config table|nil
function M.setup(ext_config)
	M._opts = config.resolve(ext_config)
end

--- The currently resolved options.
---@return table
function M.options()
	return M._opts
end

--- Open the Maccy history picker. Per-call options override the configured ones.
---@param opts table|nil
function M.maccy(opts)
	picker.show(vim.tbl_deep_extend("force", M._opts, opts or {}))
end

return M

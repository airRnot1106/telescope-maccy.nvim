local maccy = require("telescope-maccy")
local db = require("telescope-maccy.db")

local health = vim.health

local M = {}

--- :checkhealth telescope-maccy
function M.check()
	health.start("telescope-maccy")

	if vim.fn.has("nvim-0.10") == 1 then
		health.ok("Neovim >= 0.10")
	else
		health.error("Neovim 0.10+ is required (uses vim.system)")
	end

	if vim.fn.executable("sqlite3") == 1 then
		health.ok("`sqlite3` found on PATH")
	else
		health.error("`sqlite3` was not found on your PATH")
	end

	local path = db.expand_path(maccy.options().db_path)
	if vim.uv.fs_stat(path) then
		health.ok("Maccy database found: " .. path)
		if vim.uv.fs_access(path, "R") then
			health.ok("Database is readable")
		else
			health.error("Database is not readable: " .. path)
		end
	else
		health.warn("Maccy database not found at: " .. path)
	end
end

return M

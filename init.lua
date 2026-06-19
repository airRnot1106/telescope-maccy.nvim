vim.opt.swapfile = false

-- Point the demo (vhs) at a seeded sample database when asked; fall back to the
-- real Maccy store otherwise so `nix run .#nvim` keeps working out of the box.
local maccy_opts = {}
if vim.env.TELESCOPE_MACCY_DB and vim.env.TELESCOPE_MACCY_DB ~= "" then
	maccy_opts.db_path = vim.env.TELESCOPE_MACCY_DB
end

require("telescope").setup({
	extensions = {
		maccy = maccy_opts,
	},
})
require("telescope").load_extension("maccy")

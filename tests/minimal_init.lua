vim.opt.swapfile = false
vim.opt.runtimepath:append(vim.fn.getcwd())

local function append_if_dir(path)
	if path and path ~= "" and vim.fn.isdirectory(path) == 1 then
		vim.opt.runtimepath:append(path)
	end
end

-- The test dependencies (plenary, telescope) come from one of three places:
--
-- 1. CI: the flake test derivation exports their store paths as env vars.
--    These are inherited by the child Neovims that PlenaryBustedDirectory
--    spawns per spec, which do not see the Nix wrapper's packpath.
-- 2. Any bundled start packages on the packpath (belt-and-suspenders).
-- 3. Local runs: the plugin manager's install directory.
append_if_dir(vim.env.PLENARY_NVIM)
append_if_dir(vim.env.TELESCOPE_NVIM)

for _, site in ipairs(vim.opt.packpath:get()) do
	for _, dir in ipairs(vim.fn.glob(site .. "/pack/*/start/*", true, true)) do
		append_if_dir(dir)
	end
end

for _, dir in ipairs({
	"~/.local/share/nvim/lazy/plenary.nvim",
	"~/.local/share/nvim/lazy/telescope.nvim",
}) do
	append_if_dir(vim.fn.expand(dir))
end

vim.cmd("runtime plugin/plenary.vim")

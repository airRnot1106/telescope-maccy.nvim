vim.opt.swapfile = false
vim.opt.runtimepath:append(vim.fn.getcwd())

local function append_if_dir(path)
	if path ~= "" and vim.fn.isdirectory(path) == 1 then
		vim.opt.runtimepath:append(path)
	end
end

-- In CI the test dependencies (plenary, telescope) are bundled by the Nix
-- wrapper under packpath. Add the start packages to the runtimepath explicitly:
-- with `--noplugin` :packloadall does not run, so they are not picked up
-- automatically, and PlenaryBustedDirectory spawns child Neovims per spec file.
for _, site in ipairs(vim.opt.packpath:get()) do
	for _, dir in ipairs(vim.fn.glob(site .. "/pack/*/start/*", true, true)) do
		append_if_dir(dir)
	end
end

-- When running the suite locally the dependencies live under the plugin
-- manager's install directory instead.
for _, dir in ipairs({
	"~/.local/share/nvim/lazy/plenary.nvim",
	"~/.local/share/nvim/lazy/telescope.nvim",
}) do
	append_if_dir(vim.fn.expand(dir))
end

vim.cmd("runtime plugin/plenary.vim")

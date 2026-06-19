vim.opt.swapfile = false
vim.opt.runtimepath:append(vim.fn.getcwd())

-- In CI the test dependencies are provided by the Nix wrapper (already on the
-- runtimepath). When running the suite locally they live under the plugin
-- manager's install directory, so append them when present.
for _, dir in ipairs({
	"~/.local/share/nvim/lazy/plenary.nvim",
	"~/.local/share/nvim/lazy/telescope.nvim",
}) do
	local path = vim.fn.expand(dir)
	if vim.fn.isdirectory(path) == 1 then
		vim.opt.runtimepath:append(path)
	end
end

vim.cmd("runtime plugin/plenary.vim")

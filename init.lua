vim.opt.swapfile = false

require("telescope").setup({
	extensions = {
		maccy = {},
	},
})
require("telescope").load_extension("maccy")

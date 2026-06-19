-- Telescope extension entry point. Fleshed out once the picker lands.
return require("telescope").register_extension({
	exports = {
		maccy = function()
			vim.notify("telescope-maccy: not implemented yet", vim.log.levels.WARN)
		end,
	},
})

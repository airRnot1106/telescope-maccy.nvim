local maccy = require("telescope-maccy")

return require("telescope").register_extension({
	setup = maccy.setup,
	exports = {
		maccy = maccy.maccy,
	},
})

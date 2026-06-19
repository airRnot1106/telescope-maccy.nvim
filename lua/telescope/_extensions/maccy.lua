local maccy = require("telescope-maccy")

return require("telescope").register_extension({
	setup = function(ext_config)
		maccy.setup(ext_config)
	end,
	exports = {
		maccy = maccy.maccy,
	},
})

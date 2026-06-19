local init = require("telescope-maccy")
local picker = require("telescope-maccy.picker")

describe("telescope-maccy (init)", function()
	local original = picker.show
	local captured

	before_each(function()
		captured = nil
		picker.show = function(opts)
			captured = opts
		end
	end)

	after_each(function()
		picker.show = original
	end)

	it("opens the picker with the default options", function()
		init.setup()
		init.maccy()
		assert.are.equal(500, captured.limit)
	end)

	it("applies the extension configuration via setup", function()
		init.setup({ limit = 42, pin_to_top = true })
		init.maccy()
		assert.are.equal(42, captured.limit)
		assert.is_true(captured.pin_to_top)
	end)

	it("lets per-call options override the configured ones", function()
		init.setup({ limit = 42 })
		init.maccy({ limit = 1 })
		assert.are.equal(1, captured.limit)
	end)

	it("exposes the resolved options", function()
		init.setup({ limit = 7 })
		assert.are.equal(7, init.options().limit)
	end)
end)

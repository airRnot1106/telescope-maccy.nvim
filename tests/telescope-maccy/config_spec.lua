local config = require("telescope-maccy.config")

describe("telescope-maccy.config", function()
	it("returns the defaults when no options are given", function()
		local opts = config.resolve()
		assert.are.equal(500, opts.limit)
		assert.are.equal(false, opts.pin_to_top)
		assert.are.equal(true, opts.large_text.enabled)
		assert.are.equal(102400, opts.large_text.threshold)
		assert.are.equal(
			"~/Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy/Storage.sqlite",
			opts.db_path
		)
	end)

	it("overrides scalar defaults with user options", function()
		local opts = config.resolve({ limit = 50, pin_to_top = true, db_path = "/tmp/x.sqlite" })
		assert.are.equal(50, opts.limit)
		assert.are.equal(true, opts.pin_to_top)
		assert.are.equal("/tmp/x.sqlite", opts.db_path)
	end)

	it("deep-merges large_text so unspecified keys keep their defaults", function()
		local opts = config.resolve({ large_text = { threshold = 1024 } })
		assert.are.equal(1024, opts.large_text.threshold)
		assert.are.equal(true, opts.large_text.enabled)
	end)

	it("does not mutate the module defaults across calls", function()
		config.resolve({ limit = 1, large_text = { threshold = 1 } })
		local opts = config.resolve()
		assert.are.equal(500, opts.limit)
		assert.are.equal(102400, opts.large_text.threshold)
	end)
end)

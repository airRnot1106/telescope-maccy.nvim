local item = require("telescope-maccy.item")

describe("telescope-maccy.item.fold", function()
	it("collapses newlines into a single-line marker", function()
		assert.are.equal("a↵b", item.fold("a\nb"))
		assert.are.equal("a↵b", item.fold("a\r\nb"))
		assert.are.equal("a↵b", item.fold("a\rb"))
		assert.are.equal("a↵↵b", item.fold("a\n\nb"))
	end)

	it("trims surrounding whitespace but keeps inner indentation", function()
		assert.are.equal("hi", item.fold("  hi  "))
		assert.are.equal("def f():↵    return 1", item.fold("def f():\n    return 1"))
	end)

	it("trims surrounding newlines instead of turning them into markers", function()
		assert.are.equal("hi", item.fold("\n\nhi\n\n"))
	end)
end)

describe("telescope-maccy.item.relative_time", function()
	local now = 1000000

	it("formats sub-minute differences in seconds", function()
		assert.are.equal("5s ago", item.relative_time(now - 5, now))
	end)

	it("formats minute, hour, day and week differences", function()
		assert.are.equal("2m ago", item.relative_time(now - 120, now))
		assert.are.equal("3h ago", item.relative_time(now - 3 * 3600, now))
		assert.are.equal("4d ago", item.relative_time(now - 4 * 86400, now))
		assert.are.equal("2w ago", item.relative_time(now - 2 * 604800, now))
	end)

	it("clamps future timestamps to 'just now'", function()
		assert.are.equal("just now", item.relative_time(now + 100, now))
		assert.are.equal("just now", item.relative_time(now, now))
	end)
end)

describe("telescope-maccy.item.large_text_label", function()
	it("renders the size in whole kibibytes", function()
		assert.are.equal("(large text, 100 KB)", item.large_text_label(102400))
		assert.are.equal("(large text, 150 KB)", item.large_text_label(153600))
	end)
end)

describe("telescope-maccy.item.make_entry", function()
	-- 2001-01-01T00:00:00Z (Core Data epoch) -> unix 978307200.
	local now = 978307200 + 120

	it("builds a text entry with raw value preserved and folded body", function()
		local entry = item.make_entry({
			last_copied_at = 0,
			pin = nil,
			byte_len = 5,
			value = "hello\nworld",
		}, now)

		assert.are.equal("hello\nworld", entry.value)
		assert.are.equal("hello↵world", entry.body)
		assert.are.equal("hello↵world", entry.ordinal)
		assert.are.equal("2m ago", entry.time)
		assert.is_false(entry.pinned)
		assert.is_false(entry.is_large)
	end)

	it("treats a non-empty ZPIN (the pin shortcut) as pinned", function()
		local entry = item.make_entry({ last_copied_at = 0, pin = "a", byte_len = 1, value = "x" }, now)
		assert.is_true(entry.pinned)
	end)

	it("treats an empty ZPIN as not pinned", function()
		local entry = item.make_entry({ last_copied_at = 0, pin = "", byte_len = 1, value = "x" }, now)
		assert.is_false(entry.pinned)
	end)

	it("does not crash on a NULL ZVALUE (value and byte_len both nil)", function()
		local entry = item.make_entry({ last_copied_at = 0, pin = nil, byte_len = nil, value = nil }, now)
		assert.is_nil(entry.value)
		assert.is_false(entry.is_large)
		assert.are.equal("", entry.body)
	end)

	it("represents large entries with a label and no value", function()
		local entry = item.make_entry({
			last_copied_at = 0,
			pin = nil,
			byte_len = 204800,
			value = nil,
		}, now)

		assert.is_nil(entry.value)
		assert.is_true(entry.is_large)
		assert.are.equal("(large text, 200 KB)", entry.body)
		assert.are.equal("(large text, 200 KB)", entry.ordinal)
	end)
end)

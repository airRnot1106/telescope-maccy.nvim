local M = {}

-- Core Data stores timestamps as seconds since 2001-01-01 UTC. Add this to
-- convert ZLASTCOPIEDAT into a Unix timestamp.
M.CORE_DATA_EPOCH = 978307200

--- Collapse newlines into a single-line marker and trim the ends.
--- Inner whitespace (e.g. code indentation) is preserved on purpose.
---@param text string
---@return string
function M.fold(text)
	return (vim.trim(text):gsub("\r\n", "↵"):gsub("[\r\n]", "↵"))
end

local UNITS = {
	{ 604800, "w" },
	{ 86400, "d" },
	{ 3600, "h" },
	{ 60, "m" },
	{ 1, "s" },
}

--- Render the age of a Unix timestamp relative to `now` as a short string.
---@param unix number
---@param now number
---@return string
function M.relative_time(unix, now)
	local diff = math.floor(now - unix)
	if diff < 1 then
		return "just now"
	end
	for _, unit in ipairs(UNITS) do
		local seconds, suffix = unit[1], unit[2]
		if diff >= seconds then
			return string.format("%d%s ago", math.floor(diff / seconds), suffix)
		end
	end
	return "just now"
end

--- Label shown in place of the body for entries too large to load.
---@param byte_len number
---@return string
function M.large_text_label(byte_len)
	return string.format("(large text, %d KB)", math.floor(byte_len / 1024))
end

--- Turn a raw DB row into the fields the picker needs.
---@param row table { last_copied_at, pin, byte_len, value }
---@param now number current Unix time
---@return table
function M.make_entry(row, now)
	local is_large = row.value == nil
	local body = is_large and M.large_text_label(row.byte_len) or M.fold(row.value)
	-- Maccy stores ZPIN as the pin shortcut string (or NULL when unpinned).
	return {
		value = row.value,
		pinned = row.pin ~= nil and row.pin ~= "",
		is_large = is_large,
		time = M.relative_time(row.last_copied_at + M.CORE_DATA_EPOCH, now),
		body = body,
		ordinal = body,
	}
end

return M

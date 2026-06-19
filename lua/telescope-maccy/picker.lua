local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values

local db = require("telescope-maccy.db")
local item = require("telescope-maccy.item")

local M = {}

--- Verify the prerequisites before launching the picker.
---@param opts table resolved config (needs db_path)
---@return boolean ok
---@return string|nil err
function M.precheck(opts)
	if vim.fn.executable("sqlite3") == 0 then
		return false, "telescope-maccy: `sqlite3` was not found on your PATH"
	end
	local path = db.expand_path(opts.db_path)
	if not vim.uv.fs_stat(path) then
		return false, "telescope-maccy: Maccy database not found at " .. path
	end
	return true
end

--- Compose the [time, body] display columns, marking pinned rows when asked.
---@param entry table result of item.make_entry
---@param opts table resolved config
---@return string[]
function M.display_columns(entry, opts)
	local time_col = entry.time
	if opts.pin_to_top and entry.pinned then
		time_col = "📌 " .. entry.time
	end
	return { time_col, entry.body }
end

--- Build the entry_maker bound to the options and a fixed "now".
---@param opts table resolved config
---@param now number current Unix time
---@return fun(row: table): table
function M.make_entry_maker(opts, now)
	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 10 },
			{ remaining = true },
		},
	})

	return function(row)
		local entry = item.make_entry(row, now)
		return {
			value = entry.value,
			ordinal = entry.ordinal,
			body = entry.body,
			is_large = entry.is_large,
			display = function()
				return displayer(M.display_columns(entry, opts))
			end,
		}
	end
end

--- Buffer lines to preview for an entry.
---@param entry table
---@return string[]
function M.preview_lines(entry)
	if entry.value == nil then
		return { entry.body }
	end
	return vim.split(entry.value, "\n", { plain = true })
end

--- Load the entry's raw value into the system and unnamed registers.
---@param entry table
---@return boolean copied
function M.copy_entry(entry)
	if not entry or entry.value == nil then
		return false
	end
	-- `+` keeps the macOS pasteboard in sync; `"` makes plain `p` work.
	pcall(vim.fn.setreg, "+", entry.value)
	vim.fn.setreg('"', entry.value)
	return true
end

local function build_previewer()
	return previewers.new_buffer_previewer({
		title = "Maccy Entry",
		define_preview = function(self, entry)
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, M.preview_lines(entry))
		end,
	})
end

--- Launch the Maccy history picker.
---@param opts table resolved config
function M.show(opts)
	local ok, err = M.precheck(opts)
	if not ok then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	db.query(opts, function(rows, query_err)
		if query_err then
			vim.notify("telescope-maccy: " .. query_err, vim.log.levels.ERROR)
			return
		end

		local now = os.time()
		pickers
			.new(opts, {
				prompt_title = "Maccy",
				finder = finders.new_table({
					results = rows,
					entry_maker = M.make_entry_maker(opts, now),
				}),
				sorter = conf.generic_sorter(opts),
				previewer = build_previewer(),
				attach_mappings = function(prompt_bufnr)
					actions.select_default:replace(function()
						local entry = action_state.get_selected_entry()
						actions.close(prompt_bufnr)
						if entry and not M.copy_entry(entry) then
							vim.notify("telescope-maccy: entry is too large to copy", vim.log.levels.WARN)
						end
					end)
					return true
				end,
			})
			:find()
	end)
end

return M

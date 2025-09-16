local config = require("toggl-track.config")

local M = {}

---@class PickerItem
---@field id number
---@field name string
---@field _raw? table

---@class PreviewField
---@field key string
---@field label string
---@field format? fun(val:any):string

---@class PickerOpts
---@field title string
---@field items PickerItem[]
---@field format_item? fun(item:PickerItem):string
---@field on_select? fun(item:PickerItem|nil)
---@field preview_fields? PreviewField[]

---@param opts PickerOpts
function M.select(opts)
	if config.options.picker == "telescope" then
		local ok, _ = pcall(require, "telescope")
		if not ok then
			vim.notify("telescope.nvim not found, falling back to native picker", vim.log.levels.WARN)
			config.options.picker = "native"
			return M.select(opts)
		end

		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local previewers = require("telescope.previewers")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		local function is_nil(v)
			return v == nil or v == vim.NIL
		end

		local function default_format(v)
			return tostring(v)
		end

		pickers
			.new({}, {
				prompt_title = opts.title,
				finder = finders.new_table({
					results = opts.items,
					entry_maker = function(item)
						return {
							value = item,
							display = opts.format_item and opts.format_item(item) or item.name,
							ordinal = item.name,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				previewer = previewers.new_buffer_previewer({
					define_preview = function(self, entry, _)
						local item = entry and entry.value or {}
						local raw = item._raw or item or {}
						local lines = {}

						if opts.preview_fields then
							for _, f in ipairs(opts.preview_fields) do
								local val = raw[f.key]
								if not is_nil(val) then
									local fmt = f.format or default_format
									table.insert(lines, string.format("%s: %s", f.label, fmt(val)))
								end
							end
						else
							-- fallback: just dump the raw object
							table.insert(lines, vim.inspect(raw))
						end

						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					end,
				}),
				attach_mappings = function(_, map)
					local select_fn = function(bufnr)
						local selection = action_state.get_selected_entry()
						actions.close(bufnr)
						if opts.on_select then
							opts.on_select(selection and selection.value or nil)
						end
					end
					map("i", "<CR>", select_fn)
					map("n", "<CR>", select_fn)
					map("i", "<C-m>", select_fn)
					map("n", "<C-m>", select_fn)
					return true
				end,
			})
			:find()
	else
		-- fallback: vim.ui.select
		vim.ui.select(opts.items, {
			prompt = opts.title,
			format_item = opts.format_item or function(item)
				return item.name
			end,
		}, opts.on_select)
	end
end

return M

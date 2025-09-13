local config = require("toggl-track.config")
local api = require("toggl-track.api")
local state = require("toggl-track.state")

local M = {}

--- Setup plugin
--- @param opts {
---   api_token: string,          -- Toggl API token
---   auto_bootstrap?: boolean,   -- fetch workspaces/projects at startup (default true)
---   default_desc?: string,      -- default description for timers (default "nvim task")
---   notify?: boolean }          -- show notifications (default true)
function M.setup(opts)
	config.setup(opts)

	-- optional bootstrap on startup
	if config.options.auto_bootstrap then
		api.bootstrap(function() end)
	end

	vim.api.nvim_create_user_command("TogglWorkspaces", function()
		if not state.workspaces or #state.workspaces == 0 then
			vim.notify("No workspaces loaded", vim.log.levels.WARN)
			return
		end

		if config.options.picker == "telescope" then
			local has_telescope, _ = pcall(require, "telescope")
			if has_telescope then
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				pickers
					.new({}, {
						prompt_title = "Toggl Workspaces",
						finder = finders.new_table({
							results = state.workspaces,
							entry_maker = function(w)
								return {
									value = w,
									display = string.format("%s (id: %d)", w.name, w.id),
									ordinal = w.name,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(_, map)
							local select_fn = function(bufnr)
								local selection = action_state.get_selected_entry()
								actions.close(bufnr)
								api.use_workspace(selection.value.id, function(ws, err)
									if ws then
										vim.notify("Switched workspace → " .. ws.name)
									elseif err then
										vim.notify("Failed: " .. err, vim.log.levels.ERROR)
									end
								end)
							end

							map("i", "<CR>", select_fn)
							map("n", "<CR>", select_fn)
							map("i", "<C-m>", select_fn)
							map("n", "<C-m>", select_fn)

							return true
						end,
					})
					:find()
				return
			else
				vim.notify("telescope.nvim not found, falling back to native picker", vim.log.levels.WARN)
				config.options.picker = "native"
			end
		end

		-- fallback native picker
		local items = {}
		for _, w in ipairs(state.workspaces) do
			table.insert(items, { id = w.id, name = w.name })
		end

		vim.ui.select(items, {
			prompt = "Select Toggl workspace",
			format_item = function(item)
				return string.format("%s (id: %d)", item.name, item.id)
			end,
		}, function(choice)
			if not choice then
				return
			end
			api.use_workspace(choice.id, function(ws, err)
				if ws then
					vim.notify("Switched workspace → " .. ws.name)
				elseif err then
					vim.notify("Failed: " .. err, vim.log.levels.ERROR)
				end
			end)
		end)
	end, {})

	-- List and switch projects
	vim.api.nvim_create_user_command("TogglProjects", function()
		if not state.projects or #state.projects == 0 then
			vim.notify("No projects loaded", vim.log.levels.WARN)
			return
		end

		-- Telescope picker
		if config.options.picker == "telescope" then
			local has_telescope, _ = pcall(require, "telescope")
			if has_telescope then
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				pickers
					.new({}, {
						prompt_title = "Toggl Projects",
						finder = finders.new_table({
							results = state.projects,
							entry_maker = function(p)
								return {
									value = p,
									display = string.format("%s  |  hours: %d", p.name, p.actual_hours or 0),
									ordinal = p.name,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(_, map)
							local select_fn = function(bufnr)
								local selection = action_state.get_selected_entry()
								actions.close(bufnr)
								api.use_project(selection.value.id, function(project, err)
									if project then
										vim.notify("Switched project → " .. project.name)
									elseif err then
										vim.notify("Failed: " .. err, vim.log.levels.ERROR)
									end
								end)
							end

							map("i", "<CR>", select_fn)
							map("n", "<CR>", select_fn)
							map("i", "<C-m>", select_fn)
							map("n", "<C-m>", select_fn)

							return true
						end,
					})
					:find()
				return
			else
				vim.notify("telescope.nvim not found, falling back to native picker", vim.log.levels.WARN)
				config.options.picker = "native"
			end
		end

		-- Native picker
		local items = {}
		for _, p in ipairs(state.projects) do
			table.insert(items, { id = p.id, name = p.name, hours = p.actual_hours or 0 })
		end

		vim.ui.select(items, {
			prompt = "Select Toggl project",
			format_item = function(item)
				return string.format("%s  |  hours: %d", item.name, item.hours)
			end,
		}, function(choice)
			if not choice then
				-- Just show list if no selection
				for i, p in ipairs(state.projects) do
					print(string.format("%d. %s  |  hours: %d", i, p.name, p.actual_hours or 0))
				end
				return
			end
			api.use_project(choice.id, function(project, err)
				if project then
					vim.notify("Switched project → " .. project.name)
				elseif err then
					vim.notify("Failed: " .. err, vim.log.levels.ERROR)
				end
			end)
		end)
	end, {})

	vim.api.nvim_create_user_command("TogglStart", function(params)
		-- if user gave a project name directly
		if params.args and params.args ~= "" then
			local project_id = nil
			for _, p in ipairs(state.projects or {}) do
				if p.name == params.args then
					project_id = p.id
				end
			end

			api.start_timer(params.args, project_id, {}, function(res, err)
				if res and res.id then
					if config.options.notify then
						vim.notify("Started Toggl timer: " .. (params.args or config.options.default_desc))
					end
				elseif err and config.options.notify then
					vim.notify("Failed to start timer: " .. err, vim.log.levels.ERROR)
				end
			end)
			return
		end

		-- no args → use Telescope picker
		if config.options.picker == "telescope" then
			local has_telescope, _ = pcall(require, "telescope")
			if has_telescope then
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")
				local previewers = require("telescope.previewers")

				pickers
					.new({}, {
						prompt_title = "Start Toggl Timer",
						finder = finders.new_table({
							results = state.projects,
							entry_maker = function(p)
								return {
									value = p,
									display = string.format("%s  |  hours: %d", p.name, p.actual_hours or 0),
									ordinal = p.name,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						previewer = previewers.new_buffer_previewer({
							define_preview = function(self, entry)
								local p = entry.value
								local lines = {
									"Project: " .. (p.name or "(no name)"),
									"ID: " .. tostring(p.id or "?"),
									"Hours: " .. tostring(p.actual_hours or 0),
									"Status: " .. (p.status or "unknown"),
								}
								vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
							end,
						}),
						attach_mappings = function(_, map)
							local select_fn = function(bufnr)
								local selection = action_state.get_selected_entry()
								actions.close(bufnr)
								api.start_timer(selection.value.name, selection.value.id, {}, function(res, err)
									if res and res.id then
										vim.notify("Started Toggl timer: " .. selection.value.name)
									elseif err then
										vim.notify("Failed to start timer: " .. err, vim.log.levels.ERROR)
									end
								end)
							end

							map("i", "<CR>", select_fn)
							map("n", "<CR>", select_fn)
							map("i", "<C-m>", select_fn)
							map("n", "<C-m>", select_fn)

							return true
						end,
					})
					:find()
				return
			end
		end

		-- fallback: vim.ui.select
		local items = {}
		for _, p in ipairs(state.projects) do
			table.insert(items, { id = p.id, name = p.name, hours = p.actual_hours or 0 })
		end

		vim.ui.select(items, {
			prompt = "Select Toggl project",
			format_item = function(item)
				return string.format("%s  |  hours: %d", item.name, item.hours)
			end,
		}, function(choice)
			if not choice then
				return
			end
			api.start_timer(choice.name, choice.id, {}, function(res, err)
				if res and res.id then
					vim.notify("Started Toggl timer: " .. choice.name)
				elseif err then
					vim.notify("Failed to start timer: " .. err, vim.log.levels.ERROR)
				end
			end)
		end)
	end, { nargs = "?" })

	vim.api.nvim_create_user_command("TogglStop", function()
		api.stop_timer(function(_, err)
			if not err then
				if config.options.notify then
					vim.notify("Stopped Toggl timer")
				end
			elseif config.options.notify then
				vim.notify(err, vim.log.levels.WARN)
			end
		end)
	end, {})

	vim.api.nvim_create_user_command("TogglCurrent", function()
		api.get_current(function(current, _)
			if current and current.id then
				vim.notify("Current: " .. current.description)
			else
				vim.notify("No active timer")
			end
		end)
	end, {})

	-- List recent time entries
	vim.api.nvim_create_user_command("TogglEntries", function(params)
		local limit = tonumber(params.args) or 10
		api.list_entries(limit, function(entries, err)
			if err then
				vim.notify("Failed to fetch entries: " .. err, vim.log.levels.ERROR)
				return
			end
			if not entries or #entries == 0 then
				vim.notify("No recent entries")
				return
			end

			if config.options.picker == "telescope" then
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				pickers
					.new({}, {
						prompt_title = "Toggl Entries",
						finder = finders.new_table({
							results = entries,
							entry_maker = function(e)
								return {
									value = e,
									display = string.format(
										"%s | %s | %s",
										e.description or "(no desc)",
										e.start or "?",
										e.duration == -1 and "running" or tostring(e.duration)
									),
									ordinal = e.description or "",
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(_, map)
							local select_fn = function(bufnr)
								local selection = action_state.get_selected_entry()
								actions.close(bufnr)
								-- maybe restart this entry?
								api.start_timer(
									selection.value.description,
									selection.value.project_id,
									{},
									function(res, e)
										if res then
											vim.notify("Restarted entry: " .. (res.description or ""))
										elseif e then
											vim.notify("Failed: " .. e, vim.log.levels.ERROR)
										end
									end
								)
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
				-- fallback: print
				for i, e in ipairs(entries) do
					print(
						string.format(
							"%d. %s | %s | %s",
							i,
							e.description or "(no desc)",
							e.start or "?",
							e.duration == -1 and "running" or tostring(e.duration)
						)
					)
				end
			end
		end)
	end, { nargs = "?" })
end

return M

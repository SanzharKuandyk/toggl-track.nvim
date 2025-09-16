local config = require("toggl-track.config")
local api = require("toggl-track.api")
local state = require("toggl-track.state")
local picker = require("toggl-track.picker")

local M = {}

function M.register()
	--------------------------------------------------------------------
	-- Workspaces
	--------------------------------------------------------------------
	vim.api.nvim_create_user_command("TogglWorkspaces", function()
		if not state.workspaces or #state.workspaces == 0 then
			vim.notify("No workspaces loaded", vim.log.levels.WARN)
			return
		end

		local items = {}
		for _, w in ipairs(state.workspaces) do
			table.insert(items, {
				id = w.id,
				name = w.name,
				_raw = w,
			})
		end

		picker.select({
			title = "Toggl Workspaces",
			items = items,
			preview_fields = {
				{ key = "id", label = "ID" },
				{ key = "name", label = "Name" },
			},
			on_select = function(choice)
				if not choice then
					return
				end
				api.workspaces.use_workspace(choice.id, function(ws, err)
					if ws then
						vim.notify("Switched workspace → " .. ws.name)
					elseif err then
						vim.notify("Failed: " .. err, vim.log.levels.ERROR)
					end
				end)
			end,
		})
	end, {})

	--------------------------------------------------------------------
	-- Projects
	--------------------------------------------------------------------
	vim.api.nvim_create_user_command("TogglProjects", function()
		if not state.projects or #state.projects == 0 then
			vim.notify("No projects loaded", vim.log.levels.WARN)
			return
		end

		local items = {}
		for _, p in ipairs(state.projects) do
			table.insert(items, {
				id = p.id,
				name = p.name,
				_raw = p,
			})
		end

		picker.select({
			title = "Toggl Projects",
			items = items,
			preview_fields = {
				{ key = "id", label = "ID" },
				{ key = "name", label = "Name" },
				{ key = "workspace_id", label = "Workspace" },
				{ key = "color", label = "Color" },
			},
			on_select = function(choice)
				if not choice then
					return
				end
				api.projects.use_project(choice.id, function(project, err)
					if project then
						vim.notify("Switched project → " .. project.name)
					elseif err then
						vim.notify("Failed: " .. err, vim.log.levels.ERROR)
					end
				end)
			end,
		})
	end, {})

	--------------------------------------------------------------------
	-- Start timer
	--------------------------------------------------------------------
	vim.api.nvim_create_user_command("TogglStart", function(params)
		-- project name passed directly
		if params.args and params.args ~= "" then
			local project_id = nil
			for _, p in ipairs(state.projects or {}) do
				if p.name == params.args then
					project_id = p.id
				end
			end

			api.timer.start(params.args, project_id, {}, function(res, err)
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

		-- picker flow
		local items = {}
		for _, p in ipairs(state.projects or {}) do
			table.insert(items, {
				id = p.id,
				name = p.name,
				_raw = p,
			})
		end

		picker.select({
			title = "Start Toggl Timer",
			items = items,
			preview_fields = {
				{ key = "id", label = "ID" },
				{ key = "name", label = "Name" },
				{ key = "workspace_id", label = "Workspace" },
			},
			on_select = function(choice)
				if not choice then
					return
				end
				api.timer.start(choice.name, choice.id, {}, function(res, err)
					if res and res.id then
						vim.notify("Started Toggl timer: " .. choice.name)
					elseif err then
						vim.notify("Failed to start timer: " .. err, vim.log.levels.ERROR)
					end
				end)
			end,
		})
	end, { nargs = "?" })

	--------------------------------------------------------------------
	-- Stop timer
	--------------------------------------------------------------------
	vim.api.nvim_create_user_command("TogglStop", function()
		api.timer.stop(function(_, err)
			if not err then
				if config.options.notify then
					vim.notify("Stopped Toggl timer")
				end
			elseif config.options.notify then
				vim.notify(err, vim.log.levels.WARN)
			end
		end)
	end, {})

	--------------------------------------------------------------------
	-- Current timer
	--------------------------------------------------------------------
	vim.api.nvim_create_user_command("TogglCurrent", function()
		api.timer.current(function(current, _)
			if current and current.id then
				vim.notify("Current: " .. current.description)
			else
				vim.notify("No active timer")
			end
		end)
	end, {})

	--------------------------------------------------------------------
	-- Recent entries
	--------------------------------------------------------------------
	vim.api.nvim_create_user_command("TogglRecent", function(params)
		local limit = tonumber(params.args) or 10
		api.entries.list(limit, function(entries, err)
			if err then
				vim.notify("Failed to fetch entries: " .. err, vim.log.levels.ERROR)
				return
			end
			if not entries or #entries == 0 then
				vim.notify("No recent entries")
				return
			end

			local items = {}
			for _, e in ipairs(entries) do
				table.insert(items, {
					id = e.id,
					name = e.description or "(no desc)",
					_raw = e,
				})
			end

			picker.select({
				title = "Toggl Recent",
				items = items,
				preview_fields = {
					{ key = "description", label = "Description" },
					{ key = "start", label = "Start" },
					{
						key = "duration",
						label = "Duration",
						format = function(v)
							return v == -1 and "running" or tostring(v)
						end,
					},
					{ key = "project_id", label = "Project ID" },
				},
				on_select = function(choice)
					if not choice then
						return
					end
					local e = choice._raw
					api.timer.start(e.description, e.project_id, {}, function(res, err)
						if res then
							vim.notify("Restarted entry: " .. (res.description or ""))
						elseif err then
							vim.notify("Failed: " .. err, vim.log.levels.ERROR)
						end
					end)
				end,
			})
		end)
	end, { nargs = "?" })
end

return M

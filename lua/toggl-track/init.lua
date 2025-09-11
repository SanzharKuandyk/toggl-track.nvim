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

	vim.api.nvim_create_user_command("TogglProjects", function()
		if not state.projects or #state.projects == 0 then
			vim.notify("No projects loaded", vim.log.levels.WARN)
			return
		end

		for i, p in ipairs(state.projects) do
			local hours = p.actual_hours or 0
			local status = p.status or "unknown"
			print(string.format("%d. %s  |  hours: %d  |  status: %s", i, p.name, hours, status))
		end
	end, {})

	vim.api.nvim_create_user_command("TogglStart", function(params)
		local project_id = nil
		for _, p in ipairs(state.projects or {}) do
			if p.name == params.args then
				project_id = p.id
			end
		end

		api.start_timer(
			params.args ~= "" and params.args or config.options.default_desc,
			project_id,
			{},
			function(res, err)
				if res and res.id then
					if config.options.notify then
						vim.notify("Started Toggl timer: " .. (params.args or config.options.default_desc))
					end
				elseif err and config.options.notify then
					vim.notify("Failed to start timer: " .. err, vim.log.levels.ERROR)
				end
			end
		)
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
end

return M

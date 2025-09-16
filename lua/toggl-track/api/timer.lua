local state = require("toggl-track.state")
local http = require("toggl-track.http")
local config = require("toggl-track.config")
local ws = require("toggl-track.api.workspaces")

local M = {}

--- Start a timer
function M.start(desc, project_id, tags, cb)
	local start_fn = function()
		local body = {
			description = desc or config.options.default_desc,
			created_with = "toggl-track.nvim",
			workspace_id = state.current_workspace.id,
			project_id = project_id or (state.current_project and state.current_project.id),
			tags = tags or {},
			duration = -1,
			start = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}

		http.request("POST", "/workspaces/" .. state.current_workspace.id .. "/time_entries", body, function(res, err)
			if err then
				cb(nil, err)
				return
			end
			state.current_entry = res
			cb(res, nil)
		end)
	end

	if state.current_workspace then
		start_fn()
	else
		ws.bootstrap(start_fn)
	end
end

--- Stop the current timer
function M.stop(cb)
	local stop_fn = function()
		if not state.current_entry or not state.current_entry.id then
			if config.options.notify then
				vim.notify("No running timer", vim.log.levels.WARN)
			end
			cb(nil, "No running timer")
			return
		end

		http.request(
			"PATCH",
			"/workspaces/" .. state.current_workspace.id .. "/time_entries/" .. state.current_entry.id .. "/stop",
			nil,
			function(res, err)
				state.current_entry = nil
				cb(res, err)
			end
		)
	end

	if state.current_workspace then
		stop_fn()
	else
		ws.bootstrap(stop_fn)
	end
end

--- Get current running timer
function M.current(cb)
	local fetch_fn = function()
		http.request("GET", "/me/time_entries/current", nil, function(current, err)
			if err or not current or not current.id then
				state.current_entry = nil
				cb(nil, err or "No active entry")
				return
			end

			state.current_entry = current

			-- resolve project
			local pname
			for _, p in ipairs(state.projects or {}) do
				if p.id == current.project_id then
					pname = p.name
					state.current_project = p
				end
			end
			current.project_name = pname or ("#" .. tostring(current.project_id or "?"))

			cb(current, nil)
		end)
	end

	if state.current_workspace then
		fetch_fn()
	else
		ws.bootstrap(fetch_fn)
	end
end

return M

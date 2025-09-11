local state = require("toggl-track.state")
local http = require("toggl-track.http")
local config = require("toggl-track.config")

local M = {}

--- Ensure workspace and projects are initialized.
--- @param cb fun():nil Callback after bootstrap is done
function M.bootstrap(cb)
	if state.current_workspace then
		cb()
		return
	end

	http.request("GET", "/workspaces", nil, function(ws, err)
		if err or not ws or not ws[1] then
			if config.options.notify then
				vim.notify("No workspaces found in Toggl", vim.log.levels.WARN)
			end
			cb()
			return
		end

		state.workspaces = ws
		state.current_workspace = ws[1]

		--if config.options.notify then
		--	vim.notify("Using workspace: " .. state.current_workspace.name)
		--end

		http.request("GET", "/workspaces/" .. state.current_workspace.id .. "/projects", nil, function(projects)
			state.projects = projects or {}
			cb()
		end)
	end)
end

--- Start a timer.
function M.start_timer(desc, project_id, tags, cb)
	local start_fn = function()
		local body = {
			description = desc or config.options.default_desc,
			created_with = "toggl-track.nvim",
			workspace_id = state.current_workspace.id,
			project_id = project_id or (state.current_project and state.current_project.id),
			tags = tags or {},
			duration = -1, -- "-1" => running entry
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
		M.bootstrap(start_fn)
	end
end

--- Stop the current timer.
function M.stop_timer(cb)
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
		M.bootstrap(stop_fn)
	end
end

--- Get the currently running timer.
function M.get_current(cb)
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
		M.bootstrap(fetch_fn)
	end
end

return M

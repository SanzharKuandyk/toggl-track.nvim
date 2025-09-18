local state = require("toggl-track.state")
local http = require("toggl-track.http")
local config = require("toggl-track.config")

local M = {}

--- Bootstrap (workspace + projects)
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

		http.request("GET", "/workspaces/" .. state.current_workspace.id .. "/projects", nil, function(projects)
			state.projects = projects or {}
			cb()
		end)
	end)
end

--- Reload all state (workspaces, current workspace, projects)
--- @param cb fun():nil
function M.reload(cb)
	M.bootstrap(function()
		if config.options.notify then
			vim.notify("Toggl state reloaded")
		end
		if cb then
			cb()
		end
	end)
end

--- Switch current workspace
function M.use_workspace(workspace_id, cb)
	local ws
	for _, w in ipairs(state.workspaces or {}) do
		if w.id == workspace_id then
			state.current_workspace = w
			ws = w
		end
	end
	if not ws then
		cb(nil, "Workspace not found: " .. tostring(workspace_id))
		return
	end

	http.request("GET", "/workspaces/" .. ws.id .. "/projects", nil, function(projects, err)
		if err then
			cb(nil, err)
			return
		end
		state.projects = projects or {}
		cb(ws, nil)
	end)
end

return M

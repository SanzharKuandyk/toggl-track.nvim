local state = require("toggl-track.state")

local M = {}

--- Switch current project
function M.use_project(project_id, cb)
	local project
	for _, p in ipairs(state.projects or {}) do
		if p.id == project_id then
			state.current_project = p
			project = p
		end
	end
	if not project then
		cb(nil, "Project not found: " .. tostring(project_id))
	else
		cb(project, nil)
	end
end

return M

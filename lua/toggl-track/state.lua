local M = {}

-- list of all workspaces fetched from Toggl API
M.workspaces = {}

-- list of projects for the current workspace
M.projects = {}

-- the workspace currently selected/active
M.current_workspace = nil

-- the project currently selected/active
M.current_project = nil

-- the currently running time entry (if any)
M.current_entry = nil

return M

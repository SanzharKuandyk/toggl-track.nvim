local M = {}

M.timer = require("toggl-track.api.timer")
M.projects = require("toggl-track.api.projects")
M.workspaces = require("toggl-track.api.workspaces")
M.tags = require("toggl-track.api.tags")
M.reports = require("toggl-track.api.reports")
M.entries    = require("toggl-track.api.entries")

return M

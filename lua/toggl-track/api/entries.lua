local state = require("toggl-track.state")
local http = require("toggl-track.http")
local ws = require("toggl-track.api.workspaces")

local M = {}

--- List recent time entries
function M.list(limit, cb)
	local fetch_fn = function()
		http.request("GET", string.format("/me/time_entries?per_page=%d", limit or 10), nil, function(entries, err)
			if err then
				cb(nil, err)
				return
			end
			cb(entries, nil)
		end)
	end

	if state.current_workspace then
		fetch_fn()
	else
		ws.bootstrap(fetch_fn)
	end
end

return M

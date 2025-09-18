local state = require("toggl-track.state")
local http = require("toggl-track.http")
local ws = require("toggl-track.api.workspaces")

local M = {}

--- Get the last finished time entry
--- @param cb fun(entry: table|nil, err: string|nil)
function M.last(cb)
	local fetch_fn = function()
		http.request("GET", "/me/time_entries?per_page=1", nil, function(entries, err)
			if err then
				cb(nil, err)
				return
			end
			if not entries or #entries == 0 then
				cb(nil, "No previous entries")
				return
			end
			cb(entries[1], nil)
		end)
	end

	if state.current_workspace then
		fetch_fn()
	else
		ws.bootstrap(fetch_fn)
	end
end

--- Resume a previous time entry by creating a new one
--- @param entry table  -- the entry object to resume
--- @param cb fun(entry: table|nil, err: string|nil)
function M.resume(entry, cb)
  local fn = function()
    local body = {
      description    = entry.description,
      project_id     = entry.project_id,
      tags           = entry.tags or {},
      workspace_id   = state.current_workspace.id,
      duration       = -1,
      start          = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      created_with   = "toggl-track.nvim",
    }
    http.request(
      "POST",
      "/workspaces/" .. state.current_workspace.id .. "/time_entries",
      body,
      function(res, err)
        if err then
          cb(nil, err)
          return
        end
        state.current_entry = res
        cb(res, nil)
      end
    )
  end

  if state.current_workspace then
    fn()
  else
    ws.bootstrap(fn)
  end
end

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

local config = require("toggl-track.config")
local api = require("toggl-track.api")
local commands = require("toggl-track.commands")

local M = {}

--- Setup plugin
--- @param opts {
---   api_token: string,          -- Toggl API token
---   auto_bootstrap?: boolean,   -- fetch workspaces/projects at startup (default true)
---   default_desc?: string,      -- default description for timers (default "nvim task")
---   notify?: boolean,           -- show notifications (default true)
---   picker?: "telescope"|"native", -- picker backend
--- }
function M.setup(opts)
	config.setup(opts)

	if config.options.auto_bootstrap then
		api.workspaces.bootstrap(function() end)
	end

	-- register all commands
	commands.register()
end

return M

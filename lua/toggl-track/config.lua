local M = {}

M.options = {
	--- Toggl API token (required)
	api_token = nil,

	--- Whether to automatically fetch workspace + projects on setup
	auto_bootstrap = true,

	--- Default description to use when starting timers
	default_desc = "nvim task",

	--- Whether to show notifications in Neovim
	notify = true,

	--- Picker UI: "native" (vim.ui.select) or "telescope"
	picker = "native",
}

--- Apply user-provided options (shallow merge).
--- @param opts table
function M.setup(opts)
	M.options = vim.tbl_extend("force", M.options, opts or {})
end

return M

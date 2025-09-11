local curl = require("plenary.curl")
local config = require("toggl-track.config")

local M = {}

M.base_url = "https://api.track.toggl.com/api/v9"

--- Perform an asynchronous Toggl API request.
--- @param method string HTTP method ("GET", "POST", "PATCH", etc.)
--- @param endpoint string API endpoint (e.g. "/me/time_entries/current")
--- @param body table|nil Request body (Lua table, will be JSON encoded)
--- @param cb fun(res: table|nil, err: string|nil) Callback with decoded response or error
function M.request(method, endpoint, body, cb)
	if not config.options.api_token then
		if config.options.notify then
			vim.schedule(function()
				vim.notify("Toggl API token not set", vim.log.levels.ERROR)
			end)
		end
		return
	end

	curl.request({
		url = M.base_url .. endpoint,
		method = method,
		auth = config.options.api_token .. ":api_token",
		headers = {
			["Content-Type"] = "application/json",
		},
		body = body and vim.json.encode(body) or nil,
		callback = vim.schedule_wrap(function(res)
			if not res then
				cb(nil, "No response from curl")
				return
			end

			if res.exit ~= 0 then
				cb(nil, "Curl failed with exit=" .. tostring(res.exit))
				return
			end

			if res.status < 200 or res.status >= 300 then
				cb(nil, "HTTP error: " .. tostring(res.status) .. "; body: " .. tostring(res.body))
				return
			end

			if not res.body or res.body == "" then
				cb({}, nil)
				return
			end

			local ok, decoded = pcall(vim.json.decode, res.body)
			if not ok or type(decoded) ~= "table" then
				cb(nil, "JSON decode error or unexpected body: " .. tostring(res.body))
				return
			end

			cb(decoded, nil)
		end),
	})
end

return M

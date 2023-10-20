local M = {}

local awful = require("awful")

function M.awm_master_width_factor()
	return {
		key = "master_width_factor",
		value = function()
			return awful.getmwfact()
		end,
	}
end

return M

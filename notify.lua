local M = {}

local naughty = require("naughty")

function M.info(s)
	print(s)
end

function M.warn(s)
	naughty.notify({ title = "[motion warn]", text = s })
end

function M.error(s)
	naughty.notify({ title = "[motion error]", text = s, timeout = 0 })
end

return M

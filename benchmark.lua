local lib = require("modalisa.lib")
local modal = require("modalisa.modal")
local M = {}

function M.benchmark(n)
	local f = function()
		M.run("")
		M.fake_input("stop")
	end

	lib.benchmark(f, n or 100)

	modal:stop()
end

function M.benchmark_input(n, key)
	modal.run("")
	local f = function()
		M.fake_input(key or "a", true)
	end

	lib.benchmark(f, n or 100)

	modal:stop()
end

return M

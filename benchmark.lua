local lib = require("modalisa.lib")
local modal = require("modalisa.modal")
local M = {}

function M.benchmark(n)
	local f = function()
		modal.run("")
		modal.fake_input("stop")
	end

	lib.benchmark(f, n or 100)

	modal:stop()
end

function M.benchmark_input(n, key)
	modal.run("")
	local f = function()
		modal.fake_input(key or "a", true)
	end

	lib.benchmark(f, n or 100)

	modal:stop()
end

function M.benchmark_hints(n)
	modal.run("")
	local f = function()
		awesome.emit_signal("modalisa::hints::hide")
		awesome.emit_signal("modalisa::hints::toggle")
	end

	lib.benchmark(f, n or 100)

	modal:stop()
end

return M

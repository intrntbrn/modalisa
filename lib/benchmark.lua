local M = {}

local units = {
	["seconds"] = 1,
	["milliseconds"] = 1000,
	["microseconds"] = 1000000,
	["nanoseconds"] = 1000000000,
}

local function benchmark(unit, decPlaces, n, f, ...)
	local elapsed = 0
	local multiplier = units[unit]
	for _ = 1, n do
		local now = os.clock()
		f(...)
		elapsed = elapsed + (os.clock() - now)
	end
	print(
		string.format(
			"Benchmark results: %d function calls | %."
				.. decPlaces
				.. "f %s elapsed | %."
				.. decPlaces
				.. "f %s avg execution time.",
			n,
			elapsed * multiplier,
			unit,
			(elapsed / n) * multiplier,
			unit
		)
	)
end

function M.benchmark(f, n, ...)
	do
		benchmark("milliseconds", 1, n, f, ...)
	end
end

return M

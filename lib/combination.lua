local M = {}

local wrap, yield = coroutine.wrap, coroutine.yield
-- This function clones the array t and appends the item new to it.
local function _append(t, new)
	local clone = {}
	for _, item in ipairs(t) do
		clone[#clone + 1] = item
	end
	clone[#clone + 1] = new
	return clone
end

--[[
    Yields combinations of non-repeating items of tbl.
    tbl is the source of items,
    sub is a combination of items that all yielded combination ought to contain,
    min it the minimum key of items that can be added to yielded combinations.
--]]
function M.unique_combinations(tbl, sub, min)
	sub = sub or {}
	min = min or 1
	return wrap(function()
		if #sub > 0 then
			yield(sub) -- yield short combination.
		end
		if #sub < #tbl then
			for i = min, #tbl do -- iterate over longer combinations.
				for combo in M.unique_combinations(tbl, _append(sub, tbl[i]), i + 1) do
					yield(combo)
				end
			end
		end
	end)
end

return M

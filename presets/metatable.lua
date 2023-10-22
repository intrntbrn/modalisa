local M = {}

local mt = {
	__add = function(lhs, rhs)
		return vim.tbl_deep_extend("force", lhs, rhs)
	end,
}

local function set(obj)
	return setmetatable(obj, mt)
end

return setmetatable(M, {
	__call = function(_, obj)
		return set(obj)
	end,
})

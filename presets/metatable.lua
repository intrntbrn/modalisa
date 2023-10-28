local M = {}

local mt = {
	__add = function(lhs, rhs)
		return M.set(vim.tbl_deep_extend("force", lhs, rhs))
	end,
}

function M.set(obj)
	return setmetatable(obj, mt)
end

return setmetatable(M, {
	__call = function(_, obj)
		return M.set(obj)
	end,
})

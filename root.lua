local tree = require("modalisa.tree")
local config = require("modalisa.config")
local vim = require("modalisa.lib.vim")
local dump = vim.inspect

local M = {}

local root_tree

-- @param[opt=nil] seq
function M.add(key, seq)
	root_tree:add(key, seq)
end

-- @param[opt=""] prefix
function M.add_keys(keys, prefix)
	for k, v in pairs(keys) do
		root_tree:add(v, k, prefix)
	end
end

-- @param[opt=""] seq
function M.get(seq)
	seq = seq or ""
	return root_tree:get(seq)
end

function M.remove(seq)
	return root_tree:remove(seq)
end

function M.setup(opts)
	assert(root_tree == nil, "root is already setup")
	root_tree = tree:new(opts, "modalisa")

	awesome.connect_signal("modalisa::config", function(_, _)
		-- when config has been updated, we have to merge all opts again
		local new_opts = config.get_config()
		root_tree:add_opts(new_opts)
	end)
end

return setmetatable(M, {
	__index = function(_, k)
		return root_tree:get(k)
	end,
	__newindex = function(_, k, v)
		return root_tree:add(v, k)
	end,
	__tostring = function(_)
		return dump(root_tree)
	end,
})

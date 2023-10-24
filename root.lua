local tree = require("motion.tree")
local config = require("motion.config")
local vim = require("motion.lib.vim")

local M = {}

local root_tree

-- @param[opt=nil] seq
function M.add(key, seq)
	root_tree:add(key, seq)
end

function M.add_keys(keys)
	for k, v in pairs(keys) do
		root_tree:add(v, k)
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
	root_tree = tree:new(opts, "motion root")

	awesome.connect_signal("motion::config", function(k, v)
		local new_opts = config.get()
		root_tree._data.opts_raw = new_opts
		root_tree._data.opts_merged = new_opts
		root_tree:update_opts() -- update all merged opts
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
		return vim.inspect(root_tree)
	end,
})

local awesome = awesome
local tree = require("motion.tree")
local modal = require("motion.modal")
local config = require("motion.config")

local M = {}

-- run key sequence on root
M.run = function(...)
	return modal.run(...)
end

-- run benchmark
M.benchmark = function()
	return modal.benchmark()
end

-- add key to root
M.add_key = function(key)
	---@diagnostic disable-next-line: need-check-nil
	return tree.add_key(key)
end

-- get key from root
M.get_tree = function(key, opts)
	---@diagnostic disable-next-line: need-check-nil
	return tree.get_key(key, opts)
end

-- add keys to root
M.add_keys = function(keys)
	---@diagnostic disable-next-line: need-check-nil
	return tree.add_keys(keys)
end

-- config set
M.set = function(k, v)
	config[k] = v
end

-- config get
M.get = function(k)
	return config[k]
end

local once
local function gen_signals()
	-- TODO: some signatures have more than 1 arg
	assert(once == nil, "commands gen_signals once")
	once = true
	for k, v in pairs(M) do
		if type(v) == "function" then
			local name = string.format("motion::%s", k)
			awesome.connect_signal(name, v)
		end
	end
end

gen_signals()
return M

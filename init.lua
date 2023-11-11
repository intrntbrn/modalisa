local M = {}

local dump = require("modalisa.lib.vim").inspect
local root_tree = require("modalisa.root")
local modal = require("modalisa.modal")
local config = require("modalisa.config")

-- run key sequence on root
function M.run(...)
	return modal.run(...)
end

-- run inline tree
function M.run_tree(...)
	return modal.run_tree(...)
end

function M.stop()
	modal.stop()
end

function M.fake_input(...)
	return modal.fake_input(...)
end

-- add key to root
function M.add_key(...)
	return root_tree.add(...)
end

-- remove key from root
function M.remove_key(...)
	return root_tree.remove(...)
end

-- get key from root
function M.get_tree(...)
	return root_tree.get(...)
end

-- add keys to root
function M.add_keys(...)
	return root_tree.add_keys(...)
end

-- config set var
function M.set(k, v)
	config[k] = v
end

-- config get var
function M.get(k)
	return config[k]
end

-- get complete config
function M.get_config(opts)
	return config.get_config(opts)
end

local mt = {
	__call = function(_, opts)
		return M.setup(opts)
	end,
}

local once
function M.setup(opts)
	assert(once == nil, "modalisa is already setup")
	once = true
	config.setup(opts)
	opts = config.get_config() or {}

	print(dump(opts))

	require("modalisa.root").setup(opts)
	require("modalisa.modal").setup(opts)

	require("modalisa.ui.hints").setup(opts)
	require("modalisa.ui.label").setup(opts)
	require("modalisa.ui.echo").setup(opts)
	require("modalisa.ui.prompt").setup(opts)

	-- default keys
	if opts.include_default_keys then
		require("modalisa.keys").setup(opts)
	end

	-- user defined keys
	if pcall(require, "modalisa_keys") then
		require("modalisa_keys").setup(opts)
	end

	return setmetatable(M, mt)
end

return setmetatable(M, mt)

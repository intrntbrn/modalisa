local M = {}

---@diagnostic disable-next-line: unused-local
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
function M.get_config(...)
	return config.get_config(...)
end

-- get complete config
function M.get_default_config(...)
	return config.get_default_config(...)
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

	require("modalisa.root").setup(opts)
	require("modalisa.modal").setup(opts)

	-- NOTE: all UI modules are only invoked by signals making them completely
	-- optional, so that users are able to implement their own, if configuration
	-- options do not suit them.

	if not opts.disable_hints then
		require("modalisa.ui.hints").setup(opts)
	end

	if not opts.disable_label then
		require("modalisa.ui.label").setup(opts)
	end

	if not opts.disable_echo then
		require("modalisa.ui.echo").setup(opts)
	end

	if not opts.disable_prompt then
		require("modalisa.ui.prompt").setup(opts)
	end

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

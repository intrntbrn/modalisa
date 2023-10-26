local M = {}

local dump = require("motion.lib.vim").inspect
local root_tree = require("motion.root")
local modal = require("motion.modal")
local config = require("motion.config")

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
function M.get_config()
	return config.get()
end

local mt = {
	__call = function(_, opts)
		return M.setup(opts)
	end,
}

local function gen_signals()
	for k, v in pairs(M) do
		if type(v) == "function" then
			local name = string.format("motion::%s", k)
			awesome.connect_signal(name, function(...)
				v(...)
			end)
		end
	end
end

local once
function M.setup(opts)
	assert(once == nil, "motion is already setup")
	once = true
	config.setup(opts)
	opts = config.get() or {}

	print(dump(opts))

	require("motion.root").setup(opts)
	require("motion.modal").setup(opts)

	require("motion.ui.hints").setup(opts)
	require("motion.ui.label").setup(opts)
	require("motion.ui.echo").setup(opts)
	require("motion.ui.prompt").setup(opts)

	-- default keys
	if opts.include_default_keys then
		require("motion.keys").setup(opts)
	end

	-- user defined keys
	if pcall(require, "motion_keys") then
		require("motion_keys").setup(opts)
	end

	gen_signals()

	return setmetatable(M, mt)
end

return setmetatable(M, mt)

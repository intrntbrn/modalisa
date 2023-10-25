local M = {}

local dump = require("motion.lib.vim").inspect

function M.stop()
	print("fucking weird")
end

local mt = {
	__call = function(_, opts)
		return M.setup(opts)
	end,
	__index = function(_, k)
		return require("motion.api")[k]
	end,
}

local once
function M.setup(opts)
	assert(once == nil, "motion is already setup")
	once = true
	local config = require("motion.config")
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

	return setmetatable(M, mt)
end

return setmetatable(M, mt)

local M = {}

local dump = require("motion.vim").inspect

function M.setup(opts)
	local config = require("motion.config")
	config.setup(opts)
	opts = config.get() or {}

	print(dump(opts))

	require("motion.tree").setup(opts)
	require("motion.modal").setup(opts)

	require("motion.ui.hints").setup(opts)
	require("motion.ui.label").setup(opts)
	require("motion.ui.echo").setup(opts)

	if opts.default_keys then
		require("motion.default").setup(opts)
	end

	return require("motion.commands")
end

return setmetatable(M, {
	__call = function(_, opts)
		return M.setup(opts)
	end,
	__index = function(_, k)
		return require("motion.commands")[k]
	end,
})

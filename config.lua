local M = {}
local vim = require("motion.vim")

local unpack = unpack or table.unpack

local defaults = {
	-- keys
	key = "<M-y>",
	back_keys = "<BackSpace>",
	stop_keys = { "<Escape>" },

	-- core
	unique = { "key" },
	mod_hold_continue = true,
	mod_release_stop = "after", -- always | after
	stop_on_unknown_key = true,
	timeout = 0,

	-- hints
	hints_delay = 0,
	show_hints = true,

	default_keys = true,

	-- awesome
	auto_select_the_only_choice = false,
	labels = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
	resize_delta = require("beautiful").xresources.apply_dpi(32),
	resize_factor = 0.025,
	browser = "firefox || chromium || google-chrome-stable || qutebrowser",
	terminal = "alacritty || kitty || wezterm || st || urxvt || xterm",
	app_menu = "rofi -show drun -display-drun ''",
}

local options

local function update(key)
	local value = rawget(options, key)
	print("motion::config: ", key, " = ", vim.inspect(value))
	awesome.emit_signal(string.format("motion::property::%s", key), value)
end

function M.setup(opts)
	assert(not options, "setup called twice")
	options = defaults
	options = M.get(opts or {})

	for k in pairs(options) do
		update(k)
	end
end

function M.get(...)
	if options == nil then
		M.setup()
	end

	local all = { {}, options }

	for i = 1, select("#", ...) do
		local opts = select(i, ...)
		if opts then
			table.insert(all, opts)
		end
	end

	local ret = vim.tbl_deep_extend("force", unpack(all))

	return ret
end

return setmetatable(M, {
	__index = function(_, key)
		if options == nil then
			M.setup()
		end
		---@diagnostic disable-next-line: need-check-nil, param-type-mismatch
		return rawget(options, key)
	end,
	__newindex = function(_, key, value)
		if options == nil then
			M.setup()
		end
		---@diagnostic disable-next-line: param-type-mismatch
		rawset(options, key, value)
		update(key)
	end,
})

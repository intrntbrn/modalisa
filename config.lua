local M = {}
local vim = require("motion.vim")

local unpack = unpack or table.unpack

local defaults = {
	show_hints = true,
	default_keys = true,
	hints_delay = 0,
	exit_key = { "Escape" },
	back_key = "BackSpace",
	hold_mod_stay_open = true,
	hold_mod_auto_close = true,
	stop_on_unknown_key = true,
	auto_select_the_only_choice = false,
	timeout = 0,

	key = { { "Mod4" }, "y" },
	labels = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",

	resize_delta = require("beautiful").xresources.apply_dpi(32),
	resize_factor = 0.025,

	browser = "firefox || chromium || google-chrome-stable || qutebrowser",
	terminal = "alacritty || kitty || wezterm || st || urxvt || xterm",
	app_menu = "rofi -show drun -display-drun ''",

	unique = { "key" },
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

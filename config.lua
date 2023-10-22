local M = {}
local vim = require("motion.lib.vim")
local dump = vim.inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi

local unpack = unpack or table.unpack

local defaults = {
	-- keys
	key = "<M-y>",
	back_keys = "<BackSpace>",
	stop_keys = { "<Escape>" },
	default_keys = true,

	-- core
	unique = { "key", "hidden", "fg" },
	mode = "hybrid", -- "modal" | "hold" | "hybrid" | "forever"
	stop_on_unknown_key = false,
	ignore_shift_state_for_special_characters = true,
	timeout = 0,

	-- hints
	hints_show = true,
	hints_delay = 0,
	hints_show_disabled_keys = false,
	hints_sort = "group", -- group | id | nil
	hints_key_aliases = {
		-- ["(A%-)[%u%-]"] = "Alt",
		-- ["S%-"] = "Shift",
		-- ["C%-"] = "Ctrl",
		-- ["M%-"] = "Super",
		[" "] = "space",
		Left = "←",
		Right = "→",
		Up = "↑",
		Down = "→",
		XF86MonBrightnessUp = "🔆+",
		XF86MonBrightnessDown = "🔅-",
		XF86AudioRaiseVolume = "🕩+",
		XF86AudioLowerVolume = "🕩-",
		XF86AudioMute = "🔇",
		XF86AudioPlay = "⏯",
		XF86AudioPrev = "⏮",
		XF86AudioNext = "⏭",
		XF86AudioStop = "⏹",
	},
	hints_key_separator = " ➜ ",
	hints_max_key_width = 5,
	hints_min_entry_width = 30,
	hints_width = 0.75,
	hints_height = 0.4,
	hints_fill_strategy = "width", -- width | height
	hints_placement = "top",
	hints_placement_offset = {
		left = 0,
		right = 0,
		top = 0,
		bottom = dpi(50),
	},
	hints_odd_style = "row", -- row  | column | checkered | none
	hints_font = "Monospace Bold 12",
	hints_font_separator = "Monospace Bold 12",
	hints_font_desc = "Monospace 12",

	hints_color_entry_fg = "#eceffc",
	hints_color_entry_disabled_fg = "#959cbc",
	hints_color_entry_desc_fg = "#eceffc",
	hints_color_entry_separator_fg = "#82AAFF",
	hints_color_entry_bg = "#24283B",
	hints_color_entry_odd_bg = "#383F5A",

	-- echo
	echo = true,
	echo_placement = "centered",
	echo_timeout = 1000,

	echo_orientation = "horizontal", -- vertical | horizontal
	echo_entry_width = 12,
	echo_entry_width_strategy = "exact", -- min | max | exact
	echo_padding = {
		top = dpi(5),
		bottom = dpi(5),
		left = dpi(5),
		right = dpi(5),
	},
	echo_spacing = 0,

	echo_font_header = "Monospace Bold 22",
	echo_font = "Monospace Bold 22",
	echo_border_width = dpi(1),

	echo_odd = -10,
	echo_shape = nil,
	echo_opacity = 1,
	echo_color_border = "#1A1E2D",
	echo_color_bg = "#383F5A",
	echo_color_fg = "#eceffc",
	echo_color_header_fg = "#82AAFF",

	-- awesome
	auto_select_the_only_choice = false,
	labels = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
	resize_delta = dpi(32),
	resize_factor = 0.025,
	browser = "firefox || chromium || google-chrome-stable || qutebrowser",
	terminal = terminal or "alacritty || kitty || wezterm || st || urxvt || xterm",
	app_menu = "rofi -show drun || dmenu_run",
}

local options

local function on_update(key)
	local value = rawget(options, key)
	print("motion::config: ", key, " = ", vim.inspect(value))
	awesome.emit_signal(string.format("motion::property::%s", key), value)
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

function M.setup(opts)
	assert(not options, "config setup once")
	options = defaults
	options = M.get(opts or {})

	for k in pairs(options) do
		on_update(k)
	end
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
		on_update(key)
	end,
	__tostring = function(t)
		if options == nil then
			M.setup()
		end
		return dump(options)
	end,
})

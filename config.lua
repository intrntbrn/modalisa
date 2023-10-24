local M = {}
local vim = require("motion.lib.vim")
local dump = vim.inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
local awful = require("awful")

local unpack = unpack or table.unpack

local defaults = {
	-- keys
	key = "<M-y>",
	back_keys = "<BackSpace>",
	stop_keys = { "<Escape>" },
	default_keys = true,

	-- core
	unique = { "key", "hidden", "fg", "continue" },
	mode = "hybrid", -- "modal" | "hold" | "hybrid" | "forever"
	ignore_modifiers = true,
	stop_on_unknown_key = false,
	ignore_shift_state_for_special_characters = true,
	timeout = 0, -- ms

	-- hints
	hints = {
		enabled = true,
		delay = 0, -- ms
		show_disabled_keys = true,
		sort = "group", -- group | id | nil
		key_aliases = {
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
		separator = " ➜ ",
		entry_key_width = 5, -- chars
		min_entry_width = 25, -- chars
		max_entry_width = 30, -- chars
		width = 0.75, -- fraction or abs
		height = 0.3, -- fraction or abs
		fill_remaining_space = true,
		fill_strategy = "horizontal", -- horizontal | vertical
		placement = function(h)
			awful.placement.bottom(h, { honor_workarea = true })
		end,
		border_width = dpi(1),
		opacity = 1,
		shape = nil,
		odd_style = "row", -- row  | column | checkered | none
		font = "Monospace Bold 12",
		font_separator = "Monospace Bold 12",
		font_desc = "Monospace 12",

		group_colors = {
			["menu"] = "#FF00FF",
		},
		color_border = "#444A73",
		color_entry_fg = "#eceffc",
		color_entry_disabled_fg = "#959cbc",
		color_entry_desc_fg = "#eceffc",
		color_entry_separator_fg = "#82AAFF",
		color_entry_bg = "#383F5A",
		color_entry_odd_bg = -12, -- color or luminosity
		color_hover_bg = 20, -- color or luminosity
	},

	echo = {
		enabled = true,
		placement = "centered",
		timeout = 1000, -- ms
		orientation = "vertical", -- vertical | horizontal

		entry_width = 20, -- chars
		entry_width_strategy = "exact", -- min | max | exact
		padding = {
			top = dpi(5),
			bottom = dpi(5),
			left = dpi(5),
			right = dpi(5),
		},
		spacing = 0,

		font_header = "Monospace Bold 22",
		font = "Monospace Bold 22",
		border_width = dpi(1),

		odd = -12, -- luminosity or color
		shape = nil,
		opacity = 1,
		color_border = "#444A73",
		color_bg = "#383F5A",
		color_fg = "#eceffc",
		color_header_fg = "#82AAFF",
	},

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
	awesome.emit_signal("motion::config", key, value)
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

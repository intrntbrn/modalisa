local M = {}
local vim = require("motion.lib.vim")
local dump = vim.inspect
local dpi = require("beautiful").xresources.apply_dpi
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

local unpack = unpack or table.unpack

local defaults = {
	-- keys
	root_key = "<M-y>",
	back_keys = "<BackSpace>",
	stop_keys = { "<Escape>" },
	include_default_keys = true,

	-- core
	mode = "hybrid", -- "modal" | "hold" | "hybrid" | "forever"
	smart_modifiers = true,
	stop_on_unknown_key = false,
	ignore_shift_state_for_special_characters = true,
	timeout = 0, -- ms
	unique = {},

	theme = {
		fg = beautiful.fg_focus or "#eceffc",
		bg = beautiful.bg_focus or "#24283B",
		grey = beautiful.fg_normal or "#959cbc",
		border = beautiful.border_color_normal or "#444A73",
		accent = "#82AAFF",
	},

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
		border_width = beautiful.border_width or dpi(1),
		opacity = 1,
		shape = nil,
		odd_style = "row", -- row  | column | checkered | none
		font = "Monospace Bold 12",
		font_separator = "Monospace Bold 12",
		font_desc = "Monospace 12",
		group_colors = {
			["menu"] = "#FF00FF",
		},
		color_border = nil,
		color_fg = nil,
		color_disabled_fg = nil,
		color_desc_fg = nil,
		color_separator_fg = nil,
		color_bg = nil,
		color_odd_bg = -8, -- color or luminosity
		color_hover_bg = 20, -- color or luminosity
	},

	echo = {
		enabled = true,
		show_percentage_as_progressbar = true,
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
		font_header = "Monospace Bold 20",
		font = "Monospace 20",
		border_width = beautiful.border_width or dpi(1),
		odd = 0, -- luminosity or color
		shape = nil,
		opacity = 1,
		color_border = nil,
		color_bg = nil,
		color_fg = nil,
		color_header_fg = nil,

		progressbar = {
			shape = gears.shape.rounded_rect,
			bar_shape = gears.shape.rounded_rect,
			border_width = dpi(2),
			bar_border_width = dpi(2),
			color = nil,
			background_color = nil,
			border_color = nil,
			bar_border_color = nil,
			margins = {
				left = 5,
				right = 5,
				top = 5,
				bottom = 5,
			},
			paddings = nil,
			opacity = 1,
		},
	},

	prompt = {
		placement = "centered",
		orientation = "vertical",
		width = 20, -- chars
		padding = {
			top = dpi(5),
			bottom = dpi(5),
			left = dpi(5),
			right = dpi(5),
		},
		spacing = 0,
		font_header = "Monospace Bold 20",
		font = "Monospace Bold 20",
		border_width = beautiful.border_width or dpi(1),
		shape = nil,
		opacity = 1,
		color_border = nil,
		color_bg = nil,
		color_fg = nil,
		color_header_fg = nil,
		color_cursor_fg = nil,
		color_cursor_bg = nil,
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
	assert(options)

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

function M.set(k, v)
	assert(options)
	assert(type(k) == "string", "key is not a string")

	local tbl = {}
	tbl[k] = v and vim.deepcopy(v)
	local merged = vim.tbl_deep_extend("force", options, tbl)
	assert(merged)

	options = merged
	on_update(k)
end

function M.setup(opts)
	assert(not options, "config is already setup")
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

		M.set(key, value)
	end,
	__tostring = function(_)
		if options == nil then
			M.setup()
		end
		return dump(options)
	end,
})

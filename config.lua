local M = {}
local vim = require("modalisa.lib.vim")
local dump = vim.inspect
local dpi = require("beautiful").xresources.apply_dpi
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

local unpack = unpack or table.unpack

local defaults = {
	root_keys = { "<M-a>" },
	back_keys = { "<BackSpace>" },
	stop_keys = { "<Escape>" },
	include_default_keys = true,

	mode = "hybrid", -- "modal" | "hold" | "hybrid" | "forever"
	smart_modifiers = true, -- like smartcase but for all root key modifiers
	stop_on_unknown_key = false,
	timeout = 0, -- ms
	labels = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@\\^_`{|}~",
	ignore_shift_state_for_special_characters = true,

	toggle_false = "on", -- "", "", "toggle", "on"
	toggle_true = "off", -- "", -"", "toggle", "off"

	theme = {
		fg = beautiful.fg_focus or "#eceffc",
		bg = beautiful.bg_focus or "#24283B",
		grey = beautiful.fg_normal or "#959cbc",
		border = beautiful.border_color_normal or "#444A73",
		accent = "#82AAFF",
	},

	hints = {
		enabled = true,
		delay = 0, -- ms
		show_header = false,
		show_disabled_keys = true,
		sort = "group", -- group | id | key | none
		mouse_button_select = 1, -- left click
		mouse_button_select_continue = 3, -- right click
		mouse_button_stop = 2, -- middle click
		mouse_button_back = 8, -- back click
		color_border = nil,
		color_odd_bg = -8, -- color or luminosity delta
		color_hover_bg = 15, -- color or luminosity delta
		color_disabled_fg = nil,
		font_header = "Monospace 12",
		color_header_fg = nil,
		color_header_bg = nil,
		highlight = {
			bg = nil,
			key = {
				font = "Monospace 12",
			},
			desc = {
				font = "Monospace 12",
				italic = true,
			},
			separator = {
				font = "Monospace 12",
			},
		},
		menu_highlight = {
			desc = {
				bold = true,
			},
		},
		group_highlights = {
			-- ["^awesome"] = {
			-- 	desc = {
			-- 		underline = true,
			-- 	},
			-- },
		},
		separator = " ➜ ",
		entry_key_width = 5, -- chars
		min_entry_width = 25, -- chars
		max_entry_width = 30, -- chars
		entry_padding = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0,
		},
		padding = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0,
		},
		margin = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0,
		},
		width = 0.75, -- fraction or abs pixel count
		height = 0.35, -- fraction or abs pixel count
		stretch_vertical = false, -- use all available height
		stretch_horizontal = false, -- use all available width
		flow_horizontal = false, -- fill from left to right
		expand_horizontal = true, -- use all available columns first
		placement = function(h) -- function, placement (e.g. "centered") or false (last position)
			awful.placement.bottom(h, { honor_workarea = true })
		end,
		border_width = beautiful.border_width or dpi(1),
		opacity = 1,
		shape = nil,
		odd_style = "row", -- row  | column | checkered | none
		odd_empty = true, -- continue odd pattern for empty entries
		key_aliases = {
			[" "] = "space",
			Left = "←",
			Right = "→",
			["^Up"] = "↑",
			["[%-]Up"] = "↑",
			["^Down"] = "↓",
			["[%-]Down"] = "↓",
			XF86MonBrightnessUp = "󰃝 +",
			XF86MonBrightnessDown = "󰃝 -",
			XF86AudioRaiseVolume = "󰝝",
			XF86AudioLowerVolume = "󰝞",
			XF86AudioMute = "󰝟",
			XF86AudioPlay = "󰐊",
			XF86AudioPrev = "󰒮",
			XF86AudioNext = "󰒭",
			XF86AudioStop = "󰓛",
		},
	},

	echo = {
		enabled = true,
		show_percentage_as_progressbar = false, -- display 0-1.0 as progressbar
		placement = "centered", -- or any awful.placement func
		timeout = 1000, -- ms
		align_vertical = true, -- key above value
		vertical_layout = false, -- kvs from top to bottom

		entry_width = 20, -- chars
		entry_width_strategy = "exact", -- min | max | exact
		padding = {
			top = dpi(3),
			bottom = dpi(3),
			left = dpi(3),
			right = dpi(3),
		},
		spacing = 0,
		border_width = beautiful.border_width or dpi(1),
		shape = nil,
		opacity = 1,
		color_border = nil,
		highlight = {
			key = {
				font = "Monospace 20",
				bg = nil,
				fg = nil,
				italic = true,
				bold = true,
			},
			value = {
				font = "Monospace 20",
				bg = nil,
				fg = nil,
			},
		},

		progressbar = {
			shape = gears.shape.rounded_rect,
			bar_shape = gears.shape.rounded_rect,
			border_width = dpi(2),
			bar_border_width = dpi(2),
			color = nil,
			background_color = nil,
			border_color = nil,
			bar_border_color = nil,
			margin = {
				left = dpi(5),
				right = dpi(5),
				top = dpi(5),
				bottom = dpi(5),
			},
			padding = {
				left = 0,
				right = 0,
				top = 0,
				bottom = 0,
			},
			opacity = 1,
		},
	},

	prompt = {
		placement = "centered", -- or any awful.placement func
		vertical_layout = true, -- from top to bottom
		width = 20, -- chars
		width_strategy = "min", -- min | max | exact
		padding = {
			top = dpi(5),
			bottom = dpi(5),
			left = dpi(5),
			right = dpi(5),
		},
		spacing = 0,
		border_width = beautiful.border_width or dpi(1),
		shape = nil,
		opacity = 1,
		color_border = nil,
		header_highlight = {
			font = "Monospace 20",
			fg = nil,
			bg = nil,
			bold = true,
			italic = true,
		},
		font = "Monospace 20",
		color_bg = nil,
		color_fg = nil,
		color_cursor_fg = nil,
		color_cursor_bg = nil,
	},

	label = {
		shape = gears.shape.rounded_rect,
		border_width = beautiful.border_width or dpi(1),
		color_border = nil,
		width = dpi(100),
		height = dpi(100),
		opacity = 1,
		highlight = {
			font = "Monospace 40",
			bg = nil,
			fg = nil,
			bold = true,
		},
	},

	awesome = {
		auto_select_the_only_choice = false,
		resize_delta = dpi(32),
		resize_factor = 0.025,
		browser = "firefox || chromium || google-chrome-stable || qutebrowser",
		terminal = terminal or "alacritty || kitty || wezterm || st || urxvt || xterm",
		app_menu = "rofi -show drun || dmenu_run",
	},
}

local parameter_options = {
	mode = { "modal", "hold", "hybrid", "forever" },
	hints = {
		sort = { "group", "id", "key", "nil" },
		odd_style = { "row", "column", "checkered", "none" },
	},

	prompt = {
		width_strategy = { "min", "max", "exact" },
	},

	echo = {
		entry_width_strategy = { "min", "max", "exact" },
	},
}

local options

local function on_update(key)
	local value = rawget(options, key)
	print("modalisa::config: ", key, " = ", vim.inspect(value))
	awesome.emit_signal("modalisa::config", key, value)
end

function M.get_default_config(...)
	local all = { {}, defaults }

	for i = 1, select("#", ...) do
		local opts = select(i, ...)
		if opts then
			table.insert(all, opts)
		end
	end

	local ret = vim.tbl_deep_extend("force", unpack(all))
	return ret
end

function M.get_config(...)
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

function M.set_config(...)
	-- TODO: determine changed params and emit property signals
	local new = M.get_config(...)
	options = vim.deepcopy(new)
	awesome.emit_signal("modalisa::config")
end

function M.get(k)
	assert(options)
	assert(type(k) == "string", "key is not a string")

	if not options[k] then
		return nil
	end

	return vim.deepcopy(options[k])
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

function M.get_options()
	return parameter_options
end

function M.setup(opts)
	assert(not options, "config is already setup")
	options = defaults
	options = M.get_config(opts or {})
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

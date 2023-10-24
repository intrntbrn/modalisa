local config = require("motion.config")
local util = require("motion.util")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local dump = require("motion.lib.vim").inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
local lib = require("motion.lib")

local M = {}

local popup = {}
local timer

local function make_center_textbox(eopts, text, font, fg, width)
	local tb = wibox.widget.base.make_widget_declarative({
		{
			markup = util.markup.fg(fg, text),
			font = font,
			valign = "center",
			halign = "center",
			widget = wibox.widget.textbox,
		},
		forced_height = beautiful.get_font_height(font),
		width = width,
		strategy = eopts.entry_width_strategy,
		widget = wibox.container.constraint,
	})
	return tb
end

local function make_key_value_textbox(eopts, key, value)
	local font = eopts.font
	local fg = eopts.color_fg
	local font_header = eopts.font_header
	local fg_header = eopts.color_header_fg

	local font_width = dpi(math.max(util.get_font_width(font), util.get_font_width(font_header)))
	local width = font_width * eopts.entry_width

	local tb_key = make_center_textbox(eopts, key, font_header, fg_header, width)
	local tb_value = make_center_textbox(eopts, value, font, fg, width)

	local layout
	local orientation = eopts.orientation
	if orientation == "vertical" then
		layout = wibox.layout.fixed.vertical({})
	elseif orientation == "horizontal" then
		layout = wibox.layout.fixed.horizontal({})
	end

	local base = wibox.widget.base.make_widget_declarative({
		tb_key,
		tb_value,
		spacing = eopts.spacing,
		layout = layout,
	})

	return base
end

local function create_widget(eopts, kvs)
	local widgets = {}
	local i = 1
	for k, v in pairs(kvs) do
		local bg = eopts.color_bg
		local is_odd = (i % 2) == 0
		if is_odd then
			local odd = eopts.odd
			bg = util.color_or_luminosity(odd, bg)
		end

		local tb = make_key_value_textbox(eopts, k, v)
		local base = wibox.widget.base.make_widget_declarative({
			{
				tb,
				margins = eopts.padding,
				widget = wibox.container.margin,
			},
			bg = bg,
			widget = wibox.container.background,
		})
		table.insert(widgets, base)
		i = i + 1
	end

	local layout
	local orientation = eopts.orientation
	if orientation == "vertical" then
		layout = wibox.layout.fixed.horizontal({})
	elseif orientation == "horizontal" then
		layout = wibox.layout.fixed.vertical({})
	end

	for _, kv in ipairs(widgets) do
		layout:add(kv)
	end

	local base = wibox.widget.base.make_widget_declarative({
		{
			layout,
			valign = "center",
			halign = "center",
			widget = wibox.container.place,
		},
		border_width = eopts.border_width,
		border_color = eopts.color_border,
		shape = eopts.shape,
		opacity = eopts.opacity,
		widget = wibox.container.background,
	})

	return base
end

function popup:new(eopts)
	local pop = awful.popup({
		visible = false,
		ontop = true,
		above = true,
		widget = wibox.widget.base.make_widget_declarative({}),
	})

	self.popup = pop
	return pop
end

function popup:set_visible(v)
	self.popup.visible = v
end

function popup:is_visible()
	return self.popup.visible
end

function popup:set_widget(widget, eopts)
	local s = awful.screen.focused()
	local placement = type(eopts.placement) == "string" and awful.placement[eopts.placement] or eopts.placement

	self.popup.widget = widget
	self.popup.screen = s
	if placement then
		self.popup.placement = placement
	end
	self.popup.visible = true
end

local function set_timer(eopts)
	if timer then
		timer:stop()
	end

	local delay = eopts.timeout

	timer = gears.timer({
		timeout = delay / 1000,
		callback = function()
			popup:set_visible(false)
		end,
		autostart = true,
		single_shot = true,
	})
end

local function handle(args)
	local result = args.result
	if not result then
		print("no result")
		return
	end

	local t = args.tree
	if not t then
		return
	end

	local opts = t:opts()
	if not opts then
		return
	end

	local eopts = opts.echo
	if not eopts.enabled then
		return
	end

	local widget = create_widget(eopts, result)
	popup:set_widget(widget, eopts)
	set_timer(eopts)
end

local once
function M.setup(opts)
	assert(once == nil, "echo is already setup")
	once = true

	popup:new(opts)
	awesome.connect_signal("motion::exec", function(args)
		handle(args)
	end)
end

return M

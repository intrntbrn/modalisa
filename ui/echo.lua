local config = require("motion.config")
local util = require("motion.util")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local dump = require("motion.vim").inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi

local M = {}

local popup = {}
local timer

local function make_center_textbox(text, font, fg)
	local tb = wibox.widget.base.make_widget_declarative({
		{
			markup = util.markup.fg(fg, text),
			font = font,
			widget = wibox.widget.textbox,
		},
		valign = "center",
		halign = "center",
		widget = wibox.container.place,
	})
	return tb
end

local function textbox(text, opts)
	local tb = wibox.widget.base.make_widget_declarative({
		markup = text,
		font = opts.echo_font,
		widget = wibox.widget.textbox,
	})
	return tb
end

local function double_vert(opts, key, value)
	local font = opts.echo_font
	local fg = opts.echo_color_fg
	local font_header = opts.echo_font_header
	local fg_header = opts.echo_color_header_fg

	local tb_key = make_center_textbox(key, font_header, fg_header)
	local tb_value = make_center_textbox(value, font, fg)

	print("make base")

	local base = wibox.widget.base.make_widget_declarative({
		{
			{
				tb_key,
				tb_value,
				layout = wibox.layout.fixed.vertical(),
			},
			widget = wibox.container.constraint,
		},
		bg = opts.echo_color_bg,
		widget = wibox.container.background,
	})

	print("base done")

	return base
end

local function create_widget(opts, key, value)
	local widget = double_vert(opts, key, value)

	local base = wibox.widget.base.make_widget_declarative({
		{
			{
				widget,
				valign = "center",
				halign = "center",
				widget = wibox.container.place,
			},
			border_width = opts.echo_border_width,
			border_color = opts.echo_color_border,
			bg = opts.echo_color_bg,
			fg = opts.echo_color_fg,
			-- forced_width = 200,
			-- forced_height = 200,
			shape = nil,
			widget = wibox.container.background,
		},
		opacity = 1,
		widget = wibox.container.margin,
	})

	return base
end

function popup:new(opts)
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

function popup:set_widget(widget, opts)
	local s = awful.screen.focused()
	local placement = type(opts.echo_placement) == "string" and awful.placement[opts.echo_placement]
		or opts.echo_placement

	self.popup.widget = widget
	self.popup.screen = s
	if placement then
		self.popup.placement = placement
	end
	self.popup.visible = true
end

local function set_timer(opts)
	if timer then
		timer:stop()
	end

	local delay = opts.echo_timeout

	timer = gears.timer({
		timeout = delay / 1000,
		callback = function()
			popup:set_visible(false)
		end,
		autostart = true,
		single_shot = true,
	})
end

local function parse(e)
	if type(e) == "table" then
		local k = e.key
		local v = e.value
		if type(k) == "function" then
			k = k()
		end
		if type(v) == "function" then
			v = v()
		end
	end
end

local function handle(args)
	local t = args.tree
	local opts = t:opts()
	local e = args.echo

	local k
	local v
	if type(e) == "table" then
		k = e.key
		v = e.value
		if type(k) == "function" then
			k = k()
		end
		if type(v) == "function" then
			v = v()
		end
	end

	assert(k)
	assert(v)

	local widget = create_widget(opts, k, v)
	popup:set_widget(widget, opts)
	set_timer(opts)
end

local once
function M.setup(opts)
	assert(once == nil, "echo is already setup")
	once = true

	popup:new(opts)
	awesome.connect_signal("motion::echo", function(args)
		handle(args)
	end)
end

-- emit(name, value)
-- boolean: checkbox, string: textbox, float 0-1: progressbar
-- local types = "text, checkbox, progressbar"

-- local types = { value,}

return M

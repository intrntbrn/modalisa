local config = require("motion.config")
local util = require("motion.util")
local wibox = require("wibox")
local awful = require("awful")
local dump = require("motion.lib.vim").inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi

local M = {}

local popup = {}
local prompt

local function make_textbox(popts, text, font, fg, width)
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
		strategy = popts.width_strategy,
		widget = wibox.container.constraint,
	})
	return tb
end

local function make_prompt(popts, header_text)
	local font = popts.font
	local font_header = popts.font_header
	local fg_header = popts.color_header_fg

	local font_width = dpi(math.max(util.get_font_width(font), util.get_font_width(font_header)))
	local width = font_width * popts.width

	local tb_header

	if header_text and string.len(header_text) > 0 then
		tb_header = make_textbox(popts, header_text, font_header, fg_header, width)
	end

	local layout
	local orientation = popts.orientation
	if orientation == "vertical" then
		layout = wibox.layout.fixed.vertical({})
	elseif orientation == "horizontal" then
		layout = wibox.layout.fixed.horizontal({})
	end

	local base = wibox.widget.base.make_widget_declarative({
		tb_header,
		prompt,
		spacing = tb_header and popts.spacing,
		layout = layout,
	})

	return base
end

local function create_widget(text, popts)
	local tb = make_prompt(popts, text)

	local base = wibox.widget.base.make_widget_declarative({
		{
			{
				{
					tb,
					margins = popts.padding,
					widget = wibox.container.margin,
				},
				bg = popts.color_bg,
				widget = wibox.container.background,
			},
			valign = "center",
			halign = "center",
			widget = wibox.container.place,
		},
		border_width = popts.border_width,
		border_color = popts.color_border,
		shape = popts.shape,
		opacity = popts.opacity,
		widget = wibox.container.background,
	})

	return base
end

function popup:init(popts)
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

function popup:set_widget(widget, popts)
	local s = awful.screen.focused()
	local placement = type(popts.placement) == "string" and awful.placement[popts.placement] or popts.placement

	self.popup.widget = widget
	self.popup.screen = s
	if placement then
		self.popup.placement = placement
	end
	self.popup.visible = true
end

local function run(fn, initial, header_text, opts)
	assert(fn)
	opts = opts or config.get()

	local popts = opts.prompt

	local widget = create_widget(header_text, popts)
	popup:set_widget(widget, popts)

	prompt.bg = popts.color_bg
	prompt.fg = popts.color_fg

	local pargs = {
		prompt = "",
		font = popts.font,
		fg_cursor = popts.color_cursor_fg,
		bg_cursor = popts.color_cursor_bg,
		text = initial or "",
		done_callback = function()
			popup:set_visible(false)
		end,
	}

	awful.prompt.run(pargs, prompt.widget, fn)
end

local once
function M.setup(opts)
	assert(once == nil, "prompt is already setup")
	once = true

	-- create widgets
	prompt = awful.widget.prompt()
	popup:init(opts)

	---@diagnostic disable-next-line: redefined-local
	awesome.connect_signal("motion::prompt", function(fn, initial, header, opts)
		run(fn, initial, header, opts)
	end)
end

function M.run(fn, initial, header, opts)
	run(fn, initial, header, opts)
end

return M

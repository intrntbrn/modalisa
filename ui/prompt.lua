local config = require("modalisa.config")
local util = require("modalisa.util")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}

local popup = {}
local prompt

---@diagnostic disable-next-line: unused-local
local function make_textbox(opts, text, font)
	local popts = opts.prompt
	local hl_header = popts.header_highlight
	local fg = hl_header.fg or opts.theme.accent
	local markup = util.apply_highlight(text, hl_header)
	local tb = wibox.widget.base.make_widget_declarative({
		{
			markup = util.markup.fg(markup, fg),
			font = font,
			valign = "center",
			halign = "center",
			widget = wibox.widget.textbox,
		},
		forced_height = beautiful.get_font_height(font),
		strategy = "exact",
		widget = wibox.container.constraint,
	})
	return tb
end

local function make_prompt(opts, header_text)
	local popts = opts.prompt
	local hl_header = popts.header_highlight

	local default_font = popts.font
	local font = hl_header.font or default_font
	local font_width = dpi(math.max(util.get_font_width(default_font), util.get_font_width(font)))
	local width = font_width * popts.width

	local tb_header
	if header_text and string.len(header_text) > 0 then
		tb_header = make_textbox(opts, header_text, font)
	end

	local layout
	if popts.vertical_layout then
		layout = wibox.layout.fixed.vertical({})
	else
		layout = wibox.layout.fixed.horizontal({})
	end

	local base = wibox.widget.base.make_widget_declarative({
		{
			{
				tb_header,
				prompt,
				spacing = tb_header and popts.spacing,
				layout = layout,
			},
			strategy = "max",
			width = awful.screen.focused().geometry.width - popts.padding.left - popts.padding.right,
			height = awful.screen.focused().geometry.height - popts.padding.top - popts.padding.bottom,
			widget = wibox.container.constraint,
		},
		strategy = popts.width_strategy,
		width = width,
		widget = wibox.container.constraint,
	})

	return base
end

local function create_widget(text, opts)
	local popts = opts.prompt
	local tb = make_prompt(opts, text)

	local base = wibox.widget.base.make_widget_declarative({
		{
			{
				{
					tb,
					margins = popts.padding,
					widget = wibox.container.margin,
				},
				bg = popts.color_bg or opts.theme.bg,
				widget = wibox.container.background,
			},
			valign = "center",
			halign = "center",
			widget = wibox.container.place,
		},
		border_width = popts.border_width,
		border_color = popts.color_border or opts.theme.border,
		shape = popts.shape,
		opacity = popts.opacity,
		widget = wibox.container.background,
	})

	return base
end

---@diagnostic disable-next-line: unused-local
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

local function run(fn, initial_text, header_text, opts)
	assert(fn)
	opts = opts or config.get_config()
	header_text = header_text or ""

	if type(initial_text) ~= "string" then
		initial_text = string.format("%s", initial_text)
	end

	local popts = opts.prompt

	local widget = create_widget(header_text, opts)
	popup:set_widget(widget, popts)

	prompt.bg = popts.color_bg or opts.theme.bg
	prompt.fg = popts.color_fg or opts.theme.fg

	local pargs = {
		prompt = "",
		font = popts.font,
		fg_cursor = popts.color_cursor_fg or opts.theme.bg,
		bg_cursor = popts.color_cursor_bg or opts.theme.fg,
		text = initial_text or "",
		done_callback = function()
			popup:set_visible(false)
		end,
		textbox = prompt.widget,
		exe_callback = fn,
	}

	awful.prompt.run(pargs)
end

local once
function M.setup(opts)
	assert(once == nil, "prompt is already setup")
	once = true

	---@diagnostic disable-next-line: redefined-local
	awesome.connect_signal("modalisa::prompt", function(args, opts)
		local fn = args.fn
		local header = args.header
		local initial = args.initial

		run(fn, initial, header, opts)
	end)

	-- create widgets
	prompt = awful.widget.prompt()
	popup:init(opts)
end

return M

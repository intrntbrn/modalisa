local config = require("modalisa.config")
local util = require("modalisa.util")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}

local popup = {}
local timer

local function create_textbox(text, opts, fg, highlight, width)
	local eopts = opts.echo
	local font = highlight.font
	local markup = util.apply_highlight(text, highlight)
	local tb = wibox.widget.base.make_widget_declarative({
		{
			markup = util.markup.fg(markup, fg),
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

local function create_progressbar(value, opts, _, highlight, width)
	local eopts = opts.echo
	local popts = eopts.progressbar
	local font = highlight.font
	local tb = wibox.widget.base.make_widget_declarative({
		{
			max_value = 1,
			value = value,
			color = popts.color or opts.theme.fg,
			background_color = popts.background_color or opts.theme.bg,
			bar_border_color = popts.bar_border_color or opts.theme.fg,
			border_color = popts.border_color or opts.theme.border,
			bar_shape = popts.bar_shape,
			shape = popts.shape,
			border_width = popts.border_width,
			bar_border_width = popts.bar_border_width,
			margins = popts.margin,
			paddings = popts.padding,
			opacity = popts.opacity,
			widget = wibox.widget.progressbar,
		},
		forced_height = beautiful.get_font_height(font),
		width = width,
		strategy = eopts.entry_width_strategy,
		widget = wibox.container.constraint,
	})
	return tb
end

local function create_element(value, opts, fg, highlight, width)
	local eopts = opts.echo
	local t = type(value)
	if t == "string" then
		return create_textbox(value, opts, fg, highlight, width)
	end
	if t == "number" then
		if eopts.show_percentage_as_progressbar then
			if value >= 0 and value <= 1.0 then
				return create_progressbar(value, opts, fg, highlight, width)
			end
		end
	end
	return create_textbox(value, opts, fg, highlight, width)
end

local function create_key_value_widget(opts, key, value)
	local eopts = opts.echo
	local highlight = eopts.highlight
	local hl_key = highlight.key
	local hl_value = highlight.value

	local font_value = hl_value.font
	local fg_value = hl_value.fg or opts.theme.fg
	local font_key = hl_key.font or font_value
	local fg_key = hl_key.fg or opts.theme.accent

	local font_width = dpi(math.max(util.get_font_width(font_value), util.get_font_width(font_key)))
	local width = font_width * eopts.entry_width

	local tb_key
	if key ~= nil then
		tb_key = create_element(key, opts, fg_key, hl_key, width)
	end

	local tb_value
	if value ~= nil then
		if type(value) ~= "string" or string.len(value) > 0 then
			tb_value = create_element(value, opts, fg_value, hl_value, width)
		end
	end

	local layout
	if eopts.align_vertical then
		layout = wibox.layout.fixed.vertical({})
	else
		layout = wibox.layout.fixed.horizontal({})
	end

	local default_bg = opts.theme.bg
	local bg_key = hl_key.bg or default_bg
	local bg_value = hl_value.bg or default_bg

	local base = wibox.widget.base.make_widget_declarative({
		{
			{
				tb_key,
				margin = eopts.padding,
				widget = wibox.container.margin,
			},
			bg = bg_key,
			widget = wibox.container.background,
		},
		{
			{
				tb_value,
				margin = eopts.padding,
				widget = wibox.container.margin,
			},
			bg = bg_value,
			widget = wibox.container.background,
		},
		spacing = tb_key and tb_value and eopts.spacing,
		layout = layout,
	})

	return base
end

local function create_widget(opts, kvs)
	local eopts = opts.echo
	local widgets = {}
	local i = 1

	local iter = pairs
	if eopts.sort then
		iter = vim.spairs
	end

	for _, kv in iter(kvs) do
		local k = kv.key
		local v = kv.value

		local tb = create_key_value_widget(opts, k, v)
		table.insert(widgets, tb)
		i = i + 1
	end

	local layout
	if eopts.vertical_layout then
		layout = wibox.layout.fixed.vertical({})
	else
		layout = wibox.layout.fixed.horizontal({})
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
		border_color = eopts.color_border or opts.theme.border,
		shape = eopts.shape,
		opacity = eopts.opacity,
		widget = wibox.container.background,
	})

	return base
end

---@diagnostic disable-next-line: unused-local
function popup:init(eopts)
	local pop = awful.popup({
		visible = false,
		ontop = true,
		above = true,
		widget = wibox.widget.base.make_widget_declarative({}),
	})

	pop:connect_signal("button::press", function(_, _, _, _)
		pop.visible = false
	end)

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

local function transform(kvs)
	local list = {}
	for k, v in pairs(kvs) do
		table.insert(list, { key = k, value = v })
	end

	table.sort(list, function(a, b)
		return a.key < b.key
	end)
	return list
end

local function run(kvs, opts)
	opts = config.get_config(opts)
	---@diagnostic disable-next-line: need-check-nil
	local eopts = opts.echo

	local list = transform(kvs)

	local widget = create_widget(opts, list)
	popup:set_widget(widget, eopts)
	set_timer(eopts)
end

local function handle_signal(t, results)
	if not results then
		return
	end

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

	run(results, opts)
end

function M.show(kvs, opts)
	run(kvs, opts)
end

function M.show_simple(key, value, opts)
	if not value then
		value = ""
	end

	local result = {}
	result[key] = value

	run(result, opts)
end

local once
function M.setup(opts)
	assert(once == nil, "echo is already setup")
	once = true

	popup:init(opts)

	awesome.connect_signal("modalisa::on_exec", function(tree, result)
		handle_signal(tree, result)
	end)
end

return M

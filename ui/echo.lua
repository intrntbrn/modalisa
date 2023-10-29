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

local function create_textbox(text, eopts, font, fg, width)
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

local function create_progressbar(value, opts, font, fg, width)
	local eopts = opts.echo
	local popts = eopts.progressbar
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
			paddings = popts.paddings,
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

local function create_element(value, opts, font, fg, width)
	local eopts = opts.echo
	local t = type(value)
	if t == "string" then
		return create_textbox(value, eopts, font, fg, width)
	end
	if t == "number" then
		if eopts.show_percentage_as_progressbar then
			if value >= 0 and value <= 1.0 then
				return create_progressbar(value, opts, font, fg, width)
			end
		end
	end
	return create_textbox(value, eopts, font, fg, width)
end

local function create_key_value_widget(opts, key, value)
	local eopts = opts.echo
	local font = eopts.font
	local fg = eopts.color_fg or opts.theme.fg
	local font_key = eopts.font_header
	local fg_key = eopts.color_header_fg or opts.theme.accent

	local font_width = dpi(math.max(util.get_font_width(font), util.get_font_width(font_key)))
	local width = font_width * eopts.entry_width

	local tb_key
	if key ~= nil then
		tb_key = create_element(key, opts, font_key, fg_key, width)
	end

	local tb_value
	if value ~= nil then
		tb_value = create_element(value, opts, font, fg, width)
	end

	local layout
	if eopts.vertical_layout then
		layout = wibox.layout.fixed.vertical({})
	else
		layout = wibox.layout.fixed.horizontal({})
	end

	local base = wibox.widget.base.make_widget_declarative({
		tb_key,
		tb_value,
		spacing = tb_key and tb_value and eopts.spacing,
		layout = layout,
	})

	return base
end

local function create_widget(opts, kvs)
	local eopts = opts.echo
	local widgets = {}
	local i = 1
	for _, kv in ipairs(kvs) do
		local k = kv.key
		local v = kv.value

		local bg = eopts.color_bg or opts.theme.bg
		local is_odd = (i % 2) == 0
		if is_odd then
			local odd = eopts.odd
			bg = util.color_or_luminosity(odd, bg)
		end

		local tb = create_key_value_widget(opts, k, v)
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
	if eopts.vertical_layout then
		layout = wibox.layout.fixed.horizontal({})
	else
		layout = wibox.layout.fixed.vertical({})
	end

	-- local orientation = eopts.orientation
	-- if orientation == "vertical" then
	-- 	layout = wibox.layout.fixed.horizontal({})
	-- elseif orientation == "horizontal" then
	-- 	layout = wibox.layout.fixed.vertical({})
	-- end

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
	opts = opts or config.get_config()
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

	---@diagnostic disable-next-line: redefined-local
	awesome.connect_signal("modalisa::echo", function(kvs, opts)
		run(kvs, opts)
	end)

	awesome.connect_signal("modalisa::executed", function(tree, result)
		handle_signal(tree, result)
	end)
end

return M

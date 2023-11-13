local awful = require("awful")
local wibox = require("wibox")
local config = require("modalisa.config")
local util = require("modalisa.util")

local M = {}
local popup = {}
local popups = {}

function popup:new()
	local inst = {}

	inst.popup = awful.popup({
		visible = false,
		ontop = true,
		above = true,

		widget = wibox.widget({
			{
				{
					id = "textbox",
					widget = wibox.widget.textbox,
				},
				widget = wibox.container.place,
			},
			id = "background",
			widget = wibox.container.background,
		}),
	})

	return setmetatable(inst, {
		__index = popup,
	})
end

function popup:is_visible()
	return self.popup.visible
end

function popup:set_visible(value)
	self.popup.visible = value
end

function popup:set(text, placement, opts)
	local lopts = opts.label
	local widget = self.popup.widget
	local highlight = lopts.highlight

	local bg = widget:get_children_by_id("background")[1]
	local tb = widget:get_children_by_id("textbox")[1]

	tb.markup = util.apply_highlight(text, highlight)
	tb.font = highlight.font

	bg.fg = highlight.fg or opts.theme.bg
	bg.bg = highlight.bg or opts.theme.accent
	bg.forced_width = lopts.width
	bg.forced_height = lopts.height
	bg.border_color = lopts.color_border or opts.theme.border
	bg.border_width = lopts.border_width
	bg.shape = lopts.shape
	bg.opacity = lopts.opacity

	self.popup.placement = placement
end

local function hide_labels()
	for _, p in pairs(popups) do
		p:set_visible(false)
	end
	popups = {}
end

local function show_label(placement, text, opts)
	opts = opts or config.get_config()
	text = text or ""

	local p = popup:new()
	p:set(text, placement, opts)
	p:set_visible(true)
	table.insert(popups, p)
end

local function show_label_parent(parent, text, opts)
	local placement = function(x)
		awful.placement.centered(x, { parent = parent })
	end
	return show_label(placement, text, opts)
end

local once
function M.setup(_)
	assert(once == nil, "label is already setup")
	once = true

	awesome.connect_signal("modalisa::label::show", function(parent, text, opts)
		show_label_parent(parent, text, opts)
	end)

	awesome.connect_signal("modalisa::label::hide", function()
		hide_labels()
	end)

	awesome.connect_signal("modalisa::on_stop", function(_)
		hide_labels()
	end)
end

return M

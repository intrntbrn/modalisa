local awful = require("awful")
local wibox = require("wibox")
local config = require("modalisa.config")

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
	local bg = widget:get_children_by_id("background")[1]
	local tb = widget:get_children_by_id("textbox")[1]

	tb.markup = text
	tb.font = lopts.font

	bg.fg = lopts.fg or opts.theme.bg
	bg.bg = lopts.bg or opts.theme.accent
	bg.forced_width = lopts.width
	bg.forced_height = lopts.height
	bg.border_color = lopts.border_color or opts.theme.border
	bg.border_width = lopts.border_width
	bg.shape = lopts.shape
	bg.opacity = lopts.opacity

	self.popup.placement = placement
end

function M.hide_labels()
	for _, p in pairs(popups) do
		p:set_visible(false)
	end
	popups = {}
end

function M.show_label_parent(parent, label, opts)
	local placement = function(x)
		awful.placement.centered(x, { parent = parent })
	end
	return M.show_label(placement, label, opts)
end

function M.show_label(placement, label, opts)
	opts = opts or config.get_config()
	label = label or ""

	local p = popup:new()
	p:set(label, placement, opts)
	p:set_visible(true)
	table.insert(popups, p)
end

local once
function M.setup(_)
	assert(once == nil, "label is already setup")
	once = true

	awesome.connect_signal("modalisa::stopped", function(_)
		M.hide_labels()
	end)
end

return M

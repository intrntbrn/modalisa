local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local util = require("motion.util")
local dpi = require("beautiful").xresources.apply_dpi

local M = {}

local popups = {}

function M.hide_labels()
	if #popups == 0 then
		return
	end

	for _, p in pairs(popups) do
		p.visible = false
	end

	popups = {}
end

function M.show_label(parent, label)
	local p = M.create_popup(parent, string.format("%s", label))
	p.visible = true
	-- TODO: fix offset
	awful.placement.centered(p, { parent = parent, offset = { x = -50, y = -50 } })
	table.insert(popups, p)
end

function M.create_popup(c, text)
	text = text or ""

	local popup = awful.popup({
		hide_on_rightclick = true,
		screen = awful.screen.focused(),
		visible = true,
		ontop = true,
		above = true,

		widget = wibox.widget({
			{
				{
					text = text,
					font = "JetBrainsMono Nerd Font Bold 40",
					widget = wibox.widget.textbox,
				},
				widget = wibox.container.place,
			},
			fg = "#000000",
			bg = "#FCA7EA",
			forced_width = dpi(100),
			forced_height = dpi(100),
			border_color = "#383F5A",
			border_width = dpi(0),
			shape = gears.shape.rounded_rect,
			widget = wibox.container.background,
		}),
	})

	return popup
end

function M.setup(_)
	awesome.connect_signal("motion::stopped", function()
		M.hide_labels()
	end)
end

return M

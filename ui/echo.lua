local config = require("motion.config")
local util = require("motion.util")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local dump = require("motion.vim").inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi

local M = {}

local popup
local timer

local function hide(_)
	if popup then
		popup.visible = false
	end
	popup = nil
end

local function textbox(text, opts) end

local function create_popup(opts, widget)
	local old_popup = popup

	local s = awful.screen.focused()

	local base = wibox.widget.base.make_widget_declarative({
		{
			widget,
			bg = "#1A1E2D",
			-- forced_width = max_width,
			-- forced_height = max_height,
			shape = gears.shape.rounded_rect,
			widget = wibox.container.background,
		},
		-- margins = opts.hints_placement_offset,
		opacity = 1,
		bg = "#ff00ff00",
		widget = wibox.container.margin,
	})

	popup = awful.popup({
		hide_on_rightclick = true,
		screen = awful.screen.focused(),
		visible = true,
		ontop = true,
		above = true,
		placement = awful.placement.centered,
		widget = base,
	})

	-- prevent flickering
	if old_popup then
		-- without delay there is still some occasional flickering
		gears.timer({
			timeout = 0.01,
			callback = function()
				old_popup.visible = false
			end,
			single_shot = true,
			autostart = true,
		})
	end
end

local function handle(args)
	-- if enabled etc

	local opts = args.opts
	create_popup()
end

function M.show()
	create_popup()
end

function M.setup(opts)
	awesome.connect_signal("motion::echo", function(args)
		handle(args)
	end)
end

return M

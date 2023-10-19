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

local function textbox(text, opts)
	local tb = wibox.widget.base.make_widget_declarative({
		markup = text,
		font = opts.echo_font,
		widget = wibox.widget.textbox,
	})
	return tb
end

local function create_popup(opts, widget)
	local old_popup = popup

	local s = awful.screen.focused()

	local base = wibox.widget.base.make_widget_declarative({
		{
			{
				widget,
				valign = "center",
				halign = "center",

				widget = wibox.container.place,
			},
			bg = opts.echo_color_bg,
			fg = opts.echo_color_fg,
			-- forced_width = 200,
			-- forced_height = 200,
			shape = gears.shape.rounded_rect,
			widget = wibox.container.background,
		},
		opacity = 1,
		widget = wibox.container.margin,
	})

	popup = awful.popup({
		hide_on_rightclick = true,
		screen = s,
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
	print("handle", dump(args))
	-- if enabled etc
	local opts = args.opts

	create_popup(opts, textbox("lololol", opts))
end

function M.setup(opts)
	print("echo setup")
	awesome.connect_signal("motion::echo", function(args)
		handle(args)
	end)
end

-- emit(name, value)
-- boolean: checkbox, string: textbox, float 0-1: progressbar
-- local types = "text, checkbox, progressbar"

-- local types = { value,}

return M

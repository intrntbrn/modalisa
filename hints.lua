local config = require("motion.config")
local util = require("motion.util")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local dump = require("motion.vim").inspect

local M = {}

local popup
local timer

local function hide(_)
	if popup then
		popup.visible = false
	end
	popup = nil
end

local function create_popup(t)
	local old_popup = popup
	local flex = wibox.layout.fixed.vertical({
		id = "flex",
	})

	local succs = t:successors()

	local elements = {}
	for k, succ in pairs(succs) do
		if succ:cond() then
			local succ_opts = succ:opts()
			if not succ_opts.hidden then
				local group = ""
				if succ_opts and succ_opts.group then
					group = succ_opts.group
				end

				k = util.keyname(k, succ_opts.hints_key_aliases)
				local text = string.format("[%s]", k)
				local desc = succ:desc()
				if desc and string.len(desc) > 0 then
					text = text .. string.format(" > %s", succ:desc())
				end

				table.insert(elements, {
					group = group,
					text = text,
					id = succ:id(),
				})
			end
		end
	end

	-- sort by group and desc
	table.sort(elements, function(a, b)
		if a.group == b.group then
			return a.text < b.text
		end
		return a.group < b.group
	end)

	-- --sort by id
	-- table.sort(elements, function(a, b)
	-- 	return a.id < b.id
	-- end)

	-- header
	local desc = t:desc()
	if desc then
		local tb = wibox.widget.textbox(string.format("========%s========", desc))
		flex:add(tb)
	end

	-- successors
	for _, elem in pairs(elements) do
		local tb = wibox.widget.textbox(elem.text)
		flex:add(tb)
	end

	popup = awful.popup({
		hide_on_rightclick = true,
		screen = awful.screen.focused(),
		visible = true,
		ontop = true,
		above = true,
		placement = awful.placement.bottom,

		widget = wibox.widget({
			flex,
			bg = "#FF0000",
			forced_width = 500,
			forced_height = 800,
			shape = gears.shape.rounded_rect,
			widget = wibox.container.background,
		}),
	})

	-- hide after the new one to prevent flickering
	if old_popup then
		old_popup.visible = false
	end
end

local function handle(t)
	local opts = t:opts()

	if timer then
		timer:stop()
	end

	if not opts.hints_show then
		hide()
		return
	end

	local delay = opts.hints_delay

	-- do not delay if hints are already displayed
	if not popup and delay and delay > 0 then
		--hide()
		timer = gears.timer({
			timeout = delay / 1000,
			callback = function()
				create_popup(t)
				return false
			end,
			autostart = true,
			single_shot = true,
		})
	else
		create_popup(t)
	end
end

function M.setup(_)
	awesome.connect_signal("motion::start", function(t)
		handle(t)
	end)
	awesome.connect_signal("motion::stop", function(t)
		if timer then
			timer:stop()
		end
		hide(t)
	end)
end

return M

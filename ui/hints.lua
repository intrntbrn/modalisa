local config = require("motion.config")
local util = require("motion.util")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local dump = require("motion.vim").inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi

local M = {}

-- TODO:
-- merge keys with same desc
-- key description
-- margin and padding
-- group colors
-- icons?
-- opts:
-- height %, width %, placement, cell_size, overlap_wibox

local popup
local timer
local global_entries_widget

local function hide(_)
	if popup then
		popup.visible = false
	end
	popup = nil
end

local function get_font_width(font)
	local _, _, width = string.find(font, "[%s]+([0-9]+)")
	-- TODO: figure out the default font size that awesome uses
	return width or 10
end

-- TODO: opt
local function sort_entries(entries, opts)
	-- sort by group and desc
	table.sort(entries, function(a, b)
		if a.group == b.group then
			if a.text == b.text then
				return a.id < b.id
			else
				return a.text < b.text
			end
		else
			return a.group < b.group
		end
	end)

	-- --sort by id
	-- table.sort(elements, function(a, b)
	-- 	return a.id < b.id
	-- end)
	--
end
local function make_entries(keys, opts)
	local entries = {}

	local aliases = opts and opts.hints_key_aliases

	for k, key in pairs(keys) do
		-- if key:cond() then
		local kopts = key:opts()
		if not kopts or not kopts.hidden then
			local group = ""
			if kopts and kopts.group then
				group = kopts.group
			end

			local keyname = util.keyname(k, aliases)

			local separator = kopts.hints_key_separator

			table.insert(entries, {
				key_unescaped = k,
				key = keyname,
				group = group,
				cond = key.cond,
				desc = key:desc() or "",
				desc_fn = key.desc,
				id = key:id(),
				fg = kopts.fg,
				bg = kopts.bg,
				separator = separator,
				run = function()
					key:fn(kopts)
				end,
			})
		end
		-- end
	end

	return entries
end

-- colum size

local function create_popup(t)
	local old_popup = popup

	local s = awful.screen.focused()

	local opts = t:opts()
	local keys = t:successors()

	local entries = make_entries(keys, opts)
	sort_entries(entries, opts)

	-- calculations
	local geo = screen[s.index].geometry
	assert(geo)
	local max_width = math.floor(opts.hints_width * geo.width)
	local max_height = math.floor(opts.hints_height * geo.height)

	local font = opts.hints_font or opts.hints_font_desc or opts.hints_font_separator
	local font_desc = opts.hints_font_desc or font
	local font_separator = opts.hints_font_separator or font

	local cell_height = dpi(
		math.max(
			beautiful.get_font_height(font),
			beautiful.get_font_height(font_desc),
			beautiful.get_font_height(font_separator)
		)
	)
	local cell_width = dpi(get_font_width(font))

	-- print("cell_height: ", cell_height)
	-- print("cell_width: ", cell_width)

	local entry_height = cell_height
	local entry_width = cell_width * opts.hints_min_entry_width

	local max_entries = math.floor((max_width * max_height) / (entry_width * entry_height))
	local max_columns = math.floor(max_width / entry_width)
	local max_rows = math.floor(max_height / entry_height)

	-- print("max_entries: ", max_entries)
	-- print("max_columns: ", max_columns)
	-- print("max_rows: ", math.floor(max_rows))

	local num_entries = #entries
	local num_columns = max_columns
	local num_rows = max_rows

	if num_entries < max_entries then
		-- all entries fit
		-- prefer width or height?
		if opts.hints_fill_strategy == "width" then
			-- fill columns first
			num_columns = max_columns
			num_rows = math.ceil(num_entries / num_columns)
		else
			-- fill rows first
			num_rows = max_rows
			num_columns = math.ceil(num_entries / num_rows)
		end
	end

	-- print("num_entries: ", num_entries)
	-- print("num_rows: ", num_rows)
	-- print("num_columns: ", num_columns)

	local layout_columns = wibox.layout.fixed.horizontal({})

	layout_columns:weak_connect_signal("button::press", function(_, _, _, button)
		-- middle click
		if button == 2 then
			awesome.emit_signal("motion::fake_input", "stop")
			return
		end
		-- back click
		if button == 8 then
			awesome.emit_signal("motion::fake_input", "back")
			return
		end
	end)

	local entries_widget = {}
	local i = 1
	for c = 1, num_columns do
		local column = wibox.layout.fixed.vertical({})
		layout_columns:add(column)

		for r = 1, num_rows do
			local entry = entries[i]
			if not entry then
				break -- no more entries
			end

			local odd_source = opts.hints_odd_style == "row" and r or c
			if opts.hints_odd_style == "checkered" then
				odd_source = r + c
			end

			local odd = (odd_source % 2) == 0
			local bg = odd and opts.hints_color_entry_odd_bg or opts.hints_color_entry_bg
			local bg_hover = util.lighten(opts.hints_color_entry_bg, 25)

			local widget = wibox.widget.base.make_widget_declarative({
				{
					{
						{
							{
								id = "textbox_key",
								halign = "right",
								font = font,
								widget = wibox.widget.textbox,
							},
							strategy = "exact",
							width = opts.hints_max_key_width * cell_width,
							widget = wibox.container.constraint,
						},
						{

							id = "textbox_separator",
							font = font_separator,
							widget = wibox.widget.textbox,
						},
						{
							id = "textbox_desc",
							font = font_desc,
							widget = wibox.widget.textbox,
						},
						layout = wibox.layout.fixed.horizontal(),
					},
					-- fg = fg,
					bg = bg,
					id = "background_entry",
					widget = wibox.container.background,
				},
				id = string.format("entry_%d", i),
				strategy = "exact", -- TODO:
				width = entry_width,
				height = entry_height,
				widget = wibox.container.constraint,
			})

			local update = function()
				local tb_key = widget:get_children_by_id("textbox_key")[1]
				local tb_desc = widget:get_children_by_id("textbox_desc")[1]
				local tb_separator = widget:get_children_by_id("textbox_separator")[1]
				local bg_entry = widget:get_children_by_id("background_entry")[1]

				local fg
				local fg_desc
				local fg_separator
				if entry.cond() then
					fg = entry.fg or opts.hints_color_entry_fg
					fg_desc = opts.hints_color_entry_desc_fg or fg
					fg_separator = opts.hints_color_entry_separator_fg or fg
				else
					fg = opts.hints_color_entry_disabled_fg
					fg_desc = opts.hints_color_entry_disabled_fg
					fg_separator = opts.hints_color_entry_disabled_fg
				end
				bg_entry.fg = fg

				tb_key.markup = util.markup.fg(fg, entry.key)
				tb_desc.markup = util.markup.fg(fg_desc, entry.desc_fn())
				tb_separator.markup = util.markup.fg(fg_separator, entry.separator)
			end

			local function mouse_button_handler(_, _, _, button)
				if button == 1 then -- left click
					awesome.emit_signal("motion::fake_input", { key = entry.key_unescaped, continue = false })
					return
				end
				if button == 3 then -- rightclick
					awesome.emit_signal("motion::fake_input", { key = entry.key_unescaped, continue = true })
					return
				end
			end

			local background_entry = widget:get_children_by_id("background_entry")[1]
			local function mouse_enter_handler()
				background_entry.bg = bg_hover
			end
			local function mouse_leave_handler()
				background_entry.bg = bg
			end

			widget:connect_signal("button::press", mouse_button_handler)
			widget:connect_signal("mouse::enter", mouse_enter_handler)
			widget:connect_signal("mouse::leave", mouse_leave_handler)

			local teardown = function()
				widget:disconnect_signal("button::press", mouse_button_handler)
				widget:disconnect_signal("mouse::enter", mouse_enter_handler)
				widget:disconnect_signal("mouse::leave", mouse_leave_handler)
			end

			update()

			widget.update = update
			widget.teardown = teardown

			entries_widget[i] = widget

			column:add(widget)
			i = i + 1
		end
		global_entries_widget = entries_widget
	end

	-- compute size
	local placement = type(opts.hints_placement) == "string" and awful.placement[opts.hints_placement]
		or opts.hints_placement

	local widget = wibox.widget.base.make_widget_declarative({
		{
			layout_columns,
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
		placement = placement,
		widget = widget,
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

local function update(t)
	-- HACK: add a small delay to circumvent race conditions
	timer = gears.timer({
		timeout = 0.01,
		callback = function()
			for _, v in pairs(global_entries_widget) do
				v:update()
			end
		end,
		autostart = true,
		single_shot = true,
	})
end

function M.setup(_)
	awesome.connect_signal("motion::execute", function(args)
		update(args.tree)
	end)
	awesome.connect_signal("motion::update", function(args)
		handle(args.tree)
	end)
	awesome.connect_signal("motion::stop", function(args)
		if timer then
			timer:stop()
		end
		hide(args.tree)
	end)
end

return M

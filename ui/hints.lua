local util = require("motion.util")
local lib = require("motion.lib")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local dump = require("motion.lib.vim").inspect
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi

local M = {}

-- TODO:
-- merge keys with same desc
-- group colors

local popup = {}
local timer

local function sort_entries_by_group(entries, opts)
	-- sort by group, desc, id
	table.sort(entries, function(a, b)
		if a.group == b.group then
			if a.desc() == b.desc() then
				return a.id < b.id
			else
				return (a.desc() or "") < (b.desc() or "")
			end
		else
			return a.group < b.group
		end
	end)
end

local function sort_entries_by_id(entries, opts)
	table.sort(entries, function(a, b)
		return a.id < b.id
	end)
end

local function make_entries(keys, opts)
	local entries = {}

	local aliases = opts and opts.hints_key_aliases
	local show_disabled = opts.hints_show_disabled_keys
	for k, key in pairs(keys) do
		if show_disabled or key:cond() then
			local kopts = key:opts()
			if not kopts or not kopts.hidden then
				local group = ""
				if kopts and kopts.group then
					group = kopts.group
				end

				local keyname = util.keyname(k, aliases)

				table.insert(entries, {
					key_unescaped = k,
					key = keyname,
					group = group,
					cond = key.cond,
					desc = key.desc,
					id = key:id(),
					fg = kopts.fg,
					bg = kopts.bg,
					run = function()
						key:fn(kopts)
					end,
				})
			end
		end
	end

	return entries
end

function popup:teardown()
	local entries = self.entries_widget
	if not entries then
		return
	end
	for _, v in pairs(entries) do
		v:teardown()
	end
end

function popup:update(t)
	self:teardown() -- cleanup old entries

	local s = awful.screen.focused()

	local opts = t:opts()
	local keys = t:successors()

	local entries = make_entries(keys, opts)

	local sort = opts.hints_sort
	if sort then
		local fn
		if sort == "id" then
			fn = sort_entries_by_id
		elseif sort == "group" then
			fn = sort_entries_by_group
		end

		if fn then
			fn(entries, opts)
		end
	end

	-- calculations
	local max_width = util.get_pixel_width(opts.hints_width, s)
	local max_height = util.get_pixel_height(opts.hints_height, s)

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
	local cell_width = dpi(util.get_font_width(font))

	-- print("cell_height: ", cell_height)
	-- print("cell_width: ", cell_width)

	local entry_height = cell_height
	local min_entry_width = cell_width * opts.hints_min_entry_width
	local max_entry_width = cell_width * opts.hints_max_entry_width

	local max_entries = math.floor((max_width * max_height) / (min_entry_width * entry_height))
	local max_columns = math.floor(max_width / min_entry_width)
	local max_rows = math.floor(max_height / entry_height)

	local entry_width = math.floor(math.min((max_width / max_columns), max_entry_width))
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
	local entries_widget = {}
	local i = 1
	local width_remaining = max_width
	for c = 1, num_columns do
		local column = wibox.layout.fixed.vertical({})

		-- don't waste a single pixel
		width_remaining = width_remaining - entry_width
		if c == num_columns then
			entry_width = entry_width + width_remaining
		end

		layout_columns:add(column)

		for r = 1, num_rows do
			local entry = entries[i]
			if not entry then
				entry = {
					is_dummy = true,
				}
			end

			local bg = opts.hints_color_entry_bg

			local odd_style = opts.hints_odd_style
			if odd_style == "row" or odd_style == "column" or odd_style == "checkered" then
				local odd_source = r
				if odd_style == "column" then
					odd_source = c
				elseif odd_style == "checkered" then
					odd_source = r + c
				end
				local odd = (odd_source % 2) == 0
				if odd then
					bg = util.color_or_luminosity(opts.hints_color_entry_odd_bg, bg)
				end
			end

			local bg_hover = util.color_or_luminosity(opts.hints_color_hover_bg, bg)

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
							width = opts.hints_entry_key_width * cell_width,
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
					bg = bg,
					id = "background_entry",
					widget = wibox.container.background,
				},
				id = string.format("entry_%d", i),
				strategy = "exact",
				width = entry_width,
				height = entry_height,
				widget = wibox.container.constraint,
			})

			local update = function()
				if entry.is_dummy then
					return
				end
				local tb_key = widget:get_children_by_id("textbox_key")[1]
				local tb_desc = widget:get_children_by_id("textbox_desc")[1]
				local tb_separator = widget:get_children_by_id("textbox_separator")[1]
				local bg_entry = widget:get_children_by_id("background_entry")[1]

				local fg
				local fg_desc
				local fg_separator
				if entry.cond() then
					fg = entry.fg or opts.hints_color_entry_fg
					fg_desc = entry.fg or opts.hints_color_entry_desc_fg or fg
					fg_separator = opts.hints_color_entry_separator_fg or fg
				else
					fg = opts.hints_color_entry_disabled_fg
					fg_desc = opts.hints_color_entry_disabled_fg
					fg_separator = opts.hints_color_entry_disabled_fg
				end
				bg_entry.fg = fg

				tb_key.markup = util.markup.fg(fg, entry.key)
				tb_desc.markup = util.markup.fg(fg_desc, entry.desc())
				tb_separator.markup = util.markup.fg(fg_separator, opts.hints_key_separator)
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
		self.entries_widget = entries_widget
	end

	-- compute size
	local placement = type(opts.hints_placement) == "string" and awful.placement[opts.hints_placement]
		or opts.hints_placement

	local widget = wibox.widget.base.make_widget_declarative({
		{
			layout_columns,

			border_width = opts.hints_border_width,
			border_color = opts.hints_color_border,
			shape = opts.hints_shape,
			opacity = opts.hints_opacity,
			widget = wibox.container.background,
		},
		widget = wibox.container.margin,
	})

	-- update the popup
	self.popup.widget = widget
	if placement then
		self.popup.placement = placement
	end
	self.popup.screen = s
	self.popup.visible = true
end

function popup:new(opts)
	local pop = awful.popup({
		visible = false,
		ontop = true,
		above = true,
		widget = wibox.widget.base.make_widget_declarative({}),
	})

	pop:connect_signal("button::press", function(_, _, _, button)
		if button == 2 then -- middle click
			awesome.emit_signal("motion::fake_input", "stop")
			return
		end
		if button == 8 then -- back click
			awesome.emit_signal("motion::fake_input", "back")
			return
		end
	end)

	self.popup = pop
	return pop
end

function popup:is_visible()
	return self.popup.visible
end

function popup:set_visible(value)
	self.popup.visible = value
end

-- update entries (desc, cond, etc.)
function popup:refresh_entries()
	-- after execution some important global vars in awesome aren't defined yet
	-- (e.g. client.focus), resulting in incorrect cond() of entries.
	-- therefore we add a small delay to circumvent race conditions
	gears.timer({
		timeout = 0.025, -- 25ms
		callback = function()
			local entries = self.entries_widget
			if not entries then
				return
			end
			for _, v in pairs(entries) do
				v:update()
			end
		end,
		autostart = true,
		single_shot = true,
	})
end

local function handle_tree_changed(t)
	local opts = t:opts()

	if timer then
		timer:stop()
	end

	if not opts.hints_show then
		popup:set_visible(false)
		return
	end

	local delay = opts.hints_delay

	-- do not delay if hints are already displayed
	if not popup:is_visible() and delay and delay > 0 then
		timer = gears.timer({
			timeout = delay / 1000,
			callback = function()
				popup:update(t)
				return false
			end,
			autostart = true,
			single_shot = true,
		})
	else
		popup:update(t)
	end
end

local once
function M.setup(opts)
	assert(once == nil, "hints are already setup")
	once = popup:new(opts)

	awesome.connect_signal("motion::exec", function(args)
		popup:refresh_entries()
	end)
	awesome.connect_signal("motion::update", function(args)
		handle_tree_changed(args.tree)
	end)
	awesome.connect_signal("motion::stop", function(args)
		if timer then
			timer:stop()
		end
		popup:set_visible(false)
	end)
end

return M

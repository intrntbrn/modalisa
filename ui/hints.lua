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
local current_tree

local function sort_entries_by_group(entries)
	-- sort by group, desc, id
	table.sort(entries, function(a, b)
		if a.group == b.group then
			if a.desc() == b.desc() then
				return a.id < b.id
			else
				return a.desc() < b.desc()
			end
		else
			return a.group < b.group
		end
	end)
end

local function sort_entries_by_id(entries)
	table.sort(entries, function(a, b)
		return a.id < b.id
	end)
end

local function sort_entries_by_key(entries)
	table.sort(entries, function(a, b)
		return a.key < b.key
	end)
end

local function get_group_color(key, group_colors)
	local group = key:group()
	if not group or string.len(group) == 0 then
		return
	end
	for regex, color in pairs(group_colors) do
		if string.match(group, regex) then
			return color
		end
	end
	return nil
end

local function make_entries(keys, opts)
	local hopts = opts.hints
	local entries = {}

	local aliases = hopts.key_aliases
	local group_colors = hopts.group_colors
	local show_disabled = hopts.show_disabled_keys
	for k, key in pairs(keys) do
		if show_disabled or key:cond() then
			local kopts = key:opts()
			if not kopts or not key:hidden() then
				local keyname = util.keyname(k, aliases)
				local group_color = get_group_color(key, group_colors)
				table.insert(entries, {
					key_unescaped = k,
					key = keyname,
					group = key:group(),
					cond = function()
						return key:cond()
					end,
					desc = function()
						return key:desc() or ""
					end,
					id = key:id(),
					fg = key:fg(),
					bg = key:bg(),
					highlight = key:highlight(),
					group_color = group_color,
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
	local hopts = opts.hints
	local keys = t:successors()

	local entries = make_entries(keys, opts)

	local sort = hopts.sort
	if sort then
		local fn
		if sort == "id" then
			fn = sort_entries_by_id
		elseif sort == "group" then
			fn = sort_entries_by_group
		elseif sort == "key" then
			fn = sort_entries_by_key
		end

		if fn then
			fn(entries)
		end
	end

	local header_text = t:desc()
	local header_height = 0
	local header_font = hopts.font_header or hopts.font
	if hopts.show_header then
		header_height = beautiful.get_font_height(header_font)
	end

	local width_outer = 0
	local height_outer = 0
	local margins_outer = hopts.margin
	if margins_outer then
		width_outer = width_outer + (margins_outer.left or 0)
		width_outer = width_outer + (margins_outer.right or 0)
		height_outer = height_outer + (margins_outer.top or 0)
		height_outer = height_outer + (margins_outer.bottom or 0)
	end
	local padding_outer = hopts.padding
	if padding_outer then
		width_outer = width_outer + (padding_outer.left or 0)
		width_outer = width_outer + (padding_outer.right or 0)
		height_outer = height_outer + (padding_outer.top or 0)
		height_outer = height_outer + (padding_outer.bottom or 0)
	end

	-- calculations
	local max_width = util.get_screen_pixel_width(hopts.width, s)
	local max_height = util.get_screen_pixel_height(hopts.height, s)
	max_height = max_height - header_height - height_outer
	max_width = max_width - width_outer

	local font = hopts.font
	local font_key = hopts.font_key or font
	local font_desc = hopts.font_desc or font
	local font_separator = hopts.font_separator or font

	local cell_height = dpi(
		math.max(
			beautiful.get_font_height(font),
			beautiful.get_font_height(font_key),
			beautiful.get_font_height(font_desc),
			beautiful.get_font_height(font_separator)
		)
	)
	local cell_width = dpi(
		math.max(
			util.get_font_width(font),
			util.get_font_width(font_key),
			util.get_font_width(font_desc),
			util.get_font_width(font_separator)
		)
	)

	local width_padding = 0
	local height_padding = 0
	local entry_padding = hopts.entry_padding
	if entry_padding then
		width_padding = width_padding + (entry_padding.left or 0)
		width_padding = width_padding + (entry_padding.right or 0)
		height_padding = height_padding + (entry_padding.top or 0)
		height_padding = height_padding + (entry_padding.bottom or 0)
	end

	local entry_height = cell_height + height_padding
	local min_entry_width = (cell_width * hopts.min_entry_width) + width_padding
	local max_entry_width = (cell_width * hopts.max_entry_width) + width_padding

	local max_entries = math.floor((max_width * max_height) / (min_entry_width * entry_height))
	local max_columns = math.floor(max_width / min_entry_width)
	local max_rows = math.floor(max_height / entry_height)

	local entry_width = math.floor(math.min((max_width / max_columns), max_entry_width))

	local num_entries = #entries
	local num_columns = max_columns
	local num_rows = max_rows

	if num_entries < max_entries then
		-- all entries fit
		-- prefer width or height?
		if hopts.expand_horizontal then
			-- fill columns first
			num_columns = math.min(max_columns, num_entries)
			num_rows = math.ceil(num_entries / num_columns)
		else
			-- fill rows first
			num_rows = math.min(max_rows, num_entries)
			num_columns = math.ceil(num_entries / num_rows)
		end
	end

	local layout_c = "horizontal"
	local layout_r = "vertical"
	local fill_c = hopts.stretch_horizontal
	local fill_r = hopts.stretch_vertical

	local invert = hopts.flow_horizontal
	if invert then
		-- turn rows into columns and vice versa
		layout_c = "vertical"
		layout_r = "horizontal"
		num_columns, num_rows = num_rows, num_columns
		fill_c, fill_r = fill_r, fill_c
	end

	-- print("num_entries: ", num_entries)
	-- print("num_rows: ", num_rows)
	-- print("num_columns: ", num_columns)
	-- print("max_rows: ", max_rows)
	-- print("max_columns: ", max_columns)
	-- print("max_width: ", max_width)
	-- print("max_height: ", max_height)

	local layout_columns = wibox.layout.fixed[layout_c]({})
	local entries_widget = {}
	local i = 1
	local done = false
	for c = 1, num_columns do
		if done then
			break
		end
		local row = wibox.layout.fixed[layout_r]({})
		layout_columns:add(row)

		for r = 1, num_rows do
			local entry = entries[i]
			if not entry then
				-- add dummy entry to continue the odd pattern
				done = true
				if c == 1 then
					break
				end
				entry = {
					is_dummy = true,
				}
			end

			local bg = entry.bg or hopts.color_bg or opts.theme.bg
			local bg_hover = util.color_or_luminosity(hopts.color_hover_bg, bg)

			local odd_style = hopts.odd_style
			if odd_style and (odd_style == "row" or odd_style == "column" or odd_style == "checkered") then
				local odd_source = 0
				if odd_style == "row" then
					odd_source = invert and c or r
				elseif odd_style == "column" then
					odd_source = invert and r or c
				elseif odd_style == "checkered" then
					odd_source = r + c
				end
				local odd = (odd_source % 2) == 0
				if odd then
					bg = util.color_or_luminosity(hopts.color_odd_bg, bg)
				end
			end

			local widget = wibox.widget.base.make_widget_declarative({
				{
					{
						{
							{
								{
									id = "textbox_key",
									halign = "right",
									font = font_key,
									widget = wibox.widget.textbox,
								},
								strategy = "exact",
								width = hopts.entry_key_width * cell_width,
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
						margins = hopts.entry_padding,
						widget = wibox.container.margin,
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
				local tb_separator = widget:get_children_by_id("textbox_separator")[1]
				local tb_desc = widget:get_children_by_id("textbox_desc")[1]
				local bg_entry = widget:get_children_by_id("background_entry")[1]

				local fg_key
				local fg_separator
				local fg_desc
				if entry.cond() then
					fg_key = hopts.color_fg or opts.theme.fg
					fg_separator = hopts.color_separator_fg or opts.theme.accent
					fg_desc = entry.fg or entry.group_color or hopts.color_desc_fg or opts.theme.fg
				else
					fg_key = hopts.color_disabled_fg or opts.theme.grey
					fg_separator = hopts.color_disabled_fg or opts.theme.grey
					fg_desc = hopts.color_disabled_fg or opts.theme.grey
				end
				bg_entry.fg = fg_key

				local markup_desc = entry.desc()
				markup_desc = util.markup.fg(fg_desc, markup_desc)
				markup_desc = util.apply_highlight(markup_desc, entry.highlight)
				tb_desc.markup = markup_desc

				local markup_key = util.markup.fg(fg_key, entry.key)
				tb_key.markup = markup_key
				tb_separator.markup = util.markup.fg(fg_separator, hopts.separator)
			end

			local function mouse_button_handler(_, _, _, button)
				if button == 1 then -- left click
					awesome.emit_signal("modalisa::fake_input", entry.key_unescaped, false)
					return
				end
				if button == 3 then -- rightclick
					awesome.emit_signal("modalisa::fake_input", entry.key_unescaped, true)
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

			if not entry.is_dummy then
				widget:connect_signal("button::press", mouse_button_handler)
				widget:connect_signal("mouse::enter", mouse_enter_handler)
				widget:connect_signal("mouse::leave", mouse_leave_handler)
			end

			local teardown = function()
				widget:disconnect_signal("button::press", mouse_button_handler)
				widget:disconnect_signal("mouse::enter", mouse_enter_handler)
				widget:disconnect_signal("mouse::leave", mouse_leave_handler)
			end

			update()

			widget.update = update
			widget.teardown = teardown

			entries_widget[i] = widget

			row:add(widget)
			i = i + 1
		end
		self.entries_widget = entries_widget
	end

	local widget = layout_columns
	if hopts.show_header then
		local header_color = hopts.color_header or opts.theme.accent
		widget = wibox.widget.base.make_widget_declarative({
			{
				{
					markup = util.markup.fg(header_color, header_text),
					font = header_font,
					valign = "center",
					halign = "center",
					widget = wibox.widget.textbox,
				},
				forced_height = header_height,
				widget = wibox.container.place,
			},
			layout_columns,
			layout = wibox.layout.fixed.vertical,
		})
	end

	local stretch_margin_left, stretch_margin_right, stretch_margin_top, stretch_margin_bottom
	if hopts.stretch_horizontal then
		local count = invert and num_rows or num_columns
		local width_remaining = max_width - (count * entry_width)
		stretch_margin_left = math.floor(width_remaining / 2)
		stretch_margin_right = width_remaining - stretch_margin_left
	end

	if hopts.stretch_vertical then
		local count = invert and num_columns or num_rows
		local height_remaining = max_height - (count * entry_height)
		stretch_margin_top = math.floor(height_remaining / 2)
		stretch_margin_bottom = math.floor(height_remaining - stretch_margin_top)
	end

	-- compute size
	local placement = type(hopts.placement) == "string" and awful.placement[hopts.placement] or hopts.placement

	local bg = hopts.color_bg or opts.theme.bg
	local border_color = hopts.color_border or opts.theme.border

	local base_widget = wibox.widget.base.make_widget_declarative({
		{
			{
				{
					widget,
					top = stretch_margin_top,
					bottom = stretch_margin_bottom,
					right = stretch_margin_right,
					left = stretch_margin_left,
					widget = wibox.container.margin, -- fill space margin
				},
				margins = hopts.padding,
				widget = wibox.container.margin,
			},
			bg = bg,
			border_width = hopts.border_width,
			border_color = border_color,
			shape = hopts.shape,
			opacity = hopts.opacity,
			widget = wibox.container.background,
		},
		margins = hopts.margin,
		widget = wibox.container.margin,
	})

	-- update the popup
	self.popup.widget = base_widget
	self.popup.screen = s
	if placement then
		self.popup.placement = placement
	end
	self.popup.visible = true
end

---@diagnostic disable-next-line: unused-local
function popup:new(hopts)
	local pop = awful.popup({
		visible = false,
		ontop = true,
		above = true,
		widget = wibox.widget.base.make_widget_declarative({}),
	})

	pop:connect_signal("button::press", function(_, _, _, button)
		if button == 2 then -- middle click
			awesome.emit_signal("modalisa::fake_input", "stop")
			return
		end
		if button == 8 then -- back click
			awesome.emit_signal("modalisa::fake_input", "back")
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
	local entries = self.entries_widget
	if not entries then
		return
	end
	for _, v in pairs(entries) do
		v:update()
	end
end

local function show(t)
	current_tree = t
	local hopts = t:opts().hints

	if timer then
		timer:stop()
	end

	if not hopts.enabled then
		popup:set_visible(false)
		return
	end

	local delay = hopts.delay

	-- do not delay if hints are already displayed
	if not popup:is_visible() and delay and delay > 0 then
		timer = gears.timer({
			timeout = delay / 1000,
			callback = function()
				util.run_on_idle(function()
					popup:update(t)
				end)
			end,
			autostart = true,
			single_shot = true,
		})
	else
		popup:update(t)
	end
end

function M.show(t)
	show(t)
end

local once
function M.setup(opts)
	assert(once == nil, "hints are already setup")
	once = popup:new(opts.hints)

	awesome.connect_signal("modalisa::executed", function(_)
		util.run_on_idle(function()
			popup:refresh_entries()
		end)
	end)

	awesome.connect_signal("modalisa::updated", function(t)
		util.run_on_idle(function()
			show(t)
		end)
	end)

	-- live update on config change
	awesome.connect_signal("modalisa::config", function(_, _)
		util.run_on_idle(function()
			if not current_tree then
				return
			end
			if not popup:is_visible() then
				return
			end

			show(current_tree)
		end)
	end)

	awesome.connect_signal("modalisa::stopped", function(_)
		util.run_on_idle(function()
			if timer then
				timer:stop()
			end
			popup:set_visible(false)
		end)
	end)
end

return M

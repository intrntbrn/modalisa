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

local function get_group_highlight(key, group_highlights)
	local group = key:group()
	if not group or string.len(group) == 0 then
		return
	end
	for regex, highlight in pairs(group_highlights) do
		if string.match(group, regex) then
			return highlight
		end
	end
	return nil
end

local function make_entries(keys, opts)
	local hopts = opts.hints
	local entries = {}

	local aliases = hopts.key_aliases
	local group_highlights = hopts.group_highlights
	local show_disabled = hopts.show_disabled_keys
	local menu_highlight = hopts.menu_highlight

	local hl = hopts.highlight
	local theme = opts.theme

	local default_bg = hl.bg or theme.bg

	local hl_default = {
		fg = theme.fg,
		bg = default_bg,
	}

	local hl_default_separator = {
		fg = theme.accent,
		bg = default_bg,
	}

	local default_hl_key = vim.tbl_deep_extend("force", hl_default, hl.key)
	local default_hl_separator = vim.tbl_deep_extend("force", hl_default_separator, hl.separator)
	local default_hl_desc = vim.tbl_deep_extend("force", hl_default, hl.desc)

	for k, key in pairs(keys) do
		if show_disabled or key:cond() then
			local kopts = key:opts()
			if not kopts or not key:hidden() then
				local hl_key = vim.deepcopy(default_hl_key)
				local hl_separator = vim.deepcopy(default_hl_separator)
				local hl_desc = vim.deepcopy(default_hl_desc)
				local custom_bg

				local keyname = util.keyname(k, aliases)
				local highlight = key:highlight()
				-- highlight priority: individual key < group < menu
				if not highlight then
					local group_highlight = get_group_highlight(key, group_highlights)
					if group_highlight then
						highlight = group_highlight
					elseif key:is_menu() then
						highlight = menu_highlight
					end
				end

				if highlight then
					if highlight.bg then
						custom_bg = highlight.bg
					end
					if highlight.key then
						hl_key = vim.tbl_deep_extend("force", hl_key, highlight.key)
					end
					if highlight.separator then
						hl_separator = vim.tbl_deep_extend("force", hl_separator, highlight.separator)
					end
					if highlight.desc then
						hl_desc = vim.tbl_deep_extend("force", hl_desc, highlight.desc)
					end
				end

				table.insert(entries, {
					key_unescaped = k,
					key = keyname,
					group = key:group() or "",
					cond = function()
						return key:cond()
					end,
					desc = function()
						return key:desc() or ""
					end,
					id = key:id(),
					run = function()
						key:fn(kopts)
					end,
					custom_bg = custom_bg,
					highlight_key = hl_key,
					highlight_separator = hl_separator,
					highlight_desc = hl_desc,
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
	if not t then
		return
	end
	self:teardown() -- cleanup old entries

	local s = awful.screen.focused()

	local opts = t:opts()
	local hopts = opts.hints
	local keys = t:successors()

	local separator = hopts.separator

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
	local total_max_width = util.get_screen_pixel_width(hopts.width, s)
	local total_max_height = util.get_screen_pixel_height(hopts.height, s)
	local max_height = total_max_height - header_height - height_outer
	local max_width = total_max_width - width_outer

	local hl = hopts.highlight
	local hl_key = hl.key
	local hl_separator = hl.separator
	local hl_desc = hl.desc
	local font_key = hl_key.font
	local font_separator = hl_separator.font
	local font_desc = hl_desc.font

	local cell_height = dpi(
		math.max(
			beautiful.get_font_height(font_key),
			beautiful.get_font_height(font_desc),
			beautiful.get_font_height(font_separator)
		)
	)
	local cell_width = dpi(
		math.max(util.get_font_width(font_key), util.get_font_width(font_desc), util.get_font_width(font_separator))
	)

	local width_padding = 0
	local height_padding = 0
	local entry_padding = hopts.entry_padding
	if entry_padding then
		width_padding = width_padding + (entry_padding.left or 0)
		width_padding = width_padding + (entry_padding.right or 0)
		height_padding = height_padding + (entry_padding.top or 0)
		height_padding = height_padding + (entry_padding.bottom or 0)
		header_height = header_height + height_padding
	end

	local entry_height = cell_height + height_padding
	local min_entry_width = (cell_width * hopts.min_entry_width) + width_padding
	min_entry_width = math.min(min_entry_width, max_width)
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

	-- print("num_entries: ", num_entries)
	-- print("num_rows: ", num_rows)
	-- print("num_columns: ", num_columns)
	-- print("max_rows: ", max_rows)
	-- print("max_columns: ", max_columns)
	-- print("max_width: ", max_width)
	-- print("max_height: ", max_height)

	local layout_c = "horizontal"
	local layout_r = "vertical"

	local invert = hopts.flow_horizontal
	if invert then
		-- turn rows into columns and vice versa
		layout_c = "vertical"
		layout_r = "horizontal"
		num_columns, num_rows = num_rows, num_columns
	end

	local theme = opts.theme
	local odd_style = hopts.odd_style
	local highlight = hopts.highlight
	local default_bg = highlight.bg or theme.bg

	local default_bg_hover = util.color_or_luminosity(hopts.color_hover_bg, default_bg)

	local layout_columns = wibox.layout.fixed[layout_c]({})
	local entries_widget = {}
	local i = 1
	local done = false
	local skip
	local j -- logical i
	for c = 1, num_columns do
		if done then
			-- no more entries
			break
		end
		local row = wibox.layout.fixed[layout_r]({})
		layout_columns:add(row)

		for r = 1, num_rows do
			local entry = entries[i]

			skip = false
			if entry and hopts.expand_horizontal then
				if invert then
					j = (num_rows * (c - 1)) + r
				else
					j = (num_columns * (r - 1)) + c
				end

				skip = j > num_entries
			end

			if skip then
				entry = {
					is_dummy = true,
				}
			else
				if not entry then
					done = true
					if c == 1 or (invert and r == 1) then
						break -- don't increase column- or row count because of dummies
					end
					entry = {
						is_dummy = true,
					}
				end
			end

			local bg = default_bg
			local bg_hover = default_bg_hover
			if entry.custom_bg then
				bg = entry.custom_bg
				bg_hover = util.color_or_luminosity(hopts.color_hover_bg, bg)
			else
				local odd_source = nil
				if odd_style == "row" then
					odd_source = invert and c or r
				elseif odd_style == "column" then
					odd_source = invert and r or c
				elseif odd_style == "checkered" then
					odd_source = r + c
				end
				if odd_source then
					local odd = (odd_source % 2) == 0
					if odd then
						if not entry.is_dummy or hopts.odd_empty then
							bg = util.color_or_luminosity(hopts.color_odd_bg, default_bg)
						end
					end
				end
			end

			local widget_tb_key = wibox.widget.textbox()
			widget_tb_key.halign = "right"
			widget_tb_key.font = font_key

			local widget_tb_separator = wibox.widget.textbox()
			widget_tb_separator.font = font_separator

			local widget_tb_desc = wibox.widget.textbox()
			widget_tb_desc.font = font_desc

			local widget = wibox.widget.base.make_widget_declarative({
				{
					{
						{
							widget_tb_key,
							strategy = "exact",
							width = hopts.entry_key_width * cell_width,
							widget = wibox.container.constraint,
						},
						widget_tb_separator,
						widget_tb_desc,
						layout = wibox.layout.fixed.horizontal(),
					},
					margins = hopts.entry_padding,
					widget = wibox.container.margin,
				},
				bg = bg,
				id = "background_entry",
				forced_height = entry_height,
				forced_width = entry_width,
				widget = wibox.container.background,
			})

			local update = function()
				if entry.is_dummy then
					return
				end

				local markup_key = entry.key
				local markup_separator = separator
				local markup_desc = entry.desc()

				local color_disabled = hopts.color_disabled_fg or theme.grey

				markup_separator = util.apply_highlight(markup_separator, entry.highlight_separator)
				markup_key = util.apply_highlight(markup_key, entry.highlight_key)
				markup_desc = util.apply_highlight(markup_desc, entry.highlight_desc)
				if entry.cond() then
					markup_key = util.markup.fg(markup_key, entry.highlight_key.fg)
					markup_separator = util.markup.fg(markup_separator, entry.highlight_separator.fg)
					markup_desc = util.markup.fg(markup_desc, entry.highlight_desc.fg)
				else
					markup_key = util.markup.fg(markup_key, color_disabled)
					markup_separator = util.markup.fg(markup_separator, color_disabled)
					markup_desc = util.markup.fg(markup_desc, color_disabled)
				end

				widget_tb_key.markup = markup_key
				widget_tb_separator.markup = markup_separator
				widget_tb_desc.markup = markup_desc
			end

			local function mouse_button_handler(_, _, _, button)
				if button == hopts.mouse_button_select then
					require("modalisa").fake_input(entry.key_unescaped, false)
					return
				end
				if button == hopts.mouse_button_select_continue then
					require("modalisa").fake_input(entry.key_unescaped, true)
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

			table.insert(entries_widget, widget)

			row:add(widget)
			if not skip then
				i = i + 1
			end
		end
		self.entries_widget = entries_widget
	end

	local widget = layout_columns
	if hopts.show_header then
		local header_fg = hopts.color_header_fg or opts.theme.accent
		local header_bg = hopts.color_header_bg or default_bg
		widget = wibox.widget.base.make_widget_declarative({
			{
				{
					{
						{
							markup = util.markup.fg(header_text, header_fg),
							font = header_font,
							valign = "center",
							halign = "center",
							widget = wibox.widget.textbox,
						},
						left = entry_padding.left,
						right = entry_padding.right,
						top = entry_padding.top,
						bottom = entry_padding.bottom,
						widget = wibox.container.margin,
					},
					bg = header_bg,
					widget = wibox.container.background,
				},
				fill_horizontal = true,
				content_fill_vertical = true,
				content_fill_horizontal = true,
				forced_height = header_height,
				widget = wibox.container.place,
			},
			layout_columns,
			layout = wibox.layout.fixed.vertical,
		})
	end

	local stretch_margin_left, stretch_margin_right, stretch_margin_top, stretch_margin_bottom
	local entry_count_x = invert and num_rows or num_columns
	local width_remaining = total_max_width - (entry_count_x * entry_width) - width_outer
	if hopts.stretch_horizontal then
		stretch_margin_left = math.floor(width_remaining / 2)
		stretch_margin_right = width_remaining - stretch_margin_left
		width_remaining = 0
	end

	local entry_count_y = invert and num_columns or num_rows
	local height_remaining = total_max_height - (entry_count_y * entry_height) - header_height - height_outer
	if hopts.stretch_vertical then
		stretch_margin_top = math.floor(height_remaining / 2)
		stretch_margin_bottom = height_remaining - stretch_margin_top
		height_remaining = 0
	end

	-- compute size
	local placement = type(hopts.placement) == "string" and awful.placement[hopts.placement] or hopts.placement

	local border_color = hopts.color_border or opts.theme.border

	local base_widget = wibox.widget.base.make_widget_declarative({
		{
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
				border_width = hopts.border_width,
				border_color = border_color,
				shape = hopts.shape,
				opacity = hopts.opacity,
				bg = default_bg,
				widget = wibox.container.background,
			},
			width = total_max_width - (margins_outer.left or 0) - (margins_outer.right or 0) - width_remaining,
			height = total_max_height - (margins_outer.top or 0) - (margins_outer.bottom or 0) - height_remaining,
			strategy = "max",
			widget = wibox.container.constraint,
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
		local t = current_tree
		if not t or not t:opts() then
			return
		end
		local current_hopts = t:opts().hints
		if button == current_hopts.mouse_button_stop then
			require("modalisa").fake_input("stop")
			return
		end
		if button == current_hopts.mouse_button_back then
			require("modalisa").fake_input("back")
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
				popup:update(t)
			end,
			autostart = true,
			single_shot = true,
		})
	else
		popup:update(t)
	end
end

local function toggle(t)
	if popup:is_visible() then
		popup:set_visible(false)
		return
	end
	if timer then
		timer:stop()
	end
	popup:update(t)
end

local function hide()
	if timer then
		timer:stop()
	end
	popup:set_visible(false)
end

local once
function M.setup(opts)
	assert(once == nil, "hints are already setup")
	once = popup:new(opts.hints)

	awesome.connect_signal("modalisa::on_exec", function(t)
		---@diagnostic disable-next-line: redefined-local
		local opts = t:opts()
		local fn = function()
			popup:refresh_entries()
		end
		if opts.hints.low_priority then
			util.run_on_idle(fn)
		else
			fn()
		end
	end)

	awesome.connect_signal("modalisa::on_enter", function(t)
		---@diagnostic disable-next-line: redefined-local
		local opts = t:opts()
		local fn = function()
			show(t)
		end
		if opts.hints.low_priority then
			util.run_on_idle(fn)
		else
			fn()
		end
	end)

	awesome.connect_signal("modalisa::hints::toggle", function(t)
		t = t or current_tree
		toggle(t)
	end)

	awesome.connect_signal("modalisa::hints::hide", function()
		hide()
	end)

	-- live update on config change
	awesome.connect_signal("modalisa::config::update", function(_, _)
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

	awesome.connect_signal("modalisa::on_stop", function(t)
		---@diagnostic disable-next-line: redefined-local
		local opts = t:opts()
		local fn = function()
			hide()
		end
		if opts.hints.low_priority then
			util.run_on_idle(fn)
		else
			fn()
		end
	end)
end

return M

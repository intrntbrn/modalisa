local awful = require("awful")
local util = require("modalisa.util")
local vim = require("modalisa.lib.vim")
local awm = require("modalisa.awesome")
local mt = require("modalisa.presets.metatable")
local label = require("modalisa.ui.label")
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}
local helper = {}

-- TODO: placement
-- new tag
-- screen (awful.screen.focus_relative(-1), c:move_to_screen())
-- client: border_width, skip taskbar, hidden, hide bar
-- urgent
-- resize modes

function M.awesome_help()
	return mt({
		group = "awesome.menu",
		desc = "show help",
		cond = function()
			return pcall(require, "awful.hotkeys_popup")
		end,
		fn = function()
			awm.awesome_help()
		end,
	})
end

function M.awesome_menubar()
	return mt({
		group = "awesome.menu",
		desc = "show menubar",
		cond = function()
			return pcall(require, "menubar")
		end,
		fn = function()
			awm.awesome_menubar()
		end,
	})
end

function M.awesome_quit()
	return mt({
		group = "awesome.stop",
		desc = "quit awesome",
		fn = function()
			local fn = function()
				awm.awesome_quit()
			end
			return util.confirmation_menu(fn, "yes, quit awesome", "no, cancel")
		end,
	})
end

function M.awesome_restart()
	return mt({
		group = "awesome.stop",
		desc = "restart awesome",
		fn = function()
			awm.awesome_restart()
		end,
	})
end

function M.awesome_execute()
	return mt({
		group = "awesome.execute",
		desc = "lua code prompt",
		cond = function()
			return awful.screen.focused().mypromptbox
		end,
		fn = function()
			awm.awesome_lua_prompt()
		end,
	})
end

function M.awesome_run_prompt()
	return mt({
		group = "awesome.execute",
		desc = "run prompt",
		cond = function()
			return awful.screen.focused().mypromptbox
		end,
		fn = function()
			awm.awesome_run_prompt()
		end,
	})
end

function M.spawn_terminal()
	return mt({
		group = "spawn",
		desc = "terminal",
		fn = function(opts)
			awful.spawn.with_shell(opts.awesome.terminal)
		end,
	})
end

function M.spawn_browser()
	return mt({
		group = "spawn",
		desc = "browser",
		fn = function(opts)
			awful.spawn.with_shell(opts.awesome.browser)
		end,
	})
end

function M.spawn(cmd)
	return mt({
		group = string.format("spawn.%s", cmd),
		desc = cmd,
		fn = function(_)
			awful.spawn(cmd)
		end,
	})
end

function M.spawn_with_shell(cmd)
	return mt({
		group = string.format("spawn.%s", cmd),
		desc = cmd,
		fn = function(_)
			awful.spawn.with_shell(cmd)
		end,
	})
end

function M.spawn_appmenu()
	return mt({
		group = "spawn",
		desc = "open app menu",
		fn = function(opts)
			awful.spawn.with_shell(opts.awesome.app_menu)
		end,
	})
end

function M.layout_master_width_increase(factor)
	return mt({
		group = "layout.master.width",
		desc = "master width increase",
		fn = function()
			awm.layout_master_width_increase(factor)
		end,
		result = { master_width = helper.get_current_tag_master_width_factor },
	})
end

function M.layout_master_width_decrease(factor)
	return mt({
		group = "layout.master.width",
		desc = "master width decrease",
		fn = function()
			awm.layout_master_width_decrease(factor)
		end,
		result = { master_width = helper.get_current_tag_master_width_factor },
	})
end

function M.layout_master_count_decrease()
	return mt({
		group = "layout.master.count",
		desc = "master count decrease",
		cond = function()
			return awful.screen.focused().selected_tag.master_count > 0
		end,
		fn = function()
			awm.layout_master_count_decrease()
		end,
		result = { master_count = helper.get_current_tag_master_count },
	})
end

function M.layout_master_count_increase()
	return mt({
		group = "layout.master.count",
		desc = "master count increase",
		fn = function()
			awm.layout_master_count_increase()
		end,
		result = { master_count = helper.get_current_tag_master_count },
	})
end

function M.layout_column_count_decrease()
	return mt({
		group = "layout.column.count",
		desc = "column count decrease",
		cond = function()
			return awful.screen.focused().selected_tag.column_count > 0
		end,
		fn = function()
			awm.layout_master_count_decrease()
		end,
		result = { column_count = helper.get_current_tag_column_count },
	})
end

function M.layout_column_count_increase()
	return mt({
		group = "layout.column.count",
		desc = "column count increase",
		fn = function()
			awm.layout_master_count_increase()
			return "column_count", helper.get_current_tag_column_count()
		end,
		result = { column_count = helper.get_current_tag_column_count },
	})
end

function M.layout_next()
	return mt({
		group = "layout.inc",
		desc = "next layout",
		fn = function()
			awm.layout_next()
			return "layout", helper.get_current_layout_name()
		end,
	})
end

function M.layout_prev()
	return mt({
		group = "layout.inc",
		desc = "prev layout",
		fn = function()
			awm.layout_prev()
			return "layout", helper.get_current_layout_name()
		end,
	})
end

function M.layout_select_menu()
	return mt({
		group = "layout.menu.select",
		desc = "select a layout",
		is_menu = true,
		fn = function(opts)
			local s = awful.screen.focused()
			local t = s.selected_tag

			if not t then
				return
			end

			local layouts = t.layouts or {}

			local ret = {}
			for i, l in pairs(layouts) do
				table.insert(ret, {
					util.index_to_label(i, opts.labels),
					desc = l.name,
					fn = function()
						awm.layout_set(t, l)
						return "layout", l.name
					end,
				})
			end

			return ret
		end,
	})
end

function M.client_select_picker(multi_window, include_focused_client)
	return mt({
		group = "client.menu.focus",
		is_menu = true,
		opts = {
			labels = util.labels_qwerty,
		},
		cond = function()
			return client.focus
		end,
		desc = "select client picker",
		fn = function(opts)
			local filter = awm.client_create_filter(multi_window, false, include_focused_client)
			local fn = function(c)
				c:activate({ raise = true, context = "client.focus.bydirection" })
			end
			local list = awm.client_picker(opts, fn, filter)

			return list
		end,
		on_leave = function()
			label.hide_labels()
		end,
	})
end

function M.client_swap_picker()
	return mt({
		group = "client.swap",
		is_menu = true,
		opts = {
			labels = util.labels_qwerty,
		},
		cond = function()
			return client.focus
		end,
		desc = "swap client picker",
		fn = function(opts)
			local include_focused_client = false
			local filter = awm.client_create_filter(false, false, include_focused_client)
			local fn = function(c)
				client.focus:swap(c)
			end
			return awm.client_picker(opts, fn, filter)
		end,
		on_leave = function()
			label.hide_labels()
		end,
	})
end

function M.client_focus_toggle_fullscreen()
	return mt({
		group = "client.property",
		desc = function(opts)
			local c = client.focus
			if not c then
				return "fullscreen toggle"
			end
			if c.fullscreen then
				return "fullscreen" .. " " .. opts.toggle_true
			end
			return "fullscreen" .. " " .. opts.toggle_false
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_fullscreen()
		end,
	})
end

function M.client_toggle_fullscreen(c)
	assert(c)
	return mt({
		group = "client.property",
		desc = function(opts)
			if not c then
				return "fullscreen toggle"
			end
			if c.fullscreen then
				return "fullscreen" .. " " .. opts.toggle_true
			end
			return "fullscreen" .. " " .. opts.toggle_false
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_toggle_fullscreen()
		end,
	})
end

function M.client_focus_toggle_maximize()
	return mt({
		group = "client.property",
		desc = function(opts)
			local c = client.focus
			if not c then
				return "maximize toggle"
			end
			if c.maximized then
				return "maximize" .. " " .. opts.toggle_true
			end
			return "maximize" .. " " .. opts.toggle_false
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_maximize()
		end,
	})
end

function M.client_toggle_maximize(c)
	assert(c)
	return mt({
		group = "client.property",
		desc = function(opts)
			if not c then
				return "maximize toggle"
			end
			if c.maximized then
				return "maximize" .. " " .. opts.toggle_true
			end
			return "maximize" .. " " .. opts.toggle_false
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_toggle_maximize(c)
		end,
	})
end

function M.client_focus_toggle_sticky()
	return mt({
		group = "client.property",
		desc = function(opts)
			local c = client.focus
			if not c then
				return "sticky toggle"
			end
			if c.sticky then
				return "sticky" .. " " .. opts.toggle_true
			end
			return "sticky" .. " " .. opts.toggle_false
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_sticky()
		end,
	})
end

function M.client_toggle_sticky(c)
	assert(c)
	return mt({
		group = "client.property",
		desc = function(opts)
			if not c then
				return "sticky toggle"
			end
			if c.sticky then
				return "sticky" .. " " .. opts.toggle_true
			end
			return "sticky" .. " " .. opts.toggle_false
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_toggle_sticky(c)
		end,
	})
end

function M.client_focus_toggle_maximize_horizontally()
	return mt({
		group = "client.property",
		desc = function(opts)
			local c = client.focus
			if not c then
				return "maximize horizontal toggle"
			end
			if c.maximized_horizontal then
				return "maximize horizontal" .. " " .. opts.toggle_true
			end
			return "maximize horizontal" .. " " .. opts.toggle_false
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_maximize_horizontally()
		end,
	})
end

function M.client_toggle_maximize_horizontally(c)
	assert(c)
	return mt({
		group = "client.property",
		desc = function(opts)
			if not c then
				return "maximize horizontal toggle"
			end
			if c.maximized_horizontal then
				return "maximize horizontal" .. " " .. opts.toggle_true
			end
			return "maximize horizontal" .. " " .. opts.toggle_false
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_toggle_maximize_horizontally(c)
		end,
	})
end

function M.client_focus_toggle_maximize_vertically()
	return mt({
		group = "client.property",
		desc = function(opts)
			local c = client.focus
			if not c then
				return "maximize vertical toggle"
			end
			if c.maximized_vertical then
				return "maximize vertical" .. " " .. opts.toggle_true
			end
			return "maximize vertical" .. " " .. opts.toggle_false
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_maximize_vertically()
		end,
	})
end

function M.client_toggle_maximize_vertically(c)
	assert(_)
	return mt({
		group = "client.property",
		desc = function(opts)
			if not c then
				return "maximize vertical toggle"
			end
			if c.maximized_vertical then
				return "maximize vertical" .. " " .. opts.toggle_true
			end
			return "maximize vertical" .. " " .. opts.toggle_false
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_toggle_maximize_vertically(c)
		end,
	})
end

function M.client_focus_toggle_floating()
	return mt({
		group = "client.property",
		desc = function(opts)
			local c = client.focus
			if not c then
				return "floating toggle"
			end
			if c.floating then
				return "floating" .. " " .. opts.toggle_true
			end
			return "floating" .. " " .. opts.toggle_false
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_floating()
		end,
	})
end

function M.client_toggle_floating(c)
	assert(c)
	return mt({
		group = "client.property",
		desc = function(opts)
			if not c then
				return "floating toggle"
			end
			if c.floating then
				return "floating" .. " " .. opts.toggle_true
			end
			return "floating" .. " " .. opts.toggle_false
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_toggle_floating(c)
		end,
	})
end

function M.client_focus_toggle_ontop()
	return mt({
		group = "client.property",
		desc = function(opts)
			local c = client.focus
			if not c then
				return "ontop toggle"
			end
			if c.ontop then
				return "ontop" .. " " .. opts.toggle_true
			end
			return "ontop" .. " " .. opts.toggle_false
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_ontop()
		end,
	})
end

function M.client_toggle_ontop(c)
	assert(c)
	return mt({
		group = "client.property",
		desc = function(opts)
			if not c then
				return "ontop top"
			end
			if c.ontop then
				return "ontop" .. " " .. opts.toggle_true
			end
			return "ontop" .. " " .. opts.toggle_false
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_toggle_ontop(1)
		end,
	})
end

function M.client_focus_minimize()
	return mt({
		group = "client.property",
		desc = "minimize",
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_minmize()
		end,
	})
end

function M.client_minimize(c)
	assert(c)
	return mt({
		group = "client.property",
		desc = "minimize",
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_minmize(c)
		end,
	})
end

function M.client_focus_kill()
	return mt({
		group = "client.kill",
		desc = function()
			return "client kill"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_kill()
		end,
	})
end

function M.client_kill(c)
	assert(c)
	return mt({
		group = "client.kill",
		desc = function()
			return "client kill"
		end,
		cond = function()
			return c and c.valid
		end,
		fn = function()
			awm.client_kill(c)
		end,
	})
end

function M.client_swap_master_smart()
	return mt({
		group = "client.swap.smart",
		desc = "master swap smart",
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_master_swap()
		end,
	})
end

function M.client_move_to_master()
	return mt({
		group = "client.layout.move.master",
		desc = "move to master",
		cond = function()
			local master = awful.client.getmaster()
			local focus = client.focus
			return master and focus and master ~= focus
		end,
		fn = function()
			awm.client_move_to_master()
		end,
	})
end

function M.client_focus(dir)
	return mt({
		group = "client.focus",
		desc = string.format("focus %s client", dir),
		fn = function()
			awm.client_focus_bydirection(dir)
		end,
	})
end

function M.client_focus_navigator(dir)
	return mt({
		group = "client.navigate",
		desc = string.format("navigate %s", dir),
		fn = function()
			awm.client_navigate(dir)
		end,
	})
end

function M.client_focus_prev()
	return mt({
		group = "client.focus",
		desc = "focus previous client",
		fn = function()
			awm.client_focus_prev()
		end,
	})
end

function M.client_move_smart(dir)
	return mt({
		group = "client.move",
		cond = function()
			return client.focus
		end,
		desc = string.format("move client %s", dir),
		fn = function(opts)
			awm.client_move_smart(client.focus, dir, opts.awesome.resize_delta)
		end,
	})
end

function M.client_resize_smart(dir)
	return mt({
		group = "client.layout.resize",
		cond = function()
			return client.focus
		end,
		desc = function()
			local c = client.focus
			local layout = awful.layout.get(awful.screen.focused()).name
			if layout == "floating" or c and (c.floating and not c.fullscreen) then
				return string.format("increase client size %s", dir)
			end
			return string.format("resize client smart %s", dir)
		end,
		fn = function(opts)
			awm.client_resize_smart(client.focus, dir, opts.awesome.resize_delta, opts.awesome.resize_factor)
		end,
	})
end

function M.client_floating_size_increase(dir)
	return mt({
		group = "client.layout.resize",
		cond = function()
			local layout = awful.layout.get(awful.screen.focused()).name
			local c = client.focus
			return layout == "floating" or c and c.floating and not c.fullscreen
		end,
		desc = function()
			return string.format("increase client size %s", dir)
		end,
		fn = function(opts)
			local c = client.focus
			local resize_delta = opts.awesome.resize_delta
			resize_delta = math.abs(resize_delta)
			awm.client_floating_resize(c, dir, resize_delta)
		end,
	})
end

function M.client_floating_size_decrease(dir)
	return mt({
		group = "client.layout.resize",
		cond = function()
			local layout = awful.layout.get(awful.screen.focused()).name
			local c = client.focus
			return layout == "floating" or c and c.floating and not c.fullscreen
		end,
		desc = function()
			return string.format("decrease client size %s", dir)
		end,
		fn = function(opts)
			local c = client.focus
			local resize_delta = opts.awesome.resize_delta
			resize_delta = math.abs(resize_delta) * -1
			awm.client_floating_resize(c, dir, resize_delta)
		end,
	})
end

function M.client_unminimize_menu(multi_tag)
	return mt({
		group = "client.property.unminimize",
		desc = "unminimize clients",
		is_menu = true,
		fn = function(opts)
			local ret = {}
			local i = 1
			local filter = awm.client_create_filter(false, multi_tag, false)
			for _, c in ipairs(client.get()) do
				if filter(c) and c.minimized then
					table.insert(ret, {
						util.index_to_label(i, opts.labels),
						desc = function()
							return helper.clientname(c, i)
						end,
						fn = function()
							awm.client_unminmize(c)
						end,
					})
					i = i + 1
				end
			end

			if opts.awesome.auto_select_the_only_choice then
				-- unminimize if there is only 1 client
				if #ret == 1 then
					ret[1].fn()
					return
				end
			end

			return ret
		end,
	})
end

function M.client_toggle_tag_menu()
	return mt({
		is_menu = true,
		group = "client.tags.toggle",
		cond = function()
			return client.focus
		end,
		desc = "toggle client tags",
		fn = function(opts)
			local s = awful.screen.focused()
			local c = client.focus
			local ret = {}
			for i, t in pairs(s.tags) do
				table.insert(ret, {
					util.index_to_label(i, opts.labels),
					desc = function()
						return helper.tagname(t)
					end,
					fn = function()
						awm.client_toggle_tag(c, t)
					end,
				})
			end

			return ret
		end,
	})
end

function M.tag_move_focused_client_to_tag(i)
	return mt({
		group = "tag.client.move",
		cond = function()
			local c = client.focus
			if not c then
				return false
			end
			local t = awful.screen.focused().tags[i]
			if not t then
				return false
			end

			for _, ct in pairs(c:tags()) do
				if ct == t then
					return false
				end
			end

			return true
		end,
		desc = function()
			return string.format("move client to tag %s", helper.tagname_by_index(i))
		end,
		fn = function()
			local c = client.focus
			if c then
				local tag = client.focus.screen.tags[i]
				if tag then
					awm.client_move_to_tag(c, tag)
				end
			end
		end,
	})
end

function M.move_client_to_tag_menu(c)
	assert(c)
	return mt({
		is_menu = true,
		group = "tag.client.move",
		cond = function()
			return c and c.valid
		end,
		desc = "move client to tag",
		fn = function(opts)
			local s = c.screen

			local ret = {}
			for i, t in ipairs(s.tags) do
				local desc = helper.tagname(t)
				table.insert(ret, {
					util.index_to_label(i, opts.labels),
					desc = desc,
					fn = function()
						awm.client_move_to_tag(c, t)
					end,
				})
			end

			return ret
		end,
	})
end

function M.tag_move_all_clients_to_tag_menu()
	return mt({
		is_menu = true,
		group = "tag.client.move.all",
		cond = function()
			return client.focus
		end,
		desc = "move all clients to tag",
		fn = function(opts)
			local s = awful.screen.focused()
			local tags = s.selected_tags
			local cls = {}
			for _, t in ipairs(tags) do
				for _, c in ipairs(t:clients()) do
					table.insert(cls, c)
				end
			end

			local ret = {}
			for i, t in ipairs(s.tags) do
				local desc = helper.tagname(t)
				table.insert(ret, {
					util.index_to_label(i, opts.labels),
					desc = desc,
					fn = function()
						for _, c in ipairs(cls) do
							awm.client_move_to_tag(c, t)
						end
					end,
				})
			end

			return ret
		end,
	})
end

function M.tag_toggle_menu()
	return mt({
		is_menu = true,
		group = "tag.toggle",
		cond = function()
			return client.focus
		end,
		desc = "toggle tags",
		fn = function(opts)
			local s = awful.screen.focused()
			local ret = {}
			for i, t in pairs(s.tags) do
				table.insert(ret, {
					util.index_to_label(i, opts.labels),
					desc = function()
						return helper.tagname(t)
					end,
					fn = function()
						awm.tag_toggle_index(i)
					end,
				})
			end

			return ret
		end,
	})
end

function M.tag_toggle_policy()
	return mt({
		group = "tag.property.policy",
		desc = "fill policy toggle",
		cond = function()
			return awful.screen.focused().selected_tag
		end,
		result = { fill_policty = helper.get_current_tag_master_fill_policy },
		fn = function()
			local s = awful.screen.focused()
			local t = s.selected_tag
			if not t then
				return
			end
			awm.tag_toggle_fill_policy(t)
		end,
	})
end

function M.tag_toggle_volatile()
	return mt({
		group = "tag.property.volatile",
		desc = function(opts)
			local t = awful.screen.focused().selected_tag
			if not t then
				return "volatile toggle"
			end
			if t.volatile then
				return "volatile" .. " " .. opts.toggle_true
			end
			return "volatile" .. " " .. opts.toggle_false
		end,
		result = { volatile = helper.get_current_tag_volatile },
		fn = function()
			local s = awful.screen.focused()
			local t = s.selected_tag
			if not t then
				return
			end

			t.volatile = not t.volatile
		end,
	})
end

function M.tag_toggle_gap_single_client()
	return mt({
		group = "tag.property.gap.single",
		desc = function(opts)
			local t = awful.screen.focused().selected_tag
			if not t then
				return "gap single client toggle"
			end
			if t.gap_single_client then
				return "gap single client" .. " " .. opts.toggle_true
			end
			return "gap single client" .. " " .. opts.toggle_false
		end,
		result = { gap_single_client = helper.get_current_tag_gap_single_client },
		fn = function()
			local s = awful.screen.focused()
			local t = s.selected_tag
			if not t then
				return
			end

			t.gap_single_client = not t.gap_single_client
		end,
	})
end

function M.tag_view_only(i)
	return mt({
		group = "tag.view",
		desc = function()
			return "view tag " .. (helper.tagname_by_index(i) or i)
		end,
		cond = function()
			return awful.screen.focused().tags[i]
		end,
		fn = function()
			awm.tag_view_only_index(i)
		end,
	})
end

function M.tag_view_only_menu()
	return mt({
		is_menu = true,
		group = "tag.view",
		desc = "view only tag",
		fn = function(opts)
			local s = awful.screen.focused()
			local ret = {}
			for i, t in ipairs(s.tags) do
				table.insert(ret, {
					util.index_to_label(i, opts.labels),
					desc = function()
						return helper.tagname(t)
					end,
					fn = function()
						awm.tag_view_only(t)
					end,
				})
			end
			return ret
		end,
	})
end

function M.tag_delete()
	return mt({
		group = "tag.action",
		desc = "delete selected tag",
		cond = function()
			return awful.screen.focused().selected_tag
		end,
		fn = function()
			local t = awful.screen.focused().selected_tag
			if not t then
				return
			end
			awm.tag_delete(t)
		end,
	})
end

function M.tag_toggle_index(i)
	return mt({
		group = "tag.toggle",
		desc = function()
			helper.tagname_by_index(i)
		end,
		cond = function()
			return awful.screen.focused().tags[i]
		end,
		fn = function()
			awm.tag_toggle_index(i)
		end,
	})
end

function M.tag_next()
	return mt({
		group = "tag.cycle",
		desc = function()
			return "view next tag"
		end,
		fn = function()
			awm.tag_next()
		end,
	})
end

function M.tag_previous()
	return mt({
		group = "tag.cycle",
		desc = function()
			return "view previous tag"
		end,
		fn = function()
			awm.tag_prev()
		end,
	})
end

function M.tag_last()
	return mt({
		group = "tag.cycle",
		desc = function()
			return "view last tag"
		end,
		fn = function()
			awful.tag.history.restore()
		end,
	})
end

function M.tag_new()
	return mt({
		group = "tag.new",
		desc = "new tag",
		function(opts)
			local fn = function(name)
				awful.tag
					.add(name, {
						screen = awful.screen.focused(),
					})
					:view_only()
			end
			local initial = ""
			local header = "tag name:"
			require("modalisa.ui.prompt").run(fn, initial, header, opts)
		end,
	})
end

function M.tag_new_copy()
	return mt({
		group = "tag.new.copy",
		desc = "new tag copy",
		opts = { echo = { vertical_layout = true, align_vertical = false } },
		cond = function()
			return awful.screen.focused().selected_tag
		end,
		function(opts)
			local t = awful.screen.focused().selected_tag
			local fn = function(name)
				local props = {
					screen = awful.screen.focused(),
					layout = t.layout,
					layouts = vim.deepcopy(t.layouts),
					gap = t.gap,
					icon = t.icon,
					volatile = t.volatile,
					gap_single_client = t.gap_single_client,
					master_width_factor = t.master_width_factor,
					master_count = t.master_count,
					column_count = t.column_count,
					master_fill_policy = t.master_fill_policy,
				}
				awful.tag.add(name, props):view_only()
				-- don't show these values:
				props.screen = nil
				props.layouts = nil
				props.layout = props.layout.name
				require("modalisa.ui.echo").show(props, opts)
			end
			local initial = ""
			local header = "tag name:"
			require("modalisa.ui.prompt").run(fn, initial, header, opts)
		end,
	})
end

function M.tag_rename()
	return mt({
		group = "tag.rename",
		desc = "rename tag",
		cond = function()
			return awful.screen.focused().selected_tag
		end,
		function(opts)
			local fn = function(s)
				awful.tag.selected().name = s
			end
			local initial = awful.tag.selected().name
			local header = "rename tag:"
			require("modalisa.ui.prompt").run(fn, initial, header, opts)
		end,
	})
end

function M.tag_gap()
	return mt({
		group = "tag.gap",
		desc = "set tag gap",
		cond = function()
			return awful.screen.focused().selected_tag
		end,
		function(opts)
			local t = awful.screen.focused().selected_tag
			if not t then
				return
			end
			local fn = function(s)
				local gap = tonumber(s)
				if not gap then
					return
				end
				t.gap = gap
			end
			local initial = t.gap
			local header = "tag gap"
			require("modalisa.ui.prompt").run(fn, initial, header, opts)
		end,
	})
end

function helper.tagname_by_index(i)
	local s = awful.screen.focused()
	local t = s.tags[i]
	if not t then
		return string.format("%s", i)
	end

	return helper.tagname(t)
end

function helper.tagname(t)
	local i = t.index
	local txt = string.format("%d", i)
	local name = t.name
	if name then
		txt = string.format("%s: %s", txt, name)
	end

	return txt
end

function helper.clientname(c, i)
	local txt = string.format("%d", i)
	if c.class then
		txt = c.class
	end
	if c.name then
		txt = string.format("[%s] %s", txt, c.name)
	end
	return txt
end

function helper.get_current_layout_name()
	return awful.screen.focused().selected_tag.name
end

function helper.get_current_tag_master_width_factor()
	return awful.screen.focused().selected_tag.master_width_factor
end

function helper.get_current_tag_column_count()
	return awful.screen.focused().selected_tag.column_count
end

function helper.get_current_tag_master_count()
	return awful.screen.focused().selected_tag.master_count
end

function helper.get_current_tag_master_fill_policy()
	return awful.screen.focused().selected_tag.master_fill_policy
end

function helper.get_current_tag_volatile()
	return awful.screen.focused().selected_tag.volatile
end

function helper.get_current_tag_gap_single_client()
	return awful.screen.focused().selected_tag.gap_single_client
end

function helper.get_current_tag_gap()
	return awful.screen.focused().selected_tag.gap
end

M.util = helper

return M

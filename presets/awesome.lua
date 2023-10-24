local awful = require("awful")
local util = require("motion.util")
local dump = require("motion.lib.vim").inspect
local awm = require("motion.awesome")
local mt = require("motion.presets.metatable")

local M = {}
local helper = {}

-- TODO: placement
-- new tag, rename, gap
-- screen (awful.screen.focus_relative(-1), c:move_to_screen())
-- wallpaper example
-- client: border_width, skip taskbar, hidden, hide bar
-- urgent
-- resume menu
-- resize modes
-- run(true is hotkey)

function M.awesome_help()
	return mt({
		opts = { group = "awesome.menu" },
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
		opts = { group = "awesome.menu" },
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
		opts = { group = "awesome.stop" },
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
		opts = { group = "awesome.stop" },
		desc = "restart awesome",
		fn = function()
			awm.awesome_restart()
		end,
	})
end

function M.awesome_execute()
	return mt({
		opts = { group = "awesome.execute" },
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
		opts = { group = "awesome.execute" },
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
		opts = { group = "spawn" },
		desc = "terminal",
		fn = function(opts)
			if not opts.terminal then
				return
			end
			awful.spawn.with_shell(opts.terminal)
		end,
	})
end

function M.spawn_browser()
	return mt({
		opts = { group = "spawn" },
		desc = "browser",
		fn = function(opts)
			if not opts.browser then
				return
			end
			awful.spawn.with_shell(opts.browser)
		end,
	})
end

function M.spawn(cmd)
	return mt({
		opts = { group = string.format("spawn.%s", cmd) },
		desc = cmd,
		fn = function(_)
			awful.spawn(cmd)
		end,
	})
end

function M.spawn_with_shell(cmd)
	return mt({
		opts = { group = string.format("spawn.%s", cmd) },
		desc = cmd,
		fn = function(_)
			awful.spawn.with_shell(cmd)
		end,
	})
end

function M.spawn_appmenu()
	return mt({
		opts = { group = "spawn" },
		desc = "open app menu",
		fn = function(opts)
			if not opts.app_menu then
				return
			end
			awful.spawn.with_shell(opts.app_menu)
		end,
	})
end

function M.layout_master_width_increase(factor)
	return mt({
		opts = { group = "layout.master.width" },
		desc = "master width increase",
		fn = function()
			awm.layout_master_width_increase(factor)
		end,
	})
end

function M.layout_master_width_decrease(factor)
	return mt({
		opts = { group = "layout.master.width" },
		desc = "master width decrease",
		fn = function()
			awm.layout_master_width_decrease(factor)
		end,
	})
end

function M.layout_master_count_decrease()
	return mt({
		opts = { group = "layout.master.count" },
		desc = "master count decrease",
		result = { master_count = helper.get_current_tag_master_count },
		fn = function(opts, self)
			awm.layout_master_count_decrease()
		end,
	})
end

function M.layout_master_count_increase()
	return mt({
		opts = { group = "layout.master.count" },
		desc = "master count increase",
		result = { master_count = helper.get_current_tag_master_count },
		fn = function()
			awm.layout_master_count_increase()
		end,
	})
end

function M.layout_column_count_decrease()
	return mt({
		opts = { group = "layout.column.count" },
		desc = "column count decrease",
		fn = function()
			awm.layout_master_count_decrease()
		end,
	})
end

function M.layout_column_count_increase()
	return mt({
		opts = { group = "layout.column.count" },
		desc = "column count increase",
		fn = function()
			awm.layout_master_count_increase()
			return "column_count", helper.get_current_tag_column_count()
		end,
	})
end

function M.layout_next()
	return mt({
		opts = { group = "layout.inc" },
		desc = "next layout",
		fn = function()
			awm.layout_next()
			return "layout", helper.get_current_layout_name()
		end,
	})
end

function M.layout_prev()
	return mt({
		opts = { group = "layout.inc" },
		desc = "prev layout",
		fn = function()
			awm.layout_prev()
			return "layout", helper.get_current_layout_name()
		end,
	})
end

function M.layout_select_menu()
	return mt({
		opts = { group = "layout.menu.select" },
		desc = "select a layout",
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
		opts = {
			group = "client.menu.focus",
			hints_show = false,
			labels = util.labels_qwerty,
		},
		cond = function()
			return client.focus
		end,
		desc = "select client picker",
		fn = function(opts, t)
			local filter = awm.client_create_filter(multi_window, include_focused_client)
			local fn = function(c)
				c:activate({ raise = true, context = "client.focus.bydirection" })
			end
			local list = awm.client_picker(opts, fn, filter)

			-- FIXME:
			-- require("motion.config")["hints_separator"] = "xxx"

			return list
		end,
	})
end

function M.client_swap_picker()
	return mt({
		opts = {
			group = "client.swap",
			hints_show = false,
			labels = "asdfertgcvjkluionmb",
		},
		cond = function()
			return client.focus
		end,
		desc = "swap client picker",
		fn = function(opts)
			local include_focused_client = false
			local filter = awm.client_create_filter(false, include_focused_client)
			local fn = function(c)
				local cf = client.focus
				client.focus:swap(c)
			end
			return awm.client_picker(opts, fn, filter)
		end,
	})
end

function M.client_toggle_fullscreen()
	return mt({
		opts = { group = "client.property" },
		desc = function()
			local c = client.focus
			if not c then
				return "toggle fullscreen"
			end
			if c.fullscreen then
				return "unfullscreen"
			end
			return "fullscreen"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_fullscreen()
			return "fullscreen", client.focus.fullscreen
		end,
	})
end

function M.client_toggle_maximize()
	return mt({
		opts = { group = "client.property" },
		desc = function()
			local c = client.focus
			if not c then
				return "toggle maximize"
			end
			if c.maximized then
				return "unmaximize"
			end
			return "maximize"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_maximize()
		end,
	})
end

function M.client_toggle_sticky()
	return mt({
		opts = { group = "client.property" },
		desc = function()
			local c = client.focus
			if not c then
				return "toggle sticky"
			end
			if c.sticky then
				return "unsticky"
			end
			return "sticky"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_sticky()
		end,
	})
end

function M.client_toggle_maximize_horizontally()
	return mt({
		opts = { group = "client.property" },
		desc = function()
			local c = client.focus
			if not c then
				return "toggle maximize horizontally"
			end
			if c.maximized_horizontal then
				return "unmaximize horizontally"
			end
			return "maximize horizontally"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_maximize_horizontally()
		end,
	})
end

function M.client_toggle_maximize_vertically()
	return mt({
		opts = { group = "client.property" },
		desc = function()
			local c = client.focus
			if not c then
				return "toggle maximize vertically"
			end
			if c.maximized_vertical then
				return "unmaximize vertically"
			end
			return "maximize vertically"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_maximize_vertically()
		end,
	})
end

function M.client_toggle_floating()
	return mt({
		opts = { group = "client.property" },
		desc = function()
			local c = client.focus
			if not c then
				return "toggle floating"
			end
			if c.floating then
				return "unfloating"
			end
			return "floating"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_floating()
		end,
	})
end

function M.client_toggle_ontop()
	return mt({
		opts = { group = "client.property" },
		desc = function()
			local c = client.focus
			if not c then
				return "toggle ontop"
			end
			if c.ontop then
				return "ontop disable"
			end
			return "ontop"
		end,
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_toggle_ontop()
		end,
	})
end

function M.client_minimize()
	return mt({
		opts = { group = "client.property" },
		desc = "minimize",
		cond = function()
			return client.focus
		end,
		fn = function()
			awm.client_minmize()
		end,
	})
end

function M.client_kill()
	return mt({
		opts = { group = "client" },
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

function M.client_swap_master_smart()
	return mt({
		opts = { group = "client" },
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
		opts = { group = "client.layout.move.master" },
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
		opts = { group = "client.focus" },
		desc = string.format("focus %s client", dir),
		fn = function()
			awm.client_focus_bydirection(dir)
		end,
	})
end

function M.client_focus_navigator(dir)
	return mt({
		opts = { group = "client.navigate" },
		desc = string.format("navigate %s", dir),
		fn = function()
			awm.client_navigate(dir)
		end,
	})
end

function M.client_focus_prev()
	return mt({
		opts = { group = "client.focus" },
		desc = "focus previous client",
		fn = function()
			awm.client_focus_prev()
		end,
	})
end

function M.client_move_smart(dir)
	return mt({
		opts = { group = "client.layout.move" },
		cond = function()
			return client.focus
		end,
		desc = string.format("move client %s", dir),
		fn = function(opts)
			awm.client_move_smart(client.focus, dir, opts.resize_delta)
		end,
	})
end

function M.client_resize_smart(dir)
	return mt({
		opts = { group = "client.layout.resize" },
		cond = function()
			return client.focus
		end,
		result = {
			master_width = helper.get_current_tag_master_width_factor(),
			master_count = helper.get_current_tag_master_count(),
			column_count = helper.get_current_tag_column_count(),
			something = helper.get_current_tag_column_count(),
		},
		desc = function()
			-- local c = client.focus
			-- local layout = awful.layout.get(awful.screen.focused()).name
			-- if layout == "floating" or c.floating then
			-- 	return string.format("increase client size %s", dir)
			-- end
			return string.format("resize client smart %s", dir)
		end,
		fn = function(opts)
			awm.client_resize_smart(client.focus, dir, opts.resize_delta, opts.resize_factor)
		end,
	})
end

function M.client_floating_size_increase(dir)
	return mt({
		opts = { group = "client.layout.resize" },
		cond = function()
			local layout = awful.layout.get(awful.screen.focused()).name
			return layout == "floating" or client.focus and client.focus.floating
		end,
		desc = function()
			return string.format("increase client size %s", dir)
		end,
		fn = function(opts)
			local c = client.focus
			local resize_delta = opts.resize_delta
			resize_delta = math.abs(resize_delta)
			awm.client_floating_resize(c, dir, resize_delta)
		end,
	})
end

function M.client_floating_size_decrease(dir)
	return mt({
		opts = { group = "client.layout.resize" },
		cond = function()
			local layout = awful.layout.get(awful.screen.focused()).name
			return layout == "floating" or client.focus and client.focus.floating
		end,
		desc = function()
			return string.format("decrease client size %s", dir)
		end,
		fn = function(opts)
			local c = client.focus
			local resize_delta = opts.resize_delta
			resize_delta = math.abs(resize_delta) * -1
			awm.client_floating_resize(c, dir, resize_delta)
		end,
	})
end

function M.client_unminimize_menu()
	return mt({
		opts = { group = "client.property.unminimize" },
		cond = function()
			local s = awful.screen.focused()
			for _, t in ipairs(s.tags) do
				for _, c in ipairs(t:clients()) do
					if c.minimized then
						return true
					end
				end
			end
			return false
		end,
		desc = "unminimize client(s)",
		fn = function(opts)
			local s = awful.screen.focused()
			local ret = {}
			local i = 1
			for _, t in ipairs(s.tags) do
				for _, c in ipairs(t:clients()) do
					if c.minimized then
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
			end

			if opts.auto_select_the_only_choice then
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
		opts = { group = "client.tags.toggle" },
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
		opts = { group = "tag.client.move" },
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

function M.tag_move_all_clients_to_tag_menu()
	return mt({
		opts = { group = "tag.client.move.all" },
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
				local desc = string.format("%d", i)
				if t.name then
					desc = string.format("%s: %s", desc, t.name)
				end
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
		opts = { group = "tag.toggle" },
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
		opts = { group = "tag.policy" },
		desc = "toggle tag fill policy",
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

function M.tag_view_only(i)
	return mt({
		opts = { group = "tag.view" },
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
		opts = { group = "tag.view" },
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
		opts = { group = "tag.action" },
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
		opts = { group = "tag.toggle" },
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
		opts = { group = "tag.cycle" },
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
		opts = { group = "tag.cycle" },
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
		opts = { group = "tag.cycle" },
		desc = function()
			return "view last tag"
		end,
		fn = function()
			awful.tag.history.restore()
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

function helper.get_current_tag_gap()
	return awful.screen.focused().selected_tag.gap
end

M.util = helper

return M

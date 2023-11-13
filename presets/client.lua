local awful = require("awful")
local util = require("modalisa.util")
local dpi = require("beautiful").xresources.apply_dpi
local grect = require("gears.geometry").rectangle
local mt = require("modalisa.presets.metatable")
local helper = require("modalisa.presets.helper")
local pscreen = require("modalisa.presets.screen")
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}

local default_resize_delta = dpi(32)
local default_resize_factor = 0.05

function M.client_create_filter(multi_screen, multi_tag, include_focused_client)
	return function(c)
		if not c then
			return false
		end

		if c.hidden or c.type == "splash" or c.type == "dock" or c.type == "desktop" then
			return false
		end

		if c == client.focus then
			if not include_focused_client then
				return false
			end
		end

		if c.sticky then
			if c.screen == awful.screen.focused() or multi_screen then
				return true
			end
		end

		local scrs = {}

		if multi_screen then
			for scr in screen do
				table.insert(scrs, scr)
			end
		else
			table.insert(scrs, awful.screen.focused())
		end

		if multi_tag then
			return true
		end

		-- check tag selection
		for _, scr in ipairs(scrs) do
			local tags = scr.tags
			for _, t in ipairs(tags) do
				if t.selected then
					local ctags = c:tags()
					for _, v in ipairs(ctags) do
						if v == t then
							return true
						end
					end
				end
			end
		end

		return false
	end
end

local function client_picker(opts, fn, filter)
	local list = client.get() -- unsorted list from all screens

	local cls = {}
	for _, c in ipairs(list) do
		if filter(c) then
			local si = c.screen.index
			cls[si] = cls[si] or {}
			table.insert(cls[si], c)
		end
	end

	-- put clients from selected screen first, so labeling is consistent whether
	-- multiscreen is enabled or not
	local si = awful.screen.focused().index

	local clients = {}
	for _, c in ipairs(cls[si] or {}) do
		-- put filtered clients from focused screen
		table.insert(clients, c)
	end

	for s in screen do
		if s.index ~= si then
			-- put filtered clients from other screens
			for _, c in ipairs(cls[s.index] or {}) do
				table.insert(clients, c)
			end
		end
	end

	local menu = {}

	for i, c in ipairs(clients) do
		local lbl = util.index_to_label(i, opts.labels)
		awesome.emit_signal("modalisa::label::show", c, lbl, opts)
		-- create menu
		table.insert(menu, {
			lbl,
			desc = function()
				helper.clientname(c, i)
			end,
			fn = function()
				fn(c)
			end,
		})
	end

	-- only 1 client
	if opts.awesome.auto_select_the_only_choice then
		if #menu == 1 then
			awesome.emit_signal("modalisa::label::hide")
			menu[1].fn()
			return
		end
	end

	return menu
end

local function client_minmize(c)
	c = c or client.focus
	if not c then
		return
	end
	c.minimized = true
end

local function client_unminmize(c)
	c = c or client.focus
	if not c then
		return
	end
	c:activate({ raise = true, context = "key.unminimize" })
end

local function client_placement(placement, cl)
	local c = cl or client.focus
	if not c then
		return
	end
	local fn = awful.placement[placement]
	if not fn then
		return
	end

	fn(c, { honor_workarea = true })
end

local function client_kill(c)
	c = c or client.focus
	if not c then
		return
	end
	c:kill()
end

local function client_move_to_master(c)
	c = c or client.focus
	if not c then
		return
	end
	c:swap(awful.client.getmaster())
end

local function client_focus_bydirection(dir)
	awful.client.focus.global_bydirection(dir)
end

local function client_navigate(dir)
	awesome.emit_signal("navigator::navigate", dir)
end

local function client_focus_prev()
	awful.client.focus.history.previous()
	if client.focus then
		client.focus:raise()
	end
end

local function client_master_swap(c)
	c = c or client.focus
	if not c then
		return
	end
	local master = awful.client.getmaster(awful.screen.focused())
	local last_focused_window = awful.client.focus.history.get(awful.screen.focused(), 1, nil)
	-- c is the master
	if c == master then
		if not last_focused_window then
			-- no other client
			return
		end
		client.focus = last_focused_window
		c:swap(last_focused_window)
		-- client.focus = c
	else
		-- c is not the master
		client.focus = master
		c:swap(master)
		-- client.focus = c
	end
	local new_master = awful.client.getmaster(awful.screen.focused())

	if new_master then
		client.focus = new_master
	end
end

local function get_screen(s)
	return s and screen[s]
end

local function client_filter(c)
	if c.type == "desktop" or c.type == "dock" or c.type == "splash" or not c.focusable then
		return nil
	end
	return c
end

local function bydirection(dir, c, stacked)
	local sel = c or client.focus
	if sel then
		local cltbl = awful.client.visible(sel.screen, stacked)
		local geomtbl = {}
		for i, cl in ipairs(cltbl) do
			if client_filter(cl) then
				geomtbl[i] = cl:geometry()
			end
		end

		local target = grect.get_in_direction(dir, geomtbl, sel:geometry())

		-- If we found a client to focus, then do it.
		if target then
			cltbl[target]:emit_signal("request::activate", "client.focus.bydirection", { raise = false })
		end
	end
end

function M.global_bydirection(dir, c, stacked)
	local sel = c or client.focus
	-- change focus inside the screen
	bydirection(dir, sel, stacked)

	-- if focus not changed, we must change screen
	if sel == client.focus then
		local scr = awful.screen.focused()
		awful.screen.focus_bydirection(dir, scr)
		if scr ~= get_screen(awful.screen.focused()) then
			local cltbl = awful.client.visible(awful.screen.focused(), stacked)
			local geomtbl = {}
			for i, cl in ipairs(cltbl) do
				if client_filter(cl) then
					geomtbl[i] = cl:geometry()
				end
			end
			local target = grect.get_in_direction(dir, geomtbl, scr.geometry)

			if target then
				cltbl[target]:emit_signal("request::activate", "client.focus.global_bydirection", { raise = false })
			end
		end
	end
end

function M.move_global_bydirection(dir, sel)
	sel = sel or client.focus

	if sel then
		-- move focus
		M.global_bydirection(dir, sel)
		local c = client.focus

		-- swapping inside a screen
		if get_screen(sel.screen) == get_screen(c.screen) and sel ~= c then
			c:swap(sel)

		-- swapping to an empty screen
		elseif sel == c then
			sel:move_to_screen(mouse.screen)

		-- swapping to a nonempty screen
		elseif get_screen(sel.screen) ~= get_screen(c.screen) and sel ~= c then
			sel:move_to_screen(c.screen)
		end

		awful.screen.focus(sel.screen)
		sel:emit_signal("request::activate", "client.swap.global_bydirection", { raise = false })
	end
end

local function client_move_smart(c, dir, resize_delta)
	c = c or client.focus
	if not c then
		return
	end

	resize_delta = resize_delta or default_resize_delta

	if c.maximized then
		c.maximized = false
	end

	if c.maximized_vertial then
		c.maximized_vertial = false
	end

	if c.maximized_horiztonal then
		c.maximized_horizontal = false
	end

	if c.fullscreen then
		c.fullscreen = false
	end

	local s = awful.screen.focused()
	local l = awful.layout.get(s)

	if c.floating or (l == awful.layout.suit.floating) then
		if dir == "down" then
			c.y = c.y + resize_delta
		elseif dir == "up" then
			c.y = c.y - resize_delta
		elseif dir == "left" then
			c.x = c.x - resize_delta
		elseif dir == "right" then
			c.x = c.x + resize_delta
		end
		awful.placement.no_offscreen(c)
		c:raise()
	else
		M.move_global_bydirection(dir, c)
	end
end

local function client_floating_resize(c, dir, px)
	local resize = {
		left = function(cl, d)
			cl.x = cl.x - d
			cl.width = cl.width + d
		end,
		right = function(cl, d)
			cl.width = cl.width + d
		end,
		up = function(cl, d)
			cl.height = cl.height + d
			cl.y = cl.y - d
		end,
		down = function(cl, d)
			cl.height = cl.height + d
		end,
	}

	c = c or client.focus
	px = px or default_resize_delta
	resize[dir](c, px)
	awful.placement.no_offscreen(c)
end

local function client_resize_tiled(c, dir, resize_factor)
	c = c or client.focus
	if not c then
		return
	end

	resize_factor = resize_factor or default_resize_factor

	if c.maximized then
		c.maximized = false
	end

	if c.maximized_vertial then
		c.maximized_vertial = false
	end

	if c.maximized_horiztonal then
		c.maximized_horizontal = false
	end

	if c.fullscreen then
		c.fullscreen = false
	end

	local layout = awful.layout.get(awful.screen.focused()).name

	if layout == "tiletop" then
		if dir == "up" then
			dir = "right"
		elseif dir == "down" then
			dir = "left"
		elseif dir == "left" then
			dir = "up"
		elseif dir == "right" then
			dir = "down"
		end
	elseif layout == "tilebottom" then
		if dir == "right" then
			dir = "down"
		elseif dir == "left" then
			dir = "up"
		elseif dir == "up" then
			dir = "left"
		elseif dir == "down" then
			dir = "right"
		end
	elseif layout == "tileleft" then
		if dir == "right" then
			dir = "left"
		elseif dir == "left" then
			dir = "right"
		end
	end

	if dir == "up" then
		local idx = awful.client.idx(c).idx
		if idx == 1 then
			awful.client.incwfact(-resize_factor)
		else
			awful.client.incwfact(resize_factor)
		end
	elseif dir == "down" then
		local idx = awful.client.idx(c).idx
		if idx == 1 then
			awful.client.incwfact(resize_factor)
		else
			awful.client.incwfact(-resize_factor)
		end
	elseif dir == "left" then
		awful.tag.incmwfact(-resize_factor / 4)
	elseif dir == "right" then
		awful.tag.incmwfact(resize_factor / 4)
	end
end

local function client_resize_smart(c, dir, resize_delta, resize_factor)
	c = c or client.focus
	if not c then
		return
	end

	resize_delta = resize_delta or default_resize_delta
	resize_factor = resize_factor or default_resize_factor

	local layout = awful.layout.get(awful.screen.focused()).name
	if layout == "floating" or c.floating then
		return client_floating_resize(c, dir, resize_delta)
	end

	client_resize_tiled(c, dir, resize_factor)
end

local function client_toggle_tag(c, t)
	c = c or client.focus
	if not c or not t then
		return
	end
	c:toggle_tag(t)
end

local function cond_is_floating(cl)
	local c = cl or client.focus
	if not c then
		return
	end
	local layout = awful.layout.get(awful.screen.focused()).name
	return layout == "floating" or c.floating
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
			local filter = M.client_create_filter(multi_window, false, include_focused_client)
			local fn = function(c)
				c:activate({ raise = true, context = "client.focus.bydirection" })
			end
			local list = client_picker(opts, fn, filter)

			return list
		end,
		on_leave = function()
			awesome.emit_signal("modalisa::label::hide")
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
			local filter = M.client_create_filter(false, false, include_focused_client)
			local fn = function(c)
				client.focus:swap(c)
			end
			return client_picker(opts, fn, filter)
		end,
		on_leave = function()
			awesome.emit_signal("modalisa::label::hide")
		end,
	})
end

function M.client_minimize(cl)
	return mt({
		group = "client.property",
		desc = "minimize",
		cond = function()
			local c = cl or client.focus
			return c and c.valid
		end,
		fn = function()
			local c = cl or client.focus
			client_minmize(c)
		end,
	})
end

function M.client_kill(cl)
	return mt({
		group = "client.kill",
		desc = function()
			return "client kill"
		end,
		cond = function()
			local c = cl or client.focus
			return c and c.valid
		end,
		fn = function()
			local c = cl or client.focus
			client_kill(c)
		end,
	})
end

function M.client_swap_master_smart(cl)
	return mt({
		group = "client.swap.smart",
		desc = "master swap smart",
		cond = function()
			local c = cl or client.focus
			return c and c.valid
		end,
		fn = function()
			local c = cl or client.focus
			client_master_swap(c)
		end,
	})
end

function M.client_move_to_master(cl)
	return mt({
		group = "client.layout.move.master",
		desc = "move to master",
		cond = function()
			local c = cl or client.focus
			local master = awful.client.getmaster()
			return master and c and master ~= c
		end,
		fn = function()
			local c = cl or client.focus
			client_move_to_master(c)
		end,
	})
end

function M.client_focus(dir)
	return mt({
		group = "client.focus",
		desc = string.format("focus %s client", dir),
		fn = function()
			client_focus_bydirection(dir)
		end,
	})
end

function M.client_focus_navigator(dir)
	return mt({
		group = "client.navigate",
		desc = string.format("navigate %s", dir),
		fn = function()
			client_navigate(dir)
		end,
	})
end

function M.client_focus_prev()
	return mt({
		group = "client.focus",
		desc = "focus previous client",
		fn = function()
			client_focus_prev()
		end,
	})
end

function M.client_move_smart(dir, cl)
	return mt({
		group = "client.move",
		cond = function()
			local c = cl or client.focus
			return c and c.valid
		end,
		desc = string.format("move client %s", dir),
		fn = function(opts)
			local c = cl or client.focus
			client_move_smart(c, dir, opts.awesome.resize_delta)
		end,
	})
end

function M.client_toggle_titlebar(cl)
	return mt({
		group = "client.tilebar",
		cond = function()
			local c = cl or client.focus
			return c and c.valid
		end,
		desc = "client titlebar toggle",
		fn = function()
			local c = cl or client.focus
			if not c then
				return
			end

			awful.titlebar.toggle(c, "top")
			awful.titlebar.toggle(c, "bottom")
			awful.titlebar.toggle(c, "left")
			awful.titlebar.toggle(c, "right")
		end,
	})
end

function M.client_toggle_property(x, cl, raise)
	return mt({
		group = string.format("client.property.%s", x),
		cond = function()
			local c = cl or client.focus
			if not c or not c.valid then
				return
			end
			if c[x] ~= nil then
				return type(c[x]) == "boolean"
			end
		end,
		desc = function(opts)
			local c = cl or client.focus
			if not c or not c.valid then
				return string.format("client %s toggle", x)
			end
			if c[x] then
				return string.format("client %s %s", x, opts.toggle_true)
			end
			return string.format("client %s %s", x, opts.toggle_false)
		end,
		fn = function()
			local c = cl or client.focus
			if not c then
				return
			end
			c[x] = not c[x]
			if raise then
				c:raise()
			end
		end,
	})
end

function M.client_set_property(x, cl)
	return mt({
		group = string.format("client.property.%s", x),
		desc = string.format("client set %s", x),
		cond = function()
			local c = cl or client.focus
			return c and c.valid
		end,
		fn = function(opts)
			local c = cl or client.focus
			if not c then
				return
			end
			local current_value = c[x]
			if not current_value then
				return
			end

			local is_number = false
			if type(current_value) == "number" then
				is_number = true
			end

			local header = string.format("%s:", x)
			local initial = current_value
			local fn = function(str)
				local value = str
				if is_number then
					local number = tonumber(str)
					if not number then
						return
					end
					value = number
				end
				c[x] = value
			end

			awesome.emit_signal("modalisa::prompt", { fn = fn, initial = initial, header = header }, opts)
		end,
	})
end

function M.client_placement(placement, cl)
	return mt({
		group = "client.placement",
		cond = function()
			return cond_is_floating(cl)
		end,
		desc = string.format("place %s", placement),
		fn = function()
			client_placement(placement, cl)
		end,
	})
end

function M.client_resize_mode_floating(cl)
	return mt({
		group = "resize.mode",
		cond = function()
			return cond_is_floating(cl)
		end,
		desc = "resize mode",
	})
end

function M.client_resize_floating(cl)
	return mt({
		group = "client.resize",
		cond = function()
			return cond_is_floating(cl)
		end,
		desc = "resize client",
	})
end

function M.client_resize_smart(dir, cl)
	return mt({
		group = "client.layout.resize",
		cond = function()
			local c = cl or client.focus
			return c and c.valid
		end,
		desc = function()
			local c = cl or client.focus
			local layout = awful.layout.get(awful.screen.focused()).name
			if layout == "floating" or c and (c.floating and not c.fullscreen) then
				return string.format("increase client size %s", dir)
			end
			return string.format("resize client smart %s", dir)
		end,
		fn = function(opts)
			local c = cl or client.focus
			client_resize_smart(c, dir, opts.awesome.resize_delta, opts.awesome.resize_factor)
		end,
	})
end

function M.client_floating_size_increase(dir, cl)
	return mt({
		group = "client.layout.resize",
		cond = function()
			return cond_is_floating(cl)
		end,
		desc = function()
			return string.format("increase client size %s", dir)
		end,
		fn = function(opts)
			local c = cl or client.focus
			local resize_delta = opts.awesome.resize_delta
			resize_delta = math.abs(resize_delta)
			client_floating_resize(c, dir, resize_delta)
		end,
	})
end

function M.client_floating_size_decrease(dir, cl)
	return mt({
		group = "client.layout.resize",
		cond = function()
			return cond_is_floating(cl)
		end,
		desc = function()
			return string.format("decrease client size %s", dir)
		end,
		fn = function(opts)
			local c = cl or client.focus
			local resize_delta = opts.awesome.resize_delta
			resize_delta = math.abs(resize_delta) * -1
			client_floating_resize(c, dir, resize_delta)
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
			local filter = M.client_create_filter(false, multi_tag, false)
			for _, c in ipairs(client.get()) do
				if filter(c) and c.minimized then
					table.insert(ret, {
						util.index_to_label(i, opts.labels),
						desc = function()
							return helper.clientname(c, i)
						end,
						fn = function()
							client_unminmize(c)
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
						client_toggle_tag(c, t)
					end,
				})
			end

			return ret
		end,
	})
end

function M.move_to_screen_menu(cl)
	local fn = function(s)
		local c = cl or client.focus
		if not c then
			return
		end
		c:move_to_screen(s)
	end

	local menu = pscreen.generate_menu(fn, false)

	return menu
		+ {
			desc = "move client to screen",
			cond = function()
				local c = cl or client.focus
				return c
			end,
		}
end

return M

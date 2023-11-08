local awful = require("awful")
local dpi = require("beautiful").xresources.apply_dpi
local grect = require("gears.geometry").rectangle
local clabel = require("modalisa.ui.label")
local util = require("modalisa.util")

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

function M.client_picker(opts, fn, filter)
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
		local label = util.index_to_label(i, opts.labels)
		clabel.show_label_parent(c, label, opts)
		-- create menu
		table.insert(menu, {
			label,
			desc = function()
				return require("modalisa.presets.awesome").util.clientname(c, i)
			end,
			fn = function()
				fn(c)
			end,
		})
	end

	-- only 1 client
	if opts.awesome.auto_select_the_only_choice then
		if #menu == 1 then
			clabel.hide_labels()
			menu[1].fn()
			return
		end
	end

	return menu
end

function M.client_toggle_fullscreen(c)
	c = c or client.focus
	if not c then
		return
	end

	if c.maximized then
		c.maximized = false
	end

	if c.maximized_horizontal then
		c.maximized_horizontal = false
	end

	if c.maximized_vertical then
		c.maximized_vertical = false
	end

	c.fullscreen = not c.fullscreen
	c:raise()
end

function M.client_toggle_maximize(c)
	c = c or client.focus
	if not c then
		return
	end

	if c.fullscreen then
		c.fullscreen = false
	end

	if c.maximized_horizontal then
		c.maximized_horizontal = false
	end

	if c.maximized_vertical then
		c.maximized_vertical = false
	end

	c.maximized = not c.maximized
	c:raise()
end

function M.client_toggle_maximize_horizontally(c)
	c = c or client.focus
	if not c then
		return
	end

	if c.fullscreen then
		c.fullscreen = false
	end

	if c.maximized then
		c.maximized = false
	end

	c.maximized_horizontal = not c.maximized_horizontal
	c:raise()
end

function M.client_toggle_maximize_vertically(c)
	c = c or client.focus
	if not c then
		return
	end

	if c.fullscreen then
		c.fullscreen = false
	end

	if c.maximized then
		c.maximized = false
	end

	c.maximized_vertical = not c.maximized_vertical
	c:raise()
end

function M.client_toggle_sticky(c)
	c = c or client.focus
	if not c then
		return
	end
	c.sticky = not c.sticky
end

function M.client_toggle_floating(c)
	c = c or client.focus
	if not c then
		return
	end
	awful.client.floating.toggle(c)
end

function M.client_toggle_ontop(c)
	c = c or client.focus
	if not c then
		return
	end
	c.ontop = not c.ontop
end

function M.client_minmize(c)
	c = c or client.focus
	if not c then
		return
	end
	c.minimized = true
end

function M.client_unminmize(c)
	c = c or client.focus
	if not c then
		return
	end
	c:activate({ raise = true, context = "key.unminimize" })
end

function M.client_kill(c)
	c = c or client.focus
	if not c then
		return
	end
	c:kill()
end

function M.client_move_to_master(c)
	c = c or client.focus
	if not c then
		return
	end
	c:swap(awful.client.getmaster())
end

function M.client_focus_bydirection(dir)
	awful.client.focus.global_bydirection(dir)
end

function M.client_navigate(dir)
	awesome.emit_signal("navigator::navigate", dir)
end

function M.client_focus_prev()
	awful.client.focus.history.previous()
	if client.focus then
		client.focus:raise()
	end
end

function M.client_master_swap(c)
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

function M.client_move_smart(c, dir, resize_delta)
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

function M.client_resize_smart(c, dir, resize_delta, resize_factor)
	c = c or client.focus
	if not c then
		return
	end

	resize_delta = resize_delta or default_resize_delta
	resize_factor = resize_factor or default_resize_factor

	local layout = awful.layout.get(awful.screen.focused()).name
	if layout == "floating" or c.floating then
		return M.client_floating_resize(c, dir, resize_delta)
	end

	M.client_resize_tiled(c, dir, resize_factor)
end

function M.client_floating_resize(c, dir, px)
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

function M.client_resize_tiled(c, dir, resize_factor)
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

function M.client_toggle_tag(c, t)
	c = c or client.focus
	if not c or not t then
		return
	end
	c:toggle_tag(t)
end

function M.client_move_to_tag(c, t)
	c = c or client.focus
	if not c then
		return
	end
	c:move_to_tag(t)
end

return M

local awful = require("awful")
local util = require("modalisa.util")
local vim = require("modalisa.lib.vim")
local mt = require("modalisa.presets.metatable")
local helper = require("modalisa.presets.helper")
local pscreen = require("modalisa.presets.screen")
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}

local function tag_toggle_index(i)
	local s = awful.screen.focused()
	if not s then
		return
	end
	local t = s.tags[i]
	if not t then
		return
	end
	awful.tag.viewtoggle(t)
end

local function tag_view_only_index(i)
	local s = awful.screen.focused()
	if not s then
		return
	end
	local t = s.tags[i]
	if not t then
		return
	end

	-- restore instead of noop
	if t.selected then
		awful.tag.history.restore()
	else
		t:view_only()
	end
end

local function tag_get_properties(t)
	t = t or awful.screen.focused().selected_tag
	if not t then
		return nil
	end

	local props = {
		name = t.name,
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
		activated = t.activated,
	}

	return props
end

local function move_tag_to_screen(s, t, delete_old_tag)
	assert(s, "screen is nil")
	t = t or awful.screen.focused().selected_tag
	if not t then
		return
	end

	local props = tag_get_properties(t)
	assert(props)

	props.screen = s

	local clients = t:clients()

	local t_new = awful.tag.add(props.name, props)
	if not t_new then
		return
	end

	for _, c in pairs(clients) do
		c:move_to_screen(s)
	end
	t_new:clients(clients)
	if delete_old_tag then
		t:delete()
	end

	t_new:view_only()
	awful.screen.focus(s)
end

function M.move_client_to_tag_index(i, cl)
	return mt({
		group = "tag.client.move",
		cond = function()
			local c = cl or client.focus
			if not c or not c.valid then
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
			local c = cl or client.focus
			if not c or not c.valid then
				return
			end
			local t = client.focus.screen.tags[i]
			if t then
				c:move_to_tag(t)
			end
		end,
	})
end

function M.move_tag_to_screen_menu(tag, delete_old_tag)
	local fn = function(s)
		local t = tag or awful.screen.focused().selected_tag
		if not t then
			return
		end
		move_tag_to_screen(s, t, delete_old_tag)
	end

	local menu = pscreen.generate_menu(fn)

	return menu
		+ {
			desc = "move tag to screen",
			cond = function()
				local t = tag or awful.screen.focused().selected_tag
				return t and screen.count() > 1
			end,
		}
end

function M.move_all_clients_to_tag_menu(tag)
	return mt({
		is_menu = true,
		group = "tag.client.move.all",
		cond = function()
			return client.focus
		end,
		desc = "move all clients to tag",
		fn = function(opts)
			local s = awful.screen.focused()
			local t = tag or s.selected_tag
			if not t then
				return
			end

			local cls = {}
			for _, c in ipairs(t:clients()) do
				table.insert(cls, c)
			end

			local ret = {}
			for i, tg in ipairs(s.tags) do
				if tg ~= t then
					local desc = helper.tagname(tg)
					table.insert(ret, {
						util.index_to_label(i, opts.labels),
						desc = desc,
						fn = function()
							for _, c in ipairs(cls) do
								c:move_to_tag(tg)
							end
						end,
					})
				end
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
						tag_toggle_index(i)
					end,
				})
			end

			return ret
		end,
	})
end

function M.toggle_property(prop, tag, prefix)
	return mt({
		group = string.format("tag.property.%s", prop),
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		desc = function(opts)
			local t = tag or awful.screen.focused().selected_tag
			local pre = prefix or ""
			if string.len(pre) > 0 then
				pre = pre .. " "
			end
			if not t then
				return string.format("%s%s toggle", pre, prop)
			end
			if t[prop] then
				return string.format("%s%s %s", pre, prop, opts.toggle_true)
			end
			return string.format("%s%s %s", pre, prop, opts.toggle_false)
		end,
		fn = function(opts)
			local t = tag or awful.screen.focused().selected_tag
			if not t then
				return
			end
			t[prop] = not t[prop]

			local value = t[prop]

			awesome.emit_signal("modalisa::echo", { [prop] = value }, opts)
		end,
	})
end

function M.tag_toggle_policy(tag)
	return mt({
		group = "tag.property.policy",
		desc = "fill policy toggle",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		result = { fill_policty = helper.tag_get_fn_master_fill_policy(tag) },
		fn = function()
			local t = tag or awful.screen.focused().selected_tag
			if not t then
				return
			end
			awful.tag.togglemfpol(t)
		end,
	})
end

function M.view_only_index(i)
	return mt({
		group = "tag.view",
		desc = function()
			return "view tag " .. (helper.tagname_by_index(i) or i)
		end,
		cond = function()
			return awful.screen.focused().tags[i]
		end,
		fn = function()
			tag_view_only_index(i)
		end,
	})
end

function M.view_only_menu()
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
						t:view_only()
					end,
				})
			end
			return ret
		end,
	})
end

function M.delete(tag)
	return mt({
		group = "tag.action",
		desc = "delete tag",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function()
			local t = tag or awful.screen.focused().selected_tag
			if not t then
				return
			end
			t:delete()
		end,
	})
end

function M.toggle_tag_index(i)
	return mt({
		group = "tag.toggle",
		desc = function()
			helper.tagname_by_index(i)
		end,
		cond = function()
			return awful.screen.focused().tags[i]
		end,
		fn = function()
			tag_toggle_index(i)
		end,
	})
end

function M.view_next()
	return mt({
		group = "tag.cycle",
		desc = function()
			return "view next tag"
		end,
		fn = function()
			awful.tag.viewnext()
		end,
	})
end

function M.view_previous()
	return mt({
		group = "tag.cycle",
		desc = function()
			return "view previous tag"
		end,
		fn = function()
			awful.tag.viewprev()
		end,
	})
end

function M.view_last()
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

function M.new_tag(name)
	return mt({
		group = "tag.new",
		desc = "new tag",
		fn = function(opts)
			local fn = function(tag_name)
				awful.tag
					.add(tag_name, {
						screen = awful.screen.focused(),
					})
					:view_only()
			end
			if not name then
				local initial = ""
				local header = "tag name:"

				awesome.emit_signal("modalisa::prompt", { fn = fn, initial = initial, header = header }, opts)
			else
				fn(name)
			end
		end,
	})
end

function M.new_tag_copy(name, tag)
	return mt({
		group = "tag.new.copy",
		desc = "new tag copy",
		opts = { echo = { vertical_layout = true, align_vertical = false } },
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function(opts)
			local t = tag or awful.screen.focused().selected_tag
			if not t then
				return
			end
			local fn = function(tag_name)
				local props = tag_get_properties(t)
				if not props then
					return
				end
				awful.tag.add(tag_name, props):view_only()
				-- don't show these values:
				props.screen = nil
				props.layouts = nil
				props.layout = props.layout.name
				awesome.emit_signal("modalisa::echo", props, opts)
			end
			if not name then
				local initial = ""
				local header = "tag name:"
				awesome.emit_signal("modalisa::prompt", { fn = fn, initial = initial, header = header }, opts)
			else
				fn(name)
			end
		end,
	})
end

function M.rename(tag)
	return mt({
		group = "tag.rename",
		desc = "rename tag",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function(opts)
			local t = tag or awful.screen.focused().selected_tag
			if not t then
				return
			end
			local fn = function(s)
				t.name = s
			end
			local initial = t.name
			local header = "rename tag:"
			awesome.emit_signal("modalisa::prompt", { fn = fn, initial = initial, header = header }, opts)
		end,
	})
end

function M.set_gap(tag)
	return mt({
		group = "tag.gap",
		desc = "set tag gap",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function(opts)
			local t = tag or awful.screen.focused().selected_tag
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
			local header = "tag gap:"

			awesome.emit_signal("modalisa::prompt", { fn = fn, initial = initial, header = header }, opts)
		end,
	})
end

function M.master_width_increase(tag)
	return mt({
		group = "layout.master.width",
		desc = "master width increase",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function(opts)
			local f = opts.awesome.resize_factor
			awful.tag.incmwfact(f, tag)
		end,
		result = { master_width = helper.tag_get_fn_master_width_factor(tag) },
	})
end

function M.master_width_decrease(tag)
	return mt({
		group = "layout.master.width",
		desc = "master width decrease",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function(opts)
			local f = opts.awesome.resize_factor
			awful.tag.incmwfact(f * -1, tag)
		end,
		result = { master_width = helper.tag_get_fn_master_width_factor(tag) },
	})
end

function M.master_count_decrease(tag)
	return mt({
		group = "layout.master.count",
		desc = "master count decrease",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t and t.master_count > 0
		end,
		fn = function()
			local t = tag or awful.screen.focused().selected_tag
			awful.tag.incnmaster(-1, t, true)
		end,
		result = { master_count = helper.tag_get_fn_master_count(tag) },
	})
end

function M.master_count_increase(tag)
	return mt({
		group = "layout.master.count",
		desc = "master count increase",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function()
			local t = tag or awful.screen.focused().selected_tag
			awful.tag.incnmaster(1, t, true)
		end,
		result = { master_count = helper.tag_get_fn_master_count(tag) },
	})
end

function M.column_count_decrease(tag)
	return mt({
		group = "layout.column.count",
		desc = "column count decrease",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t and t.column_count > 0
		end,
		fn = function()
			local t = tag or awful.screen.focused().selected_tag
			awful.tag.incncol(-1, t, true)
		end,
		result = { column_count = helper.tag_get_fn_column_count(tag) },
	})
end

function M.column_count_increase(tag)
	return mt({
		group = "layout.column.count",
		desc = "column count increase",
		cond = function()
			local t = tag or awful.screen.focused().selected_tag
			return t
		end,
		fn = function()
			local t = tag or awful.screen.focused().selected_tag
			awful.tag.incncol(1, t, true)
		end,
		result = { column_count = helper.tag_get_fn_column_count(tag) },
	})
end

function M.layout_next()
	return mt({
		group = "layout.inc",
		desc = "next layout",
		fn = function()
			awful.layout.inc(1)
		end,
		result = { layout = helper.tag_get_fn_current_layout_name() },
	})
end

function M.layout_prev()
	return mt({
		group = "layout.inc",
		desc = "prev layout",
		fn = function()
			awful.layout.inc(-1)
		end,
		result = { layout = helper.tag_get_fn_current_layout_name() },
	})
end

function M.layout_select_menu(tag)
	return mt({
		group = "layout.menu.select",
		desc = "select a layout",
		is_menu = true,
		fn = function(opts)
			local s = awful.screen.focused()
			local t = tag or s.selected_tag

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
						awful.layout.set(l, t)
					end,
					result = { layout = l.name },
				})
			end

			return ret
		end,
	})
end

return M

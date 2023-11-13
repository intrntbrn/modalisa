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

local function tag_move_to_screen(s, t, keep_old_tag)
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
	if not keep_old_tag then
		t:delete()
	end

	t_new:view_only()
	awful.screen.focus(s)
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
				local t = client.focus.screen.tags[i]
				if t then
					c:move_to_tag(t)
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
						c:move_to_tag(t)
					end,
				})
			end

			return ret
		end,
	})
end

function M.move_tag_to_screen_menu(tag, keep_old_tag)
	local fn = function(s)
		local t = tag or awful.screen.focused().selected_tag
		if not t then
			return
		end
		tag_move_to_screen(s, t, keep_old_tag)
	end

	local menu = pscreen.screen_menu(fn, false)

	return menu
		+ {
			desc = "move tag to screen",
			cond = function()
				local t = tag or awful.screen.focused().selected_tag
				return t and helper.screen_count() > 1
			end,
		}
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
							c:move_to_tag(t)
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
						tag_toggle_index(i)
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
			awful.tag.togglemfpol(t)
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
			tag_view_only_index(i)
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
						t:view_only()
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
		desc = "delete tag",
		cond = function()
			return awful.screen.focused().selected_tag
		end,
		fn = function()
			local t = awful.screen.focused().selected_tag
			if not t then
				return
			end
			t:delete()
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
			tag_toggle_index(i)
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
			awful.tag.viewnext()
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
			awful.tag.viewprev()
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
				local props = tag_get_properties(t)
				if not props then
					return
				end
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

return M

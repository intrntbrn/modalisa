local awful = require("awful")

local M = {}

function M.tagname_by_index(i)
	local s = awful.screen.focused()
	local t = s.tags[i]
	if not t then
		return string.format("%s", i)
	end

	return M.tagname(t)
end

function M.tagname(t)
	local i = t.index
	local txt = string.format("%d", i)
	local name = t.name
	if name then
		txt = string.format("%s: %s", txt, name)
	end

	return txt
end

function M.clientname(c, i)
	local txt = string.format("%d", i)
	if c.class then
		txt = c.class
	end
	if c.name then
		txt = string.format("[%s] %s", txt, c.name)
	end
	return txt
end

function M.tag_get_fn_current_layout_name(t)
	return function()
		t = t or awful.screen.focused().selected_tag
		return t.layout.name
	end
end

function M.tag_get_fn_master_width_factor(t)
	return function()
		t = t or awful.screen.focused().selected_tag
		return t.master_width_factor
	end
end

function M.tag_get_fn_column_count(t)
	return function()
		t = t or awful.screen.focused().selected_tag
		return t.column_count
	end
end

function M.tag_get_fn_master_count(t)
	return function()
		t = t or awful.screen.focused().selected_tag
		return t.master_count
	end
end

function M.tag_get_fn_master_fill_policy(t)
	return function()
		t = t or awful.screen.focused().selected_tag
		return t.master_fill_policy
	end
end

function M.tag_get_fn_gap(t)
	return function()
		t = t or awful.screen.focused().selected_tag
		return t.gap
	end
end

return M

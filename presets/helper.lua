local awful = require("awful")

local helper = {}

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

return helper

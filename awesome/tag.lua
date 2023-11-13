local awful = require("awful")
local vim = require("modalisa.lib.vim")

local M = {}

function M.tag_toggle_index(i)
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

function M.tag_toggle_fill_policy(t)
	if not t then
		return
	end
	awful.tag.togglemfpol(t)
end

function M.tag_view_only_index(i)
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

function M.tag_view_only(t)
	if not t then
		return
	end
	t:view_only()
end

function M.tag_delete(t)
	t = t
	if not t then
		return
	end
	t:delete()
end

function M.tag_next()
	awful.tag.viewnext()
end

function M.tag_prev()
	awful.tag.viewprev()
end

function M.tag_last()
	awful.tag.history.restore()
end

function M.tag_get_properties(t)
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

function M.tag_move_to_screen(s, t)
	assert(s)
	t = t or awful.screen.focused().selected_tag
	if not t then
		return
	end

	local props = M.tag_get_properties(t)
	assert(props)

	props.screen = s

	awful.tag(props.name, props)
end

return M

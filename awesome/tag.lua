local awful = require("awful")

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

return M

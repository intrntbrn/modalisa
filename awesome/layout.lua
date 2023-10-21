local awful = require("awful")
local dpi = require("beautiful").xresources.apply_dpi

local M = {}

local default_resize_factor = 0.05

function M.layout_master_width_decrease(factor)
	local f = factor or default_resize_factor
	f = math.abs(f) * -1
	awful.tag.incmwfact(f)
end

function M.layout_master_width_increase(factor)
	local f = factor or default_resize_factor
	f = math.abs(f)
	awful.tag.incmwfact(f)
end

function M.layout_master_count_increase()
	awful.tag.incnmaster(1, nil, true)
end

function M.layout_master_count_decrease()
	awful.tag.incnmaster(-1, nil, true)
end

function M.layout_column_count_decrease()
	awful.tag.incncol(-1, nil, true)
end

function M.layout_column_count_increase()
	awful.tag.incncol(1, nil, true)
end

function M.layout_next()
	awful.layout.inc(1)
end

function M.layout_prev()
	awful.layout.inc(-1)
end

function M.layout_set(t, l)
	awful.layout.set(l, t)
end

return M

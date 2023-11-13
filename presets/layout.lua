local awful = require("awful")
local util = require("modalisa.util")
local mt = require("modalisa.presets.metatable")
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect
local helper = require("modalisa.presets.helper")

local M = {}

local default_resize_factor = 0.05

local function layout_master_width_decrease(factor)
	local f = factor or default_resize_factor
	f = math.abs(f) * -1
	awful.tag.incmwfact(f)
end

local function layout_master_width_increase(factor)
	local f = factor or default_resize_factor
	f = math.abs(f)
	awful.tag.incmwfact(f)
end

local function layout_master_count_increase()
	awful.tag.incnmaster(1, nil, true)
end

local function layout_master_count_decrease()
	awful.tag.incnmaster(-1, nil, true)
end

local function layout_column_count_decrease()
	awful.tag.incncol(-1, nil, true)
end

local function layout_column_count_increase()
	awful.tag.incncol(1, nil, true)
end

local function layout_next()
	awful.layout.inc(1)
end

local function layout_prev()
	awful.layout.inc(-1)
end

local function layout_set(t, l)
	awful.layout.set(l, t)
end

function M.layout_master_width_increase(factor)
	return mt({
		group = "layout.master.width",
		desc = "master width increase",
		fn = function()
			layout_master_width_increase(factor)
		end,
		result = { master_width = helper.get_current_tag_master_width_factor },
	})
end

function M.layout_master_width_decrease(factor)
	return mt({
		group = "layout.master.width",
		desc = "master width decrease",
		fn = function()
			layout_master_width_decrease(factor)
		end,
		result = { master_width = helper.get_current_tag_master_width_factor },
	})
end

function M.layout_master_count_decrease()
	return mt({
		group = "layout.master.count",
		desc = "master count decrease",
		cond = function()
			return awful.screen.focused().selected_tag.master_count > 0
		end,
		fn = function()
			layout_master_count_decrease()
		end,
		result = { master_count = helper.get_current_tag_master_count },
	})
end

function M.layout_master_count_increase()
	return mt({
		group = "layout.master.count",
		desc = "master count increase",
		fn = function()
			layout_master_count_increase()
		end,
		result = { master_count = helper.get_current_tag_master_count },
	})
end

function M.layout_column_count_decrease()
	return mt({
		group = "layout.column.count",
		desc = "column count decrease",
		cond = function()
			return awful.screen.focused().selected_tag.column_count > 0
		end,
		fn = function()
			layout_column_count_decrease()
		end,
		result = { column_count = helper.get_current_tag_column_count },
	})
end

function M.layout_column_count_increase()
	return mt({
		group = "layout.column.count",
		desc = "column count increase",
		fn = function()
			layout_column_count_increase()
			return "column_count", helper.get_current_tag_column_count()
		end,
		result = { column_count = helper.get_current_tag_column_count },
	})
end

function M.layout_next()
	return mt({
		group = "layout.inc",
		desc = "next layout",
		fn = function()
			layout_next()
		end,
		result = { layout = helper.get_current_layout_name },
	})
end

function M.layout_prev()
	return mt({
		group = "layout.inc",
		desc = "prev layout",
		fn = function()
			layout_prev()
		end,
		result = { layout = helper.get_current_layout_name },
	})
end

function M.layout_select_menu()
	return mt({
		group = "layout.menu.select",
		desc = "select a layout",
		is_menu = true,
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
						layout_set(t, l)
					end,
					result = { layout = l.name },
				})
			end

			return ret
		end,
	})
end

return M

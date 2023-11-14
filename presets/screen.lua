local awful = require("awful")
local mt = require("modalisa.presets.metatable")
local vim = require("modalisa.lib.vim")
local util = require("modalisa.util")

local M = {}

function M.focus_direction(dir)
	return mt({
		group = "screen.focus.dir",
		desc = string.format("focus %s screen", dir),
		cond = function()
			return screen.count() > 1
		end,
		fn = function()
			if screen.count() == 2 then
				awful.screen.focus_relative(1)
			else
				awful.screen.focus_bydirection(dir)
			end
		end,
	})
end

function M.focus_picker()
	local fn = function(s)
		awful.screen.focus(s)
	end

	local menu = M.generate_menu(fn)

	return menu + {
		desc = "select screen picker",
	}
end

function M.generate_menu(fn, args)
	args = args or {}
	local include_focused = args.include_focused

	return mt({
		desc = "screen menu",
		group = "screen",
		is_menu = true,
		cond = function()
			return screen.count() > 1
		end,
		on_leave = function()
			awesome.emit_signal("modalisa::label::hide")
		end,
		fn = function(opts)
			local focused = awful.screen.focused()
			local entries = {}
			for s in screen do
				if s ~= focused or include_focused then
					awesome.emit_signal("modalisa::label::show", s, s.index, opts)
					local entry = {
						desc = string.format("screen %d", s.index),
						fn = function()
							return fn(s)
						end,
					}
					local index = util.index_to_label(s.index, opts.labels)
					entries[index] = entry
				end
			end

			if opts.awesome.auto_select_the_only_choice then
				if vim.tbl_count(entries) == 1 then
					awesome.emit_signal("modalisa::label::hide")
					return entries[1].fn()
				end
			end

			return entries
		end,
	})
end

return M

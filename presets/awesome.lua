local awful = require("awful")
local util = require("modalisa.util")
local mt = require("modalisa.presets.metatable")
local vim = require("modalisa.lib.vim")

local M = {}

function M.awesome_help()
	return mt({
		group = "awesome.menu",
		desc = "show help",
		cond = function()
			return pcall(require, "awful.hotkeys_popup")
		end,
		fn = function()
			local hotkeys_popup = require("awful.hotkeys_popup")
			if hotkeys_popup then
				hotkeys_popup.show_help()
			end
		end,
	})
end

function M.awesome_menubar()
	return mt({
		group = "awesome.menu",
		desc = "show menubar",
		cond = function()
			return pcall(require, "menubar")
		end,
		fn = function()
			require("menubar").show()
		end,
	})
end

function M.awesome_quit()
	return mt({
		group = "awesome.stop",
		desc = "quit awesome",
		fn = function()
			local fn = function()
				awesome.quit()
			end
			return util.confirmation_menu(fn, "yes, quit awesome", "no, cancel")
		end,
	})
end

function M.awesome_restart()
	return mt({
		group = "awesome.stop",
		desc = "restart awesome",
		fn = function()
			awesome.restart()
		end,
	})
end

function M.awesome_execute()
	return mt({
		group = "awesome.execute",
		desc = "lua code prompt",
		cond = function()
			return awful.screen.focused().mypromptbox
		end,
		fn = function()
			if awful.screen.focused().mypromptbox then
				awful.prompt.run({
					prompt = "Run Lua code: ",
					textbox = awful.screen.focused().mypromptbox.widget,
					exe_callback = awful.util.eval,
					history_path = awful.util.get_cache_dir() .. "/history_eval",
				})
			end
		end,
	})
end

function M.awesome_run_prompt()
	return mt({
		group = "awesome.execute",
		desc = "run prompt",
		cond = function()
			return awful.screen.focused().mypromptbox
		end,
		fn = function()
			if awful.screen.focused().mypromptbox then
				awful.screen.focused().mypromptbox:run()
			end
		end,
	})
end

function M.awesome_toggle_wibox()
	return mt({
		group = "awesome.wibox",
		desc = function()
			local s = awful.screen.focused()
			if not s.mywibox then
				return "wibox toggle"
			end
			if s.mywibox.visible then
				return "wibox hide"
			end
			return "wibox show"
		end,
		cond = function()
			return awful.screen.focused().mywibox
		end,
		fn = function()
			local s = awful.screen.focused()
			if not s.mywibox then
				return
			end

			s.mywibox.visible = not s.mywibox.visible
		end,
	})
end

function M.awesome_padding_menu()
	return mt({
		group = "awesome.screen.padding",
		is_menu = true,
		desc = "screen padding",
		fn = function()
			local s = awful.screen.focused()
			local fn = function(x)
				return {
					desc = string.format("%s", x),
					group = "screen.padding",
					fn = function(opts)
						s.padding = s.padding or {}
						local initial = string.format("%d", s.padding[x] or 0)
						local header = string.format("padding %s", x)
						local run = function(str)
							local number = tonumber(str)
							if not number then
								return
							end
							local padding = vim.deepcopy(s.padding) or {}
							padding[x] = number
							s.padding = padding
						end

						awesome.emit_signal("modalisa::prompt", { fn = run, initial = initial, header = header }, opts)
					end,
				}
			end

			return {
				h = fn("left"),
				j = fn("bottom"),
				k = fn("top"),
				l = fn("right"),
			}
		end,
	})
end

function M.awesome_wallpaper_menu(max_depth)
	return mt({
		group = "awesome.wallpaper",
		desc = "wallpaper",
		is_menu = true,
		fn = function(opts)
			local wp = require("gears.wallpaper")
			local dir = opts.awesome.wallpaper_dir
			local fp = require("modalisa.presets.file").file_picker
			local filter = require("modalisa.presets.file").filter_image
			local entries = {
				m = fp(dir, function(w)
					wp.maximized(w)
				end, max_depth, filter) + { desc = "maximized" },
				t = fp(dir, function(w)
					wp.tiled(w)
				end, max_depth, filter) + { desc = "tiled" },
				f = fp(dir, function(w)
					wp.fit(w)
				end, max_depth, filter) + { desc = "fit" },
				c = fp(dir, function(w)
					wp.centered(w)
				end, max_depth, filter) + { desc = "centered" },
			}
			return entries
		end,
	})
end

return M

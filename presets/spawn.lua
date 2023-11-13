local awful = require("awful")
local mt = require("modalisa.presets.metatable")

local M = {}

function M.spawn_terminal()
	return mt({
		group = "spawn",
		desc = "terminal",
		fn = function(opts)
			awful.spawn.with_shell(opts.awesome.terminal)
		end,
	})
end

function M.spawn_browser()
	return mt({
		group = "spawn",
		desc = "browser",
		fn = function(opts)
			awful.spawn.with_shell(opts.awesome.browser)
		end,
	})
end

function M.spawn(cmd)
	return mt({
		group = string.format("spawn.%s", cmd),
		desc = cmd,
		fn = function(_)
			awful.spawn(cmd)
		end,
	})
end

function M.spawn_with_shell(cmd)
	return mt({
		group = string.format("spawn.%s", cmd),
		desc = cmd,
		fn = function(_)
			awful.spawn.with_shell(cmd)
		end,
	})
end

function M.spawn_appmenu()
	return mt({
		group = "spawn",
		desc = "open app menu",
		fn = function(opts)
			awful.spawn.with_shell(opts.awesome.app_menu)
		end,
	})
end

return M

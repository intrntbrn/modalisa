local mt = require("modalisa.presets.metatable")
local awful = require("awful")
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}

function M.power_shutdown()
	return mt({
		group = "power.shutdown",
		desc = "shutdown",
		function()
			awful.spawn("shutdown -h 0")
		end,
		result = { shutdown = "" },
	})
end

function M.power_shutdown_cancel()
	return mt({
		group = "power.shutdown",
		desc = "cancel shutdown timer",
		function()
			awful.spawn("shutdown -c")
		end,
		result = { shutdown = "cancled" },
	})
end

function M.power_shutdown_timer()
	return mt({
		group = "power.shutdown",
		desc = "shutdown timer",
		function(opts)
			local header = "shutdown in minutes:"
			local initial = 60
			local fn = function(x)
				local min = tonumber(x)
				if not min then
					return
				end
				local cmd = string.format("shutdown -P +%d", min)
				awful.spawn(cmd)
				require("modalisa.ui.echo").show_simple("shutdown", string.format("in %d minutes", min))
			end
			awesome.emit_signal("modalisa::prompt", fn, initial, header, opts)
		end,
	})
end

function M.power_suspend()
	return mt({
		group = "power.suspend",
		desc = "suspend",
		function()
			awful.spawn("suspend")
		end,
		result = { suspend = "" },
	})
end

function M.power_reboot()
	return mt({
		group = "power.reboot",
		desc = "reboot",
		function()
			awful.spawn("reboot")
		end,
		result = { reboot = "" },
	})
end

return M

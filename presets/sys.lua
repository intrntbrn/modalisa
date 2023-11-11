local mt = require("modalisa.presets.metatable")
local awful = require("awful")
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}

local function audio_playerctl_cmd(subcmd)
	return string.format("playerctl %s", subcmd)
end

function M.audio_next()
	return mt({
		group = "audio.inc",
		desc = "audio next",
		function()
			local cmd = audio_playerctl_cmd("next")
			awful.spawn(cmd)
		end,
	})
end

function M.audio_prev()
	return mt({
		group = "audio.inc",
		desc = "audio prev",
		function()
			local cmd = audio_playerctl_cmd("previous")
			awful.spawn(cmd)
		end,
	})
end

function M.audio_play_pause()
	return mt({
		group = "audio",
		desc = "audio play-pause",
		function()
			local cmd = audio_playerctl_cmd("play-pause")
			awful.spawn(cmd)
		end,
	})
end

function M.audio_stop()
	return mt({
		group = "audio",
		desc = "audio stop",
		function()
			local cmd = audio_playerctl_cmd("stop")
			awful.spawn(cmd)
		end,
	})
end

local function brightness_show(opts)
	local cmd = [[bash -c 'xbacklight -get']]
	awful.spawn.easy_async(cmd, function(stdout)
		stdout = string.gsub(stdout, "\n", "")
		local value = tonumber(stdout)
		require("modalisa.ui.echo").show_simple("brightness", value, opts)
	end)
end

local function brightness_cmd(inc)
	local param = "-inc"
	if inc < 0 then
		param = "-dec"
		inc = math.abs(inc)
	end
	local cmd = string.format("xbacklight %s %d", param, inc)
	return cmd
end

function M.brightness_inc(inc)
	return mt({
		group = "brightness",
		desc = "brightness",
		opts = {
			echo = {
				show_percentage_as_progressbar = true,
			},
		},
		function(opts)
			local cmd = brightness_cmd(inc)
			awful.spawn.easy_async_with_shell(cmd, function()
				brightness_show(opts)
			end)
		end,
	})
end

local function volume_show(opts)
	local amixer_get_master = [[bash -c 'amixer get Master']]
	awful.spawn.easy_async(amixer_get_master, function(stdout)
		local vol, status = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
		if status == "off" then
			require("modalisa.ui.echo").show_simple("volume", "muted", opts)
		else
			local value = tonumber(vol) / 100
			require("modalisa.ui.echo").show_simple("volume", value, opts)
		end
	end)
end

local function volume_toggle_cmd()
	return "amixer -D pulse set Master 1+ toggle"
end

local function volume_cmd(inc)
	local sign = "+"
	if inc < 0 then
		sign = "-"
	end
	local cmd = string.format("amixer set Master %s%%%s > /dev/null 2>&1", inc, sign)
	return cmd
end

function M.volume_inc(inc)
	return mt({
		group = "audio.volume",
		desc = "volume",
		opts = {
			echo = {
				show_percentage_as_progressbar = true,
			},
		},
		function(opts)
			local cmd = volume_cmd(inc)
			awful.spawn.easy_async_with_shell(cmd, function()
				volume_show(opts)
			end)
		end,
	})
end

function M.volume_mute_toggle()
	return mt({
		group = "audio.volume",
		desc = "mute toggle",
		opts = {
			echo = {
				show_percentage_as_progressbar = true,
			},
		},
		function(opts)
			local cmd = volume_toggle_cmd()
			awful.spawn.easy_async_with_shell(cmd, function()
				volume_show(opts)
			end)
		end,
	})
end

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

			require("modalisa.ui.prompt").run(fn, initial, header, opts)
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

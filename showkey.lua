local vim = require("modalisa.lib.vim")
local dump = vim.inspect
local akeygrabber = require("awful.keygrabber")

local M = {}

local grabber

function M.start(args)
	local stop_key = args.stop_key or "Escape"
	local mod_map = args.mod_map or {
		Shift = "S",
		Mod1 = "A",
		Mod4 = "M",
		Control = "C",
	}
	local opts = args.opts or {}

	-- force visibilty and no timeout
	opts.echo = opts.echo or {}
	opts.echo.enabled = true
	opts.echo.timeout = 0

	local ignore_mods = args.ignore_mods or { "Lock2", "Mod2" }
	grabber = akeygrabber({
		start_callback = function()
			awesome.emit_signal("modalisa::echo", { showkey = string.format("press %s to exit", stop_key) }, opts)
		end,
		stop_callback = function()
			awesome.emit_signal("modalisa::echo::hide")
		end,
		stop_key = stop_key,
		keypressed_callback = function(_, modifiers, key)
			local filtered_modifiers = {}
			for _, m in ipairs(modifiers) do
				local ignore = vim.tbl_contains(ignore_mods, m)
				if not ignore then
					table.insert(filtered_modifiers, m)
				end
			end
			modifiers = filtered_modifiers
			print("mods: ", dump(modifiers), "key: ", key)

			local k = ""
			for _, m in pairs(modifiers) do
				k = string.format("%s%s-", k, mod_map[m])
			end
			k = string.format("%s%s", k, key)
			if string.len(k) > 1 then
				k = string.format("<%s>", k)
			end

			awesome.emit_signal("modalisa::echo", { showkey = k }, opts)
		end,
	}):start()
end

function M.stop()
	if grabber then
		grabber:stop()
	end
end

return M

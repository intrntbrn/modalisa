local util = require("modalisa.util")
local vim = require("modalisa.lib.vim")
local dump = vim.inspect
local mt = require("modalisa.presets.metatable")

local config = require("modalisa.config")

local M = {}

M.cfg = {
	mode = { "modal", "hold", "hybrid", "forever" },
	smart_modifiers = true,
	stop_on_unknown_key = true,
	timeout = 0,
	-- back_keys = "text",
	-- stop_keys = "text",
	hints = {
		enabled = true,
		delay = 0,
	},

	-- awesome
	labels = "text",
	resize_delta = 0,
}

local function find_key(key, tbl, labels)
	local first_char = string.sub(key, 1, 1)
	if not tbl[first_char] then
		return first_char
	end

	-- local second_char = string.sub(key, 2, 2)
	-- if not tbl[second_char] then
	-- 	return second_char
	-- end

	for i = 1, string.len(labels) do
		local c = string.sub(labels, i, i)
		if not tbl[c] then
			return c
		end
	end

	error("unable to find key")
end

local function generate_entry(param, value, tbl, root_config, sub_config, labels)
	local param_type = type(value)
	local index = find_key(param, tbl, labels)

	if param_type == "table" then
		if vim.tbl_islist(value) then
			local element = {
				desc = string.format("%s", param),
				fn = function(_)
					local param_options = {}
					for _, v in ipairs(value) do
						local index = find_key(v, param_options, labels)
						param_options[index] = {
							desc = string.format("%s", v),
							fn = function(_, t)
								sub_config[param] = v
								config.set_config(root_config)
								t:add_result(param, v)
							end,
						}
					end
					return param_options
				end,
			}
			tbl[index] = element
			return
		end

		-- deep table
		local deep_tbl = {}
		local subconfig = root_config[param]
		for k, v in pairs(value) do
			generate_entry(k, v, deep_tbl, root_config, subconfig, labels)
		end
		tbl[index] = {
			desc = string.format("%s", param),
			fn = function()
				return deep_tbl
			end,
		}
		return
	end

	if param_type == "boolean" then
		local element = {
			desc = string.format("%s", param),
			fn = function(_, tree)
				local current_value = sub_config[param]
				assert(type(current_value) == param_type, "config parameter is not a boolean: ", param)
				local new_value = not current_value
				sub_config[param] = new_value
				config.set_config(root_config)
				tree:add_result(param, new_value)
			end,
		}
		tbl[index] = element
		return
	end

	if param_type == "number" then
		local element = {
			desc = string.format("%s", param),
			fn = function(opts)
				local current_value = sub_config[param]
				assert(type(current_value) == param_type, "config parameter is not a number: ", param)
				local header = param
				local initial = current_value
				local fn = function(x)
					if not x then
						return
					end
					local number = tonumber(x)
					if not number then
						return
					end
					sub_config[param] = number
					print("cfg_scope: ", dump(sub_config))
					config.set_config(root_config)
				end
				require("modalisa.ui.prompt").run(fn, initial, header, opts)
			end,
		}
		tbl[index] = element
		return
	end

	if param_type == "string" then
		local element = {
			desc = string.format("%s", param),
			fn = function(opts)
				local current_value = sub_config[param]
				assert(type(current_value) == param_type, "config parameter is not a string: ", param)
				local header = param
				local initial = current_value
				local fn = function(x)
					if not x then
						return
					end
					sub_config[param] = x
					config.set_config(root_config)
				end
				require("modalisa.ui.prompt").run(fn, initial, header, opts)
			end,
		}
		tbl[index] = element
		return
	end
end

function M.generate()
	return mt({
		desc = "modalisa configuration",
		group = "modalisa",
		fn = function(opts)
			local tbl = {}
			local labels = opts.labels or util.labels_qwerty

			for k, v in pairs(M.cfg) do
				generate_entry(k, v, tbl, opts, opts, labels)
			end

			return tbl
		end,
	})
end

return M

local util = require("modalisa.util")
local vim = require("modalisa.lib.vim")
local config = require("modalisa.config")
local mt = require("modalisa.presets.metatable")
---@diagnostic disable-next-line: unused-local
local dump = vim.inspect

local M = {}

local function make_config(cfg)
	cfg = vim.deepcopy(cfg)

	local echo = cfg.echo
	local hints = cfg.hints
	local label = cfg.label
	local prompt = cfg.prompt

	-- do not show these params:
	cfg.root_keys = nil
	cfg.back_keys = nil
	cfg.stop_keys = nil
	cfg.include_default_keys = nil
	cfg.ignore_shift_state_for_special_characters = nil
	hints.key_aliases = nil
	hints.group_highlights = nil

	-- show optional parameters that are nil
	echo.color_border = "nil"
	echo.highlight.key.bg = "nil"
	echo.highlight.key.fg = "nil"
	echo.highlight.key.italic = false
	echo.highlight.key.bold = false
	echo.highlight.key.underline = false
	echo.highlight.key.strikethrough = false
	echo.highlight.value.bg = "nil"
	echo.highlight.value.fg = "nil"
	echo.highlight.value.italic = false
	echo.highlight.value.bold = false
	echo.highlight.value.underline = false
	echo.highlight.value.strikethrough = false

	echo.progressbar.color = "nil"
	echo.progressbar.background_color = "nil"
	echo.progressbar.border_color = "nil"
	echo.progressbar.bar_border_color = "nil"

	hints.color_border = "nil"
	hints.color_disabled_fg = "nil"
	hints.color_header_fg = "nil"
	hints.highlight.bg = "nil"
	hints.highlight.key.fg = "nil"
	hints.highlight.key.italic = false
	hints.highlight.key.bold = false
	hints.highlight.key.underline = false
	hints.highlight.key.strikethrough = false
	hints.highlight.desc.fg = "nil"
	hints.highlight.desc.italic = false
	hints.highlight.desc.bold = false
	hints.highlight.desc.underline = false
	hints.highlight.desc.strikethrough = false
	hints.highlight.separator.fg = "nil"
	hints.highlight.separator.italic = false
	hints.highlight.separator.bold = false
	hints.highlight.separator.underline = false
	hints.highlight.separator.strikethrough = false

	label.highlight.fg = "nil"
	label.highlight.bg = "nil"
	label.highlight.underline = false
	label.highlight.strikethrough = false
	label.highlight.italic = false
	label.color_border = "nil"

	prompt.color_border = "nil"
	prompt.color_bg = "nil"
	prompt.color_fg = "nil"
	prompt.color_cursor_fg = "nil"
	prompt.color_cursor_bg = "nil"
	prompt.header_highlight.fg = "nil"
	prompt.header_highlight.bg = "nil"

	if prompt.header_highlight.italic == nil then
		prompt.header_highlight.italic = false
	end

	if prompt.header_highlight.bold == nil then
		prompt.header_highlight.bold = false
	end

	prompt.header_highlight.bold = true
	prompt.header_highlight.strikethrough = false
	prompt.header_highlight.underline = false

	local param_opts = config.get_options()
	cfg = vim.tbl_deep_extend("force", cfg, param_opts)

	return cfg
end

local function generate_option_list(param, value, root_config, sub_config, labels)
	return {
		desc = string.format("%s", param),
		is_menu = true,
		fn = function(_)
			local param_options = {}
			for _, v in vim.spairs(value) do
				local index = util.find_index(v, param_options, labels)
				if not index then
					break
				end
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
end

local function generate_sub_menu(param, value, root_config, sub_config, labels)
	local entries = {}
	local subconfig = sub_config[param]
	for k, v in vim.spairs(value) do
		local index = util.find_index(k, entries, labels)
		if not index then
			break
		end
		local entry = M.generate_entry(k, v, root_config, subconfig, labels)
		entries[index] = entry
	end
	return {
		desc = string.format("%s", param),
		is_menu = true,
		fn = function()
			return entries
		end,
	}
end

local function generate_boolean_toggle(param, root_config, sub_config)
	return {
		desc = function(opts)
			if sub_config[param] then
				return param .. " " .. opts.toggle_true
			end
			return param .. " " .. opts.toggle_false
		end,

		fn = function(_, tree)
			local current_value = sub_config[param]
			if current_value then
				assert(type(current_value) == "boolean", "config parameter is not a boolean: ", param)
			end
			local new_value = not current_value
			sub_config[param] = new_value
			config.set_config(root_config)
			tree:add_result(param, new_value)
		end,
	}
end

local function generate_number(param, root_config, sub_config)
	return {
		desc = string.format("%s", param),
		fn = function(opts)
			local current_value = sub_config[param]
			assert(type(current_value) == "number", "config parameter is not a number: ", param)
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
				config.set_config(root_config)
			end
			awesome.emit_signal("modalisa::prompt", { fn = fn, initial = initial, header = header }, opts)
		end,
	}
end

local function generate_string(param, root_config, sub_config)
	return {
		desc = string.format("%s", param),
		fn = function(opts)
			local current_value = sub_config[param] or ""
			assert(type(current_value) == "string", "config parameter is not a string: ", param)
			local header = param
			local initial = current_value
			local fn = function(x)
				if not x then
					return
				end
				sub_config[param] = x
				config.set_config(root_config)
			end

			awesome.emit_signal("modalisa::prompt", { fn = fn, initial = initial, header = header }, opts)
		end,
	}
end

function M.generate_entry(param, template, root_config, sub_config, labels)
	local param_type = type(template)

	if param_type == "table" then
		if vim.tbl_islist(template) then
			return generate_option_list(param, template, root_config, sub_config, labels)
		end

		return generate_sub_menu(param, template, root_config, sub_config, labels)
	end

	if param_type == "boolean" then
		return generate_boolean_toggle(param, root_config, sub_config)
	end

	if param_type == "number" then
		return generate_number(param, root_config, sub_config)
	end

	if param_type == "string" then
		return generate_string(param, root_config, sub_config)
	end
end

function M.generate()
	return mt({
		desc = "modalisa configuration",
		group = "modalisa",
		is_menu = true,
		fn = function(_)
			local root_config = config.get_config()
			local entries = {}
			local labels = util.labels_qwerty

			local cfg = make_config(root_config)

			for param, template in vim.spairs(cfg) do
				local index = util.find_index(param, entries, labels)
				if not index then
					break
				end
				local entry = M.generate_entry(param, template, root_config, root_config, labels)
				entries[index] = entry
			end

			return entries
		end,
	})
end

return M

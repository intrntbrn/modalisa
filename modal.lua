local M = {}

-- hidden property
-- force stay open keybind
-- add keybind support for each tree node
-- unique stuff
-- we can also get rid off unique if move the keys init into another function
-- keyname tester
-- timestamp
-- move wm specific configs away from config?

local awful = require("awful")
local tree = require("motion.tree")
local vim = require("motion.vim")
local util = require("motion.util")
local dump = require("motion.vim").inspect
local akeygrabber = require("motion.keygrabber")

local motion_tree

local mod_conversion = nil
local mod_map

local function generate_mod_conversion_maps()
	if mod_conversion then
		return nil
	end

	local mods = awesome._modifiers
	assert(mods)

	mod_conversion = {}

	for mod, keysyms in pairs(mods) do
		for _, keysym in ipairs(keysyms) do
			assert(keysym.keysym)
			mod_conversion[mod] = mod_conversion[mod] or keysym.keysym
			mod_conversion[keysym.keysym] = mod
		end
	end

	-- all supported mods
	local map = {
		["S"] = mod_conversion["Shift_L"], -- Shift
		["A"] = mod_conversion["Alt_L"], -- Mod1
		["C"] = mod_conversion["Control_L"], -- Control
		["M"] = mod_conversion["Super_L"], -- Mod4
	}

	for k, v in pairs(map) do
		map[v] = k
	end

	mod_map = map

	return nil
end

-- @param t table A motion (sub)tree
local function on_start(t)
	awesome.emit_signal("motion::start", t)
end

-- @param t table A motion (sub)tree
local function on_stop(t)
	awesome.emit_signal("motion::stop", t)
end

local function parse_key(k)
	-- upper alpha (e.g. "S")
	if string.match(k, "^%u$") then
		return {
			{ key = k, mods = { "Shift" }, name = k },
		}
	end

	-- alphanumeric char (e.g. "s", "4")
	if string.match(k, "^%w$") then
		return {
			{ key = k, mods = {}, name = k },
		}
	end

	-- <keysym> (e.g. <BackSpace> or <F11>)
	local _, _, keysym = string.find(k, "^<(%w+)>$")
	if keysym then
		return {
			{ key = keysym, mods = {}, name = k },
		}
	end

	-- <Mod-key> (e.g. <A-C-F1>)
	local _, _, mod_and_key = string.find(k, "^<([%u%-]+%w+)>$")
	if mod_and_key then
		local mods = {}
		for mod in string.gmatch(mod_and_key, "%u%-") do
			mod = string.gsub(mod, "%-$", "")
			local modifier = mod_map[mod]
			assert(modifier, string.format("unable to parse modifier: %s in key: %s", mod, k))
			if not vim.tbl_contains(mods, modifier) then
				-- ignore duplicate mods (e.g. <A-A-F1>)
				table.insert(mods, modifier)
			end
		end

		-- get the actual key
		local _, _, key = string.find(mod_and_key, "[%u%-]+%-(%w+)$")
		assert(key, string.format("unable to parse key: %s", k))

		-- user might not have explicitly defined Shift as mod when using an
		-- upper alpha as key (<A-K> == <A-S-K>)
		if string.match(key, "^%u$") then
			local shift = mod_map["S"]
			if not vim.tbl_contains(mods, shift) then
				table.insert(mods, shift)
			end
		end

		return {
			{ key = key, mods = mods, name = k },
		}
	end

	assert(string.len(k) == 1, string.format("unable to parse unknown key: %s", k))

	-- we assume it's a special character (e.g. $ or #)

	-- HACK: awful.keygrabber requires for special keys to also specify shift as
	-- mods. This is utterly broken, because for some layouts the
	-- minus key is on the shift layer, but for others layouts not. Therefore we're just
	-- ignoring the shift state by adding the key with and without shift to the
	-- map.

	return {
		{ key = k, mods = {}, name = k },
		{ key = k, mods = { "Shift" }, name = k },
	}
end

-- @param m table Map of parsed keys
-- @param k table Parsed key
local function add_key_to_map(m, k)
	assert(k.key)
	assert(k.mods)

	m[k.key] = m[k.key] or {}
	table.insert(m[k.key], k)

	-- sort by mod count desc
	table.sort(m[k.key], function(a, b)
		return #a.mods > #b.mods
	end)
end

-- @param t table A motion (sub)tree
-- @return table Table with tables of keys
local function keygrabber_keys(t)
	motion_tree = t
	local succs = motion_tree:successors()
	local opts = motion_tree:opts()

	local ret = {}

	-- make succs
	for k, v in pairs(succs) do
		if v:cond() then
			for _, key in pairs(parse_key(k)) do
				add_key_to_map(ret, key)
			end
		end
	end

	-- back key
	if opts.back_key and motion_tree:pred() then
		local key = {
			mods = {},
			key = opts.back_key,
			-- HACK: back key entry has special property back_tree
			back_tree = motion_tree:pred(),
		}
		add_key_to_map(ret, key)
	end

	return ret
end

local function keygrabber_stop_keys(exit_keys)
	local ks = {}

	if type(exit_keys) == "table" then
		for _, v in pairs(exit_keys) do
			table.insert(ks, v)
		end
	else
		table.insert(ks, exit_keys)
	end

	return ks
end

function M.run(key_sequence, keybind)
	assert(tree)
	local t = tree[key_sequence]
	return M.grab(t, keybind)
end

function M.grab(t, keybind)
	assert(mod_conversion)
	local opts = t:opts()

	-- hold mod init
	local hold_mod = opts.mod_hold_continue and keybind
	local hold_mod_ran_once = false
	local root_key = hold_mod and util.parse_keybind(keybind)
	if hold_mod then
		assert(root_key.key, "hold_mod is active but there is no root key")
	end

	local hold_mods_active = {}

	if hold_mod then
		-- we assume that all mods are still pressed down
		for _, mod in pairs(root_key.mods) do
			hold_mods_active[mod] = true
		end
		if vim.tbl_count(hold_mods_active) == 0 then
			-- no mods have been assigned by the user,
			-- two cases:
			-- 1) an actual mod is being used as the root key (e.g. Super_L)
			-- 2) the user uses something like XF86Calculator as the root key
			-- either way the key has to work like a mod
			local key = root_key.key
			assert(key, "root key has neither a mod or a key")
			local converted_key = mod_conversion[key] -- Super_L -> Mod4
			if mod_conversion[key] then
				-- case 1)
				hold_mods_active[converted_key] = true
				root_key.mods = { converted_key }
			else
				-- case 2)
				hold_mods_active[key] = true
			end
		end
	end

	local function is_hold_mode_active()
		return vim.tbl_count(hold_mods_active) > 0
	end

	---@diagnostic disable-next-line: redefined-local
	local function fn(t, force)
		-- force is currently only true for timeout nodes
		if not t then
			assert(false, "catch bug: t is nil in fn")
			return
		end

		---@diagnostic disable-next-line: redefined-local
		local opts = t:opts()
		local succs = t:successors()

		local run = function()
			local dynamic_succs = t:fn(opts)
			if dynamic_succs then
				-- dynamic submenu
				if type(dynamic_succs) ~= "table" or vim.tbl_count(dynamic_succs) == 0 then
					return
				end

				t:add_successors(dynamic_succs)

				assert(t)
				return t
			end

			-- do not set to true for dynamic menues!
			hold_mod_ran_once = true
		end

		-- run if no successors
		if not succs or vim.tbl_count(succs) == 0 then
			local next_t = run()

			if next_t then
				return next_t
			end

			-- go back on level if stay_open
			if opts.stay_open then
				return t:pred()
			end

			return nil
		end

		if force then
			run()
		end

		return t
	end

	-- when calling M.run() on an dynamic menu (e.g. via hotkey), we have to force the menu
	-- generation
	if vim.tbl_count(t:successors()) == 0 then
		fn(t) -- generate the submenu
		if vim.tbl_count(t:successors()) == 0 then
			-- still no successors?
			return
		end
	end

	local keybinds = keygrabber_keys(t)
	local stop_keys = keygrabber_stop_keys(opts.exit_key)
	assert(stop_keys)

	local grabber = akeygrabber({
		stop_key = stop_keys,
		keyreleased_callback = hold_mod and function(self, _, key)
			-- keyreleased_callback is only used for hold_mod
			print("released callback: ", dump(key))

			-- clear key
			if hold_mods_active[key] then
				hold_mods_active[key] = nil
			end

			-- clear mod
			local converted_key = mod_conversion[key] -- e.g. Super_L -> Mod4
			if converted_key and hold_mods_active[converted_key] then
				print("cleared converted key: ", converted_key)
				hold_mods_active[converted_key] = nil
			end

			print("hold_active: ", dump(hold_mods_active))

			if not is_hold_mode_active() then
				-- all mods/keys are cleared

				local mod_release = t:opts().mod_release_close
				if mod_release == "always" or hold_mod_ran_once and mod_release == "after" then
					self:stop()
					return
				end
				print("************** RELEASED ALL MODS ********")
			end
			on_start(t)
		end,
		keypressed_callback = function(self, modifiers, key)
			print("pressed callback: ", dump(modifiers), dump(key))
			local converted_key = mod_conversion[key] -- e.g. Super_L -> Mod4

			if keybinds[key] then
				-- Capslock and Numlock are ignored by default
				local ignore_mods = { "Lock2", "Mod2" }
				local ignore_hold_mods = {}
				local filtered_modifiers = {}
				local filtered_hold_mod_modifiers = {}

				local check_hold_mod = is_hold_mode_active()

				if check_hold_mod then
					for k in pairs(hold_mods_active) do
						table.insert(ignore_hold_mods, k)
					end
				end

				for _, m in ipairs(modifiers) do
					local ignore = vim.tbl_contains(ignore_mods, m)
					if not ignore then
						table.insert(filtered_modifiers, m)
						if check_hold_mod then
							local ignore_hold_mod = vim.tbl_contains(ignore_hold_mods, m)
							if not ignore_hold_mod then
								table.insert(filtered_hold_mod_modifiers, m)
							end
						end
					end
				end

				-- Keybinds are sorted by descending mod count.
				for _, v in ipairs(keybinds[key]) do
					-- generate mod map
					local mod = {}
					for _, v2 in ipairs(v.mods) do
						mod[v2] = true
					end

					-- check if mods are matching
					local match = false
					local mod_count = #v.mods
					if #filtered_modifiers == mod_count then
						match = true
						for _, v2 in ipairs(filtered_modifiers) do
							match = match and mod[v2]
						end
					elseif check_hold_mod and #filtered_hold_mod_modifiers == mod_count then
						match = true
						for _, v2 in ipairs(filtered_hold_mod_modifiers) do
							match = match and mod[v2]
						end
					end

					if match then
						-- run the key function and exit
						local key_name = v.name
						print("running key function: ", key_name)
						local next_t = fn(t[key_name] or v.back_tree)

						-- no tree to run next
						if not next_t then
							if not is_hold_mode_active() then
								self:stop()
								return
							end
							return
						end

						-- run the next tree
						keybinds = keygrabber_keys(next_t)
						on_start(next_t)
						t = next_t
						return
					end
				end
			else
				-- key is not defined

				-- it might be a mod key
				if converted_key then
					for _, m in pairs(root_key.mods) do
						if m == converted_key then
							-- user has re-pressed a root mod key
							hold_mods_active[converted_key] = true
							break
						end
					end

					-- user has pressed a mod key that is not a root mod
					-- ignore it
					return
				end

				-- key is not defined and not a mod
				if t:opts().stop_on_unknown_key then
					-- TODO: remove that?
					-- user is holding down a non mod key as mod (see case 2 above)
					-- if hold_mod and hold_mods_active[key] then
					-- 	return
					-- end

					self:stop()
				end
			end
		end,

		timeout = opts.timeout and opts.timeout > 0 and opts.timeout / 1000,
		timeout_callback = function()
			fn(t, true)
			on_stop(t)
		end,
		start_callback = function()
			on_start(t)
		end,
		stop_callback = function()
			on_stop(t)
		end,
	})

	grabber:start()
end

function M.add_globalkey(prefix, key)
	key = util.parse_keybind(key)
	awful.keyboard.append_global_keybindings({
		awful.key(key.mods, key.key, function()
			M.run(prefix, key)
		end),
	})
end

function M.resume()
	if not motion_tree then
		print("no previous tree found")
		return
	end
	M.grab(motion_tree)
end

function M.setup(opts)
	if opts.key then
		M.add_globalkey("", opts.key)
	end

	awesome.connect_signal("xkb::map_changed", function()
		generate_mod_conversion_maps()
	end)

	generate_mod_conversion_maps()

	print(dump(mod_conversion))
end

return M

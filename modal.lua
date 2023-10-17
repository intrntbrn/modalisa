local M = {}

-- TODO:
-- force stay open keybind
-- add keybind support for each tree node
-- keyname tester
-- timestamp
-- move wm specific configs away from config?
-- fix default clienting floating resize
-- tests for key parser
-- on_enter
-- pre(opts, t)
-- post(opts, t)
-- post_run hook

local awful = require("awful")
local vim = require("motion.vim")
local util = require("motion.util")
local dump = require("motion.vim").inspect
local mtree = require("motion.tree")
local akeygrabber = require("awful.keygrabber")

-- global
local global_tree
local global_keygrabber
local mod_conversion = nil
local ignore_mods = { "Lock2", "Mod2" }

local supported_mods = {
	["S"] = "Shift_L",
	["A"] = "Alt_L",
	["C"] = "Control_L",
	["M"] = "Super_L",
}
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
	local map = {}
	for k, v in pairs(supported_mods) do
		map[k] = mod_conversion[v]
	end

	-- vice versa
	for k, v in pairs(map) do
		map[v] = k
	end

	mod_map = map

	return nil
end

-- @param t table A motion (sub)tree
local function on_start(t)
	awesome.emit_signal("motion::start", { tree = t })
end

-- @param t table A motion (sub)tree
local function on_update(t)
	awesome.emit_signal("motion::update", { tree = t })
end

-- @param t table A motion (sub)tree
local function on_stop(t)
	global_keygrabber = nil
	awesome.emit_signal("motion::stop", { tree = t })
end

local global_execute
-- bypass the keygrabber
function M.fake_input(key, force_continue)
	if global_keygrabber and global_execute then
		global_execute(key, global_keygrabber, force_continue)
	end
end

-- @param m table Map of parsed keys
-- @param k table Parsed key
local function add_key_to_map(m, k)
	assert(k.key)
	assert(k.mods)

	m[k.key] = m[k.key] or {}
	table.insert(m[k.key], k)

	-- sort by mod count descending
	table.sort(m[k.key], function(a, b)
		return #a.mods > #b.mods
	end)
end

-- @param t table A motion (sub)tree
-- @return table Table with tables of keys
local function keygrabber_keys(t)
	local succs = t:successors()
	local opts = t:opts()

	local all_keys = {}

	-- regular keys (successors)
	for k, v in pairs(succs) do
		if v:cond() then
			for _, key in pairs(M.parse_vim_key(k, opts)) do
				add_key_to_map(all_keys, key)
			end
		end
	end

	-- stop keys
	assert(opts.stop_keys, "no stop keys found")
	local stop_keys

	if type(opts.stop_keys) == "table" then
		stop_keys = opts.stop_keys
	elseif type(opts.stop_keys) == "string" then
		stop_keys = { opts.stop_keys }
	end

	assert(stop_keys, "no stop keys found")

	for _, sk in pairs(stop_keys) do
		local parsed_keys = M.parse_vim_key(sk, opts)
		for _, parsed_key in pairs(parsed_keys) do
			local key = {
				mods = parsed_key.mods,
				key = parsed_key.key,
				stop = true,
			}
			add_key_to_map(all_keys, key)
		end
	end

	-- back keys
	if t:pred() then
		local back_keys

		if type(opts.back_keys) == "table" then
			back_keys = opts.back_keys
		elseif type(opts.back_keys) == "string" then
			back_keys = { opts.back_keys }
		end

		if back_keys then
			for _, bk in pairs(back_keys) do
				local parsed_keys = M.parse_vim_key(bk, opts)
				for _, parsed_key in pairs(parsed_keys) do
					local key = {
						mods = parsed_key.mods,
						key = parsed_key.key,
						back = t:pred(),
					}
					add_key_to_map(all_keys, key)
				end
			end
		end
	end

	return all_keys
end

local function grab(t, keybind)
	assert(mod_conversion)
	local opts = t:opts()

	-- hold mod init
	local hold_mod = opts.mod_hold_continue and keybind
	local root_key = hold_mod and keybind

	if hold_mod then
		assert(root_key.key, "hold_mod is active but there is no root key")
	end

	local hold_mod_ran_once = false

	local mm
	if hold_mod then
		mm = require("motion.modmap")(root_key.key, root_key.mods, mod_conversion)
	end

	local instance_keybinds
	local instance_tree = t

	local function set_next_tree(tree)
		instance_tree = tree
		instance_keybinds = keygrabber_keys(tree)
		global_tree = tree
		on_update(tree)
	end

	-- set the tree
	local function execute_if_leaf(tree, force)
		-- force is currently only true for timeout nodes
		if not tree then
			assert(false, "catch bug: tree is nil in run_tree")
			return
		end

		---@diagnostic disable-next-line: redefined-local
		local opts = tree:opts()
		local succs = tree:successors()

		if succs and vim.tbl_count(succs) > 0 and not force then
			-- wait for inputs
			return tree
		end

		-- run!
		local subtree = tree:fn(opts, instance_tree)
		if subtree then
			-- dynamically created list
			if type(subtree) ~= "table" or vim.tbl_count(subtree) == 0 then
				return
			end
			tree:add_successors(subtree)
			return tree
		end

		-- command did not return a new list
		hold_mod_ran_once = true

		if opts.stay_open then
			return tree:pred()
		end

		return nil
	end

	local function execute(key, grabber, continue)
		if key == "back" then
			local prev = instance_tree:pred()
			if prev then
				set_next_tree(prev)
			end
			return
		end

		if key == "stop" then
			grabber = grabber or global_keygrabber
			if grabber then
				grabber:stop()
			end
			return
		end

		local next_tree = execute_if_leaf(instance_tree[key])
		if next_tree then
			set_next_tree(next_tree)
			return
		end

		if not mm:has_pressed_mods() and not continue then
			grabber:stop()
			return
		end

		-- the execution might cause some hinting labels to change
		-- therefore we are emitting the signal again
		-- on_start(t)
	end

	execute_if_leaf(instance_tree) -- we might have to populate the tree first
	assert(vim.tbl_count(instance_tree:successors()) > 1, "emptry tree") -- there is nothing to do here
	set_next_tree(instance_tree)

	local grabber = akeygrabber({
		-- keyreleased_callback is only used for hold_mod detection
		keyreleased_callback = hold_mod and function(self, _, key)
			-- print("released callback: ", dump(key))
			mm:release(key)
			-- print("active mods: ", dump(mm))
			if not mm:has_pressed_mods() then
				local mod_release = instance_tree:opts().mod_release_stop
				if mod_release == "always" or hold_mod_ran_once and mod_release == "after" then
					print("mm: all mods are released: ", mod_release)
					self:stop()
					return
				end
				print("mm: all mods are released: ", mod_release)
			end
		end,
		keypressed_callback = function(self, modifiers, key)
			-- filter mods that are ignored by default (capslock, numlock)
			local filtered_modifiers = {}
			for _, m in ipairs(modifiers) do
				local ignore = vim.tbl_contains(ignore_mods, m)
				if not ignore then
					table.insert(filtered_modifiers, m)
				end
			end
			modifiers = filtered_modifiers

			print("pressed callback: ", dump(modifiers), dump(key))

			local converted_key = mod_conversion[key]
			if hold_mod then
				mm:press(key, modifiers)
			end

			local keys = instance_keybinds[key]
			if keys then
				local function execute_key(v)
					-- stop key
					if v.stop then
						self:stop()
						return
					end

					-- back key
					if v.back then
						execute("back", self)
						return
					end

					-- regular key
					local key_name = v.name
					print("running key function: ", key_name, instance_tree[key_name]:desc())
					execute(key_name, self)
				end

				local function is_match(v, comparator)
					if not (#v == #comparator) then
						return false
					end
					local mod = {}
					for _, v2 in ipairs(v) do
						mod[v2] = true
					end
					local match = true
					for _, v2 in ipairs(comparator) do
						match = match and mod[v2]
					end
					return match
				end

				-- check exact match first to skip combination calculations
				for _, v in pairs(keys) do
					if is_match(v.mods, modifiers) then
						return execute_key(v)
					end
				end

				if hold_mod then
					-- find the match with the least amount of ignored mods
					local pressed_mods_list = mm:get_pressed_mods()
					local combinations = {}
					for combo in util.unique_combinations(pressed_mods_list) do
						table.insert(combinations, combo)
					end
					table.sort(combinations, function(a, b)
						return #a < #b
					end)

					-- combinations are sorted by mod count ascending
					for _, combi in ipairs(combinations) do
						-- keys are sorted by mod count descending
						for _, v in pairs(keys) do
							local filtered = {} -- modifiers - combi
							for _, mod in ipairs(modifiers) do
								if not vim.tbl_contains(combi, mod) then
									table.insert(filtered, mod)
								end
							end
							-- v.mods == modifiers - combi?
							if is_match(v.mods, filtered) then
								return execute_key(v)
							end
						end
					end
				end
			end
			-- no match!

			if converted_key then
				-- user is pressing a mod key, we have to ignore it
				return
			end

			-- key is not defined and not a mod
			if instance_tree:opts().stop_on_unknown_key then
				print("unknown key: ", key)
				self:stop()
			end
		end,
		timeout = opts.timeout and opts.timeout > 0 and opts.timeout / 1000,
		timeout_callback = function()
			execute_if_leaf(instance_tree, true)
			on_stop(instance_tree)
		end,
		start_callback = function()
			on_start(instance_tree)
		end,
		stop_callback = function()
			on_stop(instance_tree)
		end,
	})

	global_keygrabber = grabber
	global_execute = function(...)
		local ret = execute(...)

		-- HACK:
		-- force update after clicks
		require("gears").timer({
			timeout = 0.05,
			callback = function()
				if global_keygrabber then
					on_update(instance_tree)
				end
			end,
			autostart = true,
			single_shot = true,
		})

		return ret
	end

	grabber:start()

	print("grabber: pressed: ", dump(grabber.keyreleased_callback))

	-- grabber.keyreleased_callback = nil
end

local function run(sequence, parsed_keybind)
	---@diagnostic disable-next-line: need-check-nil
	local t = mtree[sequence or ""]
	return grab(t, parsed_keybind)
end

function M.parse_vim_key(k, opts)
	print("parse: ", k)
	-- upper alpha (e.g. "S")
	if string.match(k, "^%u$") then
		return {
			{ key = k, mods = { mod_map["S"] }, name = k },
		}
	end

	-- alphanumeric char and space (e.g. "s", "4", " ")
	if string.match(k, "^[%w%s]$") then
		return {
			{ key = k, mods = {}, name = k },
		}
	end

	-- punctuation char (e.g. ";")
	if string.match(k, "^%p$") then
		-- HACK: awful.keygrabber requires for special keys to also specify shift as
		-- mods. This is utterly broken, because for some layouts the
		-- minus key is on the shift layer, but for others layouts not. Therefore we're just
		-- ignoring the shift state by adding the key with and without shift to the
		-- map.
		if opts and not opts.ignore_shift_state_for_special_characters then
			return {
				{ key = k, mods = {}, name = k },
			}
		end

		return {
			{ key = k, mods = {}, name = k },
			{ key = k, mods = { mod_map["S"] }, name = k },
		}
	end

	-- <keysym> (e.g. <BackSpace>, <F11>, <Alt_L>)
	local _, _, keysym = string.find(k, "^<([%w_]+)>$")
	if keysym then
		return {
			{ key = keysym, mods = {}, name = k },
		}
	end

	-- <Mod-key> (e.g. <A-C-BackSpace>, <A- >, <A-*>)
	local _, _, mod_and_key = string.find(k, "^<([%u%-]+.+)>$")
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
		local _, _, key = string.find(mod_and_key, "[%u%-]+%-(.+)$")
		assert(key, string.format("unable to parse key: %s", k))

		-- user might not have defined Shift explicitly as mod when using an
		-- upper alpha as key (<A-K> == <A-S-K>)
		if string.match(key, "^%u$") then
			local shift = mod_map["S"]
			if not vim.tbl_contains(mods, shift) then
				table.insert(mods, shift)
			end
		end

		if string.match(k, "^%p$") and not vim.tbl_contains(mods, mod_map["S"]) then
			if opts and not opts.ignore_shift_state_for_special_characters then
				local mods_with_shift = vim.deepcopy(mods)
				table.insert(mods_with_shift, mod_map["S"])
				return {
					{ key = k, mods = {}, name = k },
					{ key = k, mods = mods_with_shift, name = k },
				}
			end
			return {
				{ key = k, mods = {}, name = k },
			}
		end

		return {
			{ key = key, mods = mods, name = k },
		}
	end

	assert(string.len(k) == 1, string.format("unable to parse unknown key: %s", k))
end

local function make_awful_key(prefix, parsed_key)
	return awful.key(parsed_key.mods, parsed_key.key, function()
		run(prefix, parsed_key)
	end)
end

-- create keybind for every mod combination:
-- e.g. for <M-y>:
-- "y"	{ "Mod4", }
-- "y"	{ "Mod4", "Mod1" }
-- "y"	{ "Mod4", "Mod1", "Control" }
-- "y"	{ "Mod4", "Mod1", "Control", "Shift" }
-- "y"	{ "Mod4", "Mod1", "Shift" }
-- "y"	{ "Mod4", "Control" }
-- "y"	{ "Mod4", "Control", "Shift" }
-- "y"	{ "Mod4", "Shift" }

function M.create_run_globalkey_combinations(prefix, key)
	assert(mod_map)
	assert(mod_conversion)

	local all_mods = {}
	for _, mod in pairs(supported_mods) do
		local converted = mod_conversion[mod]
		if converted then
			all_mods[converted] = true
		end
	end

	local keys = {}
	local parsed_keys = M.parse_vim_key(key)

	for _, parsed_key in pairs(parsed_keys) do
		-- the specified key
		table.insert(keys, make_awful_key(prefix, parsed_key))

		local map = vim.deepcopy(all_mods)

		for _, m in pairs(parsed_key.mods) do
			map[m] = nil
		end

		local list = {}
		for k in pairs(map) do
			table.insert(list, k)
		end

		for combo in util.unique_combinations(list) do
			local all = {}
			vim.list_extend(all, parsed_key.mods)
			vim.list_extend(all, combo)

			local keybind = vim.deepcopy(parsed_key)
			keybind.mods = all

			print("global keybind: ", dump(keybind.key), dump(keybind.mods))
			table.insert(keys, make_awful_key(prefix, keybind))
		end
	end

	awful.keyboard.append_global_keybindings(keys)
end

function M.parse_key_all(key)
	local t = type(key)

	if t == "string" then
		return M.parse_vim_key(key)
	end

	if t ~= "table" then
		return nil
	end

	if key.key and key.mods then
		-- already parsed
		return key
	end

	if #key == 2 then
		local k, m
		for _ = 1, 2 do
			local p = key[1]
			if type(p) == "table" then
				assert(m == nil)
				m = p
				break
			end
			if type(p) == "string" then
				assert(k == nil)
				k = p
				break
			end
		end
		return { key = k, mods = m }
	end

	return nil
end

function M.create_run_globalkey_vim(prefix, vimkey)
	local parsed_keys = M.parse_vim_key(vimkey)
	for _, parsed_key in pairs(parsed_keys) do
		awful.keyboard.append_global_keybindings({
			make_awful_key(prefix, parsed_key),
		})
	end
end

-- not used currently
function M.add_globalkey(prefix, awmkey)
	local parsed_key = util.parse_awesome_key(awmkey)
	awful.keyboard.append_global_keybindings({
		make_awful_key(prefix, parsed_key),
	})
end

-- TODO: rename
-- run inline table
function M.run_tree(tree, opts, name)
	---@diagnostic disable-next-line: need-check-nil
	local t = mtree.create_tree(tree, opts, name)
	if not t then
		return
	end
	return grab(t)
end

-- run keyroot_tree with a keybind (opt)
function M.run(sequence, keybind)
	sequence = sequence or ""
	if keybind then
		keybind = M.parse_key_all(keybind)
		assert(keybind)
	end
	run(sequence, keybind)
end

local once
function M.setup(opts)
	assert(once == nil, "modal setup once")
	once = true

	awesome.connect_signal("xkb::map_changed", function()
		generate_mod_conversion_maps()
	end)

	awesome.connect_signal("motion::fake_input", function(args)
		if type(args) == "string" then
			M.fake_input(args)
			return
		end
		if type(args) == "table" then
			M.fake_input(args.key, args.continue)
			return
		end
	end)

	generate_mod_conversion_maps()

	if opts.key then
		M.create_run_globalkey_combinations("", opts.key)
	end

	print(dump(mod_conversion))
end

return setmetatable(M, {
	__call = function(self, ...)
		self.run(...)
	end,
})

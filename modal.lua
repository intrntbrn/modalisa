local M = {}

local awful = require("awful")
local lib = require("modalisa.lib")
local vim = require("modalisa.lib.vim")
local dump = require("modalisa.lib").inspect
local root_tree = require("modalisa.root")
local modmap = require("modalisa.modmap")
local akeygrabber = require("awful.keygrabber")
local gears = require("gears")
local config = require("modalisa.config")

local trunner = {}

local ignore_mods = { "Lock2", "Mod2" }
local supported_mods = {
	["S"] = "Shift_L",
	["A"] = "Alt_L",
	["C"] = "Control_L",
	["M"] = "Super_L",
}

local mod_map
local mod_conversion = nil

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

local function parse_vim_key(k, opts)
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
		if opts and not opts.ignore_shift_state_for_special_characters then
			return {
				{ key = k, mods = {}, name = k },
			}
		end

		-- HACK: awful.keygrabber requires for special keys to also specify shift as
		-- mods. This is utterly broken, because for some layouts the
		-- minus key is on the shift layer, but for others layouts not. Therefore we're just
		-- ignoring the shift state by adding the key with and without shift to the
		-- map.

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

local function parse_key_all(key)
	local t = type(key)

	if t == "string" then
		return parse_vim_key(key)
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
		for i = 1, 2 do
			local p = key[i]
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
		assert(m)
		assert(k)
		return { key = k, mods = m }
	end

	return nil
end

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

local function keygrabber_init()
	local grabber = akeygrabber({
		start_callback = function()
			trunner:on_start()
		end,
		stop_callback = function()
			trunner:on_stop()
		end,
	})
	return grabber
end

local function keygrabber_keys(t)
	local opts = t:opts()

	local succs = t:successors()

	local all_keys = {}

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
		local parsed_keys = parse_vim_key(sk, opts)
		for _, parsed_key in pairs(parsed_keys) do
			local key = {
				mods = parsed_key.mods,
				key = parsed_key.key,
				stop = true,
			}
			add_key_to_map(all_keys, key)
		end
	end

	-- toggle keys
	local toggle_keys
	if type(opts.toggle_keys) == "table" then
		toggle_keys = opts.toggle_keys
	elseif type(opts.toggle_keys) == "string" then
		toggle_keys = { opts.toggle_keys }
	end

	for _, tk in pairs(toggle_keys) do
		local parsed_keys = parse_vim_key(tk, opts)
		for _, parsed_key in pairs(parsed_keys) do
			local key = {
				mods = parsed_key.mods,
				key = parsed_key.key,
				toggle = true,
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
				local parsed_keys = parse_vim_key(bk, opts)
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

	-- regular keys (successors)
	for k in pairs(succs) do
		for _, key in pairs(parse_vim_key(k, opts)) do
			add_key_to_map(all_keys, key)
		end
	end

	return all_keys
end

function trunner:init()
	self.keygrabber = keygrabber_init()
	self.keygrabber.keyreleased_callback = self:keyreleased_callback()
	self.keygrabber.keypressed_callback = self:keypressed_callback()

	self.timer = gears.timer({
		timeout = 0,
		callback = function()
			local t = self.tree
			if t then
				self:execute(t)
			end
			self:stop()
		end,
		autostart = false,
		single_shot = true,
	})

	self:reset()
end

function trunner:start(t, root_key)
	assert(not trunner.is_running, "keygrabber is already running")
	assert(not vim.tbl_isempty(t:opts()), "trunner:new t opts are empty")

	if root_key then
		self.mm = modmap(root_key.key, root_key.mods, mod_conversion)
	else
		self.mm = modmap("", {}, mod_conversion)
	end

	self:reset()

	-- remove previously generated successors
	t:remove_temp_successors()

	if t:is_leaf() then
		-- running the node might populate itself (e.g. user calls run on an
		-- dynamic node)
		self:execute(t)

		if t:is_leaf() then
			-- there is no point in running an empty tree
			return nil
		end
	end

	self:set_tree(t)
	self:start_keygrabber()

	return self
end

function trunner:set_keygrabber(keygrabber)
	self.keygrabber = keygrabber
end

function trunner:reset()
	self.tree = nil
	self.is_running = false
	self.ran_once = false
	self.continue_external = false
	self.continue_key = false
end

function trunner:start_keygrabber()
	self.keygrabber:start()
end

function trunner:on_start()
	-- called by keygrabber
	local t = self.tree
	self.is_running = true
	print("on::start", t:desc())
	awesome.emit_signal("modalisa::on_start", t)
end

function trunner:on_enter(t)
	print("on::enter", t:desc())
	t:exec_on_enter()
	awesome.emit_signal("modalisa::on_enter", t)
end

function trunner:on_leave(t)
	print("on::leave", t:desc())
	t:exec_on_leave()
	awesome.emit_signal("modalisa::on_leave", t)
end

function trunner:on_exec(t, result)
	print("on::executed", t:desc())
	awesome.emit_signal("modalisa::on_exec", t, result)
end

function trunner:on_stop()
	-- called by keygrabber
	local t = self.tree
	self.is_running = false
	self:on_leave(t) -- also emit leave event
	print("on::stop", t:desc())
	awesome.emit_signal("modalisa::on_stop", t)
end

function trunner:toggle_hints(t)
	awesome.emit_signal("modalisa::hints::toggle", t)
end

function trunner:start_timer()
	local timeout = self.tree:opts().timeout
	self.timer:stop()

	if timeout and timeout > 0 then
		self.timer.data.timeout = timeout / 1000
		self.timer:start()
	end
end

function trunner:set_tree(t)
	local old_tree = self.tree
	self.tree = t
	self.keybinds = keygrabber_keys(t)
	self:start_timer()

	if old_tree then
		self:on_leave(old_tree)
	end
	self:on_enter(t)
end

function trunner:stop()
	self.keygrabber:stop()
end

function trunner:stop_maybe(reason)
	if self.continue_external then
		return
	end

	local opts = self.tree:opts()
	local mode = opts.mode

	print("maybe_stop: ", reason)

	if reason == "release_mod" then
		-- only "hold" and "hybrid" depend on mod states
		if not (mode == "hold" or mode == "hybrid") then
			return
		end
		if self.mm:has_pressed_mods() then
			return
		end
		if mode == "hybrid" then
			if not self.ran_once or self.continue_key then
				return
			end
		end
	elseif reason == "no_next_tree" then
		if mode == "forever" then
			return
		end

		if mode == "hold" or mode == "hybrid" then
			if self.mm:has_pressed_mods() then
				return
			end
		end

		if self.continue_key then
			return
		end
	elseif reason == "unknown_key" then
		if not opts.stop_on_unknown_key then
			return
		end
	end

	self:stop()
	return true
end

function trunner:execute(t)
	assert(t, "execute: tree is nil")

	if not t:cond() then
		-- should this count as a run?
		-- self.ran_once = true
		return
	end

	local opts = t:opts()
	local dynamic_list = t:exec(opts)

	-- make results
	local result = t:result()
	if result then
		local eval = {}
		for k, v in pairs(result) do
			if type(v) == "function" then
				eval[k] = v()
			else
				eval[k] = v
			end
		end
		result = eval
	end

	self:on_exec(t, result)

	if dynamic_list then
		if type(dynamic_list) ~= "table" or vim.tbl_isempty(dynamic_list) then
			return nil
		end
		t:add_temp_successors(dynamic_list)

		return t
	end

	-- command did not return a new list
	self.ran_once = true

	return nil
end

function trunner:step_into(node)
	local next_tree

	node:remove_temp_successors()

	if node:is_leaf() then
		next_tree = self:execute(node)
	else
		next_tree = node
	end

	if next_tree then
		-- wait for the next input
		self:set_tree(next_tree)
		return
	end

	-- there is no next tree
	-- determine if we should keep on running the current tree

	self.continue_key = false
	if node:continue() then
		self.continue_key = true
	end

	local stopped = self:stop_maybe("no_next_tree")
	if stopped then
		return
	end

	self.continue_external = false
end

function trunner:input(key)
	print("press key: ", dump(key))

	local tree = self.tree

	-- special keys that have no actual function
	if key == "back" then
		local prev = tree:pred()
		if prev then
			self:set_tree(prev)
		end
		return
	end

	if key == "stop" then
		self:stop()
		return
	end

	if key == "toggle" then
		self:toggle_hints(self.tree)
		return
	end

	-- traverse
	local node = tree:get(key)
	if not node then
		print(tree)
		assert(false, "catch bug: tree is empty for accepted key: " .. key)
		return
	end

	self:step_into(node)
end

function trunner:keypressed_callback()
	return function(_, modifiers, key)
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

		self:start_timer()

		---@diagnostic disable-next-line: need-check-nil
		local modifier_key = mod_conversion[key]
		self.mm:press(key, modifiers)

		local keys = self.keybinds[key]
		if keys then
			local function input_key(k)
				self:input(k.stop and "stop" or k.back and "back" or k.toggle and "toggle" or k.name)
			end

			for _, k in pairs(keys) do
				if is_match(k.mods, modifiers) then
					return input_key(k)
				end
			end

			local opts = self.tree:opts()
			if opts.smart_modifiers and self.mm:has_pressed_mods() then
				-- find the match with the least amount of ignored mods
				local pressed_mods_list = self.mm:get_pressed_mods()
				local combinations = {}
				for combo in lib.unique_combinations(pressed_mods_list) do
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
							return input_key(v)
						end
					end
				end
			end
		end
		-- no match!

		if modifier_key then
			-- user is pressing a mod key, we have to ignore it as it might be used
			-- to transition to a valid key combo.
			return
		end

		self:stop_maybe("unknown_key")
	end
end

function trunner:keyreleased_callback()
	return function(_, _, key)
		---@diagnostic disable-next-line: need-check-nil
		local is_modifier = mod_conversion[key]
		if is_modifier then
			self.mm:release(key)
			self:stop_maybe("release_mod")
		end
	end
end

local function run_tree(t, parsed_keybind)
	local ok = trunner:start(t, parsed_keybind)
	if not ok then
		return
	end
end

local function run_root_tree(seq, parsed_keybind)
	local t = root_tree.get(seq)
	run_tree(t, parsed_keybind)
end

function M.stop()
	trunner:stop()
end

-- bypass the keygrabber
function M.fake_input(key, force_continue)
	if not trunner.is_running then
		return
	end
	if force_continue then
		trunner.continue_external = true
	end
	trunner:input(key)
end

-- FIXME: no keybind option
-- run inline table
function M.run_tree(tree, opts, name)
	opts = config.get_config(opts)
	local t = require("modalisa.tree"):new(opts, name)
	assert(t)
	t:add_successors(tree)
	trunner:start(t)
end

-- run keyroot_tree with a keybind (opt)
function M.run(seq, keybind)
	if keybind then
		keybind = parse_key_all(keybind)
		assert(keybind)
	end
	run_root_tree(seq, keybind)
end

local function make_awful_key_run_seq(seq, parsed_key)
	return awful.key(parsed_key.mods, parsed_key.key, function()
		run_root_tree(seq, parsed_key)
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

function M.add_globalkey_run_root(vimkey, seq)
	seq = seq or ""
	-- hook every possible mod combination
	-- so we know exactly which mods are pressed down on start
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
	local parsed_keys = parse_vim_key(vimkey)

	for _, parsed_key in pairs(parsed_keys) do
		-- the specified key
		table.insert(keys, make_awful_key_run_seq(seq, parsed_key))

		local map = vim.deepcopy(all_mods)

		for _, m in pairs(parsed_key.mods) do
			map[m] = nil
		end

		local list = {}
		for k in pairs(map) do
			table.insert(list, k)
		end

		for combo in lib.unique_combinations(list) do
			local all = {}
			vim.list_extend(all, parsed_key.mods)
			vim.list_extend(all, combo)

			local keybind = vim.deepcopy(parsed_key)
			keybind.mods = all

			table.insert(keys, make_awful_key_run_seq(seq, keybind))
		end
	end

	awful.keyboard.append_global_keybindings(keys)
end

function M.add_globalkey_run_root_simple(vimkey, seq)
	seq = seq or ""
	local parsed_keys = parse_vim_key(vimkey)
	for _, parsed_key in pairs(parsed_keys) do
		awful.keyboard.append_global_keybindings({
			make_awful_key_run_seq(seq, parsed_key),
		})
	end
end

local global_keys = {}

local function global_keybinding_add(t)
	if not t then
		return
	end
	local global_key = t:global()
	if not global_key then
		return
	end

	local pks = parse_vim_key(global_key)
	for _, pk in pairs(pks) do
		local fn = function()
			run_tree(t, pk)
		end
		local akey = awful.key(pk.mods, pk.key, fn)
		global_keys[t:id()] = akey
		awful.keyboard.append_global_keybinding(akey)
	end
end

local function global_keybinding_remove(t)
	if not t or not t.id then
		return
	end

	local akey = global_keys[t:id()]
	if not akey then
		return
	end
	awful.keyboard.remove_global_keybinding(akey)
end

local once
function M.setup(opts)
	assert(once == nil, "modal is already setup")
	once = true

	trunner:init()

	awesome.connect_signal("modalisa::tree::update", function(new, old)
		global_keybinding_remove(old)
		global_keybinding_add(new)
	end)

	awesome.connect_signal("modalisa::tree::remove", function(old)
		global_keybinding_remove(old)
	end)

	awesome.connect_signal("xkb::map_changed", function()
		generate_mod_conversion_maps()
	end)

	generate_mod_conversion_maps()

	local root_keys = opts.root_keys
	if root_keys then
		if type(root_keys) == "string" then
			M.add_globalkey_run_root(root_keys, "")
		end
	elseif type(root_keys) == "table" then
		for _, key in ipairs(root_keys) do
			M.add_globalkey_run_root(key, "")
		end
	end
end

function M.showkey(opts)
	require("modalisa.showkey").start({
		mod_map = mod_map,
		ignore_mods = ignore_mods,
		opts = opts,
	})
end

return setmetatable(M, {
	__call = function(self, ...)
		self.run(...)
	end,
})

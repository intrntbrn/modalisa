local vim = require("motion.lib.vim")
local util = require("motion.util")

---@diagnostic disable-next-line: unused-local
local dump = vim.inspect

local M = {}

local global_id = 0
local function get_id()
	global_id = global_id + 1
	return global_id
end

local function mt(obj)
	return setmetatable(obj, {
		__index = M,
		__tostring = function(t)
			return vim.inspect(t)
		end,
	})
end

local function on_update(t, old_t)
	awesome.emit_signal("motion::tree::update", t, old_t)
end

local function on_remove(t)
	awesome.emit_signal("motion::tree::remove", t)
end

-- parse a loosely defined key
-- @param key string|table The key object to be parsed
-- @param table_index string The key string if the key object does not contain the key string
local function parse_key(key, table_index)
	local seq
	local fn
	local opts
	local cond
	local desc
	local result
	local temp
	local global
	local fg
	local hidden
	local group
	local continue

	local t = type(key)

	if t == "string" then
		seq = key
	else
		assert(t == "table")
		for k, v in pairs(key) do
			t = type(v)
			if t == "string" then
				-- can be key, desc, without mods
				if k == "desc" then
					assert(not desc, "multiple descrptions")
					desc = v
				elseif k == "global" then
					global = v
				elseif k == "fg" then
					fg = v
				elseif k == "group" then
					group = v
				else
					assert(not seq, "multiple undeclared strings")
					seq = v
				end
			elseif t == "table" then
				if k == "opts" then
					assert(not opts, "multiple opts")
					opts = v
				elseif k == "result" then
					result = v
				else
					assert(not opts, "multiple opts")
					opts = v
				end
			elseif t == "function" then
				-- can be fn, condition, desc with mods
				if k == "cond" then
					cond = v
				elseif k == "desc" then
					desc = v
				else
					assert(not fn, "multiple undeclared functions")
					fn = v
				end
			elseif t == "boolean" then
				if k == "temp" then
					temp = v
				elseif k == "global" then
					global = v
				elseif k == "hidden" then
					hidden = v
				elseif k == "continue" then
					continue = v
				else
					assert(false, "unknown boolean: ", k, v)
				end
			end
		end
	end

	if not seq then
		assert(table_index, "no key sequence found")
		seq = table_index
	end

	if global == true then
		global = seq
	end

	return seq,
		{
			fn = fn,
			opts_raw = opts,
			cond = cond,
			desc = desc,
			result = result,
			temp = temp,
			global = global,
			hidden = hidden,
			group = group,
			fg = fg,
			continue = continue,
		}
end

function M:opts()
	return self._data.opts_merged
end

function M:opts_merged() -- alias
	return self:opts()
end

function M:opts_raw()
	return self._data.opts_raw
end

function M:exec(opts)
	local fn = self._data.fn
	if fn then
		opts = opts or self:opts()
		return fn(opts, self)
	end
end

function M:global()
	return self._data.global
end

function M:pred()
	local prev = self._prev
	if prev then
		return mt(prev)
	end
	return nil
end

function M:cond(opts)
	local cond = self._data.cond
	if cond == nil then
		return true
	end

	if type(cond) == "function" then
		opts = opts or self:opts()
		return cond()
	end

	return cond
end

function M:result()
	return self._data.result
end

function M:set_result(key, value)
	if not self._data.result then
		self._data.result = {}
	end
	self._data.result[key] = value
end

function M:desc(opts)
	local desc = self._data.desc
	if not desc then
		return ""
	end

	if type(desc) == "function" then
		return desc(opts or self:opts())
	end

	return desc
end

function M:set_desc(desc)
	self._data.desc = desc
end

function M:id()
	return self._id
end

function M:hidden()
	return self._data.hidden
end

function M:group()
	return self._data.group or ""
end

function M:continue()
	return self._data.continue
end

function M:fg()
	return self._data.fg
end

function M:successors()
	local succs = self._succs
	if not succs then
		return {}
	end

	local tree_objects = {}
	for k in pairs(succs) do
		tree_objects[k] = self:get(k)
	end

	return tree_objects
end

function M:is_leaf()
	local succs = self._succs
	if not succs or vim.tbl_isempty(succs) then
		return true
	end
	return false
end

function M:add_temp_successors(succs)
	for k, succ in pairs(succs) do
		local seq, value = parse_key(succ, k)
		value.temp = true
		self:add(value, seq)
	end
end

function M:remove_temp_successors()
	local succs = self._succs
	if not succs then
		return
	end

	for k, succ in pairs(succs) do
		if succ._data.temp then
			self:remove(k)
		end
	end
end

function M:add_successors(succs)
	for k, succ in pairs(succs) do
		local seq, value = parse_key(succ, k)
		self:add(value, seq)
	end
end

local function make_initial_node(prev_tree)
	return {
		_id = get_id(),
		_succs = {},
		_data = {},
		_prev = prev_tree,
	}
end

function M:new(opts, name)
	local inst = make_initial_node()
	opts = opts or {}
	inst._data.opts_raw = opts
	inst._data.opts_merged = opts
	inst._data.desc = name

	local obj = setmetatable(inst, {
		__index = M,
		__tostring = function(obj)
			return vim.inspect(obj)
		end,
	})

	return obj
end

local function add(tree, value, seq, prev_opts, prev_tree)
	assert(tree)
	local key, next_seq = util.split_vim_key(seq)
	if key then
		-- keep traversing until key is nil
		local merged_opts = util.merge_opts(prev_opts, tree._data.opts_raw)
		tree._data.opts_merged = merged_opts
		local next_tree = tree._succs[key]
		if not next_tree then
			tree._succs[key] = make_initial_node(tree)
			next_tree = tree._succs[key]
		end
		return add(tree._succs[key], value, next_seq, merged_opts, tree)
	end

	local opts_raw = value and value.opts_raw
	local merged_opts = util.merge_opts(prev_opts, opts_raw)

	-- insert
	if value then
		local old = tree and vim.deepcopy(tree)
		if old then
			old = mt(old)
		end

		tree._prev = prev_tree
		tree._data = value
		tree._data.opts_merged = merged_opts

		on_update(mt(tree), old)
	else
		-- value == nil is used to refresh merged_opts on updates
		tree._prev = prev_tree
		tree._data.opts_merged = merged_opts
	end

	-- update merged_opts for all successors
	for _, succ in pairs(tree._succs) do
		-- NOTE: calling add with a nil value only merges the opts
		add(succ, nil, "", merged_opts, tree)
	end

	return mt(tree)
end

local function get(tree, seq)
	assert(tree)
	local key, next_seq = util.split_vim_key(seq)
	if key then
		local next_tree = tree._succs[key]
		if not next_tree then
			return
		end
		return get(next_tree, next_seq)
	end
	return mt(tree)
end

local function remove(tree, seq)
	local key, next_seq = util.split_vim_key(seq)
	if key then
		if next_seq and next_seq ~= "" then
			local next_tree = tree._succs[key]
			return remove(next_tree, next_seq)
		end
		local old = tree._succs[key]
		local old_data = old._data and vim.deepcopy(old._data)

		tree._succs[key] = nil

		if old_data then
			on_remove(old_data)
		end
		return true
	end

	return false
end

-- @param[opt=nil] seq
function M:add(value, seq)
	seq, value = parse_key(value, seq)
	return add(self, value, seq, self:opts(), self:pred())
end

function M:update_opts()
	return add(self, nil, "", self:opts(), self:pred())
end

function M:get(seq)
	return get(self, seq)
end

function M:remove(seq)
	assert(seq and string.len(seq) > 0)
	return remove(self, seq)
end

function M:get_id()
	return self.id
end

return setmetatable(M, {
	__call = function(self, ...)
		return self:new(...)
	end,
})

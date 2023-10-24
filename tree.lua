local vim = require("motion.lib.vim")
local util = require("motion.util")
local dump = vim.inspect

local M = {}

local id = 0
local function get_id()
	id = id + 1
	return id
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

	local t = type(key)

	if t == "string" then
		seq = key
	else
		assert(t == "table")
		for k, v in pairs(key) do
			t = type(v)
			if t == "string" then
				-- can be key, desc, without mods
				if k == "desc" or k == "description" then
					assert(not desc, "multiple descrptions")
					desc = v
				else
					assert(not seq, "multiple undeclared strings")
					seq = v
				end
			elseif t == "table" then
				if k == "opts" then
					assert(not opts, "multiple opts")
					opts = v
				elseif k == "result" then
					assert(not result, "multiple result")
					result = v
				else
					assert(not opts, "multiple opts")
					opts = v
				end
			elseif t == "function" then
				-- can be fn, condition, desc with mods
				if k == "cond" or k == "condition" then
					assert(not cond, "multiple conditions")
					cond = v
				elseif k == "desc" then
					desc = v
				else
					assert(not fn, "multiple undeclared functions")
					fn = v
				end
			end
		end
	end

	if not seq then
		seq = table_index
	end

	return seq, {
		fn = fn,
		opts_raw = opts,
		cond = cond,
		desc = desc,
		result = result,
	}
end

function M:opts()
	return self._data.opts_merged
end

function M:opts_merged() -- alias
	return M:opts()
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

function M:pred()
	return self._prev
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

function M:add_successors(succs)
	for k, succ in pairs(succs) do
		local seq, value = parse_key(succ, k)
		M:add(value, seq)
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

local mt = function(obj)
	return setmetatable(obj, {
		__index = M,
		__tostring = function(t)
			return vim.inspect(t)
		end,
	})
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

local function add(tree, value, seq, prev_opts)
	assert(tree)
	local key, next_seq = util.split_vim_key(seq)
	if key then
		local opts_raw = tree._data.opts_raw
		local merged_opts = util.merge_opts(opts_raw, prev_opts)
		-- keep traversing until key is nil
		local next_tree = tree._succs[key]
		if not next_tree then
			tree._succs[key] = make_initial_node(tree)
			next_tree = tree._succs[key]
		end
		return add(tree._succs[key], value, next_seq, merged_opts)
	end

	local opts_raw = value and value.opts_raw
	local merged_opts = util.merge_opts(opts_raw, prev_opts)

	-- insert
	if value then
		tree._data = value
	end
	tree._data.opts_merged = merged_opts

	-- update merged_opts for all successors
	for _, succ in pairs(tree._succs) do
		-- NOTE: calling add with a nil value only merges the opts
		add(succ, nil, "", merged_opts)
	end

	return mt(tree)
end

local function get(tree, seq)
	assert(tree)
	-- FIXME:
	if type(seq) == "table" then
		print("get table: ", dump(seq._data))
	end
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

local function remove(tree, seq, prev_opts)
	local key, next_seq = util.split_vim_key(seq)
	if key then
		local opts_raw = tree._data.opts_raw
		local merged_opts = util.merge_opts(opts_raw, prev_opts)
		local next_tree = tree._succs[key]
		if not next_tree then
			return false
		end
		return remove(next_tree, next_seq, merged_opts)
	end

	-- update opts_merged for successors
	if vim.tbl_count(tree._data.opts_raw) > 0 then
		for _, succ in pairs(tree._succs) do
			add(succ, nil, "", prev_opts)
		end
	end

	tree._data = {}

	return true
end

-- @param[opt=nil] seq
function M:add(value, seq)
	seq, value = parse_key(value, seq)
	return add(self, value, seq, self:opts())
end

function M:update_opts()
	return add(self, nil, "", self:opts())
end

function M:get(seq)
	print("tree.lua:get: ", seq)
	return get(self, seq)
end

function M:remove(seq)
	assert(seq and string.len(seq) > 0)
	return remove(self, seq, self:opts())
end

function M:get_id()
	return self.id
end

return setmetatable(M, {
	__call = function(self, ...)
		return self:new(...)
	end,
})

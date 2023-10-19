local config = require("motion.config")
local util = require("motion.util")
local vim = require("motion.vim")
local dump = require("motion.vim").inspect

local M = {}

local root_tree = {}

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
	local pre
	local post

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
				assert(not opts, "multiple tables")
				opts = v
			elseif t == "function" then
				-- can be fn, condition, desc with mods
				if k == "cond" or k == "condition" then
					assert(not cond, "multiple conditions")
					cond = v
				elseif k == "desc" then
					desc = v
				elseif k == "pre" then
					pre = v
				elseif k == "post" then
					post = v
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
		opts = opts,
		cond = cond,
		desc = desc,
		pre = pre,
		post = post,
	}
end

local function _remove(seq, tree)
	-- tree has no children
	local succs = rawget(tree, "_succs")
	if not succs then
		return
	end

	local key, next_seq = util.split_vim_key(seq)

	local next_tree = rawget(succs, key)
	if not next_tree then
		return
	end

	if next_seq then
		-- we're not yet done traversing the tree
		return _remove(next_seq, next_tree)
	end

	-- we've reached the node

	-- -- if there are no children, we can delete the whole node
	-- local children_char_children = rawget(children_char, "_succs")
	-- if not children_char_children or vim.tbl_count(children_char_children) == 0 then
	-- 	rawset(children, char, nil)
	-- 	return
	-- end

	-- node has children, therefore we can only delete data
	rawset(next_tree, "_data", nil)
end

local function remove(seq, tree)
	assert(tree)
	assert(seq)
	assert(string.len(seq) > 0)

	_remove(seq, tree)
end

local function _add(value, tree, seq)
	local key, next_seq = util.split_vim_key(seq)

	if key then
		-- init children
		rawset(tree, "_succs", rawget(tree, "_succs") or {})
		local succs = rawget(tree, "_succs")
		-- init children[char]
		rawset(succs, key, rawget(succs, key) or { data = { id = get_id() } })
		local next_tree = rawget(succs, key)
		return _add(value, next_tree, next_seq)
	end

	rawset(value, "id", get_id())

	-- add/overwrite only the data, keep children
	rawset(tree, "_data", value)
end

local function add(value, tree, seq)
	assert(tree)
	seq, value = parse_key(value, seq)
	assert(seq)
	assert(string.len(seq) > 0)
	return _add(value, tree, seq)
end

local function get(seq, tree, prev_opts, prev_tree)
	if not tree then
		return nil
	end

	local key, next_seq = util.split_vim_key(seq)

	local opts
	-- node has data stored
	if rawget(tree, "_data") then
		-- merge previous opts with current
		local data = rawget(tree, "_data")
		opts = util.merge_opts(prev_opts, rawget(data, "opts"))
	else
		-- we have to merge anyways to get rid of unique opts from predecessor
		opts = util.merge_opts(prev_opts, {})
	end

	if key then
		-- keep traversing until key is nil
		local next_tree
		local succs = rawget(tree, "_succs")
		if succs then
			next_tree = rawget(succs, key)
		end

		-- create prev tree copy for backtracking
		local current_data = rawget(tree, "_data") and vim.deepcopy(rawget(tree, "_data")) or {}
		rawset(current_data, "opts", opts)

		local current_succs = succs and vim.deepcopy(succs) or {}
		local current_prev = rawget(tree, "_prev") and vim.deepcopy(rawget(tree, "_prev")) or prev_tree
		prev_tree = M.mt({ _data = current_data, _succs = current_succs, _prev = current_prev })

		return get(next_seq, next_tree, opts, prev_tree)
	end

	-- no more traversing
	local data = rawget(tree, "_data") and vim.deepcopy(rawget(tree, "_data")) or {}
	local succs = rawget(tree, "_succs") and vim.deepcopy(rawget(tree, "_succs")) or {}

	-- set opts to merged opts instead of node opts
	rawset(data, "opts", opts)

	local ret = { _data = data, _succs = succs, _prev = prev_tree }

	return M.mt(ret)
end

function M.mt(obj, tree, load_default_opts)
	if not obj then
		return
	end

	tree = tree or obj

	obj.fn = function(_, opts)
		local data = rawget(obj, "_data")
		if not data then
			return nil
		end
		local fn = rawget(data, "fn")

		if fn then
			return fn(opts, obj)
		end
	end

	obj.pre = function(_, opts)
		local data = rawget(obj, "_data")
		if not data then
			return nil
		end
		local pre = rawget(data, "pre")

		if pre then
			return pre(opts, obj)
		end
	end

	obj.post = function(_, opts)
		local data = rawget(obj, "_data")
		if not data then
			return nil
		end
		local post = rawget(data, "post")

		if post then
			return post(opts, obj)
		end
	end

	obj.pred = function()
		return rawget(obj, "_prev")
	end

	obj.cond = function()
		local data = rawget(obj, "_data")
		if not data then
			return true
		end

		local cond = rawget(data, "cond")

		if cond == nil then
			return true
		end

		if type(cond) == "function" then
			return cond()
		end

		return cond
	end
	obj.opts = function()
		local data = rawget(obj, "_data")
		if not data then
			return nil
		end

		return rawget(data, "opts")
	end

	obj.desc = function()
		local data = rawget(obj, "_data")
		if not data then
			return nil
		end

		local desc = rawget(data, "desc")

		if desc and type(desc) == "function" then
			return desc()
		end

		return desc
	end

	obj.id = function()
		local data = rawget(obj, "_data")
		if not data then
			return nil
		end

		return rawget(data, "id")
	end

	obj.successors = function()
		local children = rawget(obj, "_succs")
		if not children or vim.tbl_count(obj) == 0 then
			return children
		end
		local succs = {}
		for k in pairs(children) do
			succs[k] = obj[k]
		end
		return succs
	end

	obj.remove_successors = function()
		local children = rawget(obj, "_succs")
		if not children then
			return
		end
		rawset(obj, "_succs", {})
	end

	obj.add_successors = function(self, succs)
		for k, succ in pairs(succs) do
			local path, key = parse_key(succ, k)
			add(key, self, path)
		end
	end

	obj.is_leaf = function(self)
		local children = rawget(obj, "_succs")
		if not children then
			return true
		end
		return vim.tbl_count(children) == 0
	end

	-- aliases
	obj.succs = obj.successors
	obj.description = obj.desc
	obj.condition = obj.cond
	obj.predecessor = obj.pred

	return setmetatable(obj, {
		__index = function(_, k)
			-- only get defaults opts on root_tree
			return get(k, tree, load_default_opts and config.get() or {})
		end,
		__newindex = function(_, k, v)
			if v == nil then
				remove(k, tree)
				return
			end
			add(v, tree, k)
		end,
		__tostring = function(t)
			return dump(t)
		end,
		__call = function(_, _)
			assert(false, "not implemented")
		end,
	})
end

function M.add_key(key)
	add(key, root_tree, nil)
end

function M.add_keys(keys)
	for k, v in pairs(keys) do
		add(v, root_tree, k)
	end
end

-- custom opts
function M.get(seq, opts)
	seq = seq or ""
	return get(seq, root_tree, config.get(opts) or {})
end

-- create inline tree

-- @param[opt=""] name
-- @param[opt=config.get()] opts
function M.create_tree(succs, opts, name)
	local root = {
		data = {
			desc = name,
			id = get_id(),
		},
	}

	local t = get("", root, config.get(opts))
	if not t then
		return
	end

	t:add_successors(succs)

	return t
end

function M.setup(opts)
	root_tree.data = {
		id = get_id(),
		desc = "motion",
		name = opts.key,
	}
end

return M.mt(M, root_tree, true)

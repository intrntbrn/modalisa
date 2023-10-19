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

local function _remove(index, tree)
	-- tree has no children
	local children = rawget(tree, "children")
	if not children then
		return
	end

	local char, next = util.split_vim_key(index)

	-- tree does not contain char
	local children_char = rawget(children, char)
	if not children_char then
		return
	end

	if next then
		-- we're not yet done traversing the tree
		return _remove(next, children_char)
	end

	-- we've reached the node

	-- -- if there are no children, we can delete the whole node
	-- local children_char_children = rawget(children_char, "children")
	-- if not children_char_children or vim.tbl_count(children_char_children) == 0 then
	-- 	rawset(children, char, nil)
	-- 	return
	-- end

	-- node has children, therefore we can only delete data
	rawset(children_char, "data", nil)
end

local function remove(index, tree)
	assert(tree)
	assert(index)
	assert(string.len(index) > 0)

	_remove(index, tree)
end

local function _add(succ, tree, index)
	local char, next = util.split_vim_key(index)

	if char then
		-- init children
		rawset(tree, "children", rawget(tree, "children") or {})
		local children = rawget(tree, "children")
		-- init children[char]
		rawset(children, char, rawget(children, char) or { data = { id = get_id() } })
		local children_char = rawget(children, char)
		return _add(succ, children_char, next)
	end

	rawset(succ, "id", get_id())

	-- add/overwrite only the data, keep children
	rawset(tree, "data", succ)
end

-- @param[opt=""] prefix
local function add(succ, tree, path, prefix)
	assert(tree)
	path, succ = util.parse_key(succ, path)
	assert(path)
	assert(string.len(path) > 0)
	if prefix then
		assert(type(prefix) == "string", "prefix is a not a string")
		path = string.format("%s%s", prefix, path)
	end
	return _add(succ, tree, path)
end

local function get(index, tree, prev_opts, prev_tree)
	if not tree then
		return nil
	end

	local c, suffix = util.split_vim_key(index)

	-- node has data stored
	if rawget(tree, "data") then
		-- merge previous opts with current
		local data = rawget(tree, "data")
		prev_opts = util.merge_opts(prev_opts, rawget(data, "opts"))
	else
		-- we have to merge anyways to get rid of unique opts from predecessor
		prev_opts = util.merge_opts(prev_opts, {})
	end

	if c then
		-- keep traversing until c is nil
		local next_tree
		local children = rawget(tree, "children")
		if children then
			next_tree = rawget(children, c)
		end

		-- create prev tree copy for backtracking
		local tree_data = rawget(tree, "data") and vim.deepcopy(rawget(tree, "data")) or {}
		rawset(tree_data, "opts", prev_opts)

		local tree_children = children and vim.deepcopy(children) or {}
		local prev = rawget(tree, "prev") and vim.deepcopy(rawget(tree, "prev")) or prev_tree
		prev_tree = M.mt({ prev = prev, data = tree_data, children = tree_children })

		return get(suffix, next_tree, prev_opts, prev_tree)
	end

	-- no more traversing
	local data = rawget(tree, "data") and vim.deepcopy(rawget(tree, "data")) or {}
	local children = rawget(tree, "children") and vim.deepcopy(rawget(tree, "children")) or {}

	-- set opts to merged opts instead of node opts
	rawset(data, "opts", prev_opts)

	local ret = { data = data, children = children, prev = prev_tree }

	return M.mt(ret)
end

function M.mt(obj, tree, load_default_opts)
	if not obj then
		return
	end

	tree = tree or obj

	obj.fn = function(_, opts)
		local data = rawget(obj, "data")
		if not data then
			return nil
		end
		local fn = rawget(data, "fn")

		if fn then
			return fn(opts, obj)
		end
	end

	obj.pred = function()
		return rawget(obj, "prev")
	end
	obj.predecessor = obj.pred

	obj.cond = function()
		local data = rawget(obj, "data")
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
	obj.condition = obj.cond

	obj.opts = function()
		local data = rawget(obj, "data")
		if not data then
			return nil
		end

		return rawget(data, "opts")
	end

	obj.desc = function()
		local data = rawget(obj, "data")
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
		local data = rawget(obj, "data")
		if not data then
			return nil
		end

		return rawget(data, "id")
	end

	obj.description = obj.desc

	obj.successors = function()
		local children = rawget(obj, "children")
		if not children or vim.tbl_count(obj) == 0 then
			return children
		end
		local succs = {}
		for k in pairs(children) do
			succs[k] = obj[k]
		end
		return succs
	end
	obj.succs = obj.successors

	obj.remove_successors = function()
		local children = rawget(obj, "children")
		if not children then
			return
		end
		rawset(obj, "children", {})
	end

	obj.add_successors = function(self, succs)
		for k, succ in pairs(succs) do
			local path, key = util.parse_key(succ, k)
			add(key, self, path)
		end
	end

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

-- @param[opt=""] prefix
function M.add_key(key, prefix)
	add(key, root_tree, nil, prefix)
end

-- @param[opt=""] prefix
function M.add_keys(keys, prefix)
	for k, v in pairs(keys) do
		add(v, root_tree, k, prefix)
	end
end

-- custom opts
function M.get(key, opts)
	key = key or ""
	return get(key, root_tree, config.get(opts) or {})
end

-- create inline tree

-- @param[opt=""] name
-- @param[opt=config.get()] opts
function M.create_tree(successors, opts, name)
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

	t:add_successors(successors)

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

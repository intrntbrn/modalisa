local config = require("motion.config")
local util = require("motion.util")
local vim = require("motion.vim")
local dump = require("motion.vim").inspect

-- TODO:
-- get_raw methods

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
	local echo

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
				elseif k == "echo" then
					assert(not echo, "multiple echo")
					echo = v
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
		echo = echo,
	}
end

local function _remove(seq, tree)
	-- tree has no succs
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

	-- node has succs, therefore we can only delete data
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
		-- init succs
		rawset(tree, "_succs", rawget(tree, "_succs") or {})
		local succs = rawget(tree, "_succs")
		-- init succs[char]
		rawset(succs, key, rawget(succs, key) or { ["_data"] = { id = get_id() } })
		local next_tree = rawget(succs, key)
		return _add(value, next_tree, next_seq)
	end

	rawset(value, "id", get_id())

	-- add/overwrite only the data, keep succs
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

	local data_raw = rawget(tree, "_data")
	-- node has data stored
	if data_raw then
		-- merge previous opts with current
		opts = util.merge_opts(prev_opts, rawget(data_raw, "opts"))
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
		prev_tree = M.mt({ ["_data"] = current_data, ["_succs"] = current_succs, ["_prev"] = current_prev })

		return get(next_seq, next_tree, opts, prev_tree)
	end

	-- no more traversing
	local data = rawget(tree, "_data") and vim.deepcopy(rawget(tree, "_data")) or {}
	local succs = rawget(tree, "_succs") and vim.deepcopy(rawget(tree, "_succs")) or {}

	-- set opts to merged opts instead of node opts
	rawset(data, "opts", opts)

	local ret = { ["_data"] = data, ["_succs"] = succs, ["_prev"] = prev_tree }

	return M.mt(ret)
end

function M.mt(self)
	local merge_opts = {}
	local tree = self

	-- inject root_tree methods and metatables on M
	if self == M then
		merge_opts = config.get()
		tree = root_tree
	end

	self.fn = function(_, opts)
		local data = rawget(self, "_data")
		if not data then
			return nil
		end
		local fn = rawget(data, "fn")

		if fn then
			return fn(opts, self)
		end
	end

	self.pre = function(_, opts)
		local data = rawget(self, "_data")
		if not data then
			return nil
		end
		local pre = rawget(data, "pre")

		if pre then
			return pre(opts, self)
		end
	end

	self.post = function(_, opts)
		local data = rawget(self, "_data")
		if not data then
			return nil
		end
		local post = rawget(data, "post")

		if post then
			return post(opts, self)
		end
	end

	self.pred = function()
		return rawget(self, "_prev")
	end

	self.cond = function()
		local data = rawget(self, "_data")
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
	self.opts = function()
		local data = rawget(self, "_data")
		if not data then
			return nil
		end

		return rawget(data, "opts")
	end

	self.desc = function()
		local data = rawget(self, "_data")
		if not data then
			return nil
		end

		local desc = rawget(data, "desc")

		if desc and type(desc) == "function" then
			return desc()
		end

		return desc
	end

	self.echo = function()
		local data = rawget(self, "_data")
		if not data then
			return nil
		end

		local echo = rawget(data, "echo")
		return echo
	end

	self.id = function()
		local data = rawget(self, "_data")
		if not data then
			return nil
		end

		return rawget(data, "id")
	end

	self.successors = function()
		local rawsuccs = rawget(self, "_succs")
		if not rawsuccs or vim.tbl_count(self) == 0 then
			return rawsuccs
		end
		local succs = {}
		for k in pairs(rawsuccs) do
			succs[k] = self[k]
		end
		return succs
	end

	self.remove_successors = function()
		local succs = rawget(self, "_succs")
		if not succs then
			return
		end
		rawset(self, "_succs", {})
	end

	self.add_successors = function(_, succs)
		for k, succ in pairs(succs) do
			local path, key = parse_key(succ, k)
			add(key, self, path)
		end
	end

	self.is_leaf = function(_)
		local succs = rawget(self, "_succs")
		if not succs then
			return true
		end
		return vim.tbl_count(succs) == 0
	end

	-- aliases
	self.succs = self.successors
	self.description = self.desc
	self.condition = self.cond
	self.predecessor = self.pred

	return setmetatable(self, {
		__index = function(_, k)
			-- only get defaults opts on root_tree
			return get(k, tree, merge_opts)
		end,
		__newindex = function(_, k, v)
			if v == nil or type(v) == "table" and vim.tbl_count(v) == 0 then
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

return M.mt(M) -- add methods and metatables from root_tree

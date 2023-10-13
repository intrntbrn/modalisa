local M = {}

local unpack = unpack or table.unpack

local dump = require("motion.vim").inspect

M.labels_qwerty = "asdfghjklwertyuiozxcvbnmpqASDFGHJKLQWERTYUIOPZXCVBNM1234567890"
M.labels_numericalpha = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

function M.merge_opts(a, b)
	a = a or {}
	b = b or {}
	-- print("merge_opts: ", dump(a), dump(b))
	local uniques = vim.tbl_deep_extend("force", a.unique or {}, b.unique or {})

	for _, k in pairs(uniques) do
		if a[k] then
			a[k] = nil
		end
	end

	local all = { a, b }
	local ret = vim.tbl_deep_extend("force", unpack(all))

	-- print("merge_opts ret: ", dump(ret))

	return ret
end

function M.keyname(k)
	-- we are forced to remove the <> surrounding,
	-- otherwise the key is interpreted as a tag in widgets
	_, _, key = string.find(k, "<(.+)>")
	if key then
		k = key
	end

	return k
end

function M.split_key(str)
	if not str or string.len(str) == 0 then
		return nil, nil
	end
	local regex

	-- e.g. <Tab> or <F10>
	regex = "<%w+>"
	if string.match(str, string.format("^%s", regex)) then
		for first in string.gmatch(str, regex) do
			local rest = string.gsub(str, regex, "", 1)
			return first, rest
		end
	end

	-- e.g. <A-C-Tab>
	regex = "<[%u%-]+%w+>"
	if string.match(str, string.format("^%s", regex)) then
		for first in string.gmatch(str, regex) do
			local rest = string.gsub(str, regex, "", 1)
			return first, rest
		end
	end

	-- use the first character
	local first = string.sub(str, 1, 1)
	local rest = string.gsub(str, "^.", "", 1)

	return first, rest
end

-- parse a loosely defined key
-- @param key string|table The key object to be parsed
-- @param index string The key string if the key object does not contain the key string
function M.parse_key(key, index)
	local path
	local fn
	local opts
	local cond
	local desc

	local t = type(key)

	if t == "string" then
		path = key
	else
		assert(t == "table")
		for k, v in pairs(key) do
			t = type(v)
			if t == "string" then
				-- can be key, desc, without mods
				if k == "desc" or k == "description" then
					assert(not desc, "multiple desc")
					desc = v
				else
					assert(not path, "multiple strings")
					path = v
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
				else
					assert(not fn, "multiple functions")
					fn = v
				end
			end
		end
	end

	if not path then
		path = index
	end

	return path, {
		fn = fn,
		opts = opts,
		cond = cond,
		desc = desc,
	}
end

function M.parse_keybind(keybind)
	local t = type(keybind)
	if t == "string" then
		return { mods = {}, key = keybind }
	else
		assert(t == "table", "keybind is not a table")
		local key
		local mods
		for _, v in pairs(keybind) do
			if type(v) == "table" then
				assert(mods == nil)
				mods = v
			elseif type(v) == "string" then
				assert(key == nil)
				key = v
			end
		end
		assert(key)
		return { mods = mods or {}, key = key }
	end
end

---@param i number index to convert
---@param labels string labels
-- return string Converted index
function M.index_to_label(i, labels)
	labels = labels or M.labels_numericalpha
	return string.sub(labels, i, i)
end

---@param fn function Function to run confirmation
---@param desc_yes string Text description of yes option
---@param desc_no string Text description of no option
---@return table Confirmation menu
function M.confirmation_menu(fn, desc_yes, desc_no)
	return {
		{
			"y",
			desc = desc_yes or "yes",
			fn = fn,
		},
		{
			"n",
			desc = desc_no or "no",
		},
	}
end

return M

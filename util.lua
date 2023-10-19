local M = {}

local unpack = unpack or table.unpack

local dump = require("motion.vim").inspect
local beautiful = require("beautiful")
local gstring = require("gears.string")

M.labels_qwerty = "asdfghjklwertyuiozxcvbnmpqASDFGHJKLQWERTYUIOPZXCVBNM1234567890"
M.labels_numericalpha = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

local wrap, yield = coroutine.wrap, coroutine.yield
-- This function clones the array t and appends the item new to it.
local function _append(t, new)
	local clone = {}
	for _, item in ipairs(t) do
		clone[#clone + 1] = item
	end
	clone[#clone + 1] = new
	return clone
end

--[[
    Yields combinations of non-repeating items of tbl.
    tbl is the source of items,
    sub is a combination of items that all yielded combination ought to contain,
    min it the minimum key of items that can be added to yielded combinations.
--]]
function M.unique_combinations(tbl, sub, min)
	sub = sub or {}
	min = min or 1
	return wrap(function()
		if #sub > 0 then
			yield(sub) -- yield short combination.
		end
		if #sub < #tbl then
			for i = min, #tbl do -- iterate over longer combinations.
				for combo in M.unique_combinations(tbl, _append(sub, tbl[i]), i + 1) do
					yield(combo)
				end
			end
		end
	end)
end

function M.merge_opts(a, b)
	a = a or {}
	b = b or {}
	local uniques = vim.tbl_deep_extend("force", a.unique or {}, b.unique or {})

	for _, k in pairs(uniques) do
		if a[k] then
			a[k] = nil
		end
	end

	local all = { a, b }
	local ret = vim.tbl_deep_extend("force", unpack(all))

	return ret
end

function M.keyname(k, aliases)
	-- we are forced to remove the <> surrounding,
	-- otherwise the key is interpreted as a tag in widgets
	_, _, key = string.find(k, "<(.+)>")
	if key then
		k = key
	end

	local escaped = gstring.xml_escape(k)
	if escaped then
		k = escaped
	end

	if aliases then
		for s, v in pairs(aliases) do
			k = string.gsub(k, s, v)
		end
	end

	return k
end

function M.split_vim_key(str)
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

-- input: { { "mods" }, "key" }
-- output: { mods = { "mods" }, key = "key" }
function M.parse_awesome_key(keybind)
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

-- https://gist.github.com/basaran/28b0f6c33e619ef481a097fdec480e38
-- Converts hexadecimal color to HSL
-- Lightness (L) is changed based on amt
-- Converts HSL back to hex
-- amt (0-100) can be negative to darken or positive to lighten
-- The amt specified is added to the color's existing Lightness
-- e.g., (#000000, 25) L = 25 but (#404040, 25) L = 50

function M.lighten(hex_color, amt)
	-- Rounds to whole number
	local function round(num)
		return math.floor(num + 0.5)
	end
	-- Rounds to hundredths
	local function roundH(num)
		return math.floor((num * 100) + 0.5) / 100
	end

	local r, g, b, a
	local hex = hex_color:gsub("#", "")
	if #hex < 6 then
		local t = {}
		for i = 1, #hex do
			local char = hex:sub(i, i)
			t[i] = char .. char
		end
		hex = table.concat(t)
	end
	r = tonumber(hex:sub(1, 2), 16) / 255
	g = tonumber(hex:sub(3, 4), 16) / 255
	b = tonumber(hex:sub(5, 6), 16) / 255
	if #hex ~= 6 then
		a = roundH(tonumber(hex:sub(7, 8), 16) / 255)
	end

	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local c = max - min
	-----------------------------
	-- Hue
	local h
	if c == 0 then
		h = 0
	elseif max == r then
		h = ((g - b) / c) % 6
	elseif max == g then
		h = ((b - r) / c) + 2
	elseif max == b then
		h = ((r - g) / c) + 4
	end
	h = h * 60
	-----------------------------
	-- Luminance
	local l = (max + min) * 0.5
	-----------------------------
	-- Saturation
	local s
	if l <= 0.5 then
		s = c / (l * 2)
	elseif l > 0.5 then
		s = c / (2 - (l * 2))
	end
	-----------------------------
	local H, S, L, A
	H = round(h) / 360
	S = round(s * 100) / 100
	L = round(l * 100) / 100

	amt = amt / 100
	if L + amt > 1 then
		L = 1
	elseif L + amt < 0 then
		L = 0
	else
		L = L + amt
	end

	local R, G, B
	if S == 0 then
		R, G, B = round(L * 255), round(L * 255), round(L * 255)
	else
		local function hue2rgb(p, q, t)
			if t < 0 then
				t = t + 1
			end
			if t > 1 then
				t = t - 1
			end
			if t < 1 / 6 then
				return p + (q - p) * (6 * t)
			end
			if t < 1 / 2 then
				return q
			end
			if t < 2 / 3 then
				return p + (q - p) * (2 / 3 - t) * 6
			end
			return p
		end
		local q
		if L < 0.5 then
			q = L * (1 + S)
		else
			q = L + S - (L * S)
		end
		local p = 2 * L - q
		R = round(hue2rgb(p, q, (H + 1 / 3)) * 255)
		G = round(hue2rgb(p, q, H) * 255)
		B = round(hue2rgb(p, q, (H - 1 / 3)) * 255)
	end

	if a ~= nil then
		A = round(a * 255)
		return string.format("#" .. "%.2x%.2x%.2x%.2x", R, G, B, A)
	else
		return string.format("#" .. "%.2x%.2x%.2x", R, G, B)
	end
end

-- Stripped copy of this module https://github.com/copycat-killer/lain/blob/master/util/markup.lua:
local rgba = require("gears.color").to_rgba_string
M.markup = {}
-- Set the font.
function M.markup.font(font, text)
	return '<span font="' .. tostring(font) .. '">' .. tostring(text) .. "</span>"
end
-- Set the foreground.
function M.markup.fg(color, text)
	return string.format("<span foreground='%s'>%s</span>", color, text)
end
-- Set the background.
function M.markup.bg(color, text)
	return '<span background="' .. rgba(color, beautiful.bg_normal) .. '">' .. tostring(text) .. "</span>"
end

-- https://stackoverflow.com/questions/9790688/escaping-strings-for-gsub/20778724#20778724
local quotepattern = "([" .. ("%^$().[]*+-?"):gsub("(.)", "%%%1") .. "])"
M.quote = function(str)
	return str:gsub(quotepattern, "%%%1")
end

function M.benchmark(f, n, ...)
	do
		local units = {
			["seconds"] = 1,
			["milliseconds"] = 1000,
			["microseconds"] = 1000000,
			["nanoseconds"] = 1000000000,
		}

		---@diagnostic disable-next-line: redefined-local
		local function benchmark(unit, decPlaces, n, f, ...)
			local elapsed = 0
			local multiplier = units[unit]
			for i = 1, n do
				local now = os.clock()
				f(...)
				elapsed = elapsed + (os.clock() - now)
			end
			print(
				string.format(
					"Benchmark results: %d function calls | %."
						.. decPlaces
						.. "f %s elapsed | %."
						.. decPlaces
						.. "f %s avg execution time.",
					n,
					elapsed * multiplier,
					unit,
					(elapsed / n) * multiplier,
					unit
				)
			)
		end

		benchmark("milliseconds", 1, n, f, ...)
	end
end

return M

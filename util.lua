local M = {}

local unpack = unpack or table.unpack

local beautiful = require("beautiful")
local gstring = require("gears.string")
local awful = require("awful")
local vim = require("motion.lib.vim")
local lighten = require("motion.lib.lighten")

M.labels_qwerty = "asdfghjklwertyuiozxcvbnmpqASDFGHJKLQWERTYUIOPZXCVBNM1234567890"
M.labels_numericalpha = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

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

M.markup = {}
function M.markup.fg(color, text)
	return string.format("<span foreground='%s'>%s</span>", color, text)
end

-- https://stackoverflow.com/questions/9790688/escaping-strings-for-gsub/20778724#20778724
local quotepattern = "([" .. ("%^$().[]*+-?"):gsub("(.)", "%%%1") .. "])"
M.quote = function(str)
	return str:gsub(quotepattern, "%%%1")
end

function M.get_font_width(font)
	local _, _, width = string.find(font, "[%s]+([0-9]+)")
	-- TODO: figure out the default font size that awesome uses
	return width or 10
end

local function calc_pixel_count(property, v, s)
	if v >= 0 and v <= 1 then
		s = s or awful.screen.focused()
		local geo = screen[s.index].geometry[property]
		return math.floor(v * geo)
	end
	return v
end

function M.get_pixel_width(v, s)
	return calc_pixel_count("width", v, s)
end

function M.get_pixel_height(v, s)
	return calc_pixel_count("width", v, s)
end

function M.color_or_luminosity(v, other_color)
	if type(v) == "string" then
		return v
	end
	if type(v) == "number" then
		return lighten.lighten(other_color, v)
	end
end

return M

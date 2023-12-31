local M = {}

local unpack = unpack or table.unpack

local gstring = require("gears.string")
local awful = require("awful")
local vim = require("modalisa.lib.vim")
local lighten = require("modalisa.lib.lighten")
local glib = require("lgi").GLib

M.labels_qwerty = "asdfghjklwertyuiozxcvbnmpqASDFGHJKLQWERTYUIOPZXCVBNM1234567890!\"#$%&'()*+,-./:;<=>?@\\^_`{|}~"
M.labels_numericalpha = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@\\^_`{|}~"

function M.find_index(name, tbl, labels)
	local first_char = string.sub(name, 1, 1)
	if not tbl[first_char] then
		return first_char
	end

	for i = 1, string.len(labels) do
		local c = string.sub(labels, i, i)
		if not tbl[c] then
			return c
		end
	end

	error("unable to find index")
end

function M.merge_opts(a, b)
	if not b then
		return vim.deepcopy(a)
	end

	local merged = vim.tbl_deep_extend("force", a, b)
	merged = vim.deepcopy(merged)

	return merged
end

function M.keyname(k, aliases)
	-- remove <> surrounding
	_, _, key = string.find(k, "<(.+)>")
	if key then
		k = key
	end

	local escaped = gstring.xml_escape(k)
	if escaped then
		k = escaped
	end

	local count
	if aliases then
		for s, v in pairs(aliases) do
			k, count = string.gsub(k, s, v)
			if count ~= 0 then
				break
			end
		end
	end

	return k
end

function M.split_vim_key(str)
	if not str or string.len(str) == 0 then
		return nil, nil
	end

	local all = {
		"<.*>",
		"%u",
		"[%w%s]",
		"%p",
	}

	for _, regex in ipairs(all) do
		if string.match(str, string.format("^%s", regex)) then
			for first in string.gmatch(str, regex) do
				local rest = string.gsub(str, regex, "", 1)
				return first, rest
			end
		end
	end

	assert(false, "unable to parse key:", str)
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
function M.markup.fg(text, color)
	return string.format("<span foreground='%s'>%s</span>", color, text)
end
function M.markup.bold(text)
	return string.format("<b>%s</b>", text)
end
function M.markup.italic(text)
	return string.format("<i>%s</i>", text)
end
function M.markup.strikethrough(text)
	return string.format("<s>%s</s>", text)
end
function M.markup.underline(text)
	return string.format("<u>%s</u>", text)
end

function M.apply_highlight(text, highlight)
	if not highlight then
		return text
	end
	for k, v in pairs(highlight) do
		if type(v) == "boolean" and v then
			local m = M.markup[k]
			if m then
				text = m(text)
			end
		end
	end

	return text
end

function M.get_font_width(font)
	local _, _, width = string.find(font, "[%s]+([0-9]+)")
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

function M.get_screen_pixel_width(v, s)
	return calc_pixel_count("width", v, s)
end

function M.get_screen_pixel_height(v, s)
	return calc_pixel_count("height", v, s)
end

function M.color_or_luminosity(v, other_color)
	if type(v) == "string" then
		return v
	end
	if type(v) == "number" then
		return lighten.lighten(other_color, v)
	end
end

function M.run_on_idle(f)
	glib.idle_add(glib.PRIORITY_DEFAULT_IDLE, f)
end

function M.scandir(directory)
	local i, t, popen = 0, {}, io.popen
	local pfile = popen('ls -a "' .. directory .. '"')
	if not pfile then
		return
	end
	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename
	end
	pfile:close()
	return t
end

return M

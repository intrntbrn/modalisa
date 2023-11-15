local fs = require("gears.filesystem")
local vim = require("modalisa.lib.vim")
local util = require("modalisa.util")
local mt = require("modalisa.presets.metatable")
---@diagnostic disable-next-line: unused-local
local dump = require("modalisa.lib.vim").inspect

local M = {}

local function file_suffix(f)
	local suffix = f:match("[^.]+$")
	return suffix
end

local function dir_name(dir)
	dir = string.gsub(dir, "/$", "")

	local _, dirname = dir:match("^(.*/)([^/]-)$")
	return dirname
end

function M.filter_image(f)
	local types = { "png", "jpg", "jpeg" }
	local suffix = file_suffix(f)
	suffix = string.lower(suffix)

	if vim.tbl_contains(types, suffix) then
		return true
	end
	return false
end

local function concat_dir_file(dir, file)
	if not string.find(dir, "/$") then
		dir = dir .. "/"
	end
	local f = string.format("%s%s", dir, file)
	return f
end

local function make_file(dir, file, fn)
	return {
		desc = file,
		group = "file",
		fn = function()
			local f = concat_dir_file(dir, file)
			fn(f)
		end,
	}
end

function M.file_picker(dir, fn, max_depth, filter)
	return mt({
		desc = dir_name(dir),
		group = "dir",
		is_menu = true,
		fn = function(opts)
			local fdir = util.scandir(dir)
			if not fdir then
				return
			end

			max_depth = max_depth or 0

			local files = {}
			local dirs = {}

			for _, fd in pairs(fdir) do
				local f = concat_dir_file(dir, fd)
				if fs.is_dir(f) then
					table.insert(dirs, fd)
				else
					if not filter or filter(fd) then
						table.insert(files, fd)
					end
				end
			end

			local labels = opts.labels or util.labels_qwerty
			local entries = {}

			if max_depth > 0 then
				for _, d in pairs(dirs) do
					if d ~= "." and d ~= ".." then
						local index = util.find_index(d, entries, labels)
						if not index then
							break
						end
						local entry = M.file_picker(concat_dir_file(dir, d), fn, max_depth - 1)
						entries[index] = entry
					end
				end
			end

			for _, f in pairs(files) do
				local index = util.find_index(f, entries, labels)
				if not index then
					break
				end
				local entry = make_file(dir, f, fn)
				entries[index] = entry
			end
			return entries
		end,
	})
end

return M

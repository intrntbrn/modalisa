local vim = require("modalisa.lib.vim")
local inspect = require("modalisa.lib.inspect")
local lighten = require("modalisa.lib.lighten")
local benchmark = require("modalisa.lib.benchmark")
local combination = require("modalisa.lib.combination")

local M = vim.tbl_deep_extend("error", vim, lighten, benchmark, combination)

return M

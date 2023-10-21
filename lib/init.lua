local vim = require("motion.lib.vim")
local inspect = require("motion.lib.inspect")
local lighten = require("motion.lib.lighten")
local benchmark = require("motion.lib.benchmark")
local combination = require("motion.lib.combination")

local M = vim.tbl_deep_extend("error", vim, lighten, benchmark, combination)

return M

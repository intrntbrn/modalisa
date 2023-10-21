local client = require("motion.awesome.client")
local tag = require("motion.awesome.tag")
local layout = require("motion.awesome.layout")
local awm = require("motion.awesome.awm")

local M = vim.tbl_deep_extend("error", client, tag, layout, awm)

return M

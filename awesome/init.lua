local client = require("modalisa.awesome.client")
local tag = require("modalisa.awesome.tag")
local layout = require("modalisa.awesome.layout")
local awm = require("modalisa.awesome.awm")

local M = vim.tbl_deep_extend("error", client, tag, layout, awm)

return M

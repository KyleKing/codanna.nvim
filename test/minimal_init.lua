--- Minimal init for running tests
--- This sets up the Lua path to find plugin modules

local M = {}

-- Add plugin directory to package path
local plugin_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
vim.opt.rtp:append(plugin_dir)

-- Add plenary if available (for testing)
local plenary_dir = plugin_dir .. "/.test-deps/plenary.nvim"
if vim.fn.isdirectory(plenary_dir) == 1 then
  vim.opt.rtp:append(plenary_dir)
end

return M

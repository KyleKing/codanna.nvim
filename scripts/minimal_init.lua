--- Minimal init for running tests with mini.test
--- Sets up the environment to load the plugin and mini.test

-- Add current directory to runtime path
vim.opt.rtp:append(vim.fn.getcwd())

-- Add mini.nvim to runtime path
local mini_path = vim.fn.getcwd() .. "/.test-deps/mini.nvim"
if vim.fn.isdirectory(mini_path) == 1 then
  vim.opt.rtp:append(mini_path)
end

-- Load mini.test
require("mini.test")

-- Disable other plugins
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

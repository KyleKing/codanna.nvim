--- Minimal init for running tests with mini.test
--- Sets up the environment to load the plugin and mini.test

-- Determine the project root directory
-- This script is in <project>/scripts/minimal_init.lua
local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = vim.fn.fnamemodify(script_path, ":h")
local project_dir = vim.fn.fnamemodify(script_dir, ":h")

-- Add project directory to runtime path
vim.opt.rtp:append(project_dir)

-- Add mini.nvim to runtime path
local mini_path = project_dir .. "/.test-deps/mini.nvim"
if vim.fn.isdirectory(mini_path) == 1 then
  vim.opt.rtp:append(mini_path)
else
  error(string.format("mini.nvim not found at %s. Run 'make deps' first.", mini_path))
end

-- Load mini.test
local ok, minitest = pcall(require, "mini.test")
if not ok then
  error("Failed to load mini.test. Ensure mini.nvim is properly installed in .test-deps/mini.nvim")
end

-- Disable other plugins
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

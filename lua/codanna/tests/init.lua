-- Test runner for codanna.nvim

local M = {}

local SPEC_DIR = "lua/codanna/tests"

local function run_files(files)
    local MiniTest = require("mini.test")
    MiniTest.run({
        collect = {
            find_files = function() return files end,
        },
    })
end

function M.run_all()
    local files = vim.fn.glob(SPEC_DIR .. "/*_spec.lua", false, true)
    if #files == 0 then error("No *_spec.lua files found in " .. SPEC_DIR) end
    table.sort(files)
    run_files(files)
end

return M

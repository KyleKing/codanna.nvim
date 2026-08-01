--- Integration tests for codanna.nvim with real codanna CLI
--- Tests against real indexed repositories
--- Run with: nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua MiniTest.run_file('test/test_integration.lua')"

local new_set = MiniTest.new_set

local T = new_set({
    hooks = {
        pre_once = function()
            -- Setup runs once before all tests
            -- Verify codanna is available
            local utils = require("codanna.utils")
            if not utils.command_exists("codanna") then
                error("codanna CLI not found - integration tests require codanna to be installed")
            end
        end,
    },
})

local core = require("codanna.core")
local utils = require("codanna.utils")
local eq = MiniTest.expect.equality
local is_nil = function(x) MiniTest.expect.equality(x, nil) end

-- Helper to check if we're in a test repo directory
local function in_test_repo()
    local cwd = vim.fn.getcwd()
    return cwd:match("test%-repos") ~= nil
end

-- Integration tests for semantic search
T["semantic_search"] = new_set()

T["semantic_search"]["returns results for valid query"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    local data, err = core.semantic_search("function", { limit = 5 })

    -- Should not error
    is_nil(err)

    -- Should return data
    MiniTest.expect.no_equality(data, nil)

    -- Data should be a table or array
    eq(type(data), "table")
end

T["semantic_search"]["handles empty query gracefully"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    local data, err = core.semantic_search("", { limit = 5 })

    -- May error or return empty, both acceptable
    if not err then eq(type(data), "table") end
end

-- Integration tests for search_symbols
T["search_symbols"] = new_set()

T["search_symbols"]["returns results for valid query"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    local data, err = core.search_symbols("main", { limit = 5 })

    is_nil(err)
    MiniTest.expect.no_equality(data, nil)
    eq(type(data), "table")
end

-- Integration tests for get_index_info
T["get_index_info"] = new_set()

T["get_index_info"]["returns index information"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    local data, err = core.get_index_info()

    is_nil(err)
    MiniTest.expect.no_equality(data, nil)

    -- Should have symbol_count or file_count
    if data then
        local has_counts = data.symbol_count ~= nil or data.file_count ~= nil
        eq(has_counts, true)
    end
end

-- Integration tests for result extraction
T["result_extraction"] = new_set()

T["result_extraction"]["extracts and normalizes search results"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    local data, err = core.semantic_search("test", { limit = 10 })

    if err or not data then
        MiniTest.skip("No data returned from search")
        return
    end

    local results = utils.extract_results(data)
    eq(type(results), "table")

    -- If we have results, verify normalization works
    if #results > 0 then
        local normalized = utils.normalize_result(results[1])
        if normalized then
            -- Should have required fields
            MiniTest.expect.no_equality(normalized.name, nil)
            -- File field is optional but should be present for file-based results
            -- lnum and col should be numbers
            if normalized.lnum then eq(type(normalized.lnum), "number") end
            if normalized.col then eq(type(normalized.col), "number") end
        end
    end
end

-- Integration tests for async operations
T["async_operations"] = new_set()

T["async_operations"]["semantic_search_async works"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    local done = false
    local result_data = nil
    local result_err = nil

    core.semantic_search_async("function", { limit = 3 }, function(data, err)
        result_data = data
        result_err = err
        done = true
    end)

    -- Wait for async operation (max 5 seconds)
    local timeout = 5000
    local waited = 0
    while not done and waited < timeout do
        vim.wait(100)
        waited = waited + 100
    end

    eq(done, true)
    is_nil(result_err)
    MiniTest.expect.no_equality(result_data, nil)
end

-- Integration tests for cache
T["cache"] = new_set()

T["cache"]["caches repeated queries"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    core.clear_cache()

    -- First query - should hit codanna
    local _data1, err1 = core.semantic_search("cache_test_query_12345", { limit = 5 })

    -- Second identical query - should be cached
    local start_time = vim.uv.now()
    local _data2, err2 = core.semantic_search("cache_test_query_12345", { limit = 5 })
    local elapsed = vim.uv.now() - start_time

    -- Cached query should be very fast (< 50ms)
    -- This is a heuristic but cached queries should be near-instant
    MiniTest.expect.equality(elapsed < 50, true)

    -- Results should be identical (or both nil/error)
    eq(err1, err2)
end

-- Integration tests for error handling
T["error_handling"] = new_set()

T["error_handling"]["handles non-existent symbol gracefully"] = function()
    if not in_test_repo() then
        MiniTest.skip("Not in test repo directory")
        return
    end

    -- Query for a symbol that's very unlikely to exist
    local data, err = core.find_callers("nonexistent_symbol_xyz_123456")

    -- Should not crash, either returns empty or error
    if err then
        eq(type(err), "string")
    else
        local results = utils.extract_results(data)
        eq(type(results), "table")
    end
end

return T

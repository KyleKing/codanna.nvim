--- Tests for codanna.core module using mini.test
--- Run with: nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua MiniTest.run()"

local new_set = MiniTest.new_set

local T = new_set({
    hooks = {
        pre_case = function()
            -- Reset state before each test
            local core = require("codanna.core")
            core.clear_cache()
            core.invalidate_index_cache()
            core._binary_validated = false
        end,
    },
})

local core = require("codanna.core")
local eq = MiniTest.expect.equality
local is_nil = function(x) MiniTest.expect.equality(x, nil) end

-- Cache tests
T["cache"] = new_set()

T["cache"]["clears cache when requested"] = function()
    core.clear_cache()
    is_nil(core.get_index_status())
end

-- Index status tests
T["index status"] = new_set()

T["index status"]["returns nil initially"] = function()
    local status = core.get_index_status()
    is_nil(status)
end

T["index status"]["can be invalidated"] = function()
    core.invalidate_index_cache()
    local status = core.get_index_status()
    is_nil(status)
end

-- Configuration tests
T["configuration"] = new_set()

T["configuration"]["has default configuration"] = function()
    eq(core.config.codanna_path, "codanna")
    eq(core.config.timeout_ms, 10000)
    eq(core.config.cache_ttl_ms, 5000)
end

T["configuration"]["can be configured"] = function()
    core.setup({
        codanna_path = "custom/path/codanna",
        timeout_ms = 15000,
        cache_ttl_ms = 8000,
    })

    eq(core.config.codanna_path, "custom/path/codanna")
    eq(core.config.timeout_ms, 15000)
    eq(core.config.cache_ttl_ms, 8000)
end

T["configuration"]["validates configuration on setup"] = function()
    -- This should trigger a warning but not fail
    core.setup({
        timeout_ms = -100, -- Invalid
    })
    -- Config should still be set (with warning)
    eq(core.config.timeout_ms, -100)
end

-- API functions exist tests
T["API functions"] = new_set()

T["API functions"]["exposes semantic_search"] = function() eq(type(core.semantic_search), "function") end

T["API functions"]["exposes semantic_search_async"] = function() eq(type(core.semantic_search_async), "function") end

T["API functions"]["exposes search_symbols"] = function() eq(type(core.search_symbols), "function") end

T["API functions"]["exposes search_symbols_async"] = function() eq(type(core.search_symbols_async), "function") end

T["API functions"]["exposes find_callers"] = function() eq(type(core.find_callers), "function") end

T["API functions"]["exposes find_callers_async"] = function() eq(type(core.find_callers_async), "function") end

T["API functions"]["exposes get_calls"] = function() eq(type(core.get_calls), "function") end

T["API functions"]["exposes get_calls_async"] = function() eq(type(core.get_calls_async), "function") end

T["API functions"]["exposes analyze_impact"] = function() eq(type(core.analyze_impact), "function") end

T["API functions"]["exposes analyze_impact_async"] = function() eq(type(core.analyze_impact_async), "function") end

T["API functions"]["exposes search_documents"] = function() eq(type(core.search_documents), "function") end

T["API functions"]["exposes search_documents_async"] = function() eq(type(core.search_documents_async), "function") end

T["API functions"]["exposes get_index_info"] = function() eq(type(core.get_index_info), "function") end

T["API functions"]["exposes get_index_info_async"] = function() eq(type(core.get_index_info_async), "function") end

T["API functions"]["exposes check_index_async"] = function() eq(type(core.check_index_async), "function") end

T["API functions"]["exposes notify_empty_results"] = function() eq(type(core.notify_empty_results), "function") end

-- Error-envelope regression: codanna writes its JSON error to stdout even on
-- non-zero exit, so stderr-only handling loses the message, hint, and the
-- ambiguity candidates the hint tells the caller to use.
T["exec error envelope"] = new_set()

local function stub_codanna(body, exit_code)
    local path = vim.fn.tempname() .. ".sh"
    vim.fn.writefile({ "#!/bin/sh", "cat <<'EOF'", vim.json.encode(body), "EOF", "exit " .. exit_code }, path)
    vim.fn.setfperm(path, "rwx------")
    return path
end

local function with_stub(path, fn)
    local original = { core.config.codanna_path, core.config.timeout_ms, core._binary_validated }
    core.config.codanna_path = path
    core.config.timeout_ms = 10000
    core._binary_validated = nil
    local ok, a, b = pcall(fn)
    core.config.codanna_path, core.config.timeout_ms, core._binary_validated = original[1], original[2], original[3]
    os.remove(path)
    assert(ok, a)
    return a, b
end

T["exec error envelope"]["exec surfaces stdout envelope on non-zero exit"] = function()
    local stub = stub_codanna({
        status = "error",
        exit_code = 2,
        message = "Ambiguous: found 2 symbol(s) named 'url_for'",
        hint = "re-run with symbol_id:<id>",
        data = { { id = 221, file_path = "src/helpers.py", line = 195, kind = "Function" } },
    }, 2)

    local data, err = with_stub(stub, function() return core.exec("mcp", { "find_callers", "url_for" }) end)
    is_nil(data)
    MiniTest.expect.no_equality((err or ""):find("Ambiguous"), nil)
    MiniTest.expect.no_equality((err or ""):find("symbol_id:221", 1, true), nil)
end

T["exec error envelope"]["exec_async surfaces stdout envelope on non-zero exit"] = function()
    local stub = stub_codanna({
        status = "error",
        exit_code = 2,
        message = "Ambiguous: found 2 symbol(s) named 'url_for'",
        hint = "re-run with symbol_id:<id>",
        data = { { id = 221, file_path = "src/helpers.py", line = 195, kind = "Function" } },
    }, 2)

    local done, data, err = false, nil, nil
    with_stub(stub, function()
        core.exec_async("mcp", { "find_callers", "url_for" }, function(d, e)
            data, err, done = d, e, true
        end)
        vim.wait(5000, function() return done end)
    end)
    eq(done, true)
    is_nil(data)
    MiniTest.expect.no_equality((err or ""):find("symbol_id:221", 1, true), nil)
end

return T

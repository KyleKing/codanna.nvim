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

T["API functions"]["exposes semantic_search"] = function()
  eq(type(core.semantic_search), "function")
end

T["API functions"]["exposes semantic_search_async"] = function()
  eq(type(core.semantic_search_async), "function")
end

T["API functions"]["exposes search_symbols"] = function()
  eq(type(core.search_symbols), "function")
end

T["API functions"]["exposes search_symbols_async"] = function()
  eq(type(core.search_symbols_async), "function")
end

T["API functions"]["exposes find_callers"] = function()
  eq(type(core.find_callers), "function")
end

T["API functions"]["exposes find_callers_async"] = function()
  eq(type(core.find_callers_async), "function")
end

T["API functions"]["exposes get_calls"] = function()
  eq(type(core.get_calls), "function")
end

T["API functions"]["exposes get_calls_async"] = function()
  eq(type(core.get_calls_async), "function")
end

T["API functions"]["exposes analyze_impact"] = function()
  eq(type(core.analyze_impact), "function")
end

T["API functions"]["exposes analyze_impact_async"] = function()
  eq(type(core.analyze_impact_async), "function")
end

T["API functions"]["exposes search_documents"] = function()
  eq(type(core.search_documents), "function")
end

T["API functions"]["exposes search_documents_async"] = function()
  eq(type(core.search_documents_async), "function")
end

T["API functions"]["exposes get_index_info"] = function()
  eq(type(core.get_index_info), "function")
end

T["API functions"]["exposes get_index_info_async"] = function()
  eq(type(core.get_index_info_async), "function")
end

T["API functions"]["exposes check_index_async"] = function()
  eq(type(core.check_index_async), "function")
end

T["API functions"]["exposes notify_empty_results"] = function()
  eq(type(core.notify_empty_results), "function")
end

return T

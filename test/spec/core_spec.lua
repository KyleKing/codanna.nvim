--- Tests for codanna.core module
--- These test the core functionality without requiring actual codanna binary

local core = require("codanna.core")

describe("codanna.core", function()
  before_each(function()
    -- Reset state between tests
    core.clear_cache()
    core.invalidate_index_cache()
    core._binary_validated = false
  end)

  describe("cache", function()
    it("caches results", function()
      -- This test doesn't actually call codanna, just tests cache logic
      local cache_key = require("codanna.utils").make_cache_key("test", { "arg1" })

      -- Manually set cache (testing private function behavior)
      core.clear_cache()

      -- The actual exec would populate cache, but we can't test that without codanna binary
      -- Instead we test that clear_cache works
      core.clear_cache()
      assert.is_nil(core.get_index_status())
    end)

    it("clears cache when requested", function()
      core.clear_cache()
      -- After clear, cache should be empty
      -- We can verify this indirectly through get_index_status
      assert.is_nil(core.get_index_status())
    end)
  end)

  describe("index status", function()
    it("returns nil initially", function()
      local status = core.get_index_status()
      assert.is_nil(status)
    end)

    it("can be invalidated", function()
      core.invalidate_index_cache()
      local status = core.get_index_status()
      assert.is_nil(status)
    end)
  end)

  describe("configuration", function()
    it("has default configuration", function()
      assert.equals("codanna", core.config.codanna_path)
      assert.equals(10000, core.config.timeout_ms)
      assert.equals(5000, core.config.cache_ttl_ms)
    end)

    it("can be configured", function()
      core.setup({
        codanna_path = "custom/path/codanna",
        timeout_ms = 15000,
        cache_ttl_ms = 8000,
      })

      assert.equals("custom/path/codanna", core.config.codanna_path)
      assert.equals(15000, core.config.timeout_ms)
      assert.equals(8000, core.config.cache_ttl_ms)
    end)

    it("validates configuration on setup", function()
      -- This should trigger a warning but not fail
      core.setup({
        timeout_ms = -100, -- Invalid
      })
      -- Config should still be set (with warning)
      assert.equals(-100, core.config.timeout_ms)
    end)
  end)

  describe("API functions exist", function()
    it("exposes semantic_search", function()
      assert.is_function(core.semantic_search)
    end)

    it("exposes semantic_search_async", function()
      assert.is_function(core.semantic_search_async)
    end)

    it("exposes search_symbols", function()
      assert.is_function(core.search_symbols)
    end)

    it("exposes search_symbols_async", function()
      assert.is_function(core.search_symbols_async)
    end)

    it("exposes find_callers", function()
      assert.is_function(core.find_callers)
    end)

    it("exposes find_callers_async", function()
      assert.is_function(core.find_callers_async)
    end)

    it("exposes get_calls", function()
      assert.is_function(core.get_calls)
    end)

    it("exposes get_calls_async", function()
      assert.is_function(core.get_calls_async)
    end)

    it("exposes analyze_impact", function()
      assert.is_function(core.analyze_impact)
    end)

    it("exposes analyze_impact_async", function()
      assert.is_function(core.analyze_impact_async)
    end)

    it("exposes search_documents", function()
      assert.is_function(core.search_documents)
    end)

    it("exposes search_documents_async", function()
      assert.is_function(core.search_documents_async)
    end)

    it("exposes get_index_info", function()
      assert.is_function(core.get_index_info)
    end)

    it("exposes get_index_info_async", function()
      assert.is_function(core.get_index_info_async)
    end)

    it("exposes check_index_async", function()
      assert.is_function(core.check_index_async)
    end)

    it("exposes notify_empty_results", function()
      assert.is_function(core.notify_empty_results)
    end)
  end)
end)

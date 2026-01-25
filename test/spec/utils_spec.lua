--- Tests for codanna.utils module
--- Run with: nvim --headless -c "PlenaryBustedDirectory test/spec/ { minimal_init = 'test/minimal_init.lua' }"

local utils = require("codanna.utils")

describe("codanna.utils", function()
  describe("normalize_result", function()
    it("handles nil input", function()
      local result = utils.normalize_result(nil)
      assert.is_nil(result)
    end)

    it("normalizes result with file_path field", function()
      local input = {
        name = "test_func",
        kind = "function",
        file_path = "/path/to/file.lua",
        range = { start_line = 10, start_column = 5 },
      }
      local result = utils.normalize_result(input)

      assert.equals("test_func", result.name)
      assert.equals("function", result.kind)
      assert.equals("/path/to/file.lua", result.file)
      assert.equals(11, result.lnum) -- 0-indexed to 1-indexed
      assert.equals(5, result.col)
    end)

    it("normalizes result with file field", function()
      local input = {
        name = "TestClass",
        kind = "class",
        file = "src/test.py",
        line = 20,
        column = 0,
      }
      local result = utils.normalize_result(input)

      assert.equals("TestClass", result.name)
      assert.equals("class", result.kind)
      assert.equals("src/test.py", result.file)
      assert.equals(21, result.lnum)
      assert.equals(0, result.col)
    end)

    it("normalizes result with path field", function()
      local input = {
        symbol = "MY_CONST",
        kind = "constant",
        path = "config.rs",
        lnum = 5,
        col = 10,
      }
      local result = utils.normalize_result(input)

      assert.equals("MY_CONST", result.name)
      assert.equals("constant", result.kind)
      assert.equals("config.rs", result.file)
      assert.equals(5, result.lnum) -- already 1-indexed
      assert.equals(10, result.col)
    end)

    it("handles nested array format", function()
      local input = { {
        name = "nested_func",
        file = "test.js",
      } }
      local result = utils.normalize_result(input)

      assert.equals("nested_func", result.name)
      assert.equals("test.js", result.file)
    end)

    it("uses default values when fields missing", function()
      local input = { file = "test.txt" }
      local result = utils.normalize_result(input)

      assert.equals("unknown", result.name)
      assert.is_nil(result.kind)
      assert.equals("test.txt", result.file)
      assert.equals(1, result.lnum)
      assert.equals(0, result.col)
    end)

    it("handles missing range fields gracefully", function()
      local input = {
        name = "test",
        file = "test.lua",
        range = {},
      }
      local result = utils.normalize_result(input)

      assert.equals(1, result.lnum)
      assert.equals(0, result.col)
    end)
  end)

  describe("extract_results", function()
    it("returns empty array for nil", function()
      local results = utils.extract_results(nil)
      assert.same({}, results)
    end)

    it("returns array as-is when data is already an array", function()
      local input = { { name = "a" }, { name = "b" } }
      local results = utils.extract_results(input)
      assert.same(input, results)
    end)

    it("extracts results field from object", function()
      local input = {
        results = { { name = "a" }, { name = "b" } },
        metadata = { count = 2 },
      }
      local results = utils.extract_results(input)
      assert.same({ { name = "a" }, { name = "b" } }, results)
    end)

    it("returns empty array for object without results", function()
      local input = { metadata = { count = 0 } }
      local results = utils.extract_results(input)
      assert.same({}, results)
    end)
  end)

  describe("validate_symbol", function()
    it("accepts valid symbol", function()
      local symbol, err = utils.validate_symbol("my_function")
      assert.equals("my_function", symbol)
      assert.is_nil(err)
    end)

    it("rejects nil symbol", function()
      local symbol, err = utils.validate_symbol(nil)
      assert.is_nil(symbol)
      assert.matches("No symbol provided", err)
    end)

    it("rejects empty string", function()
      local symbol, err = utils.validate_symbol("")
      assert.is_nil(symbol)
      assert.matches("No symbol provided", err)
    end)

    it("rejects whitespace-only string", function()
      local symbol, err = utils.validate_symbol("   \t  ")
      assert.is_nil(symbol)
      assert.matches("only whitespace", err)
    end)

    it("trims whitespace from valid symbol", function()
      local symbol, err = utils.validate_symbol("  my_func  ")
      assert.equals("my_func", symbol)
      assert.is_nil(err)
    end)
  end)

  describe("validate_config", function()
    it("accepts valid config", function()
      local config = {
        timeout_ms = 5000,
        cache_ttl_ms = 3000,
        debounce_ms = 150,
        preferred_picker = "telescope",
      }
      local validated, err = utils.validate_config(config)
      assert.is_nil(err)
      assert.same(config, validated)
    end)

    it("rejects negative timeout", function()
      local config = { timeout_ms = -100 }
      local validated, err = utils.validate_config(config)
      assert.matches("must be non%-negative", err)
    end)

    it("warns about low timeout", function()
      local config = { timeout_ms = 500 }
      local validated, err = utils.validate_config(config)
      assert.matches("at least 1000ms", err)
    end)

    it("rejects non-number timeout", function()
      local config = { timeout_ms = "5000" }
      local validated, err = utils.validate_config(config)
      assert.matches("must be a number", err)
    end)

    it("rejects invalid picker name", function()
      local config = { preferred_picker = "invalid" }
      local validated, err = utils.validate_config(config)
      assert.matches("must be one of", err)
    end)

    it("warns about high debounce", function()
      local config = { debounce_ms = 2000 }
      local validated, err = utils.validate_config(config)
      assert.matches("should not exceed 1000ms", err)
    end)

    it("returns all errors concatenated", function()
      local config = {
        timeout_ms = "bad",
        cache_ttl_ms = -5,
      }
      local validated, err = utils.validate_config(config)
      assert.matches("timeout_ms", err)
      assert.matches("cache_ttl_ms", err)
    end)
  end)

  describe("make_cache_key", function()
    it("creates unique keys for different commands", function()
      local key1 = utils.make_cache_key("search", { "query1" })
      local key2 = utils.make_cache_key("symbols", { "query1" })
      assert.is_not.equals(key1, key2)
    end)

    it("creates unique keys for different args", function()
      local key1 = utils.make_cache_key("search", { "query1" })
      local key2 = utils.make_cache_key("search", { "query2" })
      assert.is_not.equals(key1, key2)
    end)

    it("handles special characters in args", function()
      -- This was a bug in the original implementation
      local key1 = utils.make_cache_key("search", { "foo:bar" })
      local key2 = utils.make_cache_key("search", { "foo", "bar" })
      assert.is_not.equals(key1, key2)
    end)

    it("handles empty args", function()
      local key = utils.make_cache_key("search", {})
      assert.is_not_nil(key)
    end)
  end)

  describe("parse_json_response", function()
    it("parses valid JSON response", function()
      local stdout = '{"status": "success", "data": {"results": []}}'
      local data, err = utils.parse_json_response(stdout)
      assert.is_nil(err)
      assert.same({ results = {} }, data)
    end)

    it("handles JSON with log prefix", function()
      local stdout = [[
[INFO] Loading index...
[DEBUG] Processing query...
{"status": "success", "data": {"count": 5}}
]]
      local data, err = utils.parse_json_response(stdout)
      assert.is_nil(err)
      assert.equals(5, data.count)
    end)

    it("returns error for empty response", function()
      local data, err = utils.parse_json_response("")
      assert.is_nil(data)
      assert.matches("Empty response", err)
    end)

    it("returns error when no JSON found", function()
      local stdout = "Only log messages here\nNo JSON"
      local data, err = utils.parse_json_response(stdout)
      assert.is_nil(data)
      assert.matches("No JSON object found", err)
    end)

    it("returns error for malformed JSON", function()
      local stdout = '{"status": "success", "data": invalid}'
      local data, err = utils.parse_json_response(stdout)
      assert.is_nil(data)
      assert.matches("Failed to parse", err)
    end)

    it("handles error status in response", function()
      local stdout = '{"status": "error", "message": "Index not found"}'
      local data, err = utils.parse_json_response(stdout)
      assert.is_nil(data)
      assert.matches("Index not found", err)
    end)

    it("handles error status without message", function()
      local stdout = '{"status": "error"}'
      local data, err = utils.parse_json_response(stdout)
      assert.is_nil(data)
      assert.matches("Unknown error", err)
    end)
  end)

  describe("command_exists", function()
    it("returns true for existing command", function()
      -- 'ls' should exist on any Unix-like system
      local exists = utils.command_exists("ls")
      assert.is_true(exists)
    end)

    it("returns false for non-existing command", function()
      local exists = utils.command_exists("nonexistent_command_12345")
      assert.is_false(exists)
    end)
  end)
end)

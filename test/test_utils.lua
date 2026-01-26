--- Tests for codanna.utils module using mini.test
--- Run with: nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua MiniTest.run()"

local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      -- Setup before each test case
    end,
  },
})

local utils = require("codanna.utils")
local eq = MiniTest.expect.equality
local is_nil = function(x) MiniTest.expect.equality(x, nil) end

-- normalize_result tests
T["normalize_result()"] = new_set()

T["normalize_result()"]["handles nil input"] = function()
  local result = utils.normalize_result(nil)
  is_nil(result)
end

T["normalize_result()"]["normalizes result with file_path field"] = function()
  local input = {
    name = "test_func",
    kind = "function",
    file_path = "/path/to/file.lua",
    range = { start_line = 10, start_column = 5 },
  }
  local result = utils.normalize_result(input)

  eq(result.name, "test_func")
  eq(result.kind, "function")
  eq(result.file, "/path/to/file.lua")
  eq(result.lnum, 11) -- 0-indexed to 1-indexed
  eq(result.col, 5)
end

T["normalize_result()"]["normalizes result with file field"] = function()
  local input = {
    name = "TestClass",
    kind = "class",
    file = "src/test.py",
    line = 20,
    column = 0,
  }
  local result = utils.normalize_result(input)

  eq(result.name, "TestClass")
  eq(result.kind, "class")
  eq(result.file, "src/test.py")
  eq(result.lnum, 21)
  eq(result.col, 0)
end

T["normalize_result()"]["normalizes result with path field"] = function()
  local input = {
    symbol = "MY_CONST",
    kind = "constant",
    path = "config.rs",
    lnum = 5,
    col = 10,
  }
  local result = utils.normalize_result(input)

  eq(result.name, "MY_CONST")
  eq(result.kind, "constant")
  eq(result.file, "config.rs")
  eq(result.lnum, 5) -- already 1-indexed
  eq(result.col, 10)
end

T["normalize_result()"]["handles nested array format"] = function()
  local input = { {
    name = "nested_func",
    file = "test.js",
  } }
  local result = utils.normalize_result(input)

  eq(result.name, "nested_func")
  eq(result.file, "test.js")
end

T["normalize_result()"]["uses default values when fields missing"] = function()
  local input = { file = "test.txt" }
  local result = utils.normalize_result(input)

  eq(result.name, "unknown")
  is_nil(result.kind)
  eq(result.file, "test.txt")
  eq(result.lnum, 1)
  eq(result.col, 0)
end

T["normalize_result()"]["handles missing range fields gracefully"] = function()
  local input = {
    name = "test",
    file = "test.lua",
    range = {},
  }
  local result = utils.normalize_result(input)

  eq(result.lnum, 1)
  eq(result.col, 0)
end

-- extract_results tests
T["extract_results()"] = new_set()

T["extract_results()"]["returns empty array for nil"] = function()
  local results = utils.extract_results(nil)
  eq(vim.tbl_count(results), 0)
end

T["extract_results()"]["returns array as-is when data is already an array"] = function()
  local input = { { name = "a" }, { name = "b" } }
  local results = utils.extract_results(input)
  eq(results, input)
end

T["extract_results()"]["extracts results field from object"] = function()
  local input = {
    results = { { name = "a" }, { name = "b" } },
    metadata = { count = 2 },
  }
  local results = utils.extract_results(input)
  eq(results[1].name, "a")
  eq(results[2].name, "b")
end

T["extract_results()"]["returns empty array for object without results"] = function()
  local input = { metadata = { count = 0 } }
  local results = utils.extract_results(input)
  eq(vim.tbl_count(results), 0)
end

-- validate_symbol tests
T["validate_symbol()"] = new_set()

T["validate_symbol()"]["accepts valid symbol"] = function()
  local symbol, err = utils.validate_symbol("my_function")
  eq(symbol, "my_function")
  is_nil(err)
end

T["validate_symbol()"]["rejects nil symbol"] = function()
  local symbol, err = utils.validate_symbol(nil)
  is_nil(symbol)
  MiniTest.expect.no_equality(err, nil)
end

T["validate_symbol()"]["rejects empty string"] = function()
  local symbol, err = utils.validate_symbol("")
  is_nil(symbol)
  MiniTest.expect.no_equality(err, nil)
end

T["validate_symbol()"]["rejects whitespace-only string"] = function()
  local symbol, err = utils.validate_symbol("   \t  ")
  is_nil(symbol)
  MiniTest.expect.no_equality(err, nil)
end

T["validate_symbol()"]["trims whitespace from valid symbol"] = function()
  local symbol, err = utils.validate_symbol("  my_func  ")
  eq(symbol, "my_func")
  is_nil(err)
end

-- validate_config tests
T["validate_config()"] = new_set()

T["validate_config()"]["accepts valid config"] = function()
  local config = {
    timeout_ms = 5000,
    cache_ttl_ms = 3000,
    debounce_ms = 150,
    preferred_picker = "telescope",
  }
  local validated, err = utils.validate_config(config)
  is_nil(err)
  eq(validated.timeout_ms, 5000)
end

T["validate_config()"]["rejects negative timeout"] = function()
  local config = { timeout_ms = -100 }
  local validated, err = utils.validate_config(config)
  MiniTest.expect.no_equality(err, nil)
end

T["validate_config()"]["warns about low timeout"] = function()
  local config = { timeout_ms = 500 }
  local validated, err = utils.validate_config(config)
  MiniTest.expect.no_equality(err, nil)
end

T["validate_config()"]["rejects non-number timeout"] = function()
  local config = { timeout_ms = "5000" }
  local validated, err = utils.validate_config(config)
  MiniTest.expect.no_equality(err, nil)
end

T["validate_config()"]["rejects invalid picker name"] = function()
  local config = { preferred_picker = "invalid" }
  local validated, err = utils.validate_config(config)
  MiniTest.expect.no_equality(err, nil)
end

T["validate_config()"]["warns about high debounce"] = function()
  local config = { debounce_ms = 2000 }
  local validated, err = utils.validate_config(config)
  MiniTest.expect.no_equality(err, nil)
end

-- make_cache_key tests
T["make_cache_key()"] = new_set()

T["make_cache_key()"]["creates unique keys for different commands"] = function()
  local key1 = utils.make_cache_key("search", { "query1" })
  local key2 = utils.make_cache_key("symbols", { "query1" })
  MiniTest.expect.no_equality(key1, key2)
end

T["make_cache_key()"]["creates unique keys for different args"] = function()
  local key1 = utils.make_cache_key("search", { "query1" })
  local key2 = utils.make_cache_key("search", { "query2" })
  MiniTest.expect.no_equality(key1, key2)
end

T["make_cache_key()"]["handles special characters in args without collision"] = function()
  local key1 = utils.make_cache_key("search", { "foo:bar,baz" })
  local key2 = utils.make_cache_key("search", { "foo:bar", "baz" })
  local key3 = utils.make_cache_key("search", { "foo", "bar,baz" })
  MiniTest.expect.no_equality(key1, key2)
  MiniTest.expect.no_equality(key1, key3)
  MiniTest.expect.no_equality(key2, key3)
end

T["make_cache_key()"]["handles empty args"] = function()
  local key = utils.make_cache_key("search", {})
  MiniTest.expect.no_equality(key, nil)
end

T["make_cache_key()"]["handles nil args"] = function()
  local key = utils.make_cache_key("search", nil)
  MiniTest.expect.no_equality(key, nil)
end

-- parse_json_response tests
T["parse_json_response()"] = new_set()

T["parse_json_response()"]["parses valid JSON response"] = function()
  local stdout = '{"status": "success", "data": {"results": []}}'
  local data, err = utils.parse_json_response(stdout)
  is_nil(err)
  eq(vim.tbl_count(data.results), 0)
end

T["parse_json_response()"]["handles JSON with log prefix"] = function()
  local stdout = [[
[INFO] Loading index...
[DEBUG] Processing query...
{"status": "success", "data": {"count": 5}}
]]
  local data, err = utils.parse_json_response(stdout)
  is_nil(err)
  eq(data.count, 5)
end

T["parse_json_response()"]["returns error for empty response"] = function()
  local data, err = utils.parse_json_response("")
  is_nil(data)
  MiniTest.expect.no_equality(err, nil)
end

T["parse_json_response()"]["returns error when no JSON found"] = function()
  local stdout = "Only log messages here\nNo JSON"
  local data, err = utils.parse_json_response(stdout)
  is_nil(data)
  MiniTest.expect.no_equality(err, nil)
end

T["parse_json_response()"]["returns error for malformed JSON"] = function()
  local stdout = '{"status": "success", "data": invalid}'
  local data, err = utils.parse_json_response(stdout)
  is_nil(data)
  MiniTest.expect.no_equality(err, nil)
end

T["parse_json_response()"]["handles error status in response"] = function()
  local stdout = '{"status": "error", "message": "Index not found"}'
  local data, err = utils.parse_json_response(stdout)
  is_nil(data)
  MiniTest.expect.no_equality(err, nil)
end

T["parse_json_response()"]["handles error status without message"] = function()
  local stdout = '{"status": "error"}'
  local data, err = utils.parse_json_response(stdout)
  is_nil(data)
  MiniTest.expect.no_equality(err, nil)
end

-- command_exists tests
T["command_exists()"] = new_set()

T["command_exists()"]["returns true for existing command"] = function()
  local exists = utils.command_exists("ls")
  eq(exists, true)
end

T["command_exists()"]["returns false for non-existing command"] = function()
  local exists = utils.command_exists("nonexistent_command_12345")
  eq(exists, false)
end

return T

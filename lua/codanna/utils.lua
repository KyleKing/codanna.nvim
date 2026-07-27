--- Shared utility functions for codanna.nvim
--- @module codanna.utils
local M = {}

--- Normalize a result item from various codanna API responses
--- Handles different field names (file_path/file/path, range/line/lnum)
--- and converts to a consistent internal format
--- @param item table|nil The result item from codanna API
--- @return table|nil Normalized result with fields: name, kind, file, lnum, col
function M.normalize_result(item)
  if not item then
    return nil
  end

  -- Handle nested result format (some APIs return [[result]])
  if item[1] and type(item[1]) == "table" then
    item = item[1]
  end

  -- Extract filename from various possible field names
  local filename = item.file_path or item.file or item.path
  local lnum = 1
  local col = 0

  -- Extract line and column from various formats
  if item.range then
    -- Format: { range: { start_line: 0, start_column: 0 } }
    lnum = (item.range.start_line or 0) + 1 -- Convert 0-indexed to 1-indexed
    col = item.range.start_column or 0
  elseif item.line ~= nil then
    -- Format: { line: 0, column: 0 }
    lnum = item.line + 1 -- Convert 0-indexed to 1-indexed
    col = item.column or 0
  elseif item.lnum then
    -- Format: { lnum: 1, col: 0 } (already 1-indexed)
    lnum = item.lnum
    col = item.col or 0
  end

  return {
    name = item.name or item.symbol or item.title or "unknown",
    kind = item.kind,
    file = filename,
    lnum = lnum,
    col = col,
    signature = item.signature,
    score = item.score,
  }
end

--- Extract results array from various codanna API response formats
--- @param data table|nil The API response data
--- @return table Array of results (empty array if none found)
function M.extract_results(data)
  if not data then
    return {}
  end
  -- Some responses are already arrays
  if vim.islist(data) then
    return data
  end
  -- Some responses wrap results in a 'results' field
  if data.results then
    return data.results
  end
  return {}
end

--- Validate that a symbol string is non-empty
--- @param symbol string|nil Symbol to validate
--- @return string|nil Valid symbol or nil with error message
--- @return string|nil Error message if validation failed
function M.validate_symbol(symbol)
  if not symbol or symbol == "" then
    return nil, "No symbol provided or found under cursor"
  end
  -- Trim whitespace
  symbol = symbol:match("^%s*(.-)%s*$")
  if symbol == "" then
    return nil, "Symbol contains only whitespace"
  end
  return symbol, nil
end

--- Validate configuration options
--- @param config table Configuration to validate
--- @return table Validated configuration
--- @return string|nil Error message if validation failed
function M.validate_config(config)
  local errors = {}

  if config.timeout_ms then
    if type(config.timeout_ms) ~= "number" then
      table.insert(errors, "timeout_ms must be a number")
    elseif config.timeout_ms < 0 then
      table.insert(errors, "timeout_ms must be non-negative")
    elseif config.timeout_ms < 1000 then
      table.insert(errors, "timeout_ms should be at least 1000ms (1 second)")
    end
  end

  if config.cache_ttl_ms then
    if type(config.cache_ttl_ms) ~= "number" then
      table.insert(errors, "cache_ttl_ms must be a number")
    elseif config.cache_ttl_ms < 0 then
      table.insert(errors, "cache_ttl_ms must be non-negative")
    end
  end

  if config.debounce_ms then
    if type(config.debounce_ms) ~= "number" then
      table.insert(errors, "debounce_ms must be a number")
    elseif config.debounce_ms < 0 then
      table.insert(errors, "debounce_ms must be non-negative")
    elseif config.debounce_ms > 1000 then
      table.insert(errors, "debounce_ms should not exceed 1000ms for good UX")
    end
  end

  if config.preferred_picker then
    local valid_pickers = { snacks = true, telescope = true, mini = true }
    if not valid_pickers[config.preferred_picker] then
      table.insert(errors, "preferred_picker must be one of: snacks, telescope, mini")
    end
  end

  if #errors > 0 then
    return config, table.concat(errors, "; ")
  end

  return config, nil
end

--- Create a safe cache key that avoids collisions
--- @param cmd string Command name
--- @param args table Array of arguments
--- @return string Cache key
function M.make_cache_key(cmd, args)
  -- Use vim.json.encode for reliable serialization
  -- This handles special characters and nested structures
  local ok, key = pcall(vim.json.encode, { cmd = cmd, args = args })
  if ok then
    return key
  end

  -- Fallback: use a delimiter unlikely to appear in arguments
  -- and escape it if it does appear
  local delimiter = "\0" -- null byte, unlikely in normal strings
  local escaped_args = {}
  for _, arg in ipairs(args or {}) do
    -- Convert to string and escape the delimiter
    local str = tostring(arg):gsub("\0", "\0\0")
    table.insert(escaped_args, str)
  end
  return cmd .. delimiter .. table.concat(escaped_args, delimiter)
end

--- Parse JSON response from codanna CLI output
--- Handles cases where output contains non-JSON prefixes (logs, warnings)
--- @param stdout string Raw stdout from codanna command
--- @return table|nil Parsed data on success
--- @return string|nil Error message on failure
function M.parse_json_response(stdout)
  if not stdout or stdout == "" then
    return nil, "Empty response from codanna"
  end

  local lines = vim.split(stdout, "\n")
  local json_start = nil
  local json_end = nil

  -- Find the first line that looks like JSON start
  for i, line in ipairs(lines) do
    if not json_start and line:match("^%s*{") then
      json_start = i
    end
    -- Also track the last non-empty line for better error messages
    if line:match("%S") then
      json_end = i
    end
  end

  if not json_start then
    return nil, "No JSON object found in response. Output may contain only logs/errors."
  end

  -- Extract JSON portion
  local json_str = table.concat(vim.list_slice(lines, json_start, json_end or #lines), "\n")

  -- Try to parse JSON
  local ok, parsed = pcall(vim.json.decode, json_str)
  if not ok then
    return nil, "Failed to parse JSON response: " .. tostring(parsed)
  end

  -- Check for error status in response
  if parsed.status == "error" then
    return nil, parsed.message or "Unknown error from codanna"
  end

  return parsed.data, nil
end

--- Check if a command exists in PATH
--- @param cmd string Command name to check
--- @return boolean True if command exists
function M.command_exists(cmd)
  local result = vim.fn.executable(cmd)
  return result == 1
end

return M

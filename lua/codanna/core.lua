local M = {}

M.config = {
  codanna_path = "codanna",
  timeout_ms = 10000,
  cache_ttl_ms = 5000,
}

local _cache = {}

local function _cache_key(cmd, args)
  return cmd .. ":" .. table.concat(args, ",")
end

local function _get_cached(key)
  local entry = _cache[key]
  if entry and (vim.uv.now() - entry.time) < M.config.cache_ttl_ms then
    return entry.data
  end
  return nil
end

local function _set_cached(key, data)
  _cache[key] = { data = data, time = vim.uv.now() }
end

function M.clear_cache()
  _cache = {}
end

local function parse_response(stdout)
  local ok, parsed = pcall(vim.json.decode, stdout)
  if not ok then
    return nil, "Failed to parse JSON response"
  end

  if parsed.status == "error" then
    return nil, parsed.message or "Unknown error"
  end

  return parsed.data, nil
end

function M.exec(cmd, args, opts)
  opts = opts or {}
  local cache_key = _cache_key(cmd, args)

  if not opts.no_cache then
    local cached = _get_cached(cache_key)
    if cached then
      return cached, nil
    end
  end

  local full_args = { M.config.codanna_path, cmd, "--json" }
  vim.list_extend(full_args, args or {})

  local result = vim.system(full_args, { text = true, timeout = M.config.timeout_ms }):wait()

  if result.code ~= 0 then
    local err = result.stderr or ("codanna exited with code " .. result.code)
    return nil, err
  end

  local lines = vim.split(result.stdout or "", "\n")
  local json_start = nil
  for i, line in ipairs(lines) do
    if line:match("^%s*{") then
      json_start = i
      break
    end
  end

  if not json_start then
    return nil, "No JSON found in response"
  end

  local json_str = table.concat(vim.list_slice(lines, json_start), "\n")
  local data, err = parse_response(json_str)

  if err then
    return nil, err
  end

  _set_cached(cache_key, data)
  return data, nil
end

function M.exec_async(cmd, args, callback)
  local full_args = { M.config.codanna_path, cmd, "--json" }
  vim.list_extend(full_args, args or {})

  vim.system(full_args, { text = true, timeout = M.config.timeout_ms }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, result.stderr or ("codanna exited with code " .. result.code))
        return
      end

      local lines = vim.split(result.stdout or "", "\n")
      local json_start = nil
      for i, line in ipairs(lines) do
        if line:match("^%s*{") then
          json_start = i
          break
        end
      end

      if not json_start then
        callback(nil, "No JSON found in response")
        return
      end

      local json_str = table.concat(vim.list_slice(lines, json_start), "\n")
      local data, err = parse_response(json_str)
      callback(data, err)
    end)
  end)
end

function M.semantic_search(query, opts)
  opts = opts or {}
  local args = { "semantic_search_with_context", "query:" .. query }
  if opts.limit then
    table.insert(args, "limit:" .. opts.limit)
  end
  return M.exec("mcp", args, opts)
end

function M.semantic_search_async(query, opts, callback)
  opts = opts or {}
  local args = { "semantic_search_with_context", "query:" .. query }
  if opts.limit then
    table.insert(args, "limit:" .. opts.limit)
  end
  M.exec_async("mcp", args, callback)
end

function M.search_symbols(query, opts)
  opts = opts or {}
  local args = { "search_symbols", "query:" .. query }
  if opts.kind then
    table.insert(args, "kind:" .. opts.kind)
  end
  if opts.limit then
    table.insert(args, "limit:" .. opts.limit)
  end
  return M.exec("mcp", args, opts)
end

function M.search_symbols_async(query, opts, callback)
  opts = opts or {}
  local args = { "search_symbols", "query:" .. query }
  if opts.kind then
    table.insert(args, "kind:" .. opts.kind)
  end
  if opts.limit then
    table.insert(args, "limit:" .. opts.limit)
  end
  M.exec_async("mcp", args, callback)
end

function M.find_symbol(name, opts)
  opts = opts or {}
  return M.exec("mcp", { "find_symbol", name }, opts)
end

function M.find_symbol_async(name, opts, callback)
  opts = opts or {}
  M.exec_async("mcp", { "find_symbol", name }, callback)
end

function M.find_callers(symbol, opts)
  opts = opts or {}
  return M.exec("mcp", { "find_callers", symbol }, opts)
end

function M.find_callers_async(symbol, opts, callback)
  opts = opts or {}
  M.exec_async("mcp", { "find_callers", symbol }, callback)
end

function M.get_calls(symbol, opts)
  opts = opts or {}
  return M.exec("mcp", { "get_calls", symbol }, opts)
end

function M.get_calls_async(symbol, opts, callback)
  opts = opts or {}
  M.exec_async("mcp", { "get_calls", symbol }, callback)
end

function M.analyze_impact(symbol, opts)
  opts = opts or {}
  return M.exec("mcp", { "analyze_impact", symbol }, opts)
end

function M.analyze_impact_async(symbol, opts, callback)
  opts = opts or {}
  M.exec_async("mcp", { "analyze_impact", symbol }, callback)
end

function M.search_documents(query, opts)
  opts = opts or {}
  local args = { "search_documents", "query:" .. query }
  if opts.limit then
    table.insert(args, "limit:" .. opts.limit)
  end
  return M.exec("mcp", args, opts)
end

function M.search_documents_async(query, opts, callback)
  opts = opts or {}
  local args = { "search_documents", "query:" .. query }
  if opts.limit then
    table.insert(args, "limit:" .. opts.limit)
  end
  M.exec_async("mcp", args, callback)
end

function M.get_index_info(opts)
  opts = opts or {}
  return M.exec("mcp", { "get_index_info" }, opts)
end

function M.get_index_info_async(opts, callback)
  opts = opts or {}
  M.exec_async("mcp", { "get_index_info" }, callback)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M

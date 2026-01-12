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

function M.exec(cmd, args, opts)
  opts = opts or {}
  local cache_key = _cache_key(cmd, args)

  if not opts.no_cache then
    local cached = _get_cached(cache_key)
    if cached then
      return cached, nil
    end
  end

  local full_args = { M.config.codanna_path, cmd }
  vim.list_extend(full_args, args or {})

  local result = vim.system(full_args, { text = true, timeout = M.config.timeout_ms }):wait()

  if result.code ~= 0 then
    local err = result.stderr or ("codanna exited with code " .. result.code)
    return nil, err
  end

  local ok, parsed = pcall(vim.json.decode, result.stdout)
  if not ok then
    return { raw = result.stdout }, nil
  end

  _set_cached(cache_key, parsed)
  return parsed, nil
end

function M.exec_async(cmd, args, callback)
  local full_args = { M.config.codanna_path, cmd }
  vim.list_extend(full_args, args or {})

  vim.system(full_args, { text = true, timeout = M.config.timeout_ms }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, result.stderr or ("codanna exited with code " .. result.code))
        return
      end

      local ok, parsed = pcall(vim.json.decode, result.stdout)
      if not ok then
        callback({ raw = result.stdout }, nil)
        return
      end

      callback(parsed, nil)
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

function M.find_callers(symbol, opts)
  opts = opts or {}
  return M.exec("mcp", { "find_callers", symbol }, opts)
end

function M.find_callers_async(symbol, opts, callback)
  opts = opts or {}
  M.exec_async("mcp", { "find_callers", symbol }, callback)
end

function M.find_implementations(symbol, opts)
  opts = opts or {}
  return M.exec("mcp", { "find_implementations", symbol }, opts)
end

function M.find_implementations_async(symbol, opts, callback)
  opts = opts or {}
  M.exec_async("mcp", { "find_implementations", symbol }, callback)
end

function M.list_symbols(opts)
  opts = opts or {}
  local args = { "list_symbols" }
  if opts.file then
    table.insert(args, "file:" .. opts.file)
  end
  return M.exec("mcp", args, opts)
end

function M.list_symbols_async(opts, callback)
  opts = opts or {}
  local args = { "list_symbols" }
  if opts.file then
    table.insert(args, "file:" .. opts.file)
  end
  M.exec_async("mcp", args, callback)
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

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M

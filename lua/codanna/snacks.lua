local has_snacks, Snacks = pcall(require, "snacks")
if not has_snacks then
  return {}
end

local codanna = require("codanna.core")

local M = {}

M.config = {
  debounce_ms = 150,
}

local function normalize_result(item)
  if not item then
    return nil
  end

  if item[1] and type(item[1]) == "table" then
    item = item[1]
  end

  local filename = item.file_path or item.file or item.path
  local lnum = 1
  local col = 0

  if item.range then
    lnum = (item.range.start_line or 0) + 1
    col = item.range.start_column or 0
  elseif item.line ~= nil then
    lnum = item.line + 1
    col = item.column or 0
  elseif item.lnum then
    lnum = item.lnum
    col = item.col or 0
  end

  return {
    name = item.name or item.symbol or item.title or "unknown",
    kind = item.kind,
    file = filename,
    lnum = lnum,
    col = col,
  }
end

local function make_item(result)
  local norm = normalize_result(result)
  if not norm then
    return nil
  end

  local text = norm.name
  if norm.kind then
    text = string.format("[%s] %s", norm.kind, norm.name)
  end

  return {
    text = text,
    file = norm.file,
    pos = { norm.lnum, norm.col },
    _result = result,
  }
end

local function extract_results(data)
  if not data then
    return {}
  end
  if vim.islist(data) then
    return data
  end
  if data.results then
    return data.results
  end
  return {}
end

local function create_async_finder(search_fn, min_chars)
  min_chars = min_chars or 3

  return function(opts, ctx, cb)
    local query = ctx.filter.search or ""
    if #query < min_chars then
      cb({})
      return
    end

    search_fn(query, opts, function(data, err)
      if err then
        vim.schedule(function()
          vim.notify("Codanna: " .. err, vim.log.levels.WARN)
        end)
        cb({})
        return
      end
      local results = extract_results(data)
      local items = vim.tbl_map(make_item, results)
      items = vim.tbl_filter(function(i) return i ~= nil end, items)
      cb(items)
    end)
  end
end

local function create_static_async_finder(fetch_fn)
  return function(opts, ctx, cb)
    fetch_fn(opts, function(data, err)
      if err then
        vim.schedule(function()
          vim.notify("Codanna: " .. err, vim.log.levels.WARN)
        end)
        cb({})
        return
      end
      local results = extract_results(data)
      local items = vim.tbl_map(make_item, results)
      items = vim.tbl_filter(function(i) return i ~= nil end, items)
      cb(items)
    end)
  end
end

M.sources = {
  codanna_semantic = {
    title = "Codanna: Semantic Search",
    finder = create_async_finder(function(query, opts, callback)
      codanna.semantic_search_async(query, { limit = opts.limit or 50 }, callback)
    end),
    format = "file",
    preview = "file",
    supports_live = true,
    live = {
      debounce = M.config.debounce_ms,
    },
  },

  codanna_symbols = {
    title = "Codanna: Search Symbols",
    finder = create_async_finder(function(query, opts, callback)
      codanna.search_symbols_async(query, { limit = opts.limit or 50, kind = opts.kind }, callback)
    end),
    format = "file",
    preview = "file",
    supports_live = true,
    live = {
      debounce = M.config.debounce_ms,
    },
  },

  codanna_callers = {
    title = "Codanna: Find Callers",
    finder = create_static_async_finder(function(opts, callback)
      local symbol = opts.symbol or vim.fn.expand("<cword>")
      codanna.find_callers_async(symbol, {}, callback)
    end),
    format = "file",
    preview = "file",
  },

  codanna_calls = {
    title = "Codanna: Get Calls",
    finder = create_static_async_finder(function(opts, callback)
      local symbol = opts.symbol or vim.fn.expand("<cword>")
      codanna.get_calls_async(symbol, {}, callback)
    end),
    format = "file",
    preview = "file",
  },

  codanna_impact = {
    title = "Codanna: Analyze Impact",
    finder = create_static_async_finder(function(opts, callback)
      local symbol = opts.symbol or vim.fn.expand("<cword>")
      codanna.analyze_impact_async(symbol, {}, callback)
    end),
    format = "file",
    preview = "file",
  },

  codanna_documents = {
    title = "Codanna: Documents",
    finder = create_async_finder(function(query, opts, callback)
      codanna.search_documents_async(query, { limit = opts.limit or 50 }, callback)
    end),
    format = "file",
    preview = "file",
    supports_live = true,
    live = {
      debounce = M.config.debounce_ms,
    },
  },
}

function M.semantic_search(opts)
  opts = opts or {}
  Snacks.picker.pick("codanna_semantic", opts)
end

function M.search_symbols(opts)
  opts = opts or {}
  Snacks.picker.pick("codanna_symbols", opts)
end

function M.find_callers(opts)
  opts = opts or {}
  opts.symbol = opts.symbol or vim.fn.expand("<cword>")
  Snacks.picker.pick("codanna_callers", opts)
end

function M.get_calls(opts)
  opts = opts or {}
  opts.symbol = opts.symbol or vim.fn.expand("<cword>")
  Snacks.picker.pick("codanna_calls", opts)
end

function M.analyze_impact(opts)
  opts = opts or {}
  opts.symbol = opts.symbol or vim.fn.expand("<cword>")
  Snacks.picker.pick("codanna_impact", opts)
end

function M.documents(opts)
  opts = opts or {}
  Snacks.picker.pick("codanna_documents", opts)
end

function M.setup()
  if Snacks.picker and Snacks.picker.sources then
    for name, source in pairs(M.sources) do
      Snacks.picker.sources[name] = source
    end
  end
end

return M

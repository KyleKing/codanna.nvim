local has_snacks, Snacks = pcall(require, "snacks")
if not has_snacks then
  return {}
end

local codanna = require("codanna.core")

local M = {}

M.config = {
  debounce_ms = 150,
}

local function make_item(result)
  local filename = result.file or result.path
  local lnum = result.line or result.lnum or 1
  local col = result.column or result.col or 0
  local name = result.name or result.symbol or result.title or "unknown"

  return {
    text = name,
    file = filename,
    pos = { lnum, col },
    _result = result,
  }
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
          vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        end)
        cb({})
        return
      end
      cb(vim.tbl_map(make_item, data or {}))
    end)
  end
end

local function create_static_async_finder(fetch_fn)
  return function(opts, ctx, cb)
    fetch_fn(opts, function(data, err)
      if err then
        vim.schedule(function()
          vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        end)
        cb({})
        return
      end
      cb(vim.tbl_map(make_item, data or {}))
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

  codanna_callers = {
    title = "Codanna: Find Callers",
    finder = create_static_async_finder(function(opts, callback)
      local symbol = opts.symbol or vim.fn.expand("<cword>")
      codanna.find_callers_async(symbol, {}, callback)
    end),
    format = "file",
    preview = "file",
  },

  codanna_implementations = {
    title = "Codanna: Find Implementations",
    finder = create_static_async_finder(function(opts, callback)
      local symbol = opts.symbol or vim.fn.expand("<cword>")
      codanna.find_implementations_async(symbol, {}, callback)
    end),
    format = "file",
    preview = "file",
  },

  codanna_symbols = {
    title = "Codanna: Symbols",
    finder = create_static_async_finder(function(opts, callback)
      codanna.list_symbols_async({ file = opts.file }, callback)
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

function M.find_callers(opts)
  opts = opts or {}
  opts.symbol = opts.symbol or vim.fn.expand("<cword>")
  Snacks.picker.pick("codanna_callers", opts)
end

function M.find_implementations(opts)
  opts = opts or {}
  opts.symbol = opts.symbol or vim.fn.expand("<cword>")
  Snacks.picker.pick("codanna_implementations", opts)
end

function M.symbols(opts)
  opts = opts or {}
  Snacks.picker.pick("codanna_symbols", opts)
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

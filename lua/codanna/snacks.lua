local has_snacks, Snacks = pcall(require, "snacks")
if not has_snacks then
  return {}
end

local codanna = require("codanna.core")

local M = {}

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

M.sources = {
  codanna_semantic = {
    title = "Codanna: Semantic Search",
    finder = function(opts, ctx)
      local query = ctx.filter.search or ""
      if #query < 3 then
        return {}
      end
      local data, err = codanna.semantic_search(query, { limit = opts.limit or 50 })
      if err then
        vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        return {}
      end
      return vim.tbl_map(make_item, data or {})
    end,
    format = "file",
    preview = "file",
    supports_live = true,
  },

  codanna_callers = {
    title = "Codanna: Find Callers",
    finder = function(opts, ctx)
      local symbol = opts.symbol or vim.fn.expand("<cword>")
      local data, err = codanna.find_callers(symbol)
      if err then
        vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        return {}
      end
      return vim.tbl_map(make_item, data or {})
    end,
    format = "file",
    preview = "file",
  },

  codanna_implementations = {
    title = "Codanna: Find Implementations",
    finder = function(opts, ctx)
      local symbol = opts.symbol or vim.fn.expand("<cword>")
      local data, err = codanna.find_implementations(symbol)
      if err then
        vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        return {}
      end
      return vim.tbl_map(make_item, data or {})
    end,
    format = "file",
    preview = "file",
  },

  codanna_symbols = {
    title = "Codanna: Symbols",
    finder = function(opts, ctx)
      local data, err = codanna.list_symbols({ file = opts.file })
      if err then
        vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        return {}
      end
      return vim.tbl_map(make_item, data or {})
    end,
    format = "file",
    preview = "file",
  },

  codanna_documents = {
    title = "Codanna: Documents",
    finder = function(opts, ctx)
      local query = ctx.filter.search or ""
      if #query < 3 then
        return {}
      end
      local data, err = codanna.search_documents(query, { limit = opts.limit or 50 })
      if err then
        vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        return {}
      end
      return vim.tbl_map(make_item, data or {})
    end,
    format = "file",
    preview = "file",
    supports_live = true,
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

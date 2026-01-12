local has_mini_pick, MiniPick = pcall(require, "mini.pick")
if not has_mini_pick then
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
    path = filename,
    lnum = lnum,
    col = col,
    _result = result,
  }
end

local function default_choose(item)
  if not item then
    return
  end
  if item.path then
    vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    vim.api.nvim_win_set_cursor(0, { item.lnum or 1, item.col or 0 })
  end
end

local function file_preview(buf_id, item)
  if not item or not item.path then
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, { "No preview available" })
    return
  end

  local ok, lines = pcall(vim.fn.readfile, item.path)
  if not ok then
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, { "Cannot read file" })
    return
  end

  local start_line = math.max(1, (item.lnum or 1) - 5)
  local end_line = math.min(#lines, (item.lnum or 1) + 20)
  local preview_lines = vim.list_slice(lines, start_line, end_line)

  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, preview_lines)

  local ft = vim.filetype.match({ filename = item.path })
  if ft then
    vim.bo[buf_id].filetype = ft
  end
end

function M.semantic_search(opts)
  opts = opts or {}
  local last_query = ""
  local items = {}

  MiniPick.start({
    source = {
      name = "Codanna: Semantic Search",
      match = function(stritems, indices, query)
        local query_str = table.concat(query, "")
        if query_str ~= last_query and #query_str >= 3 then
          last_query = query_str
          local data, err = codanna.semantic_search(query_str, { limit = opts.limit or 50 })
          if err then
            vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
            items = {}
          else
            items = vim.tbl_map(make_item, data or {})
          end
          MiniPick.set_picker_items(items)
        end
        local result = {}
        for i = 1, #items do
          table.insert(result, i)
        end
        return result
      end,
      show = function(buf_id, items_to_show, query)
        local lines = vim.tbl_map(function(item)
          if item.path then
            return string.format("%s:%d - %s", vim.fn.fnamemodify(item.path, ":~:."), item.lnum or 1, item.text)
          end
          return item.text
        end, items_to_show)
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
      end,
      preview = file_preview,
      choose = default_choose,
    },
  })
end

function M.find_callers(opts)
  opts = opts or {}
  local symbol = opts.symbol or vim.fn.expand("<cword>")

  local data, err = codanna.find_callers(symbol)
  if err then
    vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
    return
  end

  local items = vim.tbl_map(make_item, data or {})

  MiniPick.start({
    source = {
      name = "Codanna: Callers of " .. symbol,
      items = items,
      preview = file_preview,
      choose = default_choose,
    },
  })
end

function M.find_implementations(opts)
  opts = opts or {}
  local symbol = opts.symbol or vim.fn.expand("<cword>")

  local data, err = codanna.find_implementations(symbol)
  if err then
    vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
    return
  end

  local items = vim.tbl_map(make_item, data or {})

  MiniPick.start({
    source = {
      name = "Codanna: Implementations of " .. symbol,
      items = items,
      preview = file_preview,
      choose = default_choose,
    },
  })
end

function M.symbols(opts)
  opts = opts or {}

  local data, err = codanna.list_symbols({ file = opts.file })
  if err then
    vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
    return
  end

  local items = vim.tbl_map(make_item, data or {})

  MiniPick.start({
    source = {
      name = "Codanna: Symbols",
      items = items,
      preview = file_preview,
      choose = default_choose,
    },
  })
end

function M.documents(opts)
  opts = opts or {}
  local last_query = ""
  local items = {}

  MiniPick.start({
    source = {
      name = "Codanna: Documents",
      match = function(stritems, indices, query)
        local query_str = table.concat(query, "")
        if query_str ~= last_query and #query_str >= 3 then
          last_query = query_str
          local data, err = codanna.search_documents(query_str, { limit = opts.limit or 50 })
          if err then
            vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
            items = {}
          else
            items = vim.tbl_map(make_item, data or {})
          end
          MiniPick.set_picker_items(items)
        end
        local result = {}
        for i = 1, #items do
          table.insert(result, i)
        end
        return result
      end,
      show = function(buf_id, items_to_show, query)
        local lines = vim.tbl_map(function(item)
          if item.path then
            return string.format("%s:%d - %s", vim.fn.fnamemodify(item.path, ":~:."), item.lnum or 1, item.text)
          end
          return item.text
        end, items_to_show)
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
      end,
      preview = file_preview,
      choose = default_choose,
    },
  })
end

return M

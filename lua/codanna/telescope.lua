local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
  return {}
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local codanna = require("codanna.core")

local M = {}

local function make_entry(item)
  local display = item.name or item.symbol or item.title or "unknown"
  local filename = item.file or item.path
  local lnum = item.line or item.lnum or 1
  local col = item.column or item.col or 0

  if filename then
    display = string.format("%s:%d - %s", vim.fn.fnamemodify(filename, ":~:."), lnum, display)
  end

  return {
    value = item,
    display = display,
    ordinal = display,
    filename = filename,
    lnum = lnum,
    col = col,
  }
end

local function goto_selection(prompt_bufnr)
  actions.close(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection and selection.filename then
    vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
    vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
  end
end

function M.semantic_search(opts)
  opts = opts or {}
  local results = {}
  local current_query = ""

  pickers.new(opts, {
    prompt_title = "Codanna: Semantic Search",
    finder = finders.new_dynamic({
      fn = function(prompt)
        if #prompt < 3 then
          return {}
        end
        current_query = prompt
        local data, err = codanna.semantic_search(prompt, { limit = opts.limit or 50 })
        if err then
          vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
          return {}
        end
        results = data or {}
        return results
      end,
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        goto_selection(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

function M.find_callers(opts)
  opts = opts or {}
  local symbol = opts.symbol or vim.fn.expand("<cword>")

  local data, err = codanna.find_callers(symbol)
  if err then
    vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
    return
  end

  pickers.new(opts, {
    prompt_title = "Codanna: Callers of " .. symbol,
    finder = finders.new_table({
      results = data or {},
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        goto_selection(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

function M.find_implementations(opts)
  opts = opts or {}
  local symbol = opts.symbol or vim.fn.expand("<cword>")

  local data, err = codanna.find_implementations(symbol)
  if err then
    vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
    return
  end

  pickers.new(opts, {
    prompt_title = "Codanna: Implementations of " .. symbol,
    finder = finders.new_table({
      results = data or {},
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        goto_selection(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

function M.symbols(opts)
  opts = opts or {}

  local data, err = codanna.list_symbols({ file = opts.file })
  if err then
    vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
    return
  end

  pickers.new(opts, {
    prompt_title = "Codanna: Symbols",
    finder = finders.new_table({
      results = data or {},
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        goto_selection(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

function M.documents(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Codanna: Search Documents",
    finder = finders.new_dynamic({
      fn = function(prompt)
        if #prompt < 3 then
          return {}
        end
        local data, err = codanna.search_documents(prompt, { limit = opts.limit or 50 })
        if err then
          vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
          return {}
        end
        return data or {}
      end,
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        goto_selection(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

return M

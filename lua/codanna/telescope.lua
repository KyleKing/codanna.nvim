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

M.config = {
  debounce_ms = 150,
}

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

local function create_live_picker(title, search_fn, opts)
  opts = opts or {}
  local results = {}
  local picker_obj = nil
  local debounce_timer = nil
  local last_query = ""
  local pending_query = nil

  local function refresh_picker()
    if picker_obj then
      picker_obj:refresh(
        finders.new_table({
          results = results,
          entry_maker = make_entry,
        }),
        { reset_prompt = false }
      )
    end
  end

  local function do_search(query)
    if #query < 3 then
      results = {}
      refresh_picker()
      return
    end

    search_fn(query, opts, function(data, err)
      if pending_query and pending_query ~= query then
        return
      end

      if err then
        vim.notify("Codanna error: " .. err, vim.log.levels.ERROR)
        results = {}
      else
        results = data or {}
      end
      refresh_picker()
    end)
  end

  local function on_input_change()
    local prompt_bufnr = picker_obj and picker_obj.prompt_bufnr
    if not prompt_bufnr or not vim.api.nvim_buf_is_valid(prompt_bufnr) then
      return
    end

    local current_line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
    local query = current_line:gsub("^>%s*", "")

    if query == last_query then
      return
    end

    last_query = query
    pending_query = query

    if debounce_timer then
      debounce_timer:stop()
    else
      debounce_timer = vim.uv.new_timer()
    end

    debounce_timer:start(M.config.debounce_ms, 0, vim.schedule_wrap(function()
      do_search(query)
    end))
  end

  picker_obj = pickers.new(opts, {
    prompt_title = title,
    finder = finders.new_table({
      results = {},
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        goto_selection(prompt_bufnr)
      end)

      vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = prompt_bufnr,
        callback = on_input_change,
      })

      vim.api.nvim_create_autocmd("BufLeave", {
        buffer = prompt_bufnr,
        once = true,
        callback = function()
          if debounce_timer then
            debounce_timer:stop()
            debounce_timer:close()
            debounce_timer = nil
          end
        end,
      })

      return true
    end,
  })

  picker_obj:find()
end

function M.semantic_search(opts)
  opts = opts or {}
  create_live_picker(
    "Codanna: Semantic Search",
    function(query, o, callback)
      codanna.semantic_search_async(query, { limit = o.limit or 50 }, callback)
    end,
    opts
  )
end

function M.find_callers(opts)
  opts = opts or {}
  local symbol = opts.symbol or vim.fn.expand("<cword>")

  codanna.find_callers_async(symbol, {}, function(data, err)
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
  end)
end

function M.find_implementations(opts)
  opts = opts or {}
  local symbol = opts.symbol or vim.fn.expand("<cword>")

  codanna.find_implementations_async(symbol, {}, function(data, err)
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
  end)
end

function M.symbols(opts)
  opts = opts or {}

  codanna.list_symbols_async(opts, function(data, err)
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
  end)
end

function M.documents(opts)
  opts = opts or {}
  create_live_picker(
    "Codanna: Search Documents",
    function(query, o, callback)
      codanna.search_documents_async(query, { limit = o.limit or 50 }, callback)
    end,
    opts
  )
end

return M

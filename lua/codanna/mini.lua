local has_mini_pick, MiniPick = pcall(require, "mini.pick")
if not has_mini_pick then return {} end
--- @cast MiniPick -nil

local codanna = require("codanna.core")
local utils = require("codanna.utils")

local M = {}

M.config = {
    debounce_ms = 150,
}

--- Convert normalized result to mini.pick item
--- @param result table Result from codanna API
--- @return table|nil Mini.pick item or nil
local function make_item(result)
    local norm = utils.normalize_result(result)
    if not norm then return nil end

    local text = norm.name
    if norm.kind then text = string.format("[%s] %s", norm.kind, norm.name) end

    return {
        text = text,
        path = norm.file,
        lnum = norm.lnum,
        col = norm.col,
        _result = result,
    }
end

local function default_choose(item)
    if not item then return end
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

    local start_line = math.max(1, (item.lnum or 1) - 5) --[[@as integer]]
    local end_line = math.min(#lines, (item.lnum or 1) + 20) --[[@as integer]]
    local preview_lines = vim.list_slice(lines, start_line, end_line)

    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, preview_lines)

    local ft = vim.filetype.match({ filename = item.path })
    if ft then vim.bo[buf_id].filetype = ft end
end

local function create_live_source(name, search_fn, opts)
    local items = {}
    local last_query = ""
    --- @type string|nil
    local pending_query = nil
    --- @type any
    local debounce_timer = nil
    local is_searching = false
    local notified_empty = false

    local function do_search(query_str)
        if is_searching then
            pending_query = query_str
            return
        end

        is_searching = true
        search_fn(query_str, opts, function(data, err)
            is_searching = false

            if pending_query and pending_query ~= query_str then
                local next_query = pending_query
                pending_query = nil
                do_search(next_query)
                return
            end

            if err then
                vim.notify("Codanna: " .. err, vim.log.levels.WARN)
                items = {}
            else
                local results = utils.extract_results(data)
                items = vim.tbl_map(make_item, results)
                items = vim.tbl_filter(function(i) return i ~= nil end, items)

                if #items == 0 and not notified_empty then
                    notified_empty = true
                    codanna.notify_empty_results(query_str)
                elseif #items > 0 then
                    notified_empty = false
                end
            end

            if MiniPick.is_picker_active() then MiniPick.set_picker_items(items) end
        end)
    end

    return {
        name = name,
        items = {},
        match = function(_stritems, _indices, query)
            local query_str = table.concat(query, "")

            if query_str ~= last_query then
                last_query = query_str

                if debounce_timer then
                    debounce_timer:stop()
                else
                    debounce_timer = vim.uv.new_timer()
                end

                if #query_str >= 3 then
                    debounce_timer:start(
                        M.config.debounce_ms,
                        0,
                        vim.schedule_wrap(function() do_search(query_str) end)
                    )
                else
                    items = {}
                    notified_empty = false
                    if MiniPick.is_picker_active() then MiniPick.set_picker_items(items) end
                end
            end

            local result = {}
            for i = 1, #items do
                table.insert(result, i)
            end
            return result
        end,
        show = function(buf_id, items_to_show, _query)
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
    }
end

function M.semantic_search(opts)
    opts = opts or {}
    MiniPick.start({
        source = create_live_source(
            "Codanna: Semantic Search",
            function(query, o, callback) codanna.semantic_search_async(query, { limit = o.limit or 50 }, callback) end,
            opts
        ),
    })
end

function M.search_symbols(opts)
    opts = opts or {}
    MiniPick.start({
        source = create_live_source(
            "Codanna: Search Symbols",
            function(query, o, callback)
                codanna.search_symbols_async(query, { limit = o.limit or 50, kind = o.kind }, callback)
            end,
            opts
        ),
    })
end

--- Find callers of a symbol
--- @param opts table Options: { symbol: string|nil }
function M.find_callers(opts)
    opts = opts or {}
    local symbol = opts.symbol or vim.fn.expand("<cword>")

    -- Validate symbol
    local valid_symbol, validate_err = utils.validate_symbol(symbol)
    if validate_err then
        vim.notify("Codanna: " .. validate_err, vim.log.levels.WARN)
        return
    end
    symbol = valid_symbol

    codanna.find_callers_async(symbol, {}, function(data, err)
        if err then
            vim.notify("Codanna: " .. err, vim.log.levels.WARN)
            return
        end

        local results = utils.extract_results(data)
        local items = vim.tbl_map(make_item, results)
        items = vim.tbl_filter(function(i) return i ~= nil end, items)

        if #items == 0 then codanna.notify_empty_results(symbol) end

        MiniPick.start({
            source = {
                name = "Codanna: Callers of " .. symbol,
                items = items,
                preview = file_preview,
                choose = default_choose,
            },
        })
    end)
end

--- Get outgoing calls from a symbol
--- @param opts table Options: { symbol: string|nil }
function M.get_calls(opts)
    opts = opts or {}
    local symbol = opts.symbol or vim.fn.expand("<cword>")

    -- Validate symbol
    local valid_symbol, validate_err = utils.validate_symbol(symbol)
    if validate_err then
        vim.notify("Codanna: " .. validate_err, vim.log.levels.WARN)
        return
    end
    symbol = valid_symbol

    codanna.get_calls_async(symbol, {}, function(data, err)
        if err then
            vim.notify("Codanna: " .. err, vim.log.levels.WARN)
            return
        end

        local results = utils.extract_results(data)
        local items = vim.tbl_map(make_item, results)
        items = vim.tbl_filter(function(i) return i ~= nil end, items)

        if #items == 0 then codanna.notify_empty_results(symbol) end

        MiniPick.start({
            source = {
                name = "Codanna: Calls from " .. symbol,
                items = items,
                preview = file_preview,
                choose = default_choose,
            },
        })
    end)
end

--- Analyze impact of changes to a symbol
--- @param opts table Options: { symbol: string|nil }
function M.analyze_impact(opts)
    opts = opts or {}
    local symbol = opts.symbol or vim.fn.expand("<cword>")

    -- Validate symbol
    local valid_symbol, validate_err = utils.validate_symbol(symbol)
    if validate_err then
        vim.notify("Codanna: " .. validate_err, vim.log.levels.WARN)
        return
    end
    symbol = valid_symbol

    codanna.analyze_impact_async(symbol, {}, function(data, err)
        if err then
            vim.notify("Codanna: " .. err, vim.log.levels.WARN)
            return
        end

        local results = utils.extract_results(data)
        local items = vim.tbl_map(make_item, results)
        items = vim.tbl_filter(function(i) return i ~= nil end, items)

        if #items == 0 then codanna.notify_empty_results(symbol) end

        MiniPick.start({
            source = {
                name = "Codanna: Impact of " .. symbol,
                items = items,
                preview = file_preview,
                choose = default_choose,
            },
        })
    end)
end

function M.documents(opts)
    opts = opts or {}
    MiniPick.start({
        source = create_live_source(
            "Codanna: Documents",
            function(query, o, callback) codanna.search_documents_async(query, { limit = o.limit or 50 }, callback) end,
            opts
        ),
    })
end

return M

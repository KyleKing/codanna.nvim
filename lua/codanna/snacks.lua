local has_snacks, Snacks = pcall(require, "snacks")
if not has_snacks then return {} end
--- @cast Snacks -nil

local codanna = require("codanna.core")
local utils = require("codanna.utils")

local M = {}

M.config = {
    debounce_ms = 150,
}

--- Convert normalized result to snacks.nvim item
--- @param result table Result from codanna API
--- @return table|nil Snacks item or nil
local function make_item(result)
    local norm = utils.normalize_result(result)
    if not norm then return nil end

    local text = norm.name
    if norm.kind then text = string.format("[%s] %s", norm.kind, norm.name) end

    return {
        text = text,
        file = norm.file,
        pos = { norm.lnum, norm.col },
        _result = result,
    }
end

local function create_async_finder(search_fn, min_chars)
    min_chars = min_chars or 3
    local notified_empty = false
    local last_query = ""

    return function(opts, ctx, cb)
        local query = ctx.filter.search or ""
        if #query < min_chars then
            notified_empty = false
            cb({})
            return
        end

        if query ~= last_query then
            last_query = query
            notified_empty = false
        end

        search_fn(query, opts, function(data, err)
            if err then
                vim.schedule(function() vim.notify("Codanna: " .. err, vim.log.levels.WARN) end)
                cb({})
                return
            end
            local results = utils.extract_results(data)
            local items = vim.tbl_map(make_item, results)
            items = vim.tbl_filter(function(i) return i ~= nil end, items)

            if #items == 0 and not notified_empty then
                notified_empty = true
                vim.schedule(function() codanna.notify_empty_results(query) end)
            elseif #items > 0 then
                notified_empty = false
            end

            cb(items)
        end)
    end
end

--- Create a static async finder (for non-search operations)
--- @param fetch_fn function Function to fetch results: fn(opts, callback)
--- @return function Snacks finder function
local function create_static_async_finder(fetch_fn)
    return function(opts, _ctx, cb)
        fetch_fn(opts, function(data, err)
            if err then
                vim.schedule(function() vim.notify("Codanna: " .. err, vim.log.levels.WARN) end)
                cb({})
                return
            end
            local results = utils.extract_results(data)
            local items = vim.tbl_map(make_item, results)
            items = vim.tbl_filter(function(i) return i ~= nil end, items)

            if #items == 0 then vim.schedule(function() codanna.notify_empty_results(opts.symbol) end) end

            cb(items)
        end)
    end
end

M.sources = {
    codanna_semantic = {
        title = "Codanna: Semantic Search",
        finder = create_async_finder(
            function(query, opts, callback) codanna.semantic_search_async(query, { limit = opts.limit or 50 }, callback) end
        ),
        format = "file",
        preview = "file",
        supports_live = true,
        live = {
            debounce = M.config.debounce_ms,
        },
    },

    codanna_symbols = {
        title = "Codanna: Search Symbols",
        finder = create_async_finder(
            function(query, opts, callback)
                codanna.search_symbols_async(query, { limit = opts.limit or 50, kind = opts.kind }, callback)
            end
        ),
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
            local valid_symbol, err = utils.validate_symbol(symbol)
            if err then
                vim.schedule(function() vim.notify("Codanna: " .. err, vim.log.levels.WARN) end)
                callback({}, err)
                return
            end
            codanna.find_callers_async(valid_symbol, {}, callback)
        end),
        format = "file",
        preview = "file",
    },

    codanna_calls = {
        title = "Codanna: Get Calls",
        finder = create_static_async_finder(function(opts, callback)
            local symbol = opts.symbol or vim.fn.expand("<cword>")
            local valid_symbol, err = utils.validate_symbol(symbol)
            if err then
                vim.schedule(function() vim.notify("Codanna: " .. err, vim.log.levels.WARN) end)
                callback({}, err)
                return
            end
            codanna.get_calls_async(valid_symbol, {}, callback)
        end),
        format = "file",
        preview = "file",
    },

    codanna_impact = {
        title = "Codanna: Analyze Impact",
        finder = create_static_async_finder(function(opts, callback)
            local symbol = opts.symbol or vim.fn.expand("<cword>")
            local valid_symbol, err = utils.validate_symbol(symbol)
            if err then
                vim.schedule(function() vim.notify("Codanna: " .. err, vim.log.levels.WARN) end)
                callback({}, err)
                return
            end
            codanna.analyze_impact_async(valid_symbol, {}, callback)
        end),
        format = "file",
        preview = "file",
    },

    codanna_documents = {
        title = "Codanna: Documents",
        finder = create_async_finder(
            function(query, opts, callback)
                codanna.search_documents_async(query, { limit = opts.limit or 50 }, callback)
            end
        ),
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

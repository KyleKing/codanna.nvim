--- Core module for codanna.nvim
--- Provides low-level interface to codanna CLI tool
--- @module codanna.core

local utils = require("codanna.utils")

local M = {}

M.config = {
    codanna_path = "codanna",
    timeout_ms = 10000,
    cache_ttl_ms = 5000,
}

--- Simple LRU cache with maximum size limit
--- Note: Uses linear search for LRU updates (O(n) on cache hit).
--- This is acceptable for small cache sizes (100 entries).
--- For larger caches, consider a doubly-linked list implementation.
local _cache = {}
local _cache_order = {} -- Track insertion order for LRU
local MAX_CACHE_SIZE = 100

local _index_status = nil
local _index_check_time = 0
local INDEX_CHECK_INTERVAL_MS = 30000

--- Get cached result if still valid
--- @param key string Cache key
--- @return table|nil Cached data or nil if expired/missing
local function _get_cached(key)
    local entry = _cache[key]
    if entry and (vim.uv.now() - entry.time) < M.config.cache_ttl_ms then
        -- Update position in LRU order (move to end)
        for i, k in ipairs(_cache_order) do
            if k == key then
                table.remove(_cache_order, i)
                break
            end
        end
        table.insert(_cache_order, key)
        return entry.data
    end
    return nil
end

--- Set cached result with LRU eviction
--- @param key string Cache key
--- @param data table Data to cache
local function _set_cached(key, data)
    -- If cache is full, evict the oldest entry
    if #_cache_order >= MAX_CACHE_SIZE then
        local oldest_key = table.remove(_cache_order, 1)
        _cache[oldest_key] = nil
    end

    _cache[key] = { data = data, time = vim.uv.now() }
    table.insert(_cache_order, key)
end

--- Clear all cached results
function M.clear_cache()
    _cache = {}
    _cache_order = {}
end

--- Execute codanna command synchronously
--- @param cmd string Codanna subcommand (e.g., "mcp")
--- @param args table Array of arguments for the command
--- @param opts table|nil Options: { no_cache: boolean }
--- @return table|nil Result data on success
--- @return string|nil Error message on failure
function M.exec(cmd, args, opts)
    opts = opts or {}
    local cache_key = utils.make_cache_key(cmd, args)

    -- Check cache unless explicitly disabled
    if not opts.no_cache then
        local cached = _get_cached(cache_key)
        if cached then return cached, nil end
    end

    -- Validate codanna binary exists (only check once per session)
    if not M._binary_validated then
        if not utils.command_exists(M.config.codanna_path) then
            return nil,
                string.format(
                    "codanna binary not found at '%s'. Please install codanna: https://github.com/bartolli/codanna",
                    M.config.codanna_path
                )
        end
        M._binary_validated = true
    end

    local full_args = { M.config.codanna_path, cmd, "--json" }
    vim.list_extend(full_args, args or {})

    local result = vim.system(full_args, { text = true, timeout = M.config.timeout_ms }):wait()

    if result.code ~= 0 then
        local err = result.stderr or ("codanna exited with code " .. result.code)
        -- Provide more context for common errors
        if err:find("not found") or err:find("No such file") then
            err = err .. "\nEnsure codanna is installed and in PATH"
        elseif err:find("not initialized") or err:find("no index") then
            err = err .. "\nRun 'codanna init' and 'codanna index .' in your project"
        end
        return nil, err
    end

    -- Parse JSON from output (may have log lines before JSON)
    local data, err = utils.parse_json_response(result.stdout)
    if err then return nil, err end

    _set_cached(cache_key, data)
    return data, nil
end

--- Execute codanna command asynchronously
--- @param cmd string Codanna subcommand
--- @param args table Array of arguments
--- @param callback function Callback(data, err) called on completion
function M.exec_async(cmd, args, callback)
    -- Validate codanna binary exists
    if not M._binary_validated then
        if not utils.command_exists(M.config.codanna_path) then
            local err = string.format(
                "codanna binary not found at '%s'. Please install codanna: https://github.com/bartolli/codanna",
                M.config.codanna_path
            )
            vim.schedule(function() callback(nil, err) end)
            return
        end
        M._binary_validated = true
    end

    local full_args = { M.config.codanna_path, cmd, "--json" }
    vim.list_extend(full_args, args or {})

    vim.system(full_args, { text = true, timeout = M.config.timeout_ms }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                local err = result.stderr or ("codanna exited with code " .. result.code)
                -- Provide more context for common errors
                if err:find("not found") or err:find("No such file") then
                    err = err .. "\nEnsure codanna is installed and in PATH"
                elseif err:find("not initialized") or err:find("no index") then
                    err = err .. "\nRun 'codanna init' and 'codanna index .' in your project"
                end
                callback(nil, err)
                return
            end

            -- Parse JSON from output
            local data, err = utils.parse_json_response(result.stdout)
            callback(data, err)
        end)
    end)
end

function M.semantic_search(query, opts)
    opts = opts or {}
    local args = { "semantic_search_with_context", "query:" .. query }
    if opts.limit then table.insert(args, "limit:" .. opts.limit) end
    return M.exec("mcp", args, opts)
end

function M.semantic_search_async(query, opts, callback)
    opts = opts or {}
    local args = { "semantic_search_with_context", "query:" .. query }
    if opts.limit then table.insert(args, "limit:" .. opts.limit) end
    M.exec_async("mcp", args, callback)
end

function M.search_symbols(query, opts)
    opts = opts or {}
    local args = { "search_symbols", "query:" .. query }
    if opts.kind then table.insert(args, "kind:" .. opts.kind) end
    if opts.limit then table.insert(args, "limit:" .. opts.limit) end
    return M.exec("mcp", args, opts)
end

function M.search_symbols_async(query, opts, callback)
    opts = opts or {}
    local args = { "search_symbols", "query:" .. query }
    if opts.kind then table.insert(args, "kind:" .. opts.kind) end
    if opts.limit then table.insert(args, "limit:" .. opts.limit) end
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
    if opts.limit then table.insert(args, "limit:" .. opts.limit) end
    return M.exec("mcp", args, opts)
end

function M.search_documents_async(query, opts, callback)
    opts = opts or {}
    local args = { "search_documents", "query:" .. query }
    if opts.limit then table.insert(args, "limit:" .. opts.limit) end
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

--- Setup core configuration
--- @param opts table Configuration options
function M.setup(opts)
    opts = opts or {}

    -- Validate configuration
    local validated, err = utils.validate_config(opts)
    if err then vim.notify("Codanna config warning: " .. err, vim.log.levels.WARN) end

    M.config = vim.tbl_deep_extend("force", M.config, validated or opts)
end

--- Get helpful message when search returns empty results
--- @param index_info table|nil Index information from get_index_info
--- @return string|nil Reason for empty results, or nil if index is okay
local function _get_empty_reason(index_info)
    if not index_info then return "Could not check index status. Ensure 'codanna init' was run in this project." end

    local symbol_count = index_info.symbol_count or 0
    local file_count = index_info.file_count or 0

    if symbol_count == 0 and file_count == 0 then
        return "Index is empty. Run 'codanna init' then 'codanna index .' in your project directory."
    end

    if symbol_count == 0 then
        return "No symbols found. Ensure project contains supported files (Rust, Python, JS, TS, Go, Java, C, C++, C#, Swift, Kotlin, PHP, GDScript)."
    end

    return nil
end

--- Check index status asynchronously with caching
--- @param callback function Callback(index_info) called with index data or nil
function M.check_index_async(callback)
    local now = vim.uv.now()
    if _index_status and (now - _index_check_time) < INDEX_CHECK_INTERVAL_MS then
        callback(_index_status)
        return
    end

    M.get_index_info_async({}, function(data, err)
        if err then
            _index_status = nil
            callback(nil)
            return
        end
        _index_status = data
        _index_check_time = vim.uv.now()
        callback(data)
    end)
end

--- Show helpful notification when search returns empty results
--- @param query string|nil The search query that returned no results
--- @param callback function|nil Optional callback(index_info) to run after check
function M.notify_empty_results(query, callback)
    M.check_index_async(function(index_info)
        local reason = _get_empty_reason(index_info)
        if reason then
            vim.notify("Codanna: " .. reason, vim.log.levels.WARN)
        elseif query and #query >= 3 then
            vim.notify("Codanna: No results for '" .. query .. "'", vim.log.levels.INFO)
        end
        if callback then callback(index_info) end
    end)
end

--- Get cached index status
--- @return table|nil Cached index information or nil
function M.get_index_status() return _index_status end

--- Invalidate cached index status (call after re-indexing)
function M.invalidate_index_cache()
    _index_status = nil
    _index_check_time = 0
end

return M

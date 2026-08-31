local M = {}

--- @type {codanna_path: string, timeout_ms: number, cache_ttl_ms: number, preferred_picker: string|nil}
M.config = {
    codanna_path = "codanna",
    timeout_ms = 10000,
    cache_ttl_ms = 5000,
    preferred_picker = nil,
}

local function get_picker()
    if M.config.preferred_picker then
        local picker_map = {
            snacks = "codanna.snacks",
            telescope = "codanna.telescope",
            mini = "codanna.mini",
        }
        local mod = picker_map[M.config.preferred_picker]
        if mod then
            local ok, picker = pcall(require, mod)
            --- @cast picker table
            if ok and next(picker) then return picker, M.config.preferred_picker end
        end
    end

    local ok, snacks_picker = pcall(require, "codanna.snacks")
    --- @cast snacks_picker table
    if ok and next(snacks_picker) then return snacks_picker, "snacks" end

    local ok2, telescope_picker = pcall(require, "codanna.telescope")
    --- @cast telescope_picker table
    if ok2 and next(telescope_picker) then return telescope_picker, "telescope" end

    local ok3, mini_picker = pcall(require, "codanna.mini")
    --- @cast mini_picker table
    if ok3 and next(mini_picker) then return mini_picker, "mini" end

    return nil, nil
end

function M.semantic_search(opts)
    local picker, _name = get_picker()
    if not picker then
        vim.notify("No picker available (install snacks.nvim, telescope.nvim, or mini.pick)", vim.log.levels.ERROR)
        return
    end
    picker.semantic_search(opts)
end

function M.search_symbols(opts)
    local picker, _name = get_picker()
    if not picker then
        vim.notify("No picker available (install snacks.nvim, telescope.nvim, or mini.pick)", vim.log.levels.ERROR)
        return
    end
    picker.search_symbols(opts)
end

function M.find_callers(opts)
    local picker, _name = get_picker()
    if not picker then
        vim.notify("No picker available (install snacks.nvim, telescope.nvim, or mini.pick)", vim.log.levels.ERROR)
        return
    end
    picker.find_callers(opts)
end

function M.get_calls(opts)
    local picker, _name = get_picker()
    if not picker then
        vim.notify("No picker available (install snacks.nvim, telescope.nvim, or mini.pick)", vim.log.levels.ERROR)
        return
    end
    picker.get_calls(opts)
end

function M.analyze_impact(opts)
    local picker, _name = get_picker()
    if not picker then
        vim.notify("No picker available (install snacks.nvim, telescope.nvim, or mini.pick)", vim.log.levels.ERROR)
        return
    end
    picker.analyze_impact(opts)
end

function M.documents(opts)
    local picker, _name = get_picker()
    if not picker then
        vim.notify("No picker available (install snacks.nvim, telescope.nvim, or mini.pick)", vim.log.levels.ERROR)
        return
    end
    picker.documents(opts)
end

function M.telescope()
    local ok, picker = pcall(require, "codanna.telescope")
    --- @cast picker table
    if ok and next(picker) then return picker end
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return {}
end

function M.mini()
    local ok, picker = pcall(require, "codanna.mini")
    --- @cast picker table
    if ok and next(picker) then return picker end
    vim.notify("mini.pick not available", vim.log.levels.ERROR)
    return {}
end

function M.snacks()
    local ok, picker = pcall(require, "codanna.snacks")
    --- @cast picker table
    if ok and next(picker) then return picker end
    vim.notify("snacks.nvim not available", vim.log.levels.ERROR)
    return {}
end

function M.core() return require("codanna.core") end

function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend("force", M.config, opts)

    require("codanna.core").setup({
        codanna_path = M.config.codanna_path,
        timeout_ms = M.config.timeout_ms,
        cache_ttl_ms = M.config.cache_ttl_ms,
    })

    local ok, snacks_mod = pcall(require, "codanna.snacks")
    if not ok then return end
    --- @cast snacks_mod -nil
    if snacks_mod.setup then snacks_mod.setup() end
end

return M

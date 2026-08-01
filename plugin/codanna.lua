if vim.g.loaded_codanna then return end
vim.g.loaded_codanna = true

vim.api.nvim_create_user_command(
    "CodannaSearch",
    function(opts) require("codanna").semantic_search({ default_text = opts.args }) end,
    { nargs = "?", desc = "Codanna semantic search" }
)

vim.api.nvim_create_user_command(
    "CodannaSymbols",
    function(opts) require("codanna").search_symbols({ default_text = opts.args }) end,
    { nargs = "?", desc = "Search symbols" }
)

vim.api.nvim_create_user_command("CodannaCallers", function(opts)
    local symbol = opts.args ~= "" and opts.args or nil
    require("codanna").find_callers({ symbol = symbol })
end, { nargs = "?", desc = "Find callers of symbol" })

vim.api.nvim_create_user_command("CodannaCalls", function(opts)
    local symbol = opts.args ~= "" and opts.args or nil
    require("codanna").get_calls({ symbol = symbol })
end, { nargs = "?", desc = "Get calls from symbol" })

vim.api.nvim_create_user_command("CodannaImpact", function(opts)
    local symbol = opts.args ~= "" and opts.args or nil
    require("codanna").analyze_impact({ symbol = symbol })
end, { nargs = "?", desc = "Analyze impact of symbol" })

vim.api.nvim_create_user_command(
    "CodannaDocuments",
    function(opts) require("codanna").documents({ default_text = opts.args }) end,
    { nargs = "?", desc = "Search documents" }
)

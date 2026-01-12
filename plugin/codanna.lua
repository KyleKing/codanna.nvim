if vim.g.loaded_codanna then
  return
end
vim.g.loaded_codanna = true

vim.api.nvim_create_user_command("CodannaSearch", function(opts)
  require("codanna").semantic_search({ default_text = opts.args })
end, { nargs = "?", desc = "Codanna semantic search" })

vim.api.nvim_create_user_command("CodannaCallers", function(opts)
  local symbol = opts.args ~= "" and opts.args or nil
  require("codanna").find_callers({ symbol = symbol })
end, { nargs = "?", desc = "Find callers of symbol" })

vim.api.nvim_create_user_command("CodannaImplementations", function(opts)
  local symbol = opts.args ~= "" and opts.args or nil
  require("codanna").find_implementations({ symbol = symbol })
end, { nargs = "?", desc = "Find implementations of symbol" })

vim.api.nvim_create_user_command("CodannaSymbols", function(opts)
  local file = opts.args ~= "" and opts.args or nil
  require("codanna").symbols({ file = file })
end, { nargs = "?", desc = "List symbols", complete = "file" })

vim.api.nvim_create_user_command("CodannaDocuments", function(opts)
  require("codanna").documents({ default_text = opts.args })
end, { nargs = "?", desc = "Search documents" })

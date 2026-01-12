-- Minimal config for testing codanna.nvim with Telescope
-- Usage: nvim --clean -u test/configs/minimal_telescope.lua

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
local deps_path = root .. "/.test-deps"

vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(deps_path .. "/plenary.nvim")
vim.opt.rtp:prepend(deps_path .. "/telescope.nvim")

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.signcolumn = "yes"

local function ensure_deps()
  vim.fn.mkdir(deps_path, "p")

  local repos = {
    ["plenary.nvim"] = "https://github.com/nvim-lua/plenary.nvim",
    ["telescope.nvim"] = "https://github.com/nvim-telescope/telescope.nvim",
  }

  for name, url in pairs(repos) do
    local path = deps_path .. "/" .. name
    if vim.fn.isdirectory(path) == 0 then
      print("Cloning " .. name .. "...")
      vim.fn.system({ "git", "clone", "--depth=1", url, path })
    end
  end
end

ensure_deps()

require("plenary")
require("telescope").setup({})
require("telescope").load_extension("codanna")

require("codanna").setup({
  preferred_picker = "telescope",
})

vim.keymap.set("n", "<leader>cs", "<cmd>CodannaSearch<cr>", { desc = "Codanna: Semantic Search" })
vim.keymap.set("n", "<leader>cc", "<cmd>CodannaCallers<cr>", { desc = "Codanna: Find Callers" })
vim.keymap.set("n", "<leader>ci", "<cmd>CodannaImplementations<cr>", { desc = "Codanna: Find Implementations" })
vim.keymap.set("n", "<leader>co", "<cmd>CodannaSymbols<cr>", { desc = "Codanna: Symbols" })
vim.keymap.set("n", "<leader>cd", "<cmd>CodannaDocuments<cr>", { desc = "Codanna: Documents" })

vim.keymap.set("n", "<leader>ts", function()
  require("telescope").extensions.codanna.semantic_search()
end, { desc = "Telescope: Codanna Semantic Search" })

print([[
Codanna.nvim loaded with Telescope!

Commands:
  :CodannaSearch [query]     - Semantic search
  :CodannaCallers [symbol]   - Find callers
  :CodannaImplementations    - Find implementations
  :CodannaSymbols [file]     - List symbols
  :CodannaDocuments [query]  - Search documents

Keymaps:
  <leader>cs - Semantic Search
  <leader>cc - Find Callers
  <leader>ci - Find Implementations
  <leader>co - Symbols
  <leader>cd - Documents
  <leader>ts - Telescope extension directly
]])

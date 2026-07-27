-- Minimal config for testing codanna.nvim with snacks.nvim picker
-- Usage: nvim --clean -u test/configs/minimal_snacks.lua

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
local deps_path = root .. "/.test-deps"

vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(deps_path .. "/snacks.nvim")

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.signcolumn = "yes"

local function ensure_deps()
  vim.fn.mkdir(deps_path, "p")

  local repos = {
    ["snacks.nvim"] = "https://github.com/folke/snacks.nvim",
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

require("snacks").setup({
  picker = { enabled = true },
})

require("codanna").setup({
  preferred_picker = "snacks",
})

vim.keymap.set("n", "<leader>cs", "<cmd>CodannaSearch<cr>", { desc = "Codanna: Semantic Search" })
vim.keymap.set("n", "<leader>cy", "<cmd>CodannaSymbols<cr>", { desc = "Codanna: Search Symbols" })
vim.keymap.set("n", "<leader>cc", "<cmd>CodannaCallers<cr>", { desc = "Codanna: Find Callers" })
vim.keymap.set("n", "<leader>cC", "<cmd>CodannaCalls<cr>", { desc = "Codanna: Get Calls" })
vim.keymap.set("n", "<leader>ci", "<cmd>CodannaImpact<cr>", { desc = "Codanna: Analyze Impact" })
vim.keymap.set("n", "<leader>cd", "<cmd>CodannaDocuments<cr>", { desc = "Codanna: Documents" })

vim.keymap.set("n", "<leader>ss", function()
  require("snacks.picker").pick("codanna_semantic")
end, { desc = "Snacks: Codanna Semantic Search" })

print(string.format(
  [[
Codanna.nvim loaded with snacks.nvim picker!
Working directory: %s

Commands:
  :CodannaSearch [query]   - Semantic search
  :CodannaSymbols [query]  - Search symbols
  :CodannaCallers [symbol] - Find callers
  :CodannaCalls [symbol]   - Get calls from symbol
  :CodannaImpact [symbol]  - Analyze impact
  :CodannaDocuments [query]- Search documents

Keymaps:
  <leader>cs - Semantic Search
  <leader>cy - Search Symbols
  <leader>cc - Find Callers
  <leader>cC - Get Calls
  <leader>ci - Analyze Impact
  <leader>cd - Documents
  <leader>ss - Snacks picker directly

Supported languages: Rust, Python, JS, TS, Go, Java, C, C++, C#, Swift, Kotlin, PHP, GDScript
Ensure 'codanna index .' was run in this directory first.
]],
  vim.fn.getcwd()
))

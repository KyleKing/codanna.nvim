# codanna.nvim

Neovim plugin for [codanna](https://github.com/bartolli/codanna) semantic code search. Supports Telescope, mini.pick, and snacks.nvim pickers.

## Requirements

- [codanna](https://github.com/bartolli/codanna) CLI
- Neovim 0.10+
- One of: [snacks.nvim](https://github.com/folke/snacks.nvim), [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), or [mini.pick](https://github.com/echasnovski/mini.nvim)

## Installation

### lazy.nvim

```lua
{
  "kyleking/codanna.nvim",
  dependencies = {
    -- Use one of:
    "folke/snacks.nvim",
    -- "nvim-telescope/telescope.nvim",
    -- "echasnovski/mini.pick",
  },
  opts = {
    preferred_picker = "snacks", -- "snacks", "telescope", or "mini"
  },
  keys = {
    { "<leader>cs", "<cmd>CodannaSearch<cr>", desc = "Semantic Search" },
    { "<leader>cy", "<cmd>CodannaSymbols<cr>", desc = "Symbols" },
    { "<leader>cc", "<cmd>CodannaCallers<cr>", desc = "Find Callers" },
    { "<leader>cC", "<cmd>CodannaCalls<cr>", desc = "Get Calls" },
    { "<leader>ci", "<cmd>CodannaImpact<cr>", desc = "Analyze Impact" },
    { "<leader>cd", "<cmd>CodannaDocuments<cr>", desc = "Documents" },
  },
}
```

## Configuration

```lua
require("codanna").setup({
  codanna_path = "codanna",  -- Path to codanna binary
  timeout_ms = 10000,        -- Command timeout
  cache_ttl_ms = 5000,       -- Cache TTL for results
  preferred_picker = nil,    -- nil = auto-detect, or "snacks"/"telescope"/"mini"
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:CodannaSearch [query]` | Semantic code search |
| `:CodannaSymbols [query]` | Search indexed symbols |
| `:CodannaCallers [symbol]` | Find callers (uses word under cursor if no argument) |
| `:CodannaCalls [symbol]` | Get outgoing calls from symbol |
| `:CodannaImpact [symbol]` | Analyze impact of changes to symbol |
| `:CodannaDocuments [query]` | Search documentation |

## Setup Your Project

Before using, index your project with codanna:

```bash
cd /path/to/your/project
codanna init
codanna index .
```

**Supported languages:** Rust, Python, JS, TS, Go, Java, C, C++, C#, Swift, Kotlin, PHP, GDScript

## Development

```bash
make index-test-project   # Clone and index codanna repo for testing
make test-telescope       # Test with Telescope
make test-mini            # Test with mini.pick
make test-snacks          # Test with snacks.nvim

# Or test with your own project:
make test-telescope PROJECT=/path/to/your/project
```

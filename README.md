# codanna.nvim

[![Tests](https://github.com/KyleKing/codanna.nvim/workflows/Tests/badge.svg)](https://github.com/KyleKing/codanna.nvim/actions)

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
make test                 # Run unit tests
make test-integration     # Run integration tests (requires codanna CLI)
make setup-test-repos     # Setup test repositories for integration tests
make test-telescope       # Test with Telescope
make test-mini            # Test with mini.pick
make test-snacks          # Test with snacks.nvim

# Or test with your own project:
make test-telescope PROJECT=/path/to/your/project
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development guide.

## Troubleshooting

### "codanna binary not found"

**Cause**: The `codanna` CLI tool is not installed or not in PATH.

**Solution**:
1. Install codanna: https://github.com/bartolli/codanna
2. Ensure it's in your PATH: `which codanna`
3. Or specify full path in setup:
   ```lua
   require("codanna").setup({
     codanna_path = "/full/path/to/codanna",
   })
   ```

### "Index is empty" or "No results"

**Cause**: Project hasn't been indexed, or index is out of date.

**Solution**:
```bash
cd /path/to/your/project
codanna init           # Initialize codanna in this project
codanna index .        # Index all files in current directory
```

Re-run search after indexing.

### "No picker available"

**Cause**: None of the supported picker plugins are installed.

**Solution**: Install at least one of:
- snacks.nvim: `{ "folke/snacks.nvim" }`
- telescope.nvim: `{ "nvim-telescope/telescope.nvim" }`
- mini.pick: `{ "echasnovski/mini.nvim" }`

### Search returns no results but index has data

**Possible causes**:
1. **Query too short**: Minimum 3 characters required for live search
2. **Language not supported**: Check if your file types are supported (Rust, Python, JS, TS, Go, Java, C, C++, C#, Swift, Kotlin, PHP, GDScript)
3. **Files excluded**: Check `.codannaignore` - might be excluding your files
4. **Stale index**: Re-run `codanna index .` to update

### Performance issues / Slow searches

**Solutions**:
1. Increase cache TTL to reduce repeated queries:
   ```lua
   require("codanna").setup({
     cache_ttl_ms = 10000,  -- Cache results for 10 seconds
   })
   ```

2. Adjust debounce for live search:
   ```lua
   require("codanna.telescope").config.debounce_ms = 300
   ```

3. Limit result count:
   ```lua
   require("codanna").semantic_search({ limit = 20 })
   ```

### "Failed to parse JSON response"

**Cause**: Codanna output format changed or contains unexpected data.

**Solution**:
1. Check codanna version: `codanna --version`
2. Try running codanna directly: `codanna mcp semantic_search_with_context "query:test" --json`
3. Check for errors in `:messages`
4. File an issue with the error details

### Symbol under cursor not detected

**Cause**: Cursor is not on a valid symbol.

**Solution**:
1. Ensure cursor is on a word (function name, class, etc.)
2. Or provide symbol explicitly:
   ```vim
   :CodannaCallers my_function_name
   ```

### Commands not available

**Cause**: Plugin not loaded or commands not registered.

**Solution**:
1. Check if plugin loaded: `:lua =require("codanna")`
2. Verify commands exist: `:command Codanna`
3. Try `:checkhealth` to diagnose issues
4. Ensure plugin directory is in runtimepath

### Cache issues / Stale results

**Solution**: Clear the cache manually:
```vim
:lua require("codanna.core").clear_cache()
:lua require("codanna.core").invalidate_index_cache()
```

Or restart Neovim.

## Contributing

Contributions welcome! See [DEVELOPMENT.md](DEVELOPMENT.md) for development setup and guidelines.

## License

MIT

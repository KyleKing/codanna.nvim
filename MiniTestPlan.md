# Codanna.nvim Test Plan

## Prerequisites

1. Install [codanna](https://github.com/bartolli/codanna) CLI
2. Initialize codanna in a test project: `codanna init && codanna index src`
3. Neovim 0.10+ recommended

## Manual Testing

### Quick Start

```bash
# Test with Telescope
make test-telescope

# Test with mini.pick
make test-mini

# Test with snacks.nvim
make test-snacks
```

Or manually:

```bash
nvim --clean -u test/configs/minimal_telescope.lua .
nvim --clean -u test/configs/minimal_mini.lua .
nvim --clean -u test/configs/minimal_snacks.lua .
```

## Test Cases

### TC-01: Plugin Loading

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch nvim with test config | No errors on startup |
| 2 | Run `:checkhealth codanna` | Health check passes (if implemented) |
| 3 | Run `:lua print(vim.inspect(require('codanna')))` | Module loads without error |

### TC-02: Command Registration

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Type `:Codanna` and press Tab | Shows all 5 commands |
| 2 | Run `:CodannaSearch` | Opens picker UI |
| 3 | Run `:CodannaCallers` | Opens picker with callers |
| 4 | Run `:CodannaImplementations` | Opens picker with implementations |
| 5 | Run `:CodannaSymbols` | Opens picker with symbols |
| 6 | Run `:CodannaDocuments` | Opens picker with documents |

### TC-03: Semantic Search (All Pickers)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `:CodannaSearch` | Picker opens |
| 2 | Type fewer than 3 chars | No results (debounced) |
| 3 | Type 3+ chars query | Results appear from codanna |
| 4 | Select a result | Navigates to file:line |
| 5 | Press Escape | Picker closes cleanly |

### TC-04: Find Callers

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Position cursor on function name | - |
| 2 | Run `:CodannaCallers` | Shows callers of function under cursor |
| 3 | Run `:CodannaCallers foo` | Shows callers of `foo` |
| 4 | Select a caller | Navigates to call site |

### TC-05: Find Implementations

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Position cursor on trait/interface | - |
| 2 | Run `:CodannaImplementations` | Shows implementations |
| 3 | Select an implementation | Navigates to implementation |

### TC-06: Symbols

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `:CodannaSymbols` | Shows all indexed symbols |
| 2 | Run `:CodannaSymbols %` | Shows symbols in current file |
| 3 | Filter by typing | Fuzzy matches symbols |
| 4 | Select a symbol | Navigates to definition |

### TC-07: Documents Search

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `:CodannaDocuments` | Picker opens |
| 2 | Type query (3+ chars) | Shows matching documents |
| 3 | Select a document | Opens document |

### TC-08: Picker-Specific Tests

#### Telescope

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `:Telescope codanna semantic_search` | Opens via Telescope extension |
| 2 | Preview enabled | Shows file preview on selection |
| 3 | Multi-select with Tab | Can select multiple items |

#### mini.pick

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `:lua require('codanna.mini').semantic_search()` | Opens mini.pick UI |
| 2 | Toggle preview | Preview shows file content |
| 3 | Marking works | Can mark multiple items |

#### snacks.nvim

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `:lua Snacks.picker.pick('codanna_semantic')` | Opens snacks picker |
| 2 | Live search | Results update as you type |
| 3 | File format | Shows file:line format |

### TC-09: Error Handling

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Stop codanna server | - |
| 2 | Run `:CodannaSearch` | Shows error notification |
| 3 | Search with invalid query | Graceful error handling |

### TC-10: Auto-Detection

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Load config without `preferred_picker` | Picks first available picker |
| 2 | Only have telescope installed | Uses telescope |
| 3 | Only have mini.pick installed | Uses mini.pick |
| 4 | Set `preferred_picker = "telescope"` | Always uses telescope |

## Unit Tests (Future - Mini.Test)

```lua
-- test/codanna_spec.lua
local T = MiniTest.new_set()

T["core"] = MiniTest.new_set()

T["core"]["exec returns parsed JSON"] = function()
  -- Mock vim.system or test with real codanna
end

T["core"]["caching works"] = function()
  -- Test cache hit/miss
end

T["telescope"] = MiniTest.new_set()

T["telescope"]["extension registers"] = function()
  local ok = pcall(require, "telescope._extensions.codanna")
  MiniTest.expect.equality(ok, true)
end

T["mini"] = MiniTest.new_set()

T["mini"]["picker functions exist"] = function()
  local mini = require("codanna.mini")
  MiniTest.expect.equality(type(mini.semantic_search), "function")
end

T["snacks"] = MiniTest.new_set()

T["snacks"]["sources are defined"] = function()
  local snacks = require("codanna.snacks")
  MiniTest.expect.equality(type(snacks.sources.codanna_semantic), "table")
end

return T
```

## Known Limitations

1. Codanna must be running and project must be indexed
2. Semantic search requires minimum 3 character query
3. Preview requires readable files

## Regression Testing

After any changes, run through:
1. All three picker configs load without error
2. Basic search works in each picker
3. Navigation to results works

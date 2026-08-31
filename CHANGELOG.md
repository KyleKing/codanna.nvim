## v0.1.1 (2026-08-31)

### Fix

- satisfy emmylua_check across picker modules

## v0.1.0 (2026-08-31)

### Feat

- initialize codanna.nvim

### Fix

- **test**: address the integration test file absolutely so it runs from the target repo
- **ci**: extract the codanna binary from its versioned archive directory
- **test**: call mini.test setup so the headless runner has MiniTest
- add error handling when index not found
- correctly interact with codanna
- implement debounce and async integration

### Refactor

- introduce utils, LRU caching, testing, and CI

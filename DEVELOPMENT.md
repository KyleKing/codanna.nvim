# Development Guide

This guide is for contributors who want to develop and test codanna.nvim.

## Setup Development Environment

1. Clone the repository:
```bash
git clone https://github.com/kyleking/codanna.nvim
cd codanna.nvim
```

2. Install development dependencies:
```bash
make deps
```

This will install:
- mini.nvim (for testing with mini.test and mini.pick integration)
- telescope.nvim (for testing Telescope integration)
- snacks.nvim (for testing Snacks integration)

## Running Tests

### Automated Unit Tests

Run the unit test suite with:
```bash
make test
```

This runs all unit tests in `test/` using mini.test from mini.nvim.

You can also run the test script directly:
```bash
./scripts/run_tests.sh
```

### Integration Tests

Integration tests verify the plugin works with the real codanna CLI tool against indexed repositories.

Setup test repositories (Flask for Python, Express for JavaScript):
```bash
make setup-test-repos
```

Run integration tests:
```bash
make test-integration
```

This will:
1. Clone Flask and Express repositories at pinned commits
2. Initialize and index them with codanna
3. Run integration tests against both repositories
4. Verify semantic search, symbol search, and other features work end-to-end

Clean test repositories:
```bash
make clean-test-repos
```

### Manual Integration Testing

Test with different picker backends using a real project:

```bash
# Clone and index a test project
make test-project
make index-test-project

# Test with Telescope
make test-telescope

# Test with mini.pick
make test-mini

# Test with snacks.nvim
make test-snacks
```

Or test with your own project:
```bash
make test-telescope PROJECT=/path/to/your/project
```

## Code Quality

### CI/CD

The project uses GitHub Actions for continuous integration:
- **Unit Tests Job**: Runs on Ubuntu and macOS with stable and nightly Neovim
- **Integration Tests Job**: Runs on Ubuntu and macOS with stable Neovim
  - Installs codanna CLI v0.9.13 from GitHub releases (binary)
  - Caches codanna binary, dependencies, and test repositories
  - Tests against real indexed Flask (Python) and Express (JavaScript) repositories
- Checks code formatting (on Ubuntu stable only)

See `.github/workflows/test.yml` for configuration.

### Linting

Check code style with stylua:
```bash
make lint
```

### Formatting

Format code with stylua:
```bash
make format
```

## Project Structure

```
codanna.nvim/
├── .github/
│   └── workflows/
│       └── test.yml          # CI configuration
├── lua/
│   ├── codanna/
│   │   ├── init.lua          # Main module, picker orchestration
│   │   ├── core.lua          # Core API, codanna CLI wrapper
│   │   ├── utils.lua         # Shared utilities
│   │   ├── telescope.lua     # Telescope picker implementation
│   │   ├── mini.lua          # mini.pick implementation
│   │   └── snacks.lua        # snacks.nvim implementation
│   └── telescope/
│       └── _extensions/
│           └── codanna.lua   # Telescope extension registration
├── plugin/
│   └── codanna.lua           # User commands registration
├── scripts/
│   ├── minimal_init.lua      # Test initialization for mini.test
│   └── run_tests.sh          # Test runner script
├── test/
│   ├── test_utils.lua        # Unit tests for utils module
│   ├── test_core.lua         # Unit tests for core module
│   └── configs/              # Manual test configs
│       ├── minimal_telescope.lua
│       ├── minimal_mini.lua
│       └── minimal_snacks.lua
└── Makefile                  # Development tasks
```

## Architecture

### Core Components

1. **core.lua**: Low-level interface to codanna CLI
   - Executes codanna commands via `vim.system()`
   - Handles JSON parsing and error handling
   - Implements LRU cache with 100-entry limit
   - Provides both sync and async APIs

2. **utils.lua**: Shared utility functions
   - Result normalization across different API response formats
   - Input validation (symbols, configuration)
   - JSON parsing with error recovery
   - Cache key generation

3. **Picker Implementations** (telescope.lua, mini.lua, snacks.lua):
   - Adapt core API to picker-specific interfaces
   - Handle debouncing and live search
   - Implement file preview and navigation
   - Share common logic via utils module

4. **init.lua**: Main entry point
   - Picker auto-detection and fallback
   - Configuration management
   - Public API for all commands

### Data Flow

```
User Command (plugin/codanna.lua)
    ↓
Main Module (init.lua) - picks appropriate picker
    ↓
Picker (telescope/mini/snacks.lua) - UI layer
    ↓
Core (core.lua) - executes codanna CLI
    ↓
Utils (utils.lua) - parse and normalize results
    ↓
Back to Picker - display results
```

## Adding New Features

### Adding a New Command

1. Add the core API function in `core.lua`:
```lua
function M.new_command(query, opts)
  opts = opts or {}
  local args = { "new_command", "query:" .. query }
  return M.exec("mcp", args, opts)
end

function M.new_command_async(query, opts, callback)
  -- async version
end
```

2. Add picker functions in `telescope.lua`, `mini.lua`, `snacks.lua`

3. Register user command in `plugin/codanna.lua`:
```lua
vim.api.nvim_create_user_command("CodannaNew", function(opts)
  require("codanna").new_command({ default_text = opts.args })
end, { nargs = "?", desc = "New command" })
```

4. Add tests in `test/test_*.lua` using mini.test format

### Testing Guidelines

- Use mini.test for all unit tests
- Write unit tests for all utility functions
- Test edge cases (nil values, empty arrays, malformed input)
- Test error handling paths
- Use descriptive test names
- Group related tests with `describe` blocks

### Code Style

- Follow existing code patterns
- Use JSDoc-style comments for functions
- Keep functions small and focused
- Prefer explicit over implicit
- Use meaningful variable names

## Common Issues

### Tests Failing

If tests fail, ensure:
- Dependencies are installed: `make deps`
- Neovim version is 0.10+
- mini.nvim is available for mini.test

### Picker Not Loading

Check:
- The picker plugin is installed
- The picker module loads without errors: `:lua =require('telescope')` (or mini, snacks)
- Check `:checkhealth` for dependency issues

## Release Process

1. Update version in README if needed
2. Ensure all tests pass: `make test`
3. Ensure code is formatted: `make format`
4. Update CHANGELOG (if exists)
5. Create git tag
6. Push to GitHub

## Getting Help

- Check existing issues on GitHub
- Read the main README.md
- Look at test files for usage examples
- Review code comments and documentation

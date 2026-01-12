.PHONY: test-telescope test-mini test-snacks clean deps

NVIM ?= nvim

# Test with different picker backends
test-telescope:
	$(NVIM) --clean -u test/configs/minimal_telescope.lua .

test-mini:
	$(NVIM) --clean -u test/configs/minimal_mini.lua .

test-snacks:
	$(NVIM) --clean -u test/configs/minimal_snacks.lua .

# Install test dependencies
deps:
	@mkdir -p .test-deps
	@test -d .test-deps/plenary.nvim || git clone --depth=1 https://github.com/nvim-lua/plenary.nvim .test-deps/plenary.nvim
	@test -d .test-deps/telescope.nvim || git clone --depth=1 https://github.com/nvim-telescope/telescope.nvim .test-deps/telescope.nvim
	@test -d .test-deps/mini.nvim || git clone --depth=1 https://github.com/echasnovski/mini.nvim .test-deps/mini.nvim
	@test -d .test-deps/snacks.nvim || git clone --depth=1 https://github.com/folke/snacks.nvim .test-deps/snacks.nvim
	@echo "Dependencies installed in .test-deps/"

# Clean test dependencies
clean:
	rm -rf .test-deps

# Lint with stylua (if installed)
lint:
	stylua --check lua/

# Format with stylua (if installed)
format:
	stylua lua/

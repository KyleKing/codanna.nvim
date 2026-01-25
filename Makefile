.PHONY: test-telescope test-mini test-snacks clean deps test-project index-test-project test lint format

NVIM ?= nvim
TEST_PROJECT ?= .test-deps/codanna

# Run automated tests with mini.test
test: deps
	@./scripts/run_tests.sh

# Test with different picker backends
# Usage: make test-telescope PROJECT=/path/to/project
test-telescope:
	cd $(or $(PROJECT),$(TEST_PROJECT)) && $(NVIM) --clean -u $(CURDIR)/test/configs/minimal_telescope.lua .

test-mini:
	cd $(or $(PROJECT),$(TEST_PROJECT)) && $(NVIM) --clean -u $(CURDIR)/test/configs/minimal_mini.lua .

test-snacks:
	cd $(or $(PROJECT),$(TEST_PROJECT)) && $(NVIM) --clean -u $(CURDIR)/test/configs/minimal_snacks.lua .

# Clone codanna repo for testing (it's Rust, a supported language)
test-project:
	@mkdir -p .test-deps
	@test -d $(TEST_PROJECT) || git clone --depth=1 https://github.com/bartolli/codanna $(TEST_PROJECT)
	@echo "Test project cloned to $(TEST_PROJECT)"
	@echo "Run 'make index-test-project' to index it with codanna"

# Index the test project with codanna
index-test-project: test-project
	@echo "Indexing $(TEST_PROJECT)..."
	cd $(TEST_PROJECT) && codanna index .
	@echo "Done! Now run 'make test-telescope', 'make test-mini', or 'make test-snacks'"

# Install test dependencies (picker plugins)
deps:
	@mkdir -p .test-deps
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

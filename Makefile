.PHONY: test test-integration test-telescope test-mini test-snacks clean deps test-project index-test-project setup-test-repos lint format clean-test-repos

NVIM ?= nvim
TEST_PROJECT ?= .test-deps/codanna
TEST_REPOS_DIR ?= test-repos

# Pinned tags/commits for test repositories
# Using recent stable releases for reproducibility
FLASK_REF ?= 3.0.0
EXPRESS_REF ?= 4.18.2

# Run automated unit tests with mini.test
test: deps
	@./scripts/run_tests.sh

# Run integration tests with real codanna CLI
test-integration: deps setup-test-repos
	@./scripts/run_integration_tests.sh

# Setup test repositories for integration testing
setup-test-repos:
	@echo "Setting up test repositories..."
	@mkdir -p $(TEST_REPOS_DIR)
	
	# Clone Flask (Python) at pinned tag
	@if [ ! -d "$(TEST_REPOS_DIR)/flask" ]; then \
		echo "Cloning Flask $(FLASK_REF)..."; \
		git clone --branch $(FLASK_REF) --depth=1 https://github.com/pallets/flask $(TEST_REPOS_DIR)/flask; \
	fi
	
	# Clone Express (JavaScript) at pinned tag
	@if [ ! -d "$(TEST_REPOS_DIR)/express" ]; then \
		echo "Cloning Express $(EXPRESS_REF)..."; \
		git clone --branch $(EXPRESS_REF) --depth=1 https://github.com/expressjs/express $(TEST_REPOS_DIR)/express; \
	fi
	
	# Initialize and index repositories with codanna
	@echo "Initializing codanna indexes..."
	@cd $(TEST_REPOS_DIR)/flask && (codanna init || true) && codanna index .
	@cd $(TEST_REPOS_DIR)/express && (codanna init || true) && codanna index .
	@echo "Test repositories ready in $(TEST_REPOS_DIR)/"

# Clean test repositories
clean-test-repos:
	rm -rf $(TEST_REPOS_DIR)

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
	rm -rf .test-deps $(TEST_REPOS_DIR)

# Lint with stylua (if installed)
lint:
	stylua --check lua/

# Format with stylua (if installed)
format:
	stylua lua/

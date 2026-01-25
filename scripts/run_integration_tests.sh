#!/usr/bin/env bash
# Integration test runner script for codanna.nvim
# Runs integration tests against real indexed repositories

set -e

NVIM="${NVIM:-nvim}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_REPOS_DIR="${TEST_REPOS_DIR:-test-repos}"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running codanna.nvim integration tests...${NC}"
echo ""

# Check if codanna is installed
if ! command -v codanna &> /dev/null; then
    echo -e "${RED}✗ codanna CLI not found${NC}"
    echo "Please install codanna: https://github.com/bartolli/codanna"
    exit 1
fi

echo -e "${BLUE}Using codanna version: $(codanna --version)${NC}"
echo ""

# Check if test repositories exist
if [ ! -d "$TEST_REPOS_DIR/flask" ] || [ ! -d "$TEST_REPOS_DIR/express" ]; then
    echo -e "${YELLOW}Test repositories not found. Run 'make setup-test-repos' first.${NC}"
    exit 1
fi

echo -e "${BLUE}Test repositories found in $TEST_REPOS_DIR/${NC}"
echo ""

# Run integration tests for Flask (Python)
echo -e "${YELLOW}Running tests against Flask repository...${NC}"
cd "$PROJECT_DIR/$TEST_REPOS_DIR/flask"
if $NVIM --headless --noplugin -u "$PROJECT_DIR/scripts/minimal_init.lua" \
  -c "lua MiniTest.run_file('$PROJECT_DIR/test/test_integration.lua')" 2>&1; then
  echo -e "${GREEN}✓ Flask integration tests passed${NC}"
  FLASK_RESULT=0
else
  echo -e "${RED}✗ Flask integration tests failed${NC}"
  FLASK_RESULT=1
fi
echo ""

# Run integration tests for Express (JavaScript)
echo -e "${YELLOW}Running tests against Express repository...${NC}"
cd "$PROJECT_DIR/$TEST_REPOS_DIR/express"
if $NVIM --headless --noplugin -u "$PROJECT_DIR/scripts/minimal_init.lua" \
  -c "lua MiniTest.run_file('$PROJECT_DIR/test/test_integration.lua')" 2>&1; then
  echo -e "${GREEN}✓ Express integration tests passed${NC}"
  EXPRESS_RESULT=0
else
  echo -e "${RED}✗ Express integration tests failed${NC}"
  EXPRESS_RESULT=1
fi
echo ""

# Return to project directory
cd "$PROJECT_DIR"

# Summary
echo "----------------------------------------"
if [ $FLASK_RESULT -eq 0 ] && [ $EXPRESS_RESULT -eq 0 ]; then
  echo -e "${GREEN}✓ All integration tests passed${NC}"
  exit 0
else
  echo -e "${RED}✗ Some integration tests failed${NC}"
  [ $FLASK_RESULT -ne 0 ] && echo -e "  ${RED}✗ Flask tests failed${NC}"
  [ $EXPRESS_RESULT -ne 0 ] && echo -e "  ${RED}✗ Express tests failed${NC}"
  exit 1
fi

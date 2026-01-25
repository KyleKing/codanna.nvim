#!/usr/bin/env bash
# Test runner script for codanna.nvim using mini.test

set -e

NVIM="${NVIM:-nvim}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running codanna.nvim tests with mini.test...${NC}"
echo ""

# Run tests
if $NVIM --headless --noplugin -u scripts/minimal_init.lua \
  -c "lua MiniTest.run_file('test/test_utils.lua')" \
  -c "lua MiniTest.run_file('test/test_core.lua')" 2>&1; then
  echo ""
  echo -e "${GREEN}✓ All tests passed${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Tests failed${NC}"
  exit 1
fi

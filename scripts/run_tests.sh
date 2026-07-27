#!/usr/bin/env bash
# Test runner script for codanna.nvim using mini.test
# Each file runs in its own Neovim because the mini.test stdout reporter
# quits the process as soon as it finishes a run.

set -uo pipefail

NVIM="${NVIM:-nvim}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TEST_FILES=(test/test_utils.lua test/test_core.lua)

echo -e "${YELLOW}Running codanna.nvim tests with mini.test...${NC}"
echo ""

FAILED=()
for test_file in "${TEST_FILES[@]}"; do
  echo -e "${YELLOW}--- ${test_file} ---${NC}"
  if $NVIM --headless --noplugin -u scripts/minimal_init.lua \
    -c "lua MiniTest.run_file('${test_file}')" 2>&1; then
    echo -e "${GREEN}✓ ${test_file} passed${NC}"
  else
    echo -e "${RED}✗ ${test_file} failed${NC}"
    FAILED+=("$test_file")
  fi
  echo ""
done

echo "----------------------------------------"
if [ ${#FAILED[@]} -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed${NC}"
  exit 0
fi

echo -e "${RED}✗ Tests failed${NC}"
for test_file in "${FAILED[@]}"; do
  echo -e "  ${RED}✗ ${test_file}${NC}"
done
exit 1

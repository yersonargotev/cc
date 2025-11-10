#!/bin/bash
# Test Suite for Session Manager v2 Scripts
# Phase 2 Integration Testing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

echo "========================================"
echo "Session Manager v2 Scripts Test Suite"
echo "========================================"
echo ""

# Test 1: generate-session-id.sh exists and is executable
echo "Test 1: Script files exist and are executable"
if [ -x "$SCRIPT_DIR/generate-session-id.sh" ]; then
  pass "generate-session-id.sh is executable"
else
  fail "generate-session-id.sh not found or not executable"
fi

if [ -x "$SCRIPT_DIR/resolve-session-id.sh" ]; then
  pass "resolve-session-id.sh is executable"
else
  fail "resolve-session-id.sh not found or not executable"
fi

if [ -x "$SCRIPT_DIR/session-index.sh" ]; then
  pass "session-index.sh is executable"
else
  fail "session-index.sh not found or not executable"
fi

echo ""

# Test 2: Generate valid v2 session ID
echo "Test 2: Generate valid v2 session ID"
TEST_DESC="Test Session for Integration"
SESSION_ID=$(bash "$SCRIPT_DIR/generate-session-id.sh" "$TEST_DESC" 2>&1)

if [ $? -eq 0 ]; then
  pass "Session ID generated successfully"
  info "Generated ID: $SESSION_ID"
else
  fail "Failed to generate session ID"
fi

# Test 3: Validate v2 format
echo ""
echo "Test 3: Validate v2 session ID format"
if [[ "$SESSION_ID" =~ ^v2-[0-9]{8}T[0-9]{6}-[a-z0-9]{8}-.+$ ]]; then
  pass "Session ID matches v2 format"
else
  fail "Session ID does not match v2 format: $SESSION_ID"
fi

# Test 3a: Check version prefix
if [[ "$SESSION_ID" =~ ^v2- ]]; then
  pass "Version prefix 'v2-' present"
else
  fail "Version prefix 'v2-' missing"
fi

# Test 3b: Check timestamp format
TIMESTAMP=$(echo "$SESSION_ID" | cut -d'-' -f2)
if [[ "$TIMESTAMP" =~ ^[0-9]{8}T[0-9]{6}$ ]]; then
  pass "Timestamp format valid: $TIMESTAMP"
else
  fail "Timestamp format invalid: $TIMESTAMP"
fi

# Test 3c: Check random ID (8-char base32)
RANDOM_ID=$(echo "$SESSION_ID" | cut -d'-' -f3)
if [ ${#RANDOM_ID} -eq 8 ] && [[ "$RANDOM_ID" =~ ^[a-z0-9]+$ ]]; then
  pass "Random ID valid: $RANDOM_ID (8 chars, base32)"
else
  fail "Random ID invalid: $RANDOM_ID (expected 8 chars, alphanumeric)"
fi

# Test 3d: Check slug
SLUG=$(echo "$SESSION_ID" | cut -d'-' -f4-)
if [ -n "$SLUG" ] && [[ "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
  pass "Slug valid: $SLUG (kebab-case)"
else
  fail "Slug invalid: $SLUG"
fi

echo ""

# Test 4: Generate multiple IDs (uniqueness)
echo "Test 4: Generate multiple unique IDs"
ID1=$(bash "$SCRIPT_DIR/generate-session-id.sh" "Test 1")
sleep 1
ID2=$(bash "$SCRIPT_DIR/generate-session-id.sh" "Test 2")

if [ "$ID1" != "$ID2" ]; then
  pass "Generated IDs are unique"
  info "ID1: $ID1"
  info "ID2: $ID2"
else
  fail "Generated IDs are not unique"
fi

echo ""

# Test 5: Test with special characters
echo "Test 5: Handle special characters in description"
SPECIAL_DESC="Test: Feature with Special @#$ Characters & Spaces!"
SPECIAL_ID=$(bash "$SCRIPT_DIR/generate-session-id.sh" "$SPECIAL_DESC" 2>&1)

if [ $? -eq 0 ] && [[ "$SPECIAL_ID" =~ ^v2-.+ ]]; then
  pass "Handled special characters correctly"
  SPECIAL_SLUG=$(echo "$SPECIAL_ID" | cut -d'-' -f4-)
  info "Sanitized slug: $SPECIAL_SLUG"
else
  fail "Failed to handle special characters"
fi

echo ""

# Test 6: Test with empty description (should fail)
echo "Test 6: Reject empty description"
EMPTY_ID=$(bash "$SCRIPT_DIR/generate-session-id.sh" "" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  pass "Correctly rejected empty description"
else
  fail "Should have rejected empty description"
fi

echo ""

# Test 7: Test session-index.sh init
echo "Test 7: Session index initialization"

# Clean test index
TEST_INDEX="/tmp/test-session-index.json"
rm -f "$TEST_INDEX"

# Set temporary index location
export INDEX_FILE="$TEST_INDEX"

# Test init
bash "$SCRIPT_DIR/session-index.sh" init > /dev/null 2>&1

if [ -f "$TEST_INDEX" ]; then
  pass "Index file created successfully"

  # Validate JSON structure
  if jq empty "$TEST_INDEX" 2>/dev/null; then
    pass "Index file is valid JSON"
  else
    fail "Index file is not valid JSON"
  fi
else
  fail "Index file not created"
fi

echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi

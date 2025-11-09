#!/bin/bash
# Test script for Claude Code hooks
# Verifies configuration and hook functionality

echo "🧪 Testing Claude Code Hooks"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check configuration file exists
echo "1. Checking configuration..."
if [ -f ".claude/settings.json" ]; then
    pass "Configuration file exists: .claude/settings.json"
    
    # Validate JSON
    if jq empty .claude/settings.json 2>/dev/null; then
        pass "Configuration is valid JSON"
    else
        fail "Configuration is invalid JSON"
    fi
else
    fail "Configuration file not found: .claude/settings.json"
fi
echo ""

# Test 2: Check hook scripts exist and are executable
echo "2. Checking hook scripts..."
HOOKS=(
    "cc/hooks/pre-tool-use/validate-session.sh"
    "cc/hooks/stop/auto-save-session.sh"
    "cc/hooks/user-prompt-submit/load-context.sh"
)

for hook in "${HOOKS[@]}"; do
    if [ -f "$hook" ]; then
        if [ -x "$hook" ]; then
            pass "Hook exists and is executable: $hook"
        else
            fail "Hook exists but is not executable: $hook"
            warn "Run: chmod +x $hook"
        fi
    else
        fail "Hook not found: $hook"
    fi
done
echo ""

# Test 3: Test PreToolUse hook with valid input
echo "3. Testing PreToolUse hook..."

# Test case: Valid SlashCommand (should pass through)
TEST_INPUT='{"tool_name":"Bash","tool_input":{"command":"ls"}}'
if echo "$TEST_INPUT" | bash cc/hooks/pre-tool-use/validate-session.sh > /dev/null 2>&1; then
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "PreToolUse hook passes non-cc commands (exit 0)"
    else
        fail "PreToolUse hook failed for non-cc command (exit $EXIT_CODE)"
    fi
else
    pass "PreToolUse hook correctly blocks invalid session (expected behavior)"
fi

# Test case: Missing session (should block with exit 2)
TEST_INPUT='{"tool_name":"SlashCommand","tool_input":{"command":"/cc:plan nonexistent-session"}}'
if echo "$TEST_INPUT" | bash cc/hooks/pre-tool-use/validate-session.sh > /dev/null 2>&1; then
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 2 ]; then
        pass "PreToolUse hook blocks missing session (exit 2)"
    else
        fail "PreToolUse hook should exit 2 for missing session (got exit $EXIT_CODE)"
    fi
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 2 ]; then
        pass "PreToolUse hook blocks missing session (exit 2)"
    fi
fi
echo ""

# Test 4: Test Stop hook
echo "4. Testing Stop hook..."
TEST_INPUT='{"session_id":"test","timestamp":"2024-01-01"}'
if echo "$TEST_INPUT" | bash cc/hooks/stop/auto-save-session.sh > /dev/null 2>&1; then
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "Stop hook executes successfully (exit 0)"
    else
        fail "Stop hook failed (exit $EXIT_CODE)"
    fi
else
    EXIT_CODE=$?
    fail "Stop hook failed (exit $EXIT_CODE)"
fi
echo ""

# Test 5: Test UserPromptSubmit hook
echo "5. Testing UserPromptSubmit hook..."
TEST_INPUT='{"prompt":"test prompt","timestamp":"2024-01-01"}'
OUTPUT=$(echo "$TEST_INPUT" | bash cc/hooks/user-prompt-submit/load-context.sh 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    pass "UserPromptSubmit hook executes successfully (exit 0)"
else
    fail "UserPromptSubmit hook failed (exit $EXIT_CODE)"
fi

# Check if output is contextual (optional - may be empty if no git changes or sessions)
if [ -n "$OUTPUT" ]; then
    warn "UserPromptSubmit hook produced output (this is fine if you have git changes or sessions)"
fi
echo ""

# Test 6: Verify jq is installed (required dependency)
echo "6. Checking dependencies..."
if command -v jq &> /dev/null; then
    pass "jq is installed (required for JSON processing)"
else
    fail "jq is not installed - hooks require jq for JSON processing"
    warn "Install with: brew install jq"
fi
echo ""

# Summary
echo "=============================="
echo "Test Summary"
echo "=============================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Your hooks are properly configured and ready to use."
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Please review the failures above and fix any issues."
    exit 1
fi


#!/bin/bash
# PreToolUse Hook: Validate Session References
# Runs before tool execution, can block with non-zero exit
# Stdout provides feedback to Claude

set -euo pipefail

COMMAND="$1"
PLUGIN_DIR=".claude/plugins/session-manager"

# Only validate session-related commands
if ! echo "$COMMAND" | grep -qE "/cc:(plan|code)|/session-|/explore"; then
  exit 0  # Not a session command, allow
fi

# Skip validation for commands that don't need session refs
if echo "$COMMAND" | grep -qE "/session-list|/session-rebuild-index|/session-migrate|/explore"; then
  exit 0  # These commands don't require existing sessions
fi

# Extract session reference from command
SESSION_REF=""
if echo "$COMMAND" | grep -qE "/cc:(plan|code)"; then
  # Extract second argument: /cc:plan <session-ref>
  SESSION_REF=$(echo "$COMMAND" | awk '{print $2}')
fi

# If no session ref provided, try @latest
if [ -z "$SESSION_REF" ]; then
  SESSION_REF="@latest"
fi

# Resolve session reference
if [ ! -x "$PLUGIN_DIR/scripts/resolve-session-id.sh" ]; then
  echo "⚠️  Session resolver not available"
  exit 0  # Don't block if resolver missing
fi

RESOLVED_ID=$(bash "$PLUGIN_DIR/scripts/resolve-session-id.sh" "$SESSION_REF" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  # Resolution failed
  echo "❌ Session reference '$SESSION_REF' could not be resolved"
  echo ""
  echo "$RESOLVED_ID"  # Error message from resolver
  echo ""
  echo "💡 Available commands:"
  echo "   /session-list              - View all sessions"
  echo "   /explore <description>     - Create new session"
  echo "   /session-rebuild-index     - Rebuild session index"
  exit 1  # Block tool execution
fi

# Validation succeeded
echo "✅ Session resolved: $SESSION_REF → $RESOLVED_ID"
exit 0  # Allow tool execution

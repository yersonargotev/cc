#!/bin/bash
# PreToolUse Hook: Unified Session Validation
# Combines CC workflow validation + Session Manager v2 reference resolver
#
# Features:
# - Resolves session references (@latest, short IDs, slug search)
# - Validates workflow sequence (explore → plan → code)
# - Provides helpful error messages
#
# Exit codes:
#   0 = Allow (pass through)
#   1 = Block with error message
#   2 = Block and provide feedback to Claude

set -euo pipefail

PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name and command from JSON
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only validate for SlashCommand tool with cc:plan or cc:code
if [ "$TOOL_NAME" != "SlashCommand" ]; then
  exit 0  # Not a slash command, allow
fi

if ! echo "$COMMAND" | grep -qE '/cc:(plan|code)'; then
  exit 0  # Not plan/code command, allow
fi

# Extract session reference (first argument after command)
SESSION_REF=$(echo "$COMMAND" | awk '{print $2}')

# Default to @latest if not provided
if [ -z "$SESSION_REF" ]; then
  SESSION_REF="@latest"
fi

# Check if resolver script exists
if [ ! -x "$PLUGIN_DIR/scripts/resolve-session-id.sh" ]; then
  echo "⚠️  Warning: Session resolver not available"
  echo ""
  echo "Using fallback validation..."

  # Fallback: try v1 format with find
  SESSION_DIR=$(find .claude/sessions -name "${SESSION_REF}_*" -type d 2>/dev/null | head -1)

  if [ -z "$SESSION_DIR" ]; then
    echo "❌ Validation Error: Session '$SESSION_REF' not found"
    echo ""
    echo "Available sessions:"
    if [ -d ".claude/sessions" ]; then
      ls -1 .claude/sessions/ | sed 's/^/  - /'
    else
      echo "  No sessions found"
    fi
    echo ""
    echo "💡 Tip: Start with /cc:explore to create a new session"
    exit 2
  fi

  # Check plan exists for code phase (fallback)
  if echo "$COMMAND" | grep -q '/cc:code'; then
    if [ ! -f "$SESSION_DIR/plan.md" ]; then
      echo "❌ Validation Error: No plan found for session '$SESSION_REF'"
      echo ""
      echo "💡 Run /cc:plan $SESSION_REF to create implementation plan first"
      exit 2
    fi
  fi

  exit 0
fi

# Use resolver to resolve session reference
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
  echo "   /cc:explore <description>  - Create new session"
  echo "   /session-rebuild-index     - Rebuild session index"
  exit 2  # Block with feedback to Claude
fi

# Resolution succeeded - validate workflow requirements
SESSION_DIR=".claude/sessions/${RESOLVED_ID}"

# Verify session directory exists
if [ ! -d "$SESSION_DIR" ]; then
  echo "❌ Validation Error: Session directory not found"
  echo ""
  echo "Resolved ID: $RESOLVED_ID"
  echo "Expected path: $SESSION_DIR"
  echo ""
  echo "💡 Try running: /session-rebuild-index"
  exit 2
fi

# For code phase, ensure plan exists
if echo "$COMMAND" | grep -q '/cc:code'; then
  if [ ! -f "$SESSION_DIR/plan.md" ]; then
    echo "❌ Validation Error: No plan found for session"
    echo ""
    echo "Session: $RESOLVED_ID"
    echo ""
    echo "💡 Run /cc:plan $SESSION_REF to create implementation plan first"
    exit 2
  fi
fi

# All validations passed
echo "✅ Session resolved: $SESSION_REF → $RESOLVED_ID"
echo ""

exit 0  # Allow tool execution

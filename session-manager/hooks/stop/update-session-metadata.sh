#!/bin/bash
# Stop Hook: Update Session Metadata
# Runs after each Claude response completes
# Stdout not visible to user

set -euo pipefail

INDEX_FILE=".claude/sessions/index.json"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# Check requirements (silently fail if missing)
if [ ! -f "$INDEX_FILE" ] || ! command -v jq &> /dev/null; then
  exit 0
fi

# Get latest session
LATEST_ID=$(jq -r '.refs["@latest"] // empty' "$INDEX_FILE" 2>/dev/null)

if [ -z "$LATEST_ID" ]; then
  exit 0  # No active session
fi

# Update timestamp (lightweight operation)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Use index manager for atomic update
if [ -x "$PLUGIN_DIR/scripts/session-index.sh" ]; then
  bash "$PLUGIN_DIR/scripts/session-index.sh" update "$LATEST_ID" \
    "updated=$TIMESTAMP" &>/dev/null || true
fi

# Append to activity log (don't read it to save tokens)
SESSION_DIR=".claude/sessions/$LATEST_ID"
if [ -d "$SESSION_DIR" ]; then
  echo "[$(date)] Activity" >> "$SESSION_DIR/activity.log" 2>/dev/null || true
fi

exit 0

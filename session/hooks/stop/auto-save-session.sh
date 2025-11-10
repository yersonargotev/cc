#!/bin/bash
# Stop Hook: Unified Session State Management
# Combines CC auto-save + Session Manager v2 index updates
#
# Features:
# - Updates CLAUDE.md timestamps
# - Updates session index
# - Appends to activity log
# - Supports both v1 and v2 session formats
#
# Runs after each Claude response completes
# Stdout not visible to user

# Read stdin (required even if not used)
cat > /dev/null

INDEX_FILE=".claude/sessions/index.json"
PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"
TIMESTAMP_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
TIMESTAMP_LOCAL=$(date '+%Y-%m-%d %H:%M')

# Find active session (try v2 first, then v1)
ACTIVE_SESSION=""

# Method 1: Try @latest from index (v2 sessions)
if [ -f "$INDEX_FILE" ] && command -v jq &> /dev/null; then
  LATEST_ID=$(jq -r '.refs["@latest"] // empty' "$INDEX_FILE" 2>/dev/null)

  if [ -n "$LATEST_ID" ]; then
    SESSION_DIR=".claude/sessions/$LATEST_ID"
    if [ -d "$SESSION_DIR" ]; then
      ACTIVE_SESSION="$SESSION_DIR"
    fi
  fi
fi

# Method 2: Fallback - most recently modified session (v1 or v2)
if [ -z "$ACTIVE_SESSION" ]; then
  # Find sessions with CLAUDE.md, sort by modification time
  ACTIVE_SESSION=$(find .claude/sessions -maxdepth 1 -type d \( -name "20*" -o -name "v2-*" \) 2>/dev/null | \
    while read dir; do
      if [ -f "$dir/CLAUDE.md" ]; then
        stat -c "%Y $dir" "$dir/CLAUDE.md" 2>/dev/null || \
        stat -f "%m $dir" "$dir/CLAUDE.md" 2>/dev/null
      fi
    done | sort -rn | head -1 | awk '{print $2}')
fi

# If no active session found, exit silently
if [ -z "$ACTIVE_SESSION" ] || [ ! -f "$ACTIVE_SESSION/CLAUDE.md" ]; then
  exit 0
fi

SESSION_ID=$(basename "$ACTIVE_SESSION")

# Update CLAUDE.md timestamp
if grep -q "^Last Updated:" "$ACTIVE_SESSION/CLAUDE.md" 2>/dev/null; then
  # Update existing timestamp (cross-platform sed)
  if sed --version 2>&1 | grep -q "GNU"; then
    # GNU sed (Linux)
    sed -i "s/^Last Updated:.*/Last Updated: $TIMESTAMP_LOCAL/" "$ACTIVE_SESSION/CLAUDE.md"
  else
    # BSD sed (macOS)
    sed -i '' "s/^Last Updated:.*/Last Updated: $TIMESTAMP_LOCAL/" "$ACTIVE_SESSION/CLAUDE.md"
  fi
fi

# Update activity log
ACTIVITY_LOG="$ACTIVE_SESSION/activity.log"
echo "[$TIMESTAMP_ISO] Session checkpoint" >> "$ACTIVITY_LOG" 2>/dev/null || true

# Update session index (if v2 session and index available)
if [[ "$SESSION_ID" =~ ^v2- ]] && [ -f "$INDEX_FILE" ] && [ -x "$PLUGIN_DIR/scripts/session-index.sh" ]; then
  bash "$PLUGIN_DIR/scripts/session-index.sh" update "$SESSION_ID" \
    "updated=$TIMESTAMP_ISO" &>/dev/null || true
fi

# Silent success
exit 0

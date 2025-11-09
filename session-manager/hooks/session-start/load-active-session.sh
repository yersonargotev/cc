#!/bin/bash
# SessionStart Hook: Auto-load Active Session
# Runs when Claude Code starts or resumes a session
# Stdout is injected as context

set -euo pipefail

INDEX_FILE=".claude/sessions/index.json"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# Ensure index exists
if [ ! -f "$INDEX_FILE" ]; then
  if [ -x "$PLUGIN_DIR/scripts/session-index.sh" ]; then
    bash "$PLUGIN_DIR/scripts/session-index.sh" init &>/dev/null || true
  fi
fi

# Check if index exists now
if [ ! -f "$INDEX_FILE" ]; then
  echo "💡 No sessions yet. Create one with: /explore <description>"
  exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "⚠️  jq not available, session features limited"
  exit 0
fi

# Get @latest reference from index (fast, no directory scan)
LATEST_ID=$(jq -r '.refs["@latest"] // empty' "$INDEX_FILE" 2>/dev/null)

if [ -z "$LATEST_ID" ]; then
  echo "💡 No active session. Start with: /explore <description>"
  exit 0
fi

# Get session metadata from index
SESSION_DATA=$(jq -r ".sessions[\"$LATEST_ID\"] // empty" "$INDEX_FILE" 2>/dev/null)

if [ -z "$SESSION_DATA" ]; then
  echo "⚠️  Session index may be corrupt. Run: /session-rebuild-index"
  exit 0
fi

# Extract session info
SLUG=$(echo "$SESSION_DATA" | jq -r '.slug // "unknown"')
PHASE=$(echo "$SESSION_DATA" | jq -r '.phase // "unknown"')
STATUS=$(echo "$SESSION_DATA" | jq -r '.status // "unknown"')
UPDATED=$(echo "$SESSION_DATA" | jq -r '.updated // "unknown"')
BRANCH=$(echo "$SESSION_DATA" | jq -r '.branch // "main"')

# Calculate relative time (simplified)
AGE="unknown"
if [ "$UPDATED" != "unknown" ]; then
  if command -v date &> /dev/null; then
    UPDATED_TS=$(date -d "$UPDATED" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$UPDATED" +%s 2>/dev/null || echo "0")
    NOW_TS=$(date +%s)
    DIFF=$((NOW_TS - UPDATED_TS))

    if [ $DIFF -lt 3600 ]; then
      AGE="$((DIFF / 60))m ago"
    elif [ $DIFF -lt 86400 ]; then
      AGE="$((DIFF / 3600))h ago"
    else
      AGE="$((DIFF / 86400))d ago"
    fi
  fi
fi

# Extract short ID (8-char random part)
SHORT_ID=$(echo "$LATEST_ID" | cut -d'-' -f3)

# Status emoji
case "$STATUS" in
  in_progress) STATUS_ICON="🟢" ;;
  completed) STATUS_ICON="✅" ;;
  archived) STATUS_ICON="📦" ;;
  *) STATUS_ICON="⚪" ;;
esac

# Phase emoji
case "$PHASE" in
  exploration) PHASE_ICON="🔍" ;;
  planning) PHASE_ICON="📋" ;;
  implementation) PHASE_ICON="⚙️" ;;
  testing) PHASE_ICON="🧪" ;;
  review) PHASE_ICON="👀" ;;
  *) PHASE_ICON="📌" ;;
esac

# Output context (injected into Claude's context window)
cat <<EOF
📊 Active Session Loaded

  ${STATUS_ICON} ${LATEST_ID}

  Name: ${SLUG}
  Phase: ${PHASE_ICON} ${PHASE}
  Status: ${STATUS}
  Updated: ${AGE}
  Branch: ${BRANCH}

📁 Session context auto-loaded from:
   .claude/sessions/${LATEST_ID}/CLAUDE.md

💡 Quick references:
   @latest, @, ${SHORT_ID}, @/${SLUG}

🚀 Continue working:
   /cc:plan @latest     - Create/update plan
   /cc:code @latest     - Start implementation
   /session-list        - View all sessions
EOF

exit 0

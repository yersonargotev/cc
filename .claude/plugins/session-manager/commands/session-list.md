List and browse sessions with filtering and sorting.

**Usage**: `/session-list [filter] [--limit N]`

**Examples**:
```
/session-list                  # List recent sessions
/session-list auth             # Filter by keyword
/session-list --limit 5        # Limit to 5 results
/session-list feature --limit 10  # Filter + limit
```

---

**Execute**:

```bash
#!/bin/bash
set -euo pipefail

PLUGIN_DIR=".claude/plugins/session-manager"
INDEX_FILE=".claude/sessions/index.json"

# Parse arguments
FILTER=""
LIMIT=10

while [ $# -gt 0 ]; do
  case "$1" in
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --limit=*)
      LIMIT="${1#*=}"
      shift
      ;;
    *)
      FILTER="$1"
      shift
      ;;
  esac
done

# Check requirements
if [ ! -f "$INDEX_FILE" ]; then
  echo "❌ No session index found"
  echo ""
  echo "💡 Create your first session:"
  echo "   /explore <description>"
  echo ""
  echo "Or rebuild index from existing sessions:"
  echo "   /session-rebuild-index"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ jq is required but not installed"
  echo "Install: sudo apt-get install jq  (or brew install jq on macOS)"
  exit 1
fi

# Get total session count
TOTAL=$(jq '.sessions | length' "$INDEX_FILE" 2>/dev/null)

echo "📋 Sessions ($TOTAL total)"
echo ""

# Apply filter if provided
if [ -n "$FILTER" ]; then
  echo "🔍 Filter: '$FILTER'"
  echo ""

  SESSIONS=$(jq -r --arg filter "$FILTER" \
    '.sessions | to_entries[] |
     select(.value.slug | test($filter; "i")) |
     "\(.key)|\(.value.slug)|\(.value.phase)|\(.value.status)|\(.value.updated)|\(.value.branch)"' \
    "$INDEX_FILE" 2>/dev/null)
else
  # Show recent sessions (sorted by updated time, descending)
  SESSIONS=$(jq -r \
    '.sessions | to_entries |
     sort_by(.value.updated) | reverse |
     .[] | "\(.key)|\(.value.slug)|\(.value.phase)|\(.value.status)|\(.value.updated)|\(.value.branch)"' \
    "$INDEX_FILE" 2>/dev/null)
fi

# Check if any results
if [ -z "$SESSIONS" ]; then
  if [ -n "$FILTER" ]; then
    echo "❌ No sessions found matching: $FILTER"
    echo ""
    echo "💡 Try:"
    echo "   /session-list              - View all sessions"
    echo "   /explore <description>     - Create new session"
  else
    echo "❌ No sessions found"
    echo ""
    echo "💡 Create your first session:"
    echo "   /explore <description>"
  fi
  exit 0
fi

# Limit results
SESSIONS=$(echo "$SESSIONS" | head -n "$LIMIT")
SHOWN=$(echo "$SESSIONS" | wc -l | tr -d ' ')

# Format output
COUNT=0
echo "$SESSIONS" | while IFS='|' read -r id slug phase status updated branch; do
  COUNT=$((COUNT + 1))

  # Status icon
  case "$status" in
    in_progress) ICON="🟢" ;;
    completed) ICON="✅" ;;
    archived) ICON="📦" ;;
    paused) ICON="⏸️" ;;
    *) ICON="⚪" ;;
  esac

  # Phase emoji
  case "$phase" in
    exploration) PHASE_EMOJI="🔍" ;;
    planning) PHASE_EMOJI="📋" ;;
    implementation) PHASE_EMOJI="⚙️" ;;
    testing) PHASE_EMOJI="🧪" ;;
    review) PHASE_EMOJI="👀" ;;
    *) PHASE_EMOJI="📌" ;;
  esac

  # Extract short ID
  SHORT_ID=$(echo "$id" | cut -d'-' -f3)

  # Calculate relative time
  AGE="unknown"
  if [ -n "$updated" ] && command -v date &> /dev/null; then
    UPDATED_TS=$(date -d "$updated" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated" +%s 2>/dev/null || echo "0")
    NOW_TS=$(date +%s)
    DIFF=$((NOW_TS - UPDATED_TS))

    if [ $DIFF -lt 60 ]; then
      AGE="just now"
    elif [ $DIFF -lt 3600 ]; then
      AGE="$((DIFF / 60))m ago"
    elif [ $DIFF -lt 86400 ]; then
      AGE="$((DIFF / 3600))h ago"
    else
      AGE="$((DIFF / 86400))d ago"
    fi
  fi

  # Check if this is @latest
  LATEST_MARKER=""
  LATEST_ID=$(jq -r '.refs["@latest"] // empty' "$INDEX_FILE" 2>/dev/null)
  if [ "$id" = "$LATEST_ID" ]; then
    LATEST_MARKER=" ⭐ @latest"
  fi

  # Output formatted entry
  echo "${COUNT}. $ICON $id$LATEST_MARKER"
  echo "     Name: $slug"
  echo "     Phase: $PHASE_EMOJI $phase | Status: $status"
  echo "     Updated: $AGE | Branch: $branch"
  echo "     Quick refs: @latest, $SHORT_ID, @/$slug"
  echo ""
done

# Show references
echo "📌 Quick References:"
jq -r '.refs | to_entries |
       sort_by(.key) |
       .[] | "   \(.key) → \(.value)"' \
       "$INDEX_FILE" 2>/dev/null | head -10
echo ""

# Show stats
if [ "$SHOWN" -lt "$TOTAL" ]; then
  echo "📊 Showing $SHOWN of $TOTAL sessions"
  echo "   Use --limit to show more: /session-list --limit 20"
  echo ""
fi

# Show available actions
echo "💡 Commands:"
echo "   /cc:plan <ref>              - Create/update plan"
echo "   /cc:code <ref>              - Start implementation"
echo "   /explore <description>      - Create new session"
echo "   /session-list <keyword>     - Filter sessions"
echo "   /session-migrate            - Migrate v1 sessions to v2"
echo "   /session-rebuild-index      - Rebuild session index"
```

Rebuild session index from session directories (recovery tool).

**Usage**: `/session-rebuild-index [--verify]`

**Modes**:
- Default: Rebuild index from all session directories
- `--verify`: Verify index integrity without rebuilding

**When to use**:
- Index file is missing or corrupted
- Sessions not showing up in /session-list
- After manual directory changes
- Reference resolution failures

**Examples**:
```
/session-rebuild-index           # Rebuild index
/session-rebuild-index --verify  # Check integrity
```

---

**Execute**:

```bash
#!/bin/bash
set -euo pipefail

PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"
INDEX_FILE=".claude/sessions/index.json"

# Parse arguments
MODE="rebuild"
if [ "${1:-}" = "--verify" ]; then
  MODE="verify"
fi

if [ "$MODE" = "verify" ]; then
  echo "🔍 Verifying Session Index"
  echo ""

  if [ ! -f "$INDEX_FILE" ]; then
    echo "❌ Index file not found: $INDEX_FILE"
    echo ""
    echo "💡 Rebuild index:"
    echo "   /session-rebuild-index"
    exit 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
  fi

  # Check JSON validity
  if ! jq empty "$INDEX_FILE" 2>/dev/null; then
    echo "❌ Index file is corrupted (invalid JSON)"
    echo ""
    echo "💡 Rebuild index:"
    echo "   /session-rebuild-index"
    exit 1
  fi

  # Check structure
  SESSIONS=$(jq '.sessions | length' "$INDEX_FILE" 2>/dev/null)
  REFS=$(jq '.refs | length' "$INDEX_FILE" 2>/dev/null)

  echo "📊 Index Statistics:"
  echo "   Sessions: $SESSIONS"
  echo "   References: $REFS"
  echo ""

  # Verify sessions exist
  MISSING=0
  jq -r '.sessions | keys[]' "$INDEX_FILE" 2>/dev/null | while read -r session_id; do
    if [ ! -d ".claude/sessions/$session_id" ]; then
      echo "⚠️  Missing directory: $session_id"
      MISSING=$((MISSING + 1))
    fi
  done

  if [ $MISSING -gt 0 ]; then
    echo ""
    echo "⚠️  Found $MISSING missing session(s)"
    echo ""
    echo "💡 Clean up missing sessions:"
    echo "   bash $PLUGIN_DIR/scripts/session-index.sh gc"
  else
    echo "✅ Index is healthy"
  fi

  exit 0
fi

# Rebuild mode
echo "🔨 Rebuilding Session Index"
echo ""

if [ ! -x "$PLUGIN_DIR/scripts/session-index.sh" ]; then
  echo "❌ Index manager script not found or not executable"
  echo "   Expected: $PLUGIN_DIR/scripts/session-index.sh"
  exit 1
fi

# Check if index exists (backup it first)
if [ -f "$INDEX_FILE" ]; then
  BACKUP_FILE="$INDEX_FILE.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$INDEX_FILE" "$BACKUP_FILE"
  echo "📦 Backed up existing index:"
  echo "   $BACKUP_FILE"
  echo ""
fi

# Run rebuild
bash "$PLUGIN_DIR/scripts/session-index.sh" rebuild

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo "✅ Index rebuilt successfully!"
  echo ""

  if command -v jq &> /dev/null && [ -f "$INDEX_FILE" ]; then
    SESSIONS=$(jq '.sessions | length' "$INDEX_FILE" 2>/dev/null)
    REFS=$(jq '.refs | length' "$INDEX_FILE" 2>/dev/null)

    echo "📊 Index Statistics:"
    echo "   Sessions indexed: $SESSIONS"
    echo "   References: $REFS"
    echo ""
  fi

  echo "💡 Next steps:"
  echo "   /session-list              - View all sessions"
  echo "   /cc:plan @latest           - Continue latest session"
  echo "   /session-rebuild-index --verify  - Verify integrity"
else
  echo ""
  echo "❌ Rebuild failed with exit code: $EXIT_CODE"
  echo ""
  echo "💡 Troubleshooting:"
  echo "   1. Check if jq is installed: command -v jq"
  echo "   2. Check permissions on .claude/sessions/"
  echo "   3. Check for corrupted session directories"

  if [ -f "$BACKUP_FILE" ]; then
    echo ""
    echo "Restore backup if needed:"
    echo "   cp $BACKUP_FILE $INDEX_FILE"
  fi

  exit 1
fi
```

Migrate v1 sessions to v2 format with improved session IDs.

**Usage**: `/session-migrate [--dry-run|--execute] [session-id]`

**Modes**:
- `--dry-run` (default): Preview changes without applying
- `--execute`: Apply migration
- `[session-id]`: Migrate specific session (optional)

**Examples**:
```
/session-migrate                    # Preview all migrations
/session-migrate --execute          # Apply all migrations
/session-migrate 20251109_114715_f0903a7c  # Migrate specific session
```

---

**Execute**:

```bash
#!/bin/bash
set -euo pipefail

PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"

# Parse arguments
MODE="--dry-run"
SPECIFIC_SESSION=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      MODE="--dry-run"
      ;;
    --execute)
      MODE="--execute"
      ;;
    *)
      SPECIFIC_SESSION="$arg"
      ;;
  esac
done

echo "🔄 Session Migration: v1 → v2"
echo ""

if [ "$MODE" = "--dry-run" ]; then
  echo "🔍 DRY RUN MODE (no changes will be made)"
  echo "   Run with --execute to apply changes"
  echo ""
fi

# Find v1 sessions
if [ -n "$SPECIFIC_SESSION" ]; then
  # Migrate specific session
  V1_SESSIONS=$(find .claude/sessions -maxdepth 1 -type d -name "${SPECIFIC_SESSION}*" 2>/dev/null)

  if [ -z "$V1_SESSIONS" ]; then
    echo "❌ Session not found: $SPECIFIC_SESSION"
    exit 1
  fi
else
  # Find all v1 sessions
  V1_SESSIONS=$(find .claude/sessions -maxdepth 1 -type d -name "20*_*_*" 2>/dev/null | sort)
fi

if [ -z "$V1_SESSIONS" ]; then
  echo "✅ No v1 sessions found"
  echo ""
  echo "All sessions are already using v2 format!"
  echo ""
  echo "💡 View sessions: /session-list"
  exit 0
fi

COUNT=$(echo "$V1_SESSIONS" | wc -l | tr -d ' ')
echo "Found $COUNT v1 session(s) to migrate"
echo ""

MIGRATED=0
FAILED=0

echo "$V1_SESSIONS" | while read -r old_dir; do
  basename=$(basename "$old_dir")

  # Parse v1 format: YYYYMMDD_HHMMSS_randomhex_description
  if [[ "$basename" =~ ^([0-9]{8})_([0-9]{6})_([a-f0-9]{8})(_(.+))?$ ]]; then
    date="${BASH_REMATCH[1]}"
    time="${BASH_REMATCH[2]}"
    old_random="${BASH_REMATCH[3]}"
    description="${BASH_REMATCH[5]:-session}"  # Default if no description

    # Convert to v2 format
    timestamp="${date}T${time}"
    new_random=$(echo "$old_random" | head -c 8)  # Keep first 8 chars
    slug=$(echo "$description" | tr '_' '-' | tr '[:upper:]' '[:lower:]')  # Convert to kebab-case

    new_name="v2-${timestamp}-${new_random}-${slug}"
    new_dir=".claude/sessions/$new_name"

    echo "📦 $basename"
    echo "   → $new_name"

    if [ "$MODE" = "--execute" ]; then
      # Check if target exists
      if [ -d "$new_dir" ]; then
        echo "   ⚠️  Target already exists, skipping"
        FAILED=$((FAILED + 1))
      else
        # Perform migration
        if mv "$old_dir" "$new_dir" 2>/dev/null; then
          # Update CLAUDE.md if it exists
          if [ -f "$new_dir/CLAUDE.md" ]; then
            # Update session ID reference in CLAUDE.md
            sed -i.bak "s|# Session: $basename|# Session: $new_name|g" "$new_dir/CLAUDE.md" 2>/dev/null || true
            rm -f "$new_dir/CLAUDE.md.bak"

            # Add migration note
            echo "" >> "$new_dir/CLAUDE.md"
            echo "---" >> "$new_dir/CLAUDE.md"
            echo "**Migration Note**: Migrated from v1 format on $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$new_dir/CLAUDE.md"
            echo "  - Old ID: $basename" >> "$new_dir/CLAUDE.md"
            echo "  - New ID: $new_name" >> "$new_dir/CLAUDE.md"
          fi

          echo "   ✅ Migrated successfully"
          MIGRATED=$((MIGRATED + 1))
        else
          echo "   ❌ Migration failed"
          FAILED=$((FAILED + 1))
        fi
      fi
    else
      echo "   📝 Would migrate (use --execute to apply)"
    fi
    echo ""
  else
    echo "⚠️  Skipping (invalid v1 format): $basename"
    echo ""
  fi
done

echo "---"
echo ""

if [ "$MODE" = "--execute" ]; then
  echo "✅ Migration Complete"
  echo ""
  echo "📊 Results:"
  echo "   Migrated: $MIGRATED"
  echo "   Failed: $FAILED"
  echo "   Total: $COUNT"
  echo ""

  if [ $MIGRATED -gt 0 ]; then
    echo "🔨 Rebuilding session index..."
    if [ -x "$PLUGIN_DIR/scripts/session-index.sh" ]; then
      bash "$PLUGIN_DIR/scripts/session-index.sh" rebuild
      echo ""
    fi

    echo "✅ All done!"
    echo ""
    echo "💡 View migrated sessions:"
    echo "   /session-list"
  fi
else
  echo "💡 This was a dry run. To apply changes:"
  echo "   /session-migrate --execute"
  echo ""
  echo "Or migrate a specific session:"
  echo "   /session-migrate --execute $basename"
fi
```

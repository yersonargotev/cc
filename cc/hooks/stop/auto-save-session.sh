#!/bin/bash
# Stop Hook: Auto-save session state after agent completes
# Updates timestamps and saves session metadata
#
# Stop hooks run when Claude Code finishes responding
# They receive event data via stdin but typically don't need to process it

# Read stdin (required even if not used)
cat > /dev/null

# Find most recent session directory
LATEST_SESSION=$(find .claude/sessions -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)

if [ -n "$LATEST_SESSION" ] && [ -f "$LATEST_SESSION/CLAUDE.md" ]; then
    # Update last modified timestamp
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Check if timestamp line exists, update or add it
    if grep -q "^Last Updated:" "$LATEST_SESSION/CLAUDE.md" 2>/dev/null; then
        # macOS compatible sed command
        sed -i '' "s/^Last Updated:.*/Last Updated: $TIMESTAMP/" "$LATEST_SESSION/CLAUDE.md"
    else
        # Add timestamp after Status section if it exists
        if grep -q "^## Status" "$LATEST_SESSION/CLAUDE.md"; then
            sed -i '' "/^## Status/a\\
Last Updated: $TIMESTAMP" "$LATEST_SESSION/CLAUDE.md"
        else
            # Add at the beginning of the file
            sed -i '' "1i\\
Last Updated: $TIMESTAMP\\
" "$LATEST_SESSION/CLAUDE.md"
        fi
    fi

    # Log session activity (optional - create activity log)
    ACTIVITY_LOG="$LATEST_SESSION/activity.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session updated" >> "$ACTIVITY_LOG"
fi

# Silent success
exit 0

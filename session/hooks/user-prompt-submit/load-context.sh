#!/bin/bash
# UserPromptSubmit Hook: Load git and session context on every prompt
# Provides helpful context without cluttering conversation
#
# UserPromptSubmit hooks run when the user submits a prompt, before Claude processes it
# They receive the prompt data via stdin and can inject additional context

# Read stdin (prompt data - available but not needed for this use case)
cat > /dev/null

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Only show git status if there are changes
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "📊 Git Status:"
        git status --short 2>/dev/null | head -10
        echo ""
    fi
fi

# Check for active sessions
if [ -d ".claude/sessions" ]; then
    LATEST_SESSION=$(find .claude/sessions -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)

    if [ -n "$LATEST_SESSION" ] && [ -f "$LATEST_SESSION/CLAUDE.md" ]; then
        SESSION_NAME=$(basename "$LATEST_SESSION")
        SESSION_ID=$(echo "$SESSION_NAME" | cut -d'_' -f1,2,3)

        # Extract phase from CLAUDE.md
        PHASE=$(grep "^Phase:" "$LATEST_SESSION/CLAUDE.md" 2>/dev/null | head -1 | sed 's/Phase: //')

        if [ -n "$PHASE" ]; then
            echo "📁 Active Session: $SESSION_ID"
            echo "   Phase: $PHASE"
            echo "   Context: Auto-loaded from $LATEST_SESSION/CLAUDE.md"
            echo ""
        fi
    fi
fi

# Success - output is shown to user as context
exit 0

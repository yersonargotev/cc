#!/bin/bash
# PreToolUse Hook: Validate session exists before plan/code phases
# This hook ensures users follow the proper workflow sequence

TOOL_NAME="$1"
TOOL_INPUT="$2"

# Only validate for SlashCommand tool with cc:plan or cc:code
if [ "$TOOL_NAME" = "SlashCommand" ]; then
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command' 2>/dev/null || echo "$TOOL_INPUT")

    # Check if command is plan or code phase
    if echo "$COMMAND" | grep -qE '/cc:(plan|code)'; then
        # Extract session ID (first argument after command)
        SESSION_ID=$(echo "$COMMAND" | sed -E 's|.*/(cc:(plan|code))\s+([^ ]+).*|\3|')

        if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "/cc:plan" ] && [ "$SESSION_ID" != "/cc:code" ]; then
            # Check if session directory exists
            SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)

            if [ -z "$SESSION_DIR" ]; then
                echo "❌ Validation Error: Session '$SESSION_ID' not found"
                echo ""
                echo "Available sessions:"
                if [ -d ".claude/sessions" ]; then
                    ls -1 .claude/sessions/ | sed 's/^/  - /'
                else
                    echo "  No sessions found"
                fi
                echo ""
                echo "💡 Tip: Start with /cc:explore to create a new session"
                exit 1
            fi

            # For code phase, also check if plan exists
            if echo "$COMMAND" | grep -q '/cc:code'; then
                if [ ! -f "$SESSION_DIR/plan.md" ]; then
                    echo "❌ Validation Error: No plan found for session '$SESSION_ID'"
                    echo ""
                    echo "💡 Run /cc:plan $SESSION_ID to create implementation plan first"
                    exit 1
                fi
            fi
        fi
    fi
fi

# No modification needed - pass through original input
echo "$TOOL_INPUT"

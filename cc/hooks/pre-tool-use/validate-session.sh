#!/bin/bash
# PreToolUse Hook: Validate session exists before plan/code phases
# This hook ensures users follow the proper workflow sequence
# 
# Exit codes:
#   0 = Allow (pass through)
#   1 = Block with error message
#   2 = Block and provide feedback to Claude

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name and command from JSON
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only validate for SlashCommand tool with cc:plan or cc:code
if [ "$TOOL_NAME" = "SlashCommand" ] && echo "$COMMAND" | grep -qE '/cc:(plan|code)'; then
    # Extract session ID (first argument after command)
    # Use awk for better portability across macOS and Linux
    SESSION_ID=$(echo "$COMMAND" | awk '{for(i=1;i<=NF;i++) if($i ~ /^\/cc:(plan|code)$/ && i<NF) print $(i+1)}')

    if [ -n "$SESSION_ID" ]; then
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
            exit 2  # Block with feedback to Claude
        fi

        # For code phase, also check if plan exists
        if echo "$COMMAND" | grep -q '/cc:code'; then
            if [ ! -f "$SESSION_DIR/plan.md" ]; then
                echo "❌ Validation Error: No plan found for session '$SESSION_ID'"
                echo ""
                echo "💡 Run /cc:plan $SESSION_ID to create implementation plan first"
                exit 2  # Block with feedback to Claude
            fi
        fi
    fi
fi

# Allow - pass through (exit 0 with no output)
exit 0

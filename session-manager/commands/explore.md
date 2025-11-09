Create a new exploration session with v2 session ID format.

**Usage**: `/explore <description>`

**What this does**:
1. Generates a v2 session ID: `v2-YYYYMMDDTHHmmss-base32random-kebab-slug`
2. Creates session directory in `.claude/sessions/`
3. Initializes CLAUDE.md with session metadata
4. Adds session to index
5. Sets as @latest reference

**Example**:
```
/explore Implement user authentication with OAuth
```

---

**Execute**:

```bash
#!/bin/bash
set -euo pipefail

DESCRIPTION="$*"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"

# Validate input
if [ -z "$DESCRIPTION" ]; then
  echo "❌ Error: Description required"
  echo ""
  echo "Usage: /explore <description>"
  echo ""
  echo "Examples:"
  echo "  /explore Implement user authentication"
  echo "  /explore Fix bug in payment processing"
  echo "  /explore Add dark mode feature"
  exit 1
fi

# Generate v2 session ID
echo "🔨 Generating session ID..."
SESSION_ID=$(bash "$PLUGIN_DIR/scripts/generate-session-id.sh" "$DESCRIPTION")

if [ $? -ne 0 ] || [ -z "$SESSION_ID" ]; then
  echo "❌ Failed to generate session ID"
  exit 1
fi

echo "✅ Generated: $SESSION_ID"
echo ""

# Create session directory
SESSION_DIR=".claude/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"

# Initialize CLAUDE.md
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

cat > "$SESSION_DIR/CLAUDE.md" <<EOF
# Session: $SESSION_ID

**Status**: Active
**Phase**: Exploration
**Created**: $TIMESTAMP
**Last Updated**: $TIMESTAMP

## Objective
$DESCRIPTION

## Context
[Auto-populated during exploration]

## Key Findings
[To be filled during exploration]

## Technical Details
- Branch: $BRANCH
- Session Format: v2
- Quick Reference: @latest, $(echo "$SESSION_ID" | cut -d'-' -f3), @/$(echo "$SESSION_ID" | cut -d'-' -f4-)

## Next Steps
[To be determined after exploration]

---

## Exploration Log
[Findings and discoveries will be documented here]
EOF

# Initialize activity log
cat > "$SESSION_DIR/activity.log" <<EOF
[$TIMESTAMP] Session created
[$TIMESTAMP] Description: $DESCRIPTION
[$TIMESTAMP] Branch: $BRANCH
EOF

# Extract slug from session ID
SLUG=$(echo "$SESSION_ID" | cut -d'-' -f4-)

# Add to session index
echo "📇 Adding to session index..."
if [ -x "$PLUGIN_DIR/scripts/session-index.sh" ]; then
  bash "$PLUGIN_DIR/scripts/session-index.sh" add \
    "$SESSION_ID" \
    "$SLUG" \
    "exploration" \
    "in_progress" \
    "$BRANCH" || echo "⚠️  Warning: Failed to add to index"

  # Set as @latest
  bash "$PLUGIN_DIR/scripts/session-index.sh" set-ref "@latest" "$SESSION_ID" || true
fi

echo ""
echo "✅ Session created successfully!"
echo ""
echo "📋 Session Details:"
echo "  ID: $SESSION_ID"
echo "  Name: $SLUG"
echo "  Phase: Exploration"
echo "  Branch: $BRANCH"
echo ""
echo "📁 Session directory:"
echo "  $SESSION_DIR"
echo ""
echo "💡 Quick references:"
echo "  @latest              - Always refers to this session (until next session)"
echo "  @                    - Shorthand for @latest"
echo "  $(echo "$SESSION_ID" | cut -d'-' -f3)             - Short ID (8 chars)"
echo "  @/$SLUG - Slug search"
echo ""
echo "🚀 Next steps:"
echo "  1. Continue exploration (I'll help you understand the codebase)"
echo "  2. When ready: /cc:plan @latest     - Create implementation plan"
echo "  3. Then code: /cc:code @latest      - Start implementation"
echo ""
echo "🔍 View all sessions: /session-list"
echo ""

# Now proceed with exploration
echo "---"
echo ""
echo "Let's begin exploring! What would you like to understand about the codebase?"
echo ""
echo "I can help you:"
echo "  - Map out the project structure"
echo "  - Find relevant files and patterns"
echo "  - Understand existing implementations"
echo "  - Identify dependencies and relationships"
echo "  - Research best practices and approaches"
```

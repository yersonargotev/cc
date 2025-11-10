---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: "[session_id] [implementation focus] [target files/components]"
description: Implement solution with auto-loaded session context and plan
---

# Code: Implementation

Implement solution for session: **$1** with focus: **$2**$3

## Session Reference Resolution

Resolve session reference to full session ID:

```bash
#!/bin/bash
set -euo pipefail

# Get session reference (default to @latest)
SESSION_REF="${1:-@latest}"

# Resolve reference to full session ID
if [ -x "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" ]; then
  SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" "$SESSION_REF" 2>&1)
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Failed to resolve session reference: $SESSION_REF"
    echo ""
    echo "$SESSION_ID"
    echo ""
    echo "💡 Available commands:"
    echo "   /session-list              - View all sessions"
    echo "   /cc:explore <description>  - Create new session"
    exit 1
  fi

  echo "✅ Resolved: $SESSION_REF → $SESSION_ID"
  echo ""
else
  # Fallback: assume SESSION_REF is full ID
  SESSION_ID="$SESSION_REF"
  echo "⚠️  Session resolver not available, using: $SESSION_ID"
  echo ""
fi

# Set SESSION_DIR for rest of command
SESSION_DIR=".claude/sessions/${SESSION_ID}"

# Verify session exists
if [ ! -d "$SESSION_DIR" ]; then
  echo "❌ Session not found: $SESSION_ID"
  echo ""
  echo "💡 Try:"
  echo "   /session-list              - View all sessions"
  echo "   /cc:explore <description>  - Create new session"
  exit 1
fi

# Verify plan exists
if [ ! -f "$SESSION_DIR/plan.md" ]; then
  echo "❌ No plan found for this session"
  echo ""
  echo "💡 Create a plan first:"
  echo "   /cc:plan $SESSION_REF"
  exit 1
fi

echo "📁 Using session: $SESSION_DIR"
echo "📋 Context: CLAUDE.md (auto-loaded) | plan.md | explore.md"
echo ""

# Update phase to implementation
sed -i "s/Phase: planning/Phase: implementation/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
```

**Context Available**:
- Session CLAUDE.md (auto-loaded): Findings + plan summary
- Detailed plan: @$SESSION_DIR/plan.md
- Exploration: @$SESSION_DIR/explore.md

## Implementation Task

Execute plan following these principles:

### Quality Standards
- **Code style**: Match existing conventions
- **Error handling**: Handle edge cases
- **Testing**: Add tests per plan
- **Documentation**: Update as needed
- **Security**: Follow best practices

### Approach
- Make small, testable increments
- Verify each step before proceeding
- Follow plan step-by-step
- Self-review for potential issues

## Deliverables

Save implementation summary to `$SESSION_DIR/code.md`:

```markdown
# Implementation Summary: [Feature Name]

## Session Information
- Session ID: ${SESSION_ID}
- Date: $(date)
- Phase: Implementation
- Focus: $2$3

## Summary
[Brief overview of what was implemented]

## Key Changes
1. **[File/Component]**: [What changed and why]
2. **[File/Component]**: [What changed and why]

## Tests Added/Updated
- [Test file]: [What it tests]

## Validation Results
- ✅ [Success criterion]: Verified

## Status
[Completed | Pending user approval]
```

Update `$SESSION_DIR/CLAUDE.md` with implementation summary:

```markdown
## Implementation Phase Complete

### Changes Made
- [File/Component]: [Brief description]

### Tests Added
- [X] unit tests
- [X] integration tests

### Status
✅ Implementation complete - awaiting user approval

### References
Implementation details: @.claude/sessions/${SESSION_ID}_*/code.md
```

## User Approval

**IMPORTANT**: Wait for user approval before finalizing.

Present for review:

```
✅ Implementation complete: ${SESSION_ID}

📝 Summary: [Brief description]

🔧 Changes:
- [X] files modified
- [X] tests added
- [X] components updated

✅ Validation:
- All success criteria met
- Tests passing
- Integration verified

⏸️  Awaiting user approval

Session: .claude/sessions/${SESSION_ID}_*/CLAUDE.md
Summary: .claude/sessions/${SESSION_ID}_*/code.md
```

After user approval:

```
🎉 Implementation approved!

Next steps:
1. /commit feat "[description]" - Create conventional commit
2. Push changes to remote
3. Create pull request for review
```

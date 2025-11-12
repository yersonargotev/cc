---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: "[session_id] [implementation focus] [target files/components]"
description: Implement solution with auto-loaded session context and plan
---

# Code: Implementation

Implement solution for session: **$1** with focus: **$2**$3

## Session Validation

<task>Validate session and load context</task>

```bash
SESSION_ID="$1"
SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)

[ -z "$SESSION_DIR" ] && echo "❌ Session not found: $SESSION_ID" && exit 1
[ ! -f "$SESSION_DIR/plan.md" ] && echo "❌ No plan found. Run /plan first" && exit 1

echo "✅ Loaded: $SESSION_ID | Context: CLAUDE.md (auto) + plan.md"
sed -i "s/Phase: planning/Phase: implementation/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
```

**Context**: Session CLAUDE.md (auto-loaded) | Plan: @$SESSION_DIR/plan.md

## Implementation Task

<task>Execute plan following quality standards</task>

<requirements>
**Quality**: Match code style | Handle errors | Add tests | Update docs | Follow security best practices
**Approach**: Small increments | Verify each step | Follow plan order | Self-review for issues
</requirements>

## Deliverables

<task>Document implementation and update session</task>

Save to `$SESSION_DIR/code.md`:

<template>
```markdown
# Implementation: [Feature Name]

<session_info>
ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Phase: Implementation | Focus: $2$3
</session_info>

## Summary
[Brief overview of what was implemented]

## Key Changes
1. **[file.ext:line]**: [what + why]
2. **[file.ext:line]**: [what + why]

## Tests
- [test_file.ext]: [what it tests]
- Validation: [commands run + results]

## Status
[✅ Complete | ⏸️ Pending approval]
```
</template>

Update `$SESSION_DIR/CLAUDE.md`:

```markdown
## Implementation Complete

**Changes**: [X] files | [components list]
**Tests**: [X] unit + [X] integration
**Status**: ✅ Complete - awaiting approval

**Details**: @.claude/sessions/${SESSION_ID}_*/code.md
```

## User Approval

<critical>Wait for user approval before finalizing</critical>

Present for review:

```
✅ Implementation complete: ${SESSION_ID}

📝 Summary: [brief description]

🔧 Changes: [X] files | [X] tests | [X] components

✅ Validation: Success criteria met | Tests passing | Integration verified

⏸️  Awaiting approval

Session: .claude/sessions/${SESSION_ID}_*/CLAUDE.md
Details: .claude/sessions/${SESSION_ID}_*/code.md
```

After approval:

```
🎉 Approved!

Next:
1. /commit feat "[description]"
2. Push to remote
3. Create PR
```

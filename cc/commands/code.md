---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: "<session_id> [mode: fast|strict] [focus]"
description: Implement solution with strict scope control and token-efficient validation
---

# Code: Implementation

Implement solution for session: **$1**$2

MODE:

- Default: `strict`
- If `$2` starts with `fast:` → `fast` mode (lightweight validation, simpler docs)

## 1. Session Validation & Error Handling

<task>Validate session existence and load context with comprehensive error handling</task>

```bash
SESSION_ID="$1"

# Error 1: Missing session ID
if [ -z "$SESSION_ID" ]; then
  echo "❌ ERROR: Session ID required"
  echo "Usage: /code <session_id> [focus]"
  echo ""
  echo "Find sessions: ls .claude/sessions/"
  exit 1
fi

# Error 2: Session not found
SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)
if [ -z "$SESSION_DIR" ]; then
  echo "❌ ERROR: Session not found: $SESSION_ID"
  echo ""
  echo "Available sessions:"
  ls .claude/sessions/ 2>/dev/null | grep -o '^[0-9_a-f]*' | head -5
  exit 1
fi

# Error 3: Missing plan
if [ ! -f "$SESSION_DIR/plan.md" ]; then
  echo "❌ ERROR: No implementation plan found"
  echo "Run: /plan <query> to create a plan first"
  exit 1
fi

# Error 4: Already implemented (warning, not error)
if [ -f "$SESSION_DIR/code.md" ]; then
  echo "⚠️  WARNING: Implementation already exists at:"
  echo "   $SESSION_DIR/code.md"
  echo ""
  echo "Continue anyway? This will overwrite existing implementation."
  echo "Press Ctrl+C to cancel, or continue to proceed..."
  echo ""
fi

echo "✅ Loaded: $SESSION_ID"
echo "   Plan: $SESSION_DIR/plan.md"
echo "   Context: CLAUDE.md (auto-loaded)"
echo ""

# Update phase in session context
sed -i "s/Phase: planning.*/Phase: implementation/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
```

**Context**: Session CLAUDE.md auto-loaded | Plan: @$SESSION_DIR/plan.md

## 2. Scope Definition & Boundaries (CORE)

<task>Extract implementation scope from plan and enforce hard boundaries</task>

From `$SESSION_DIR/plan.md`, derive:

- **Target Files**: exact paths from implementation steps
- **Target Components**: functions/classes/modules to change
- **Out of Scope**: everything not explicitly listed above

<critical>
STRICT SCOPE (applies to ALL modes):
- Only touch listed files/components.
- Do not refactor neighbors "while you're there".
- Do not add features/tests/deps unless plan or user explicitly says so.
- If scope is ambiguous → STOP and ask user.
</critical>

Output a short scope summary (1–3 lines) before coding.

## 3. Implementation & Validation (CORE)

<task>Implement plan in small steps with minimal-but-real validation</task>

For each plan step:

1. **Change** only target files/components.
2. **Validate**:
   - Syntax/build check for affected language.
   - Run only relevant tests (from plan or nearest test files).
   - Optional lint if configured.

<requirements>
- Match existing style and naming in touched files.
- Keep changes small and focused.
- Avoid unnecessary tool calls or re-reading large files.
- Prefer Read/Write/Edit over Bash when possible.
- No secrets or destructive operations.
</requirements>

If validation fails: fix, re-run, then continue.

In `fast` mode:

- Keep validation minimal (syntax + most relevant tests).
- Skip incremental checkpoints and extended reporting.

In `strict` mode:

- Apply full validation (tests, lint, any project checks from CLAUDE.md/plan.md).
- Be conservative with scope and error handling.

## 4. Implementation Report (LITE)

<task>Write a concise implementation report to `$SESSION_DIR/code.md`</task>

Use this **lite** template (see `@docs/code-command-implementation-template.md` for full version):

```markdown
# Implementation: [Name from plan]

ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Mode: [fast|strict]

## Summary

- [2–3 short bullets: what & why]

## Changes

- file:lines - WHAT | WHY | TESTS
- file:lines - ...

## Validation

- Tests: [command(s)] → [X passed, Y failed (0 if none)]
- Other checks (lint/build): [commands + short result]

## Status

- [✅ Complete | ⏸️ Needs review]
```

Keep report short and specific; link to extra details only if needed.

Update `$SESSION_DIR/CLAUDE.md` with a one-line implementation status referencing `code.md`.

## 5. User Review

Present a brief summary for the user:

```
✅ Implementation: ${SESSION_ID} | Mode: [fast|strict]
Files: [count] | Tests: [summary]
Details: ${SESSION_DIR}/code.md
⏸️ Awaiting review/approval
```

Wait for explicit approval before considering the task done or moving to `/commit`.

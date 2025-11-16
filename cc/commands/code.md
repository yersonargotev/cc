---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: "<session_id> [mode: fast|strict] [scope/focus]"
description: Token-efficient implementation with strict scope and minimal-but-real validation
---

# Code: Implementation (Token-Efficient)

Implement solution for session **$1** with strict scope control and adaptive validation.

MODE (internal):

- Default: `strict`
- If `$2` starts with `fast` → `fast` (lighter validation, same scope rules)

## 1. Session Validation & Context

<task>Validate session and load minimal context</task>

```bash
SESSION_ID="$1"

if [ -z "$SESSION_ID" ]; then
  echo "❌ ERROR: Session ID required"
  echo "Usage: /code <session_id> [mode] [scope/focus]"
  echo "Find sessions: ls .claude/sessions/"
  exit 1
fi

SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)
if [ -z "$SESSION_DIR" ]; then
  echo "❌ ERROR: Session not found: $SESSION_ID"
  exit 1
fi

if [ ! -f "$SESSION_DIR/plan.md" ]; then
  echo "❌ ERROR: No implementation plan found for $SESSION_ID"
  echo "Run: /plan <query> first to create a plan"
  exit 1
fi

if [ -f "$SESSION_DIR/code.md" ]; then
  echo "⚠️  WARNING: Existing implementation at $SESSION_DIR/code.md (will be overwritten if you continue)"
fi

echo "✅ Session: $SESSION_ID"
echo "   Plan:   $SESSION_DIR/plan.md"

sed -i "s/Phase: planning.*/Phase: implementation/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
```

Use `@${SESSION_DIR}/CLAUDE.md` and `@${SESSION_DIR}/plan.md` as primary context; do not restate them fully.

## 2. Scope Extraction & Hard Boundaries

<task>Extract exact implementation scope from plan and enforce it</task>

From `@${SESSION_DIR}/plan.md` derive a concise scope:

- Target files (exact paths)
- Target components (functions/classes/modules)

<critical>
STRICT SCOPE (all modes):
- Only touch listed files/components.
- Do not refactor neighbors "while you're there".
- Do not add tests/dependencies/features unless plan or user explicitly says so.
- If scope or intent is unclear → stop and ask the user.
</critical>

Output a 1–3 line scope summary before coding.

If `$3` narrows scope (e.g. specific file/component), treat it as an extra filter, never as permission to expand scope.

## 3. Implementation & Validation (Token-Aware)

<task>Implement plan in small focused steps with minimal-but-real validation</task>

For each relevant plan step:

1. Change only scoped files/components.
2. Validate with token-efficient checks:
   - Syntax/build for affected language only.
   - Run the most relevant tests (from plan or nearest test files), not the whole suite unless required.
   - Optional lint if already configured and cheap.

<requirements>
- Match existing style and patterns in touched files.
- Keep edits minimal; avoid large refactors.
- Prefer `Read/Write/Edit` over shell when possible.
- Avoid re-reading large files repeatedly.
- No destructive operations or secret handling.
</requirements>

Mode specifics:

- `fast`: syntax + 1–2 key tests; no extended explanations.
- `strict`: syntax + relevant tests (+ lint if available); be conservative with errors.

If any check fails, fix and re-run before continuing.

## 4. Implementation Report (Compact)

<task>Write a compact implementation report to `$SESSION_DIR/code.md`</task>

Use this **compact** template (full version in `@docs/code-command-implementation-template.md`):

```markdown
# Implementation: [Name from plan]

ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Mode: [fast|strict]

## Summary

- [2–3 short bullets: what was changed and why]

## Changes

- path/file.ext:line-range – WHAT | WHY | TESTS
- ...

## Validation

- Tests: [command(s)] → [X passed, Y failed (0 if none)]
- Other checks (lint/build): [commands + short result or N/A]

## Status

- [✅ Complete | ⏸️ Needs review]
```

Keep this file short and factual; link to extra details (issues/PRs/docs) only when essential.

Append to `@${SESSION_DIR}/CLAUDE.md` a one-line implementation status referencing `code.md`.

## 5. User-Facing Summary

Present a brief summary to the user:

```
✅ Implementation: ${SESSION_ID} | Mode: [fast|strict]
Files touched: [count] | Tests: [short result]
Details: ${SESSION_DIR}/code.md
⏸️ Review changes, then proceed with /commit if satisfied
```

Do not repeat the full report in the chat; rely on `code.md` for details.

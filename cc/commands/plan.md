---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[query] [context] [constraints]"
description: Token-efficient research (code/web/both) then concise implementation plan
---

# Plan: Token-Efficient Research & Strategy

Plan for: **$1**$2$3

## 1. Session Setup

<task>Create session directory and initialize minimal context</task>

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DIR=".claude/sessions/${SESSION_ID}_$(echo "$1" | tr -cs 'a-z0-9' '_' | head -c 20)"
mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/CLAUDE.md" << 'EOF'
# Session: $1
Status: planning | ID: ${SESSION_ID} | Started: $(date '+%Y-%m-%d %H:%M')
Objective: $1
Context: $2$3
Research: detecting strategy...
EOF
```

Use `@${SESSION_DIR}/CLAUDE.md` as main context; avoid repeating it in the plan.

## 2. Query Analysis & Strategy (CODE/WEB/BOTH)

<task>Classify query and choose minimal research strategy</task>

Analyze `$1 $2 $3` and set `STRATEGY`:

- `CODE` → work only with local codebase (no web research)
  - Signals: mentions files/functions/tests, no learning/docs keywords.
- `WEB` → external info only (no code search)
  - Signals: "research", "learn", "docs", "examples", etc. without repo paths.
- `BOTH` → need repo + external info
  - Signals: implement/integrate new tech (e.g. Stripe, Next.js) or user explicitly asks for external research.

<critical>
- Prefer `CODE` or `WEB` when in doubt; only use `BOTH` if clearly required.
- If intent is ambiguous, ask the user which strategy to use instead of guessing.
</critical>

Append `Research: ${STRATEGY} strategy detected` to `@${SESSION_DIR}/CLAUDE.md`.

## 3. Token-Aware Research

<task>Launch only the necessary agents with shallow, focused prompts</task>

### Strategy: CODE

```
Task(
  subagent: "code-search-agent",
  model: "haiku",
  description: "Analyze repo for implementation planning",
  prompt: "Query: $1. Context: $2$3. Output: ${SESSION_DIR}/code-search.md. Focus only on files and components directly related to the query. Keep output to 5–7 bullets with file:line references."
)
```

### Strategy: WEB

```
Task(
  subagent: "web-research-agent",
  model: "haiku",
  description: "Research external info for implementation planning",
  prompt: "Query: $1. Context: $2$3. Focus: 2024–2025. Output: ${SESSION_DIR}/web-research.md. Limit to 5–7 key findings with URLs; avoid basic concepts the model already knows."
)
```

### Strategy: BOTH (run in parallel)

Launch both tasks above in a single message (two `Task` calls) and wait for completion before synthesis.

## 4. Plan Generation (Compact by Default)

<task>Synthesize research into a concise implementation plan</task>

Read only the available research files:

- `CODE` or `BOTH`: `@${SESSION_DIR}/code-search.md`
- `WEB` or `BOTH`: `@${SESSION_DIR}/web-research.md`

Detail level:

- Default: **compact** plan (40–80 lines).
- Only if `$3` explicitly asks for "detailed/extended/full" → allow more detail, but keep under ~180 lines.

<template>
```markdown
# Implementation Plan: [Feature from $1]

ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Phase: Planning
Strategy: ${STRATEGY} | Detail: [compact|extended]

## Summary

- Goal: [1 line]
- Current state: [1–2 bullets, file:line or high-level]
- High-level approach: [1–2 bullets]

## Research Snapshot

[IF CODE or BOTH]

- Code (3–5 bullets): key files/components with file:line evidence.

[IF WEB or BOTH]

- Web (3–5 bullets): key concepts/docs with URLs.

## Implementation Steps (max 5–7)

1. [Action] [Target]

   - Files: [paths:line ranges]
   - Changes: [what & why]
   - Validation: [tests/commands]

2. [Action] [Target]
   - ...

## Risks & Mitigations

- 🔴 [Risk] – [impact] → Mitigation: [short]
- 🟡 [Risk] – [impact] → Mitigation: [short]

## Testing & Validation

- Tests to run: [commands]
- Edge cases: [2–3 bullets]

## References

- Session: @${SESSION_DIR}/CLAUDE.md
- Plan: @${SESSION_DIR}/plan.md (this file)
[IF CODE or BOTH: - Code research: @${SESSION_DIR}/code-search.md]
  [IF WEB or BOTH: - Web research: @${SESSION_DIR}/web-research.md]

````
</template>

<requirements>
- Use file:line evidence or URLs for claims when possible.
- Do not restate large chunks from research files; summarize.
- Keep total plan length within target limits (compact by default).
- Focus on clear, actionable steps rather than long narrative.
</requirements>

Write the plan to `${SESSION_DIR}/plan.md` using this template.

## 5. Update Session & User Summary

<task>Record planning completion and present a short summary</task>

Append to `@${SESSION_DIR}/CLAUDE.md`:

```markdown
## Status
Phase: planning-complete | Completed: $(date '+%Y-%m-%d %H:%M')
Strategy: ${STRATEGY}
Plan: @${SESSION_DIR}/plan.md
````

Then present a brief summary in chat:

```
✅ Planning complete: ${SESSION_ID}
Strategy: ${STRATEGY} (token-efficient: minimal necessary research)
Steps: [count] | Risks: [count] | Tests: [count]
Plan file: ${SESSION_DIR}/plan.md
Next: /code ${SESSION_ID}
```

Avoid printing the full plan in chat; rely on `plan.md` for details.

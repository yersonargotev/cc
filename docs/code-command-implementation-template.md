# Template extendido: `code.md`

Este doc define la versión completa del reporte de implementación para el comando `/code`.

Usa esta estructura **solo cuando necesites más detalle**; el prompt usa una versión _lite_ por defecto.

````markdown
# Implementation: [Feature/Fix/Refactor Name from Plan]

<session_info>
ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Phase: Implementation
Type: [FEATURE|FIX|REFACTOR|TEST] | Mode: [fast|strict]
Focus: [short focus from plan]
</session_info>

## Summary

- [1] What was implemented.
- [2] Why it was needed (link to plan step).
- [3] Any important constraints or trade-offs.

## Key Changes

> For **each** change, include: file:lines, WHAT, WHY, TESTS.

1. **path/to/file.py:45-67**

   - WHAT: [code-level change]
   - WHY: [reference to plan step / issue]
   - TESTS: [unit/integration tests that cover this]

2. **path/to/other_file.ts:10-25**
   - WHAT: [...]
   - WHY: [...]
   - TESTS: [...]

[Add as many items as needed, usually 2–7]

## Validation

### Tests

```bash
$ [test command]
[short output summary: e.g. "5 passed in 1.23s"]
```
````

- Status: [✅ All relevant tests passed | ❌ Failures (explain above)].

### Other Checks

- Lint/build/format: `[command]` → [short result].
- Manual checks (if any): [1–2 bullets].

## Issues & Follow-ups

- [Optional] Any known limitations, TODOs, or follow-up tasks.

## Status & Next Steps

- Status: [✅ Complete | ⏸️ Needs review].
- Next: `/commit [type] "desc"` + push/PR if applicable.
- References: `@${SESSION_DIR}/CLAUDE.md`, `@${SESSION_DIR}/plan.md`.

```

```

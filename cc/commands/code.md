---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: "<session_id> [implementation focus]"
description: Implement solution with strict scope control and integrated validation
---

# Code: Implementation

Implement solution for session: **$1**$2

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

## 2. Scope Definition & Boundaries

<task>Extract exact implementation scope from plan and establish strict boundaries</task>

Read `$SESSION_DIR/plan.md` and extract:
- **Target Files**: Exact file paths from implementation steps
- **Target Components**: Specific functions/classes/modules to modify
- **Changes**: What will be modified in each file
- **Out of Scope**: Everything not explicitly mentioned

<critical>
STRICT SCOPE ENFORCEMENT - DO EXACTLY WHAT IS ASKED, NOTHING MORE:

**ONLY modify**:
- ✅ Files explicitly listed in plan implementation steps
- ✅ Components/functions mentioned in plan
- ✅ Changes described in plan steps

**DO NOT**:
- ❌ Refactor adjacent code "while you're there"
- ❌ Add features not in the plan
- ❌ Modify tests unless plan explicitly requires it
- ❌ Change dependencies unless plan specifies
- ❌ "Improve" or "optimize" code outside scope
- ❌ Rename variables/functions not mentioned in plan
- ❌ Add comments/documentation beyond what plan requests

**If scope is unclear or ambiguous**: STOP and ASK user for clarification before proceeding.
</critical>

Present scope summary:

```
📋 Implementation Scope: ${SESSION_ID}

🎯 FOCUS: $2

✅ WILL MODIFY:
   Files: [list exact paths from plan steps]
   Components: [list functions/classes from plan]
   Estimated changes: ~[X] lines across [Y] files

❌ WILL NOT TOUCH:
   [Explicitly list what's out of scope: tests (unless plan says), dependencies (unless plan says), adjacent code, etc.]

📝 Plan Steps: [X] steps across [Y] phases
⏱️  Estimated time: [from plan]

Scope confirmed. Proceeding with implementation...
```

## 3. Task Type Analysis

<task>Analyze plan to determine implementation type and adjust approach</task>

Read `$SESSION_DIR/plan.md` and classify task type:

**Task Type Detection**:
- 🆕 **FEATURE** - Keywords: implement, add, create, build → New functionality
- 🔧 **FIX** - Keywords: fix, resolve, patch, correct → Bug fix
- ♻️ **REFACTOR** - Keywords: refactor, restructure, optimize, clean → Code improvement
- 🧪 **TEST** - Keywords: test, coverage → Test addition

Set `TYPE` based on plan analysis.

**Type-Specific Approach**:

```markdown
[IF TYPE=FEATURE]:
- Approach: Full TDD cycle with comprehensive tests
- Requirements: New tests (happy path + edge cases), documentation updates, integration tests
- Validation: All new tests pass + integration test demonstrates end-to-end

[IF TYPE=FIX]:
- Approach: Reproduce bug → minimal fix → regression test
- Requirements: Regression test proving bug + fix, minimal code change
- Validation: Bug test fails before fix, passes after fix, all existing tests still pass

[IF TYPE=REFACTOR]:
- Approach: Preserve behavior, improve structure
- Requirements: ZERO behavioral changes, all existing tests unchanged
- Validation: 100% existing tests pass, code metrics improved (complexity/duplication)

[IF TYPE=TEST]:
- Approach: Focus on coverage and edge cases
- Requirements: Coverage increase ≥ plan target, follow existing test patterns
- Validation: Coverage measurement, all tests pass
```

**Implementation Mode**:
- If plan has >5 steps OR >2 hours estimated: **INCREMENTAL** (checkpoints at each phase)
- Otherwise: **CONTINUOUS** (full implementation)

## 4. Implementation with Continuous Validation

<task>Execute plan following strict quality standards with validation at each step</task>

<requirements>
**Quality Standards** (SPECIFIC):

**Code Style**:
- Match existing patterns in modified files (check first 50 lines for conventions)
- Use same naming conventions as surrounding code
- Follow indentation/formatting of the file
- If formatter exists (.prettierrc, .editorconfig, pyproject.toml), run it

**Incremental Changes**:
- Max 50 lines per logical change
- One concern per increment
- Validate after each increment

**Security & Best Practices**:
- No hardcoded secrets/credentials/API keys
- Proper error handling for edge cases
- Input validation where applicable
- Follow OWASP guidelines (no SQL injection, XSS, etc.)
- Use parameterized queries, escape user input

**Self-Review Checklist** (verify before documenting):
- [ ] All target files modified as planned (nothing more, nothing less)
- [ ] No out-of-scope changes
- [ ] Tests pass (with evidence)
- [ ] No security vulnerabilities introduced
- [ ] Error handling for edge cases
- [ ] Documentation updated (if public API changed)
- [ ] Code follows existing patterns
</requirements>

**Implementation Process**:

For each step in plan:

1. **Implement**: Make changes to target file(s)
2. **Validate immediately**:

```bash
# Step A: Syntax/compilation check (language-specific)
# Python: python -m py_compile <file>
# TypeScript: tsc --noEmit
# Rust: cargo check
# Go: go build
# [Use appropriate command for your language]

# Step B: Run affected tests
# [Use test command from plan or CLAUDE.md]
# Examples: pytest tests/test_auth.py, npm test -- auth.test.ts, cargo test auth

# Step C: Linting (if configured)
# [Run lint command if available in project]
# Examples: pylint, eslint, cargo clippy
```

3. **Handle validation failures**:

<critical>
**If ANY validation check fails**:
1. ❌ STOP implementation immediately
2. 🔍 Review error output
3. 🔧 FIX the issue
4. ✅ Re-run validation
5. ➡️ Continue ONLY after all checks pass

**Common Failure Modes & Recovery**:

- **Tests fail**:
  - Review test output for specific assertion failures
  - Fix implementation to satisfy test requirements
  - If test itself is wrong (rare), update test with clear justification in code.md

- **Compilation/syntax errors**:
  - Fix syntax immediately before proceeding
  - Do not continue with broken code

- **Dependency missing**:
  - Check plan for dependency installation step
  - If missing from plan: STOP and ask user for approval
  - Do not auto-install dependencies without explicit plan step or user approval

- **Scope ambiguity discovered**:
  - STOP implementation
  - Ask user to clarify scope
  - Update plan if needed before continuing
</critical>

4. **Document evidence**: Save validation output for code.md documentation

[IF MODE=INCREMENTAL]:
After each plan phase:
1. Document phase progress in code.md
2. Run full validation suite
3. Present checkpoint status to user
4. Wait for approval before continuing to next phase

## 5. Implementation Documentation

<task>Document implementation with evidence-based specificity</task>

Create `$SESSION_DIR/code.md` with comprehensive evidence:

<template>
```markdown
# Implementation: [Feature/Fix/Refactor Name from Plan]

<session_info>
ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Phase: Implementation
Type: [FEATURE|FIX|REFACTOR|TEST] | Focus: $2
Mode: [INCREMENTAL|CONTINUOUS]
</session_info>

## Summary

[2-3 sentence overview of what was implemented and why, referencing plan objectives]

## Key Changes (REQUIRED: file:line for EVERY change)

<critical>
Every change MUST include:
- Exact file path and line range
- What changed (code-level specificity)
- Why it changed (reference plan step)
- Impact (performance/security/functionality/maintainability)
- Test coverage for this change
</critical>

**Format**: `file:lines - WHAT | WHY | IMPACT | TESTS`

### 1. **src/auth/validator.py:45-67** - Extract email validation
- **WHAT**: Extracted email validation into `validate_email()` helper
- **WHY**: Reduce cyclomatic complexity 12→7 (plan step 2)
- **IMPACT**: +15% test coverage, reusable across modules
- **TESTS**: tests/test_auth.py:123-145 (3 new cases)

[Continue for ALL changes - minimum 2, typically 3-7 depending on scope]

## Type-Specific Details

[IF TYPE=FEATURE]: **Feature** | **API Changes** | **Integration** | **Examples**
[IF TYPE=FIX]: **Bug** | **Root Cause** (file:line) | **Fix** (file:line) | **Regression Test**
[IF TYPE=REFACTOR]: **Metrics** (before→after) | **Tests** ([X] pass) | **Structure**
[IF TYPE=TEST]: **Coverage** ([X]%→[Y]%, +[Z]%) | **New** ([X] unit, [Y] integration) | **Edge Cases**

## Validation Evidence

<critical>
REQUIRED: Provide actual command output, not just "tests passed"
</critical>

### Tests Executed
```bash
$ [exact test command] # e.g., pytest tests/test_auth.py -v
[output summary: X passed in Ys]
```
**Status**: ✅ [X] tests run, [Y] passed, [Z] added | **Coverage**: [if measured]%

### Code Quality Checks
[IF linting/compilation]: `$ [command]` → **Status**: ✅ Pass | ⚠️ Warnings | ❌ Fixed
[IF manual testing]: [Brief steps + results]

## Issues & Resolution
[If any]: **Issue** → Cause → Resolution → Prevention
[If none]: No issues encountered.

## Files Modified
**Summary**: [X] modified, [Y] added, [Z] deleted
- `[path]`: +[X] -[Y] lines

## Documentation Updates
[List updates or "None required"]

## Status & Next Steps

**Status**: [✅ Complete | ⏸️ Pending approval | 🔄 Checkpoint N/M]
**Next**: Review → `/commit [type] "desc"` → `git push -u origin [branch]`
**Refs**: @${SESSION_DIR}/CLAUDE.md | @${SESSION_DIR}/plan.md
```
</template>

Update `$SESSION_DIR/CLAUDE.md`:
```markdown
## Implementation Complete
**Phase**: implementation | $(date '+%Y-%m-%d %H:%M') | Type: [FEATURE|FIX|REFACTOR|TEST]
**Changes**: [X] files | [components] | Tests: [X] run, [Y] pass, [Z] new | Coverage: [X→Y%]
**Validation**: ✅ Tests, Lint, Scope, Security | **Details**: @code.md
```

## 6. User Approval

<critical>
WAIT for user approval before considering task complete.
DO NOT proceed to commit without explicit approval.
</critical>

Present summary:
```
✅ Implementation: ${SESSION_ID} | Type: [TYPE] | Focus: $2

📝 [2-3 sentence summary]

🔧 Files: [X] mod, [Y] add | Components: [list] | Lines: ~[+/-]
✅ Tests: [X] run, [Y] pass, [Z] new | Lint: [status] | Coverage: [X→Y%]
🔒 Scope: ✅ Plan-only | Security: ✅
📁 Details: ${SESSION_DIR}/code.md

⏸️  AWAITING APPROVAL - Review code.md, approve or request changes
```

After approval:
```
🎉 Approved! Next: /commit [type] "desc" → git push -u origin [branch]
```

---

**Quality Checklist** (self-verify before presenting):
- [ ] Scope: Modified ONLY what was in plan
- [ ] Evidence: Every change has file:line + WHAT/WHY/IMPACT
- [ ] Validation: Tests run and passed (with output)
- [ ] Security: No vulnerabilities, no secrets, proper error handling
- [ ] Documentation: code.md complete with all required sections
- [ ] Consistency: Follows existing code patterns
- [ ] User approval: Awaiting explicit approval before commit

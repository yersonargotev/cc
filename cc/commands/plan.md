---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[query] [context] [constraints]"
description: Research (code + web in parallel) then create implementation plan in one step
---

# Plan: Integrated Research & Strategy

Plan for: **$1**$2$3

## 1. Session Setup

<task>Create session directory and initialize context tracker</task>

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DIR=".claude/sessions/${SESSION_ID}_$(echo "$1" | tr -cs 'a-z0-9' '_' | head -c 20)"
mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/CLAUDE.md" << 'EOF'
# Session: $1
Status: planning | ID: ${SESSION_ID} | Started: $(date '+%Y-%m-%d %H:%M')
Objective: $1
Context: $2$3
Research: code + web (in progress)
Next: Plan generation after research completes
EOF
```

## 2. Parallel Research

<task>Launch code + web agents simultaneously</task>

<critical>
Use single message with TWO Task calls (parallel execution)
</critical>

### Task 1: Code Analysis
```
Task(
  subagent: "code-search-agent",
  model: "haiku",
  description: "Analyze codebase",
  prompt: "Query: $1. Context: $2$3. Output: ${SESSION_DIR}/code-search.md. See agents/code-search-agent.md for methodology."
)
```

### Task 2: Web Research
```
Task(
  subagent: "web-research-agent",
  model: "haiku",
  description: "Research external info",
  prompt: "Query: $1. Context: $2$3. Focus: 2024-2025. Output: ${SESSION_DIR}/web-research.md. See agents/web-research-agent.md for methodology."
)
```

<output>
Wait for both to complete before proceeding to synthesis.
</output>

## 3. Plan Generation with Integrated Synthesis

<task>After both agents complete, synthesize findings and create comprehensive plan</task>

### Step 1: Read Research Results

Read both files:
- `${SESSION_DIR}/code-search.md` - Code analysis
- `${SESSION_DIR}/web-research.md` - Web research

### Step 2: Create Comprehensive Plan

Create `${SESSION_DIR}/plan.md` with integrated synthesis:

<template>
```markdown
# Implementation Plan: [Feature from $1]

<session_info>
ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Phase: Planning
Objective: $1 | Context: $2$3
</session_info>

<context>
## Synthesis (Code + Web Analysis)

### Current State (from codebase)
**Architecture**: [pattern] at [file:line]
- Organization: [structure with key dirs]
- Components ([N] files): [list with file:line]
- Tests: ~[X]% coverage | Framework: [name] | Gaps: [areas]
- Dependencies: [X] external ([status: ✅/⚠️/❌]) | [X] internal
- Docs: [available] | Quality: ✅/⚠️/❌ | Gaps: [areas]

**Strengths** ✅: [2-3 items with file:line evidence]
**Weaknesses** ⚠️: [2-3 items with file:line evidence]

### Available Information (from research)
**Key Concepts**: [3-5 concepts with URL sources]
**Official Docs**: [URLs with coverage notes]
**Examples**: [URLs with what they demonstrate]
**Related Tech**: [ecosystem context]
**Recent Updates**: [2024-2025 changes if relevant]

### Integrated Analysis

**Gaps & Priorities** (Top 5-7):
1. 🔴 **[Gap]** | Current: [file:line] → Recommended: [from URL] | Impact: [why] | Effort: L/M/H
2. 🟡 **[Gap]** | Current: [state] → Recommended: [approach] | Impact: [significance] | Effort: L/M/H
[Continue for top gaps]

**Risks & Mitigation**:
- 🔴 **[Risk]** ([Security/Performance/Reliability]): [current at file:line] | Mitigation: [steps] | Reference: [URL]
- 🟡 **[Risk]**: [description] | Mitigation: [approach]
- 🟢 **[Consideration]**: [brief + approach]
</context>

<implementation>
## Strategy & Approach

**Approach**: [1-2 sentence synthesis of code reality + research findings]
**Rationale**: Code: [evidence] + Web: [findings] → [this approach]
**Architecture Decisions**: [2-3 key choices with trade-offs]
**Pattern**: [selected pattern] | Justification: [why] | Reference: [URL] | Current usage: [file:line]

## Step-by-Step Implementation (Max 7 steps)

### Phase 1: Foundation
**Step 1: [Action Verb] [Target]**
- Files: [paths:line ranges]
- Changes: [what + why]
- Dependencies: [prerequisites]
- Validation: [how to verify - commands/tests]
- Effort: [hours/days]

**Step 2: [Action Verb] [Target]**
- Files: [paths]
- Changes: [details]
- Validation: [verification]
- Effort: [estimate]

### Phase 2: Core Implementation
**Step 3-5**: [Continue pattern above]

### Phase 3: Polish
**Step 6-7**: [Final steps]
</implementation>

<validation>
## Testing & Success

**Unit Tests** ([N] new):
- `test_[name]` in [file]: [what it tests]
- `test_[name]` in [file]: [what it tests]

**Integration Tests** ([N] scenarios):
- [Scenario]: [description] | Expected: [outcome]

**Edge Cases**: [2-3 cases with handling approach]

**Validation Commands**:
```bash
[test command]        # Run tests
[coverage command]    # Check coverage
[integration command] # Verify integration
```

**Success Criteria**:
- ✅ Technical: [criterion with verification method]
- ✅ Quality: Coverage ≥[X]% (current: [Y]%) | All tests pass | No regressions
- ✅ Functional: [features] working as specified
- ✅ Performance: [metric]: [target] (current: [baseline])

**Timeline**: Phase 1: [est] | Phase 2: [est] | Phase 3: [est] | Total: [rough est]
</validation>

<references>
## Documentation & References

**Updates Needed**:
- Code comments: [files needing documentation]
- API docs: [endpoints/functions to document]
- README: [sections to add/update]
- Migration: [if breaking changes]

**Session Files**:
- Context: @${SESSION_DIR}/CLAUDE.md
- Code: @${SESSION_DIR}/code-search.md
- Web: @${SESSION_DIR}/web-research.md

**External**: [Key URLs from research]

**Assumptions**: [2-3 key assumptions]
**Limitations**: [known gaps in analysis/research]
</references>
```
</template>

<requirements>
- Use priority indicators: 🔴🟡🟢 consistently
- Evidence: file:line (code) or URLs (web) - no vague descriptions
- Max 5-7 implementation steps
- Each step: max 3 sub-tasks
- Total plan length: aim for 150-250 lines
- Consolidate similar sections
- Use extended thinking for synthesis
</requirements>

### Step 3: Update Session Context

Update `${SESSION_DIR}/CLAUDE.md`:

```markdown
## Status
Phase: planning-complete | Completed: $(date '+%Y-%m-%d %H:%M')

## Research Summary
**Code** ([N] files): [pattern] | [key components] | ~[X]% coverage | [X] ext + [X] int deps
**Web** ([N] sources): [docs] | [examples] | [ecosystem]

## Key Insights (Synthesized)
1. **[Insight]**: Code: [file:line] + Web: [URL] → [conclusion]
2. **[Insight]**: [combining evidence]
3. **[Insight]**: [combining evidence]

## Critical Gaps
🔴 **[Gap]**: [X] → [Y] | Impact: [why] | Effort: [est]
🟡 **[Gap]**: [X] → [Y] | Impact: [why] | Effort: [est]

## Implementation
**Strategy**: [one sentence]
**Phases**: [X] steps | Phase 1: [summary] | Phase 2: [summary] | Phase 3: [summary]

## Risks
🔴 High: [X] identified | 🟡 Medium: [X] identified | 🟢 Low: [X] considerations

## Next Steps
Run `/code ${SESSION_ID}` to implement

## References
- Plan: @${SESSION_DIR}/plan.md
- Code: @${SESSION_DIR}/code-search.md
- Web: @${SESSION_DIR}/web-research.md
```

## 4. Report to User

Present summary:

```
✅ Planning complete: ${SESSION_ID}

🔍 RESEARCH:
  📊 Code: [X] files | [X] components | ~[X]% coverage
  🌐 Web: [X] sources | 2024-2025 standards

🎯 KEY GAPS:
  1. 🔴 [Gap]: [current] → [recommended] | Impact: [why] | Effort: [est]
  2. 🟡 [Gap]: [current] → [recommended] | Impact: [why] | Effort: [est]
  3. 🟢 [Gap]: [current] → [recommended] | Impact: [why] | Effort: [est]

📋 PLAN:
  • Approach: [one-sentence]
  • Steps: [X] across [Y] phases
  • Tests: [X] scenarios
  • Risks: [X] mitigated

🔴 HIGH: [X] | 🟡 MEDIUM: [X] | 🟢 LOW: [X]

📁 SESSION: ${SESSION_ID}
   Context: ${SESSION_DIR}/CLAUDE.md (auto-loads)
   Plan: ${SESSION_DIR}/plan.md
   Details: code-search.md + web-research.md

🚀 NEXT: /code ${SESSION_ID}
```

## Quality Standards

<requirements>
✅ **Integration**: Synthesize code + web findings
✅ **Evidence**: All claims → file:line or URLs (no vague descriptions)
✅ **Execution**: Prioritized (🔴🟡🟢), risk-aware, actionable steps with validation
✅ **Scope**: Realistic, complete (context + strategy + steps + tests + risks + docs)
</requirements>

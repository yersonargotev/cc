---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[query] [context] [constraints]"
description: Intelligent research (code/web/both) then create implementation plan
---

# Plan: Intelligent Research & Strategy

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
Research: detecting strategy...
Next: Plan generation after research completes
EOF
```

## 2. Query Analysis & Agent Selection

<task>Analyze query intent and determine optimal research strategy</task>

### Classification Logic

Analyze the combined query: `$1 $2 $3`

**🔵 CODE-ONLY** (code-search-agent only):
- Keywords: `refactor|test|debug|optimize|fix|improve|coverage|lint|clean|organize|restructure`
- Context: References to existing files, functions, classes, modules
- Intent: Work with existing codebase, no external research needed
- Examples: "refactor auth module", "add tests to user.py", "fix bug in payment service"

**🌐 WEB-ONLY** (web-research-agent only):
- Keywords: `research|learn|documentation|docs|examples|tutorial|guide|explain|understand|practices|standards|compare`
- Context: Learning, exploring concepts, finding documentation
- Intent: External information needed, no codebase analysis required
- Examples: "research GraphQL best practices", "find React 18 examples", "latest Next.js docs"

**🔄 BOTH** (both agents in parallel):
- Keywords: `implement|add|create|build|integrate|develop|feature|new|migrate|setup`
- Context: New functionality requiring both codebase understanding and external knowledge
- Intent: Need to understand current state AND research implementation approaches
- Examples: "implement OAuth", "add GraphQL API", "integrate Stripe payments"

**❓ UNCLEAR** (ask user):
- Ambiguous intent or query could fit multiple categories
- Very general queries without clear direction
- Better to ask than waste tokens on wrong research

### Strategy Selection

<critical>
Determine strategy based on classification above. If UNCLEAR, present options to user.
</critical>

**If UNCLEAR, present this to user:**
```
🤔 Query intent is unclear. Please select research strategy:

Query: "$1 $2 $3"

Options:
1. 🔵 CODE - Analyze codebase only (refactor/test/debug existing code)
2. 🌐 WEB - Research external info only (learn/explore/find documentation)
3. 🔄 BOTH - Full research (implement new features, integrate libraries)
4. ❌ CANCEL - Let me refine the query

Enter choice [1-4]:
```

Wait for user response and set STRATEGY accordingly.

**Otherwise, set STRATEGY automatically:**
- CODE-ONLY → STRATEGY="CODE"
- WEB-ONLY → STRATEGY="WEB"
- BOTH → STRATEGY="BOTH"

Update session file with detected strategy:
```bash
echo "Research: ${STRATEGY} strategy detected" >> "$SESSION_DIR/CLAUDE.md"
```

## 3. Conditional Research Execution

<task>Launch appropriate agents based on strategy</task>

<critical>
Launch agents according to STRATEGY. Use single message with parallel Task calls when launching multiple agents.
</critical>

### Strategy: CODE (code-search-agent only)

```
Task(
  subagent: "code-search-agent",
  model: "haiku",
  description: "Analyze codebase",
  prompt: "Query: $1. Context: $2$3. Output: ${SESSION_DIR}/code-search.md. See agents/code-search-agent.md for methodology. Focus on: components, architecture, tests, dependencies, documentation."
)
```

Skip web research. Set `WEB_RESEARCH="(skipped - code-only query)"` for plan generation.

### Strategy: WEB (web-research-agent only)

```
Task(
  subagent: "web-research-agent",
  model: "haiku",
  description: "Research external info",
  prompt: "Query: $1. Context: $2$3. Focus: 2024-2025. Output: ${SESSION_DIR}/web-research.md. See agents/web-research-agent.md for methodology. Find: concepts, documentation, examples, ecosystem context."
)
```

Skip code analysis. Set `CODE_SEARCH="(skipped - web-only query)"` for plan generation.

### Strategy: BOTH (parallel execution)

Launch BOTH agents in a single message with TWO Task calls:

**Task 1: Code Analysis**
```
Task(
  subagent: "code-search-agent",
  model: "haiku",
  description: "Analyze codebase",
  prompt: "Query: $1. Context: $2$3. Output: ${SESSION_DIR}/code-search.md. See agents/code-search-agent.md for methodology."
)
```

**Task 2: Web Research**
```
Task(
  subagent: "web-research-agent",
  model: "haiku",
  description: "Research external info",
  prompt: "Query: $1. Context: $2$3. Focus: 2024-2025. Output: ${SESSION_DIR}/web-research.md. See agents/web-research-agent.md for methodology."
)
```

<output>
Wait for agent(s) to complete before proceeding to synthesis.
</output>

## 4. Plan Generation with Synthesis

<task>After research completes, synthesize findings and create comprehensive plan</task>

### Step 1: Read Available Research Results

Read files based on STRATEGY:
- CODE or BOTH: Read `${SESSION_DIR}/code-search.md`
- WEB or BOTH: Read `${SESSION_DIR}/web-research.md`

### Step 2: Create Comprehensive Plan

Create `${SESSION_DIR}/plan.md` with integrated synthesis:

<template>
```markdown
# Implementation Plan: [Feature from $1]

<session_info>
ID: ${SESSION_ID} | Date: $(date '+%Y-%m-%d %H:%M') | Phase: Planning
Objective: $1 | Context: $2$3 | Strategy: ${STRATEGY}
</session_info>

<context>
## Research Summary

[IF STRATEGY = CODE or BOTH, include:]
### Current State (Codebase Analysis)
**Architecture**: [pattern] at [file:line]
- Organization: [structure with key directories]
- Key Components ([N] files): [list with file:line references]
- Tests: ~[X]% coverage | Framework: [name] | Gaps: [areas]
- Dependencies: [X] external (status: ✅/⚠️/❌) | [X] internal
- Documentation: [available] | Quality: ✅/⚠️/❌ | Gaps: [areas]

**Strengths** ✅: [2-3 items with file:line evidence]
**Weaknesses** ⚠️: [2-3 items with file:line evidence]

[IF STRATEGY = WEB or BOTH, include:]
### External Research
**Key Concepts**: [3-5 concepts with URL sources]
**Official Docs**: [URLs with coverage notes]
**Examples**: [URLs with demonstrated patterns]
**Related Technologies**: [ecosystem context]
**Recent Updates**: [2024-2025 changes if relevant]

[IF STRATEGY = BOTH, include:]
### Integrated Analysis
**Gaps & Priorities** (Top 5-7):
1. 🔴 **[Gap]** | Current: [file:line] → Recommended: [from URL] | Impact: [why] | Effort: L/M/H
2. 🟡 **[Gap]** | Current: [state] → Recommended: [approach] | Impact: [significance] | Effort: L/M/H
[Continue for critical gaps]

**Risks & Mitigation**:
- 🔴 **[Risk]** ([Security/Performance/Reliability]): [current at file:line] | Mitigation: [steps] | Reference: [URL]
- 🟡 **[Risk]**: [description] | Mitigation: [approach]
- 🟢 **[Consideration]**: [brief + approach]
</context>

<implementation>
## Strategy & Approach

**Approach**: [1-2 sentence synthesis of findings]
[IF BOTH: Code: [evidence] + Web: [findings] → [conclusion]]
[IF CODE: Based on current architecture: [evidence] → [approach]]
[IF WEB: Based on research: [findings] → [approach]]

**Rationale**: [why this approach]
**Architecture Decisions**: [2-3 key choices with trade-offs]
**Pattern**: [selected pattern] | Justification: [why] | Reference: [URL or file:line]

## Implementation Steps (Max 7)

### Phase 1: Foundation
**Step 1: [Action Verb] [Target]**
- Files: [paths:line ranges]
- Changes: [what + why]
- Dependencies: [prerequisites]
- Validation: [how to verify - commands/tests]
- Effort: [hours/days]

**Step 2: [Action Verb] [Target]**
[Same structure]

### Phase 2: Core Implementation
**Step 3-5**: [Core changes]

### Phase 3: Validation & Polish
**Step 6-7**: [Testing, documentation, cleanup]
</implementation>

<validation>
## Testing & Success Criteria

**Tests** ([N] new):
- Unit: `test_[name]` in [file] - [what it tests]
- Integration: [scenario] - [expected outcome]

**Edge Cases**: [2-3 cases with handling]

**Validation**:
```bash
[test command]        # Run tests
[lint command]        # Check quality
[coverage command]    # Verify coverage
```

**Success Criteria**:
- ✅ Technical: [criterion with verification method]
- ✅ Quality: Coverage ≥[X]% | All tests pass | No regressions
- ✅ Functional: [features] working as specified

**Timeline**: Phase 1: [est] | Phase 2: [est] | Phase 3: [est] | Total: [estimate]
</validation>

<references>
## Documentation & References

**Updates Needed**:
- Code comments: [files]
- API docs: [endpoints/functions]
- README: [sections]

**Session Files**:
- Context: @${SESSION_DIR}/CLAUDE.md
[IF CODE or BOTH: - Code: @${SESSION_DIR}/code-search.md]
[IF WEB or BOTH: - Web: @${SESSION_DIR}/web-research.md]

**External References**: [Key URLs from research]

**Assumptions**: [2-3 key assumptions]
**Limitations**: [known gaps in analysis]
</references>
```
</template>

<requirements>
- Use priority indicators: 🔴🟡🟢 consistently
- Evidence: file:line (code) or URLs (web) - no vague descriptions
- Max 5-7 implementation steps, max 3 sub-tasks each
- Total plan length: aim for 150-250 lines
- Adapt content based on STRATEGY (don't include skipped research sections)
- Use extended thinking for synthesis
</requirements>

### Step 3: Update Session Context

Update `${SESSION_DIR}/CLAUDE.md`:

```markdown
## Status
Phase: planning-complete | Completed: $(date '+%Y-%m-%d %H:%M')
Strategy: ${STRATEGY}

## Research Summary
[IF CODE or BOTH: **Code** ([N] files): [pattern] | [components] | ~[X]% coverage | [deps]]
[IF WEB or BOTH: **Web** ([N] sources): [docs] | [examples] | [ecosystem]]

## Key Insights
1. **[Insight]**: [evidence] → [conclusion]
2. **[Insight]**: [evidence] → [conclusion]
3. **[Insight]**: [evidence] → [conclusion]

## Critical Gaps
🔴 **[Gap]**: [current] → [target] | Impact: [why] | Effort: [est]
🟡 **[Gap]**: [current] → [target] | Impact: [why] | Effort: [est]

## Implementation
**Strategy**: [one sentence]
**Phases**: [X] steps | Phase 1: [summary] | Phase 2: [summary] | Phase 3: [summary]

## Risks
🔴 High: [X] | 🟡 Medium: [X] | 🟢 Low: [X]

## Next Steps
Run `/code ${SESSION_ID}` to implement

## References
- Plan: @${SESSION_DIR}/plan.md
[IF CODE or BOTH: - Code: @${SESSION_DIR}/code-search.md]
[IF WEB or BOTH: - Web: @${SESSION_DIR}/web-research.md]
```

## 5. Report to User

Present summary based on STRATEGY:

```
✅ Planning complete: ${SESSION_ID}

🎯 STRATEGY: ${STRATEGY}
[IF CODE: 🔵 Code analysis only - no external research needed]
[IF WEB: 🌐 Web research only - no codebase analysis needed]
[IF BOTH: 🔄 Full research - code + web]

🔍 RESEARCH:
[IF CODE or BOTH:   📊 Code: [X] files | [X] components | ~[X]% coverage]
[IF WEB or BOTH:   🌐 Web: [X] sources | 2024-2025 standards]

🎯 KEY FINDINGS:
  1. 🔴 [Finding]: [evidence] → [recommendation] | Impact: [why] | Effort: [est]
  2. 🟡 [Finding]: [evidence] → [recommendation] | Impact: [why] | Effort: [est]
  3. 🟢 [Finding]: [evidence] → [recommendation] | Impact: [why] | Effort: [est]

📋 PLAN:
  • Approach: [one-sentence summary]
  • Steps: [X] across [Y] phases
  • Tests: [X] scenarios
  • Risks: [X] identified and mitigated

📁 SESSION: ${SESSION_ID}
   Context: ${SESSION_DIR}/CLAUDE.md (auto-loads)
   Plan: ${SESSION_DIR}/plan.md
[IF CODE or BOTH:    Code: code-search.md]
[IF WEB or BOTH:    Web: web-research.md]

🚀 NEXT: /code ${SESSION_ID}

💡 Token efficiency: Launched ${STRATEGY} agents only (skipped unnecessary research)
```

## Quality Standards

<requirements>
✅ **Intelligence**: Only launch necessary agents based on query analysis
✅ **Efficiency**: Minimize token usage by avoiding unnecessary research
✅ **Clarity**: Ask user when intent is unclear rather than guessing
✅ **Evidence**: All claims → file:line or URLs (no vague descriptions)
✅ **Integration**: Synthesize available findings (code and/or web)
✅ **Execution**: Prioritized (🔴🟡🟢), risk-aware, actionable steps with validation
✅ **Completeness**: Realistic scope with context + strategy + steps + tests + risks + docs
✅ **Adaptability**: Plan content adapts to research strategy (CODE/WEB/BOTH)
</requirements>

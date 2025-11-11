---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[query] [context] [constraints]"
description: Research (code + web in parallel) then create implementation plan in one step
---

# Plan: Integrated Research & Strategy

Plan for: **$1**$2$3

## 1. Session Setup

Create unique session for tracking:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

echo "📋 Planning session: ${SESSION_ID}"
echo "🔍 Launching parallel research..."

# Initialize CLAUDE.md
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: planning-research | Started: $(date '+%Y-%m-%d %H:%M') | ID: ${SESSION_ID}

## Objective
$1

## Context
$2$3

## Research Status
- Code search: In progress...
- Web research: In progress...

## Next Steps
Plan generation after research completes
EOF
```

## 2. Parallel Research (Launch Both Simultaneously)

**IMPORTANT**: Launch BOTH agents in parallel using a single message with two Task calls.

### Task 1: Code Search Agent
- **Subagent**: `code-search-agent`
- **Model**: `haiku`
- **Description**: "Analyze codebase for code search"
- **Prompt**:
```
Analyze codebase for: $1. Context: $2$3.

Save complete analysis to: ${SESSION_DIR}/code-search.md

Include:
- File:line references for all components
- Architecture patterns
- Test coverage analysis
- Dependencies (external + internal)
- Documentation state
- Current implementation quality
```

### Task 2: Web Research Agent
- **Subagent**: `web-research-agent`
- **Model**: `haiku`
- **Description**: "Research web for topic information"
- **Prompt**:
```
Research information and documentation for: $1. Context: $2$3.

Focus on 2024-2025 content. Save complete research to: ${SESSION_DIR}/web-research.md

Include:
- Official documentation and API references
- Current concepts and definitions
- Code examples and implementations
- Related technologies and ecosystem
- Recent updates and features
```

## 3. Plan Generation with Integrated Synthesis

**After both agents complete**, use extended thinking to:

### Step 1: Read Research Results

Read both files:
- `${SESSION_DIR}/code-search.md` - Detailed code analysis
- `${SESSION_DIR}/web-research.md` - Detailed web research

### Step 2: Create Comprehensive Plan

Create `${SESSION_DIR}/plan.md` with integrated synthesis:

```markdown
# Implementation Plan: [Feature Name from $1]

## Session Information
- Session ID: ${SESSION_ID}
- Date: $(date '+%Y-%m-%d %H:%M')
- Phase: Planning
- Objective: $1
- Context: $2$3

## Context Analysis (Integrated Synthesis)

### Current State (Codebase)
**Architecture**: [pattern found with file:line]
- Pattern: [MVC/Layered/etc.]
- Organization: [directory structure]
- Key components: [list with file:line]

**Components Analyzed**: [N files]
- Core components: [list with purposes]
- Supporting modules: [list]
- Configuration: [locations]

**Test Coverage**: ~[X]%
- Framework: [Jest/PyTest/etc.]
- Well-tested areas: [list]
- Coverage gaps: [list with file:line]

**Dependencies**:
- External: [package@version list] | Status: ✅/⚠️/❌
- Internal: [module imports]
- Security risks: 🔴/🟡/🟢 [assessment]

**Documentation**:
- Available: [README, docs/, comments]
- Quality: ✅/⚠️/❌ [assessment]
- Gaps: [missing/outdated areas]

**Current Strengths**: ✅
1. [Strength with evidence from code]
2. [Strength with evidence from code]

**Current Weaknesses**: ⚠️
1. [Weakness with evidence from code]
2. [Weakness with evidence from code]

### Available Information (External Research)

**Key Concepts**: [from web research]
- [Concept]: [definition/explanation] ([source URL])
- [Concept]: [definition/explanation] ([source URL])

**Official Documentation**: [URLs]
- [Doc source]: [what it covers]
- [API ref]: [what it documents]

**Available Examples**: [URLs]
- [Implementation]: [what it demonstrates]
- [Tutorial]: [what it teaches]

**Related Technologies**: [ecosystem context]
- [Technology]: [how it relates]

**Recent Updates (2024-2025)**: [if relevant]
- [Update]: [description] ([source])

### Gap Analysis

**1. [Gap Name]** - 🔴/🟡/🟢 Priority: High/Medium/Low
- **Current**: [state from code with file:line]
- **Available Info**: [relevant info from web research]
- **Impact**: [why this matters]
- **Effort**: Low/Medium/High
- **Evidence**: Code: [file:line] | Web: [URL]

**2. [Gap Name]** - 🔴/🟡/🟢 Priority: High/Medium/Low
- **Current**: [state from code]
- **Available Info**: [relevant info from web]
- **Impact**: [significance]
- **Effort**: L/M/H

[Top 5-7 gaps identified]

### Risk Assessment

**🔴 High Priority Risks**:
1. **[Risk Name]** - [Category: Security/Performance/Reliability]
   - Current: [code state with file:line]
   - Relevant Info: [from web research with URL]
   - Likelihood: High/Medium/Low
   - Impact: High/Medium/Low
   - Mitigation: [specific steps]

**🟡 Medium Priority Risks**:
1. **[Risk Name]** - [description]
   - Mitigation: [approach]

**🟢 Low Priority Considerations**:
- [Risk]: [brief description + approach]

## Implementation Strategy

### Approach
[Strategic approach synthesizing code reality + available information]

**Why This Approach**:
- Based on: [code evidence] + [web research findings]
- Aligns with: [project architecture]
- Addresses: [key gaps identified]

### Architecture Decisions

**Decision 1: [Choice]**
- Rationale: [based on code evidence + web information]
- Trade-offs: Pros: [list] | Cons: [list]
- Impact: [areas affected]

**Decision 2: [Choice]**
- Rationale: [reasoning]
- Trade-offs: [analysis]

### Pattern Choices

**Selected Pattern: [Pattern Name]**
- Justification: [why this pattern based on both sources]
- Current usage: [evidence from code]
- Reference: [URL from web research]
- Implementation: [how to apply]

## Step-by-Step Implementation

### Phase 1: Foundation
**1. [Step Name]**
- **Files**: [specific paths with line ranges]
- **Changes**: [what to change and why]
- **Dependencies**: [what must be done first]
- **Validation**: [how to verify - commands/tests]
- **Estimated Effort**: [hours/days]

**2. [Step Name]**
- **Files**: [paths]
- **Changes**: [details]
- **Validation**: [verification steps]

### Phase 2: Core Implementation
**3. [Step Name]**
- **Files**: [paths]
- **Changes**: [details]
- **Validation**: [verification]

[Continue with all steps...]

## Testing Strategy

### Unit Tests
- **New Tests Needed**: [N tests]
  - `test_[name]` in [file]: [what it tests]
  - `test_[name]` in [file]: [what it tests]

### Integration Tests
- **Test Scenarios**: [N scenarios]
  - [Scenario]: [description] | Expected: [outcome]
  - [Scenario]: [description] | Expected: [outcome]

### Edge Cases
- [Case]: [how to handle]
- [Case]: [approach]

### Test Data Requirements
- [Data type]: [what's needed]
- [Fixtures]: [to create/update]

### Validation Commands
```bash
# Run tests
[command to run tests]

# Check coverage
[command to check coverage]

# Integration validation
[command to verify integration]
```

## Risk Mitigation

**For Each High-Priority Risk**:

**Risk: [Name]**
- **Strategy**: [mitigation approach]
- **Contingency**: [backup plan]
- **Rollback**: [how to undo if needed]
- **Monitoring**: [what to watch for]

## Documentation Updates

### Code Comments
- [File]: [what comments to add]
- [Component]: [documentation needed]

### API Documentation
- [Endpoint/Function]: [what to document]
- [Interface]: [documentation updates]

### README Updates
- Section: [what to add/update]
- Examples: [new examples needed]

### Migration Guides (if needed)
- [Breaking change]: [how to migrate]

## Success Criteria

**Technical**:
- ✅ [Criterion]: [how to verify]
- ✅ [Criterion]: [verification method]

**Quality**:
- ✅ Test coverage: ≥[X]% (current: [Y]%)
- ✅ All tests passing
- ✅ No regressions in [area]

**Functional**:
- ✅ [Feature] working as specified
- ✅ [Integration] functional

**Performance**:
- ✅ [Metric]: [target] (current: [baseline])

## Timeline Estimate

**Phase 1 (Foundation)**: [estimate]
**Phase 2 (Core)**: [estimate]
**Phase 3 (Polish)**: [estimate]
**Total**: [rough estimate]

**Note**: Timeline may vary based on unforeseen complexity

## References

**Session Files**:
- Context: @${SESSION_DIR}/CLAUDE.md
- Code Analysis: @${SESSION_DIR}/code-search.md
- Web Research: @${SESSION_DIR}/web-research.md

**External Sources**: [Key URLs from web research]

**Assumptions**:
- [Assumption 1]
- [Assumption 2]

**Limitations**:
- [Limitation in code analysis]
- [Gap in web research]
```

### Step 3: Update Session Context

Update `${SESSION_DIR}/CLAUDE.md` with:

```markdown
## Status
Phase: planning-complete | Completed: $(date '+%Y-%m-%d %H:%M')

## Research Summary

### Code Analysis ([N] files)
- Architecture: [pattern]
- Components: [key components]
- Coverage: ~[X]%
- Dependencies: [X] external, [X] internal

### Web Research ([N] sources)
- Documentation: [official sources found]
- Examples: [implementations found]
- Ecosystem: [related technologies]

## Key Insights (Synthesized)

1. **[Insight]**: [combining code + web evidence]
   - Code: [file:line]
   - Web: [URL]

2. **[Insight]**: [combining evidence]
   - Code: [file:line]
   - Web: [URL]

3. **[Insight]**: [combining evidence]
   - Code: [file:line]
   - Web: [URL]

## Critical Gaps Identified

🔴 **[Gap]**: Current [X] → Recommended [Y]
- Impact: [why critical]
- Effort: [estimate]

🟡 **[Gap]**: Current [X] → Recommended [Y]
- Impact: [significance]
- Effort: [estimate]

## Implementation Approach

**Strategy**: [one-sentence summary]

**Phases**: [X] steps across [Y] phases
- Phase 1: [summary]
- Phase 2: [summary]
- Phase 3: [summary]

## Risks & Mitigation

🔴 **High**: [X] identified with mitigation strategies
🟡 **Medium**: [X] identified with approaches
🟢 **Low**: [X] considerations

## Next Steps

Run `/code ${SESSION_ID}` to implement

## References

- **Plan** (integrated analysis + strategy): @${SESSION_DIR}/plan.md
- **Code Analysis** (detailed): @${SESSION_DIR}/code-search.md
- **Web Research** (detailed): @${SESSION_DIR}/web-research.md
```

## 4. Report to User

Present comprehensive summary:

```
✅ Planning complete: ${SESSION_ID}

🔍 RESEARCH CONDUCTED:
  📊 Code: [X] files | [X] components | ~[X]% coverage
  🌐 Web: [X] authoritative sources | 2024-2025 standards

🎯 KEY GAPS IDENTIFIED:
  1. 🔴 [Gap]: [current] → [recommended] | Impact: [why] | Effort: [estimate]
  2. 🟡 [Gap]: [current] → [recommended] | Impact: [why] | Effort: [estimate]
  3. 🟢 [Gap]: [current] → [recommended] | Impact: [why] | Effort: [estimate]

📋 PLAN CREATED:
  • Approach: [one-sentence summary]
  • Steps: [X] defined with validation
  • Phases: [X] (Foundation → Core → Polish)
  • Tests: [X] scenarios
  • Risks: [X] mitigated

🔴 HIGH PRIORITY: [X] | 🟡 MEDIUM: [X] | 🟢 LOW: [X]

📁 SESSION: ${SESSION_ID}
   Context: ${SESSION_DIR}/CLAUDE.md (auto-loads in /code)
   Plan: ${SESSION_DIR}/plan.md (integrated analysis + strategy)
   Details: code-search.md + web-research.md (full research)

🚀 NEXT: /code ${SESSION_ID}
```

## Quality Standards

Ensure plan meets these criteria:

✅ **Evidence-Based**: All claims backed by file:line (code) or URLs (web)
✅ **Actionable**: Specific, implementable steps with clear validation
✅ **Comprehensive**: Context + strategy + steps + tests + risks + docs
✅ **Prioritized**: Critical items first (🔴 > 🟡 > 🟢)
✅ **Integrated**: Synthesis of code reality + available information
✅ **Concise**: Dense information, clear structure, no fluff
✅ **Validated**: Success criteria with verification methods

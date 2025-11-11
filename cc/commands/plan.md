---
allowed-tools: Read, Write, Task, Bash, ExitPlanMode
argument-hint: "[session_id] [implementation approach] [key constraints]"
description: "⚠️ DEPRECATED: Use /explore in HYBRID mode instead (generates plan automatically)"
---

# Plan: Implementation Strategy

⚠️ **DEPRECATED**: This command is deprecated. Use `/explore` in HYBRID mode instead, which automatically generates an implementation plan.

## Migration Guide
- **Old workflow**: `/explore` → `/plan` → `/code`
- **New workflow**: `/explore` (HYBRID mode) → `/code`

The `/explore` command now generates the implementation plan automatically when running in HYBRID mode (code analysis + web research).

Create detailed plan for session: **$1** with approach: **$2**$3

## Session Validation

```bash
SESSION_ID="$1"
SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)

[ -z "$SESSION_DIR" ] && echo "❌ Session not found: $SESSION_ID" && exit 1

echo "✅ Loaded: $SESSION_ID"
echo "📋 Context auto-loaded from CLAUDE.md"

sed -i "s/Phase: explore/Phase: planning/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
```

**Context Available**:
- Session CLAUDE.md (auto-loaded): Key findings, gaps, priorities
- Detailed exploration: @$SESSION_DIR/explore.md (reference if needed)

## Planning Task

Use extended thinking to create comprehensive implementation plan covering:

### 1. Implementation Strategy
- Overall approach and rationale
- Architecture decisions
- Pattern choices based on exploration findings

### 2. Step-by-Step Plan
Detailed steps with:
- **Files**: Specific paths to modify
- **Changes**: What to change and why
- **Validation**: How to verify each step

### 3. Risk Mitigation
- Strategies for identified risks from exploration
- Contingency plans
- Rollback procedures

### 4. Testing Approach
- Unit tests to add/update
- Integration tests needed
- Edge cases to cover
- Test data requirements

### 5. Documentation Updates
- Code comments
- API documentation
- README updates
- Migration guides (if needed)

## Deliverables

Save comprehensive plan to `$SESSION_DIR/plan.md`:

```markdown
# Implementation Plan: [Feature Name]

## Session Information
- Session ID: ${SESSION_ID}
- Date: $(date)
- Phase: Planning
- Approach: $2$3

## Executive Summary
[Brief overview of implementation plan]

## Implementation Strategy
[Detailed strategy based on exploration findings]

## Step-by-Step Implementation
1. **[Step Name]**
   - Files: [specific file paths]
   - Changes: [what to change]
   - Validation: [how to verify]

## Risk Mitigation
[Strategies for identified risks]

## Testing Strategy
[Comprehensive testing approach]

## Documentation Plan
[What documentation needs updating]

## Timeline Estimate
[Rough estimate of implementation time]

## Success Criteria
[How we'll know it's done correctly]
```

Update `$SESSION_DIR/CLAUDE.md` with concise planning summary:

```markdown
## Planning Phase Complete

### Implementation Approach
[One-sentence description]

### Key Steps
1. [Step 1 summary]
2. [Step 2 summary]
3. [Step 3 summary]

### Critical Risks & Mitigation
- [Risk]: [Mitigation]

### Success Criteria
- [Criterion 1]
- [Criterion 2]

### References
Detailed plan: @.claude/sessions/${SESSION_ID}_*/plan.md
```

## Completion

Report to user:

```
✅ Planning complete: ${SESSION_ID}

📋 Approach: [One-sentence summary]
🎯 Steps: [X] defined
📊 Tests: [X] scenarios
⚠️  Risks: [X] with mitigation

🚀 NEXT: /code ${SESSION_ID}

Context: .claude/sessions/${SESSION_ID}_*/CLAUDE.md (auto-loads)
Plan: .claude/sessions/${SESSION_ID}_*/plan.md
```

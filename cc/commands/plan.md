---
allowed-tools: Read, Write, Task, Bash, ExitPlanMode
argument-hint: "[session_id] [implementation approach] [key constraints]"
description: Create detailed implementation plan with auto-loaded session context
---

# Plan: Strategy and Implementation Planning

Create comprehensive implementation plan for session: **$1** with approach: **$2**$3

## Session Validation and Context Loading

Validate session exists and note that session CLAUDE.md is auto-loaded:

```bash
# Resolve session reference (supports @latest, @{N}, short IDs, slug search)
SESSION_REF="$1"

echo "🔍 Resolving session reference: $SESSION_REF"
SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" "$SESSION_REF" 2>&1)

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to resolve session reference '$SESSION_REF'"
    echo ""
    echo "$SESSION_ID"  # Error message from resolver
    echo ""
    echo "💡 Available commands:"
    echo "   /session-list              - View all sessions"
    echo "   /cc:explore <description>  - Create new session"
    exit 1
fi

echo "✅ Resolved: $SESSION_REF → $SESSION_ID"
echo ""

# Session directory (v2 format - no wildcard needed)
SESSION_DIR=".claude/sessions/${SESSION_ID}"

if [ ! -d "$SESSION_DIR" ]; then
    echo "❌ Error: Session directory not found: $SESSION_DIR"
    exit 1
fi

echo "📁 Directory: $SESSION_DIR"
echo ""
echo "📋 Context:"
echo "  - Session CLAUDE.md: Auto-loaded by Claude Code"
echo "  - Detailed exploration: @$SESSION_DIR/explore.md"
echo ""

# Update session phase
if [ -f "$SESSION_DIR/CLAUDE.md" ]; then
    if sed --version 2>&1 | grep -q "GNU"; then
        sed -i "s/Phase: explore/Phase: planning/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
    else
        sed -i '' "s/Phase: explore/Phase: planning/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
    fi
fi

# Update index phase
if [ -x "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" ]; then
    bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" update "$SESSION_ID" \
      "phase=planning" &>/dev/null || true
fi
```

**Note**: The session CLAUDE.md is automatically loaded by Claude Code's hierarchical memory system. You have immediate access to all key findings without manual file reads.

## Access to Exploration Results

You have access to:
1. **Session CLAUDE.md** (auto-loaded): Key findings, critical insights, risk factors
2. **Detailed exploration** (reference if needed): @$SESSION_DIR/explore.md

Reference the detailed exploration only if you need comprehensive information beyond the key findings in session CLAUDE.md.

## Your Task

Based on the auto-loaded session context, create a detailed implementation plan:

1. **Review Session Context**: Session CLAUDE.md is already in your context
2. **Analyze Requirements**: Build on the key findings
3. **Design Solution**: Create step-by-step implementation approach
4. **Identify Risks**: Expand on risk factors from exploration
5. **Plan Testing**: Define validation strategy
6. **Consider Edge Cases**: Think about error handling
7. **Update Session**: Save plan and update session CLAUDE.md

## Planning Process

Use extended thinking to thoroughly evaluate:

- **Implementation Strategy**: What's the best approach given the findings?
- **Breaking Changes**: Backward compatibility considerations
- **Testing Strategy**: How to validate each step
- **Documentation**: What needs updating
- **Performance**: Implications from dependency analysis

## Deliverables

Create a concrete plan including:

### 1. Implementation Strategy
- Overall approach and rationale
- Architecture decisions
- Pattern choices

### 2. Step-by-Step Plan
```markdown
1. **Step 1**: [Action]
   - Files: [specific files to modify]
   - Changes: [what to change]
   - Validation: [how to verify]

2. **Step 2**: [Action]
   - Files: [specific files]
   - Changes: [what to change]
   - Validation: [how to verify]
```

### 3. Risk Mitigation
- High-risk items and mitigation strategies
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

## Session Persistence

### 1. Create plan.md

Save comprehensive plan to `$SESSION_DIR/plan.md`:

```markdown
# Implementation Plan: [Feature Name]

## Session Information
- Session ID: ${SESSION_ID}
- Date: $(date)
- Phase: Planning
- Approach: $2$3

## Executive Summary
[Brief overview of the implementation plan]

## Implementation Strategy
[Detailed strategy based on exploration findings]

## Step-by-Step Implementation
[Detailed steps with files, changes, validation]

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

### 2. Update Session CLAUDE.md

Update session CLAUDE.md with planning summary (keep concise):

```bash
cat >> "$SESSION_DIR/CLAUDE.md" << 'EOF'

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
Detailed plan: @.claude/sessions/${SESSION_ID}/plan.md
EOF
```

## Plan Quality Checklist

Before completing, ensure:

- ✅ Implementation strategy is clear and justified
- ✅ Steps are specific with file paths and line numbers (where possible)
- ✅ Each step has validation criteria
- ✅ Risks from exploration phase are addressed
- ✅ Testing approach is comprehensive
- ✅ Documentation updates identified
- ✅ Session CLAUDE.md updated with concise summary
- ✅ Detailed plan saved to plan.md

## Next Steps

When planning is complete, inform the user:

```
✅ Planning complete for session: ${SESSION_ID}

📋 Implementation Approach:
[One-sentence summary]

🎯 Key Steps: [X] steps defined
📊 Tests Planned: [X] test scenarios
⚠️  Risks Identified: [X] with mitigation strategies

🚀 Next: Run `/cc:code @latest` to begin implementation

Session context available at:
- Auto-loaded: .claude/sessions/${SESSION_ID}/CLAUDE.md
- Detailed plan: .claude/sessions/${SESSION_ID}/plan.md

💡 Quick references: @latest, @, $(echo "$SESSION_ID" | cut -d'-' -f3), @/$(echo "$SESSION_ID" | cut -d'-' -f4-)
```

## Efficiency Notes

- **Auto-loaded context**: Session CLAUDE.md provides immediate access to findings
- **Reference on demand**: Use @ imports for detailed exploration only when needed
- **Token efficiency**: Concise session context + detailed reference files
- **Context continuity**: Hierarchical memory maintains focus across phases

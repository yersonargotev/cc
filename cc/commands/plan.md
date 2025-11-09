---
allowed-tools: Read, Write, Task, Bash, ExitPlanMode
argument-hint: "[session_id/explore file] [implementation approach] [key constraints]"
description: Create detailed implementation plan with session persistence
---

# Plan: Strategy and Implementation Planning

Think deeply and create a comprehensive implementation plan for session: **$1** with approach: **$2**$3

## Session Validation

Load existing session and validate:

```bash
# Extract session ID and validate session exists
SESSION_ID="$1"
SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d | head -1)

if [ -z "$SESSION_DIR" ]; then
    echo "Error: Session $SESSION_ID not found"
    echo "Available sessions:"
    ls -la .claude/sessions/ 2>/dev/null || echo "No sessions found"
    exit 1
fi

echo "Loaded session: $SESSION_ID"
echo "Session directory: $SESSION_DIR"

# Load exploration results
if [ -f "$SESSION_DIR/explore.md" ]; then
    echo "Exploration results found"
else
    echo "Warning: No exploration results found for this session"
fi
```

## Your Task

Based on the exploration results, create a detailed implementation plan:

1. **Load Exploration Context**: Review findings from the exploration phase
2. **Analyze Requirements**: Build on previous analysis
3. **Design Solution**: Create a step-by-step implementation approach
4. **Identify Risks**: Assess potential challenges and mitigation strategies
5. **Plan Testing**: Define how to validate the implementation
6. **Consider Edge Cases**: Think about error handling and special cases
7. **Save Session**: Persist the plan to session files

## Planning Process

Use extended thinking to thoroughly evaluate:

- **Implementation Strategy**: What's the best approach and why?
- **Breaking Changes**: What needs to be considered for backward compatibility?
- **Testing Strategy**: How will this be validated and tested?
- **Documentation**: What needs to be updated or created?
- **Performance**: Are there performance implications to consider?

## Deliverables

Create a concrete plan that includes:

- **Step-by-step implementation** with specific files and changes
- **Validation checkpoints** to ensure quality at each stage
- **Risk mitigation** strategies for potential issues
- **Testing approach** with specific test cases to cover
- **Documentation updates** needed for the changes

## Session Persistence

Save the detailed plan to session files:

- Create implementation plan file at $SESSION_DIR/plan.md
- Include: implementation strategy, step-by-step approach, risks, testing, documentation, and validation checkpoints

## Session Metadata
- Session ID: ${SESSION_ID}
- Implementation Focus: $2$3
- Timestamp: $(date)


## Implementation Guidance

When planning is complete, run:

```
/cc:code ${SESSION_ID} [focus area] [target files/components]
```

This will execute the saved plan following best practices and validation checkpoints.

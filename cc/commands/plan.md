---
allowed-tools: Read, Write, Task, Bash, ExitPlanMode, mcp__serena__read_memory, mcp__serena__write_memory, mcp__serena__list_memories, mcp__serena__find_symbol, mcp__serena__get_symbols_overview, mcp__serena__check_onboarding_performed, mcp__serena__think_about_task_adherence
argument-hint: "[session_id/explore file] [implementation approach] [key constraints]"
description: Create detailed implementation plan with session persistence and optional exploration context
---

# Plan: Strategy and Implementation Planning

Think deeply and create a comprehensive implementation plan for session: **$1** with approach: **$2**$3

## Session Validation & Context Loading

Load session context (with optional exploration):

```bash
# Extract session ID
SESSION_ID="$1"

# Try to load exploration context from Serena memory
EXPLORE_CONTEXT=$(read_memory("session_${SESSION_ID}_explore") 2>/dev/null || echo "")

# If no exploration in Serena, try legacy file system
if [ -z "$EXPLORE_CONTEXT" ]; then
    SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)
    if [ -n "$SESSION_DIR" ] && [ -f "$SESSION_DIR/explore.md" ]; then
        EXPLORE_CONTEXT=$(cat "$SESSION_DIR/explore.md")
        echo "Loaded exploration from legacy file system"
    fi
fi

# Load session metadata if available
SESSION_META=$(read_memory("session_${SESSION_ID}_meta") 2>/dev/null || echo "{}")

# STANDALONE MODE: If no exploration context, use project onboarding instead
if [ -z "$EXPLORE_CONTEXT" ]; then
    echo "⚠️  No exploration context found for session ${SESSION_ID}"
    echo "Running in STANDALONE mode - using project knowledge as context"

    # Check if project has been onboarded
    check_onboarding_performed

    # Load project onboarding as fallback context
    EXPLORE_CONTEXT=$(read_memory("onboarding") 2>/dev/null || echo "")

    if [ -n "$EXPLORE_CONTEXT" ]; then
        echo "✓ Loaded project onboarding knowledge"
    else
        echo "⚠️  No project knowledge available - proceeding with minimal context"
        echo "Consider running /cc:explore first for better planning"
    fi
else
    echo "✓ Loaded exploration context for session: $SESSION_ID"
fi
```

## Your Task

Create a detailed implementation plan with available context:

1. **Load Context**: Review exploration findings OR project knowledge (if standalone)
2. **Analyze Requirements**: Build on available analysis
3. **Design Solution**: Create a step-by-step implementation approach
4. **Identify Risks**: Assess potential challenges and mitigation strategies
5. **Plan Testing**: Define how to validate the implementation
6. **Consider Edge Cases**: Think about error handling and special cases
7. **Validate Adherence**: Ensure plan follows exploration/requirements
8. **Save Session**: Persist the plan to session memory

## Standalone Mode Support

This command can now run in two modes:

**Mode 1: With Exploration** (Recommended)
- Loads exploration context from previous /cc:explore session
- Has detailed understanding of codebase
- More accurate and comprehensive planning

**Mode 2: Standalone** (Quick Planning)
- Uses project onboarding knowledge as context
- Can still create effective plans
- Useful for quick tasks or when exploration isn't needed

The command automatically detects which mode to use based on available context.

## Planning Process

Use extended thinking to thoroughly evaluate:

- **Implementation Strategy**: What's the best approach and why?
- **Breaking Changes**: What needs to be considered for backward compatibility?
- **Testing Strategy**: How will this be validated and tested?
- **Documentation**: What needs to be updated or created?
- **Performance**: Are there performance implications to consider?

## Semantic Code Understanding

When designing the implementation, leverage Serena for code insights:

```bash
# Find symbols you'll need to modify or extend
find_symbol("target_class_or_function")

# Understand directory structure for changes
get_symbols_overview("src/target/module/")

# Check what might be affected by changes
# (Use exploration context or direct search)
```

This helps create more accurate implementation plans by understanding:
- Existing code structure
- Potential impact areas
- Integration points

## Deliverables

Create a concrete plan that includes:

- **Step-by-step implementation** with specific files and changes
- **Validation checkpoints** to ensure quality at each stage
- **Risk mitigation** strategies for potential issues
- **Testing approach** with specific test cases to cover
- **Documentation updates** needed for the changes

## Validation

Before saving the plan, verify it aligns with requirements:

```bash
# Use Serena's thinking tool to ensure plan follows exploration/requirements
think_about_task_adherence
```

This validates:
- Plan addresses the original requirements
- Implementation strategy aligns with exploration findings
- No critical aspects were overlooked
- Approach is consistent with project patterns

## Session Persistence

Save the plan using both methods for compatibility:

### Method 1: Serena Memory (Primary)

```bash
# Save implementation plan to Serena memory
write_memory("session_${SESSION_ID}_plan", "# Implementation Plan

## Implementation Strategy
[Your step-by-step implementation approach]

## Risks and Mitigation
[Potential challenges and how to handle them]

## Testing Strategy
[How to validate the implementation]

## Documentation Updates
[What needs to be documented]

## Validation Checkpoints
[Key milestones to verify during implementation]
")

# Update session metadata
write_memory("session_${SESSION_ID}_meta", "{
  \"sessionId\": \"${SESSION_ID}\",
  \"description\": \"[task description]\",
  \"state\": \"PLANNING_COMPLETE\",
  \"created\": \"[created timestamp]\",
  \"updated\": \"$(date -Iseconds)\",
  \"phases\": {
    \"explore\": { \"status\": \"completed\" },
    \"plan\": {
      \"status\": \"completed\",
      \"timestamp\": \"$(date -Iseconds)\",
      \"approach\": \"$2$3\"
    }
  }
}")
```

### Method 2: Legacy File System (Backup)

```bash
# Also save to legacy directory if it exists
if [ -n "$SESSION_DIR" ]; then
    echo "$PLAN_RESULTS" > "$SESSION_DIR/plan.md"
fi
```


## Implementation Guidance

When planning is complete, run:

```
/cc:code ${SESSION_ID} [focus area] [target files/components]
```

This will execute the saved plan following best practices and validation checkpoints.

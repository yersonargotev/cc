---
allowed-tools: Read, Write, Edit, Bash, Task, mcp__serena__read_memory, mcp__serena__write_memory, mcp__serena__find_symbol, mcp__serena__find_referencing_symbols, mcp__serena__get_symbols_overview, mcp__serena__insert_after_symbol, mcp__serena__insert_before_symbol, mcp__serena__replace_symbol_body, mcp__serena__think_about_whether_you_are_done, mcp__serena__think_about_task_adherence, mcp__serena__summarize_changes
argument-hint: "[session_id] [implementation focus] [target files/components]"
description: Implement solution with semantic code operations and optional plan context
---

# Code: Implementation and Execution

Implement the solution for session: **$1** with focus: **$2**$3 following the established plan and best practices.

## Session Validation & Context Loading

Load implementation context (with optional plan):

```bash
# Extract session ID
SESSION_ID="$1"

# Try to load plan context from Serena memory
PLAN_CONTEXT=$(read_memory("session_${SESSION_ID}_plan") 2>/dev/null || echo "")

# If no plan in Serena, try legacy file system
if [ -z "$PLAN_CONTEXT" ]; then
    SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)
    if [ -n "$SESSION_DIR" ] && [ -f "$SESSION_DIR/plan.md" ]; then
        PLAN_CONTEXT=$(cat "$SESSION_DIR/plan.md")
        echo "Loaded plan from legacy file system"
    fi
fi

# Also try to load exploration context for additional reference
EXPLORE_CONTEXT=$(read_memory("session_${SESSION_ID}_explore") 2>/dev/null || echo "")

# Load session metadata if available
SESSION_META=$(read_memory("session_${SESSION_ID}_meta") 2>/dev/null || echo "{}")

# STANDALONE/QUICK MODE: If no plan context, can still proceed
if [ -z "$PLAN_CONTEXT" ]; then
    echo "⚠️  No plan context found for session ${SESSION_ID}"
    echo "Running in QUICK mode - implementing directly"
    echo "Note: Having a plan (via /cc:plan) is recommended for complex tasks"

    # Load exploration context if available for guidance
    if [ -n "$EXPLORE_CONTEXT" ]; then
        echo "✓ Found exploration context - using as implementation guide"
    else
        echo "⚠️  No exploration or plan found - proceeding with minimal context"
        echo "Implementation will be based on: $2$3"
    fi
else
    echo "✓ Loaded implementation plan for session: $SESSION_ID"
    echo "Plan summary:"
    echo "$PLAN_CONTEXT" | head -10
fi
```

## Your Task

Execute implementation with available context:

1. **Load Context**: Review plan (if available) and exploration findings
2. **Use Semantic Operations**: Prefer Serena tools for code modifications
3. **Code Quality**: Write clean, maintainable code following project conventions
4. **Best Practices**: Apply established patterns and architectural guidelines
5. **Error Handling**: Implement proper error handling and validation
6. **Testing**: Add appropriate tests for the implemented functionality
7. **Validate Completion**: Check work is truly complete before finishing
8. **Summarize Changes**: Document what was implemented
9. **Save Progress**: Persist results to session memory

## Implementation Modes

This command supports flexible execution:

**Mode 1: Guided Implementation** (Recommended)
- Follows detailed plan from /cc:plan
- Has exploration context for reference
- Most comprehensive approach

**Mode 2: Quick Implementation**
- Implements directly based on description
- Uses exploration context if available
- Faster for simple changes

The command automatically adapts based on available context.

## Semantic Code Operations

Leverage Serena for precise, symbol-level code modifications:

### Finding Implementation Targets

```bash
# Find the symbol (class, function, etc.) to modify
find_symbol("target_function_or_class")

# Understand what references it (impact analysis)
find_referencing_symbols("target_symbol")

# Get overview of the module structure
get_symbols_overview("src/module/path/")
```

### Making Code Changes

```bash
# Insert code after a symbol (e.g., add method to class)
insert_after_symbol("ClassName", "
  def new_method(self):
      # implementation
      pass
")

# Insert code before a symbol (e.g., add decorator)
insert_before_symbol("function_name", "@decorator\n")

# Replace entire symbol implementation
replace_symbol_body("old_function", "
  # New implementation
  return new_value
")
```

### Traditional Editing (Fallback)

Use traditional Edit/Write tools when:
- Modifying configuration files
- Creating new files
- Working with non-code files
- Serena operations aren't suitable

## Implementation Principles

Follow these principles during implementation:
- **Semantic First**: Use Serena's symbol-level operations when possible
- **Incremental Changes**: Make small, testable increments
- **Validation**: Verify each step before proceeding
- **Code Style**: Maintain consistency with existing codebase
- **Performance**: Consider efficiency and resource usage
- **Security**: Follow security best practices

## Quality Assurance

During implementation, ensure:
- **Code Reviews**: Self-review code for potential issues
- **Test Coverage**: Add comprehensive tests for new functionality
- **Edge Cases**: Handle error conditions and unexpected inputs
- **Integration**: Ensure changes work with existing systems
- **Documentation**: Keep code comments and docs up to date

## Validation

Before completing implementation, perform quality checks:

### Task Adherence Check

```bash
# Verify you followed the plan and requirements
think_about_task_adherence
```

Validates:
- Implementation matches the plan
- Original requirements were addressed
- No scope creep or deviation

### Completion Check

```bash
# Verify work is truly complete
think_about_whether_you_are_done
```

Validates:
- All planned changes were implemented
- Tests are passing
- Documentation is updated
- No loose ends remain

### Change Summary

```bash
# Generate summary of what was modified
CHANGES_SUMMARY=$(summarize_changes)
```

Documents:
- Files modified
- Symbols changed
- Key implementation details

## Session Persistence

Save implementation results using both methods:

### Method 1: Serena Memory (Primary)

```bash
# Get change summary
CHANGES=$(summarize_changes)

# Save implementation results to Serena memory
write_memory("session_${SESSION_ID}_code", "# Implementation Results

## Summary
[Brief overview of what was implemented]

## Changes Made
$CHANGES

## Key Implementation Details
[Important technical decisions or approaches]

## Testing Results
[Test outcomes, coverage, validation]

## Documentation Updates
[What was documented]

## Notes
[Any important considerations for future work]
")

# Update session metadata
write_memory("session_${SESSION_ID}_meta", "{
  \"sessionId\": \"${SESSION_ID}\",
  \"description\": \"[task description]\",
  \"state\": \"IMPLEMENTATION_COMPLETE\",
  \"created\": \"[created timestamp]\",
  \"updated\": \"$(date -Iseconds)\",
  \"phases\": {
    \"explore\": { \"status\": \"completed\" },
    \"plan\": { \"status\": \"completed\" },
    \"code\": {
      \"status\": \"completed\",
      \"timestamp\": \"$(date -Iseconds)\",
      \"focus\": \"$2$3\"
    }
  }
}")
```

### Method 2: Legacy File System (Backup)

```bash
# Also save to legacy directory if it exists
if [ -n "$SESSION_DIR" ]; then
    echo "$IMPLEMENTATION_RESULTS" > "$SESSION_DIR/code.md"
fi
```

**IMPORTANT**: Focus on synthesis - essential outcomes only, no verbose explanations.

## Validation

Before considering implementation complete, wait for user approval:
- **Wait user approval**: Wait for user approval to continue with the implementation
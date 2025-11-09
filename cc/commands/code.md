---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: "[session_id] [implementation focus] [target files/components]"
description: Implement solution following the saved plan with session persistence
---

# Code: Implementation and Execution

Implement the solution for session: **$1** with focus: **$2**$3 following the established plan and best practices.

## Session Validation

Load existing session and plan:
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

# Validate plan exists
if [ -f "$SESSION_DIR/plan.md" ]; then
    echo "Implementation plan found"
    echo "Plan summary:"
    head -10 "$SESSION_DIR/plan.md"
else
    echo "Error: No implementation plan found for this session"
    echo "Please run /cc:plan first"
    exit 1
fi
```

## Your Task

Execute the implementation plan with attention to:
1. **Load Plan Context**: Review the detailed implementation plan
2. **Code Quality**: Write clean, maintainable code following project conventions
3. **Best Practices**: Apply established patterns and architectural guidelines
4. **Error Handling**: Implement proper error handling and validation
5. **Testing**: Add appropriate tests for the implemented functionality
6. **Documentation**: Update or create necessary documentation
7. **Save Progress**: Persist implementation details and progress to session files

## Implementation Approach

Follow these principles during implementation:
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

## Session Persistence

Save implementation progress and details:

- Save implementation results
- Create implementation results file at $SESSION_DIR/code.md
- Include: implementation summary, key changes, critical issues, validation results

**IMPORTANT**: Focus on síntesis - essential outcomes only, no verbose explanations or template content.

## Validation

Before considering implementation complete, wait for user approval:
- **Wait user approval**: Wait for user approval to continue with the implementation
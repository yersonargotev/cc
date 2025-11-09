---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: "[session_id] [implementation focus] [target files/components]"
description: Implement solution with auto-loaded session context and plan
---

# Code: Implementation and Execution

Implement solution for session: **$1** with focus: **$2**$3

## Session Validation and Context Loading

Validate session and plan exist, noting auto-loaded context:

```bash
# Extract session ID and validate
SESSION_ID="$1"
SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d | head -1)

if [ -z "$SESSION_DIR" ]; then
    echo "❌ Error: Session $SESSION_ID not found"
    echo ""
    echo "Available sessions:"
    ls -la .claude/sessions/ 2>/dev/null || echo "No sessions found"
    exit 1
fi

# Validate plan exists
if [ ! -f "$SESSION_DIR/plan.md" ]; then
    echo "❌ Error: No implementation plan found for this session"
    echo "Please run /cc:plan $SESSION_ID first"
    exit 1
fi

echo "✅ Session loaded: $SESSION_ID"
echo "📁 Directory: $SESSION_DIR"
echo ""
echo "📋 Context Available:"
echo "  - Session CLAUDE.md: Auto-loaded (key findings + plan summary)"
echo "  - Detailed plan: @$SESSION_DIR/plan.md"
echo "  - Exploration details: @$SESSION_DIR/explore.md"
echo ""

# Update session status
sed -i "s/Phase: planning/Phase: implementation/" "$SESSION_DIR/CLAUDE.md" 2>/dev/null || true
```

**Context Access**:
- Session CLAUDE.md with key findings and plan summary is auto-loaded
- Reference detailed plan.md if you need comprehensive step-by-step details
- Reference explore.md if you need original exploration findings

## Your Task

Execute the implementation plan with attention to:

1. **Review Plan**: Session CLAUDE.md contains plan summary; reference plan.md for details
2. **Code Quality**: Write clean, maintainable code following project conventions
3. **Best Practices**: Apply established patterns from exploration findings
4. **Error Handling**: Implement proper error handling and validation
5. **Testing**: Add appropriate tests as specified in plan
6. **Documentation**: Update necessary documentation
7. **Incremental Progress**: Make small, testable changes
8. **Save Progress**: Update session CLAUDE.md with implementation status

## Implementation Approach

Follow these principles:

### Incremental Development
- Make small, testable increments
- Verify each step before proceeding
- Follow the step-by-step plan from planning phase

### Quality Standards
- **Code Style**: Maintain consistency with existing codebase
- **Performance**: Consider efficiency and resource usage
- **Security**: Follow security best practices
- **Error Handling**: Handle edge cases and unexpected inputs

### Validation
- Test each component as you build it
- Verify integration with existing systems
- Check that success criteria from plan are met

## Quality Assurance

During implementation, ensure:

- ✅ **Code Review**: Self-review for potential issues
- ✅ **Test Coverage**: Add comprehensive tests per plan
- ✅ **Edge Cases**: Handle error conditions
- ✅ **Integration**: Works with existing systems
- ✅ **Documentation**: Update code comments and docs

## Session Persistence

### 1. Create code.md

Save concise implementation summary to `$SESSION_DIR/code.md`:

```markdown
# Implementation Summary: [Feature Name]

## Session Information
- Session ID: ${SESSION_ID}
- Date: $(date)
- Phase: Implementation
- Focus: $2$3

## Implementation Summary
[Brief overview of what was implemented]

## Key Changes
1. **[File/Component]**: [What changed and why]
2. **[File/Component]**: [What changed and why]
3. **[File/Component]**: [What changed and why]

## Tests Added/Updated
- [Test file]: [What it tests]
- [Test file]: [What it tests]

## Critical Issues Encountered
[Any challenges or deviations from plan]

## Validation Results
- ✅ [Success criterion 1]: Verified
- ✅ [Success criterion 2]: Verified
- ✅ [Success criterion 3]: Verified

## Documentation Updated
- [File]: [What was updated]

## Status
[Completed | Pending user approval | Needs review]
```

**IMPORTANT**: Keep concise - essential outcomes only, no verbose explanations.

### 2. Update Session CLAUDE.md

Add implementation summary to session CLAUDE.md:

```bash
cat >> "$SESSION_DIR/CLAUDE.md" << 'EOF'

## Implementation Phase Complete

### Changes Made
- [File/Component]: [Brief description]
- [File/Component]: [Brief description]

### Tests Added
- [X] unit tests
- [X] integration tests

### Status
✅ Implementation complete - awaiting user approval

### References
Implementation details: @.claude/sessions/${SESSION_ID}_${SESSION_DESC}/code.md
EOF
```

## Pre-Completion Checklist

Before requesting user approval:

- ✅ All planned changes implemented
- ✅ Tests added/updated per plan
- ✅ Code follows project conventions
- ✅ Error handling implemented
- ✅ Documentation updated
- ✅ Integration verified
- ✅ Success criteria from plan met
- ✅ code.md saved with summary
- ✅ Session CLAUDE.md updated

## User Approval

**IMPORTANT**: Wait for user approval before considering implementation complete.

Present implementation for review:

```
✅ Implementation complete for session: ${SESSION_ID}

📝 Summary:
[Brief description of what was implemented]

🔧 Changes:
- [X] files modified
- [X] tests added
- [X] components updated

✅ Validation:
- All success criteria met
- Tests passing
- Integration verified

⏸️  Awaiting user approval to finalize

Session details:
- Context: .claude/sessions/${SESSION_ID}_${SESSION_DESC}/CLAUDE.md
- Summary: .claude/sessions/${SESSION_ID}_${SESSION_DESC}/code.md
```

After user approval, suggest next steps:

```
🎉 Implementation approved!

Next steps:
1. Run `/cc:commit feat "description"` to create conventional commit
2. Push changes to remote repository
3. Create pull request for review
```

## Efficiency Notes

- **Auto-loaded context**: Session CLAUDE.md provides immediate access to plan
- **Reference on demand**: Access detailed plan.md only when needed for specifics
- **Incremental validation**: Test as you go to catch issues early
- **Token efficiency**: Concise summaries in session, detailed logs in files
- **Human-in-the-loop**: User approval ensures quality control

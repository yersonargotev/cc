---
allowed-tools: Read, Glob, Grep, Task, Bash, Write
argument-hint: "[feature/issue description] [scope/context]"
description: Explore codebase using parallel subagent analysis with CLAUDE.md memory
---

# Explore: Research and Context Gathering

Orchestrate comprehensive codebase exploration for: **$1**$2

## Session Setup

Generate unique session ID and create session directory with CLAUDE.md:

```bash
# Generate session ID
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"

# Create session structure
mkdir -p "$SESSION_DIR"

# Initialize session CLAUDE.md
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore
Started: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Key Findings
[To be populated during exploration]

## Next Steps
Run \`/cc:plan ${SESSION_ID}\` to create implementation plan

## References
@.claude/sessions/${SESSION_ID}_${SESSION_DESC}/explore.md
EOF

echo "✅ Session initialized: ${SESSION_ID}"
echo "📁 Directory: $SESSION_DIR"
```

## Parallel Exploration with Subagents

Launch specialized subagents to explore different aspects in parallel:

### 1. Code Structure Analysis
Use the Task tool to spawn a `code-structure-explorer` subagent:
```
Analyze the code structure for: $1

Focus areas:
- Relevant files and their purposes
- Key components and their locations
- Architecture patterns
- Code organization
```

### 2. Test Coverage Assessment
Use the Task tool to spawn a `test-coverage-analyzer` subagent:
```
Assess test coverage for: $1

Focus areas:
- Existing test files
- Coverage gaps
- Test quality and patterns
- Missing test scenarios
```

### 3. Dependency Analysis
Use the Task tool to spawn a `dependency-analyzer` subagent:
```
Analyze dependencies for: $1

Focus areas:
- External dependencies
- Internal module dependencies
- Integration points
- Risk assessment
```

### 4. Documentation Review
Use the Task tool to spawn a `documentation-reviewer` subagent:
```
Review documentation for: $1

Focus areas:
- Existing documentation
- Requirements extraction
- Technical specifications
- Documentation gaps
```

## Synthesis Process

After all subagents complete:

1. **Combine Findings**: Synthesize all subagent reports into cohesive analysis
2. **Identify Patterns**: Find common themes and critical insights
3. **Assess Risks**: Consolidate risk factors from all analyses
4. **Prioritize**: Determine most important findings

## Session Persistence

Save findings to session files:

### 1. Update Session CLAUDE.md

Update the session CLAUDE.md with key findings (keep < 200 lines):

```markdown
# Session: [Feature Name]

## Status
Phase: explore → plan
Completed: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Key Findings
- **Architecture**: [Critical architectural insight]
- **Components**: [Main components: file:line references]
- **Dependencies**: [Key dependencies and risks]
- **Tests**: [Coverage status and gaps]
- **Documentation**: [Documentation state]

## Critical Insights
1. [Most important discovery]
2. [Second most important]
3. [Third most important]

## Risk Factors
- **High**: [Critical risk]
- **Medium**: [Moderate concerns]
- **Low**: [Minor issues]

## Implementation Considerations
- [Key constraint or consideration]
- [Important pattern to follow]

## References
Detailed findings: @.claude/sessions/${SESSION_ID}_${SESSION_DESC}/explore.md
```

### 2. Create Detailed explore.md

Save comprehensive exploration results to `$SESSION_DIR/explore.md`:

```markdown
# Exploration Results: [Feature Name]

## Session Information
- Session ID: ${SESSION_ID}
- Date: $(date)
- Scope: $1 $2

## Requirements Analysis
[Detailed breakdown of requirements]

## Code Structure Analysis
[Complete findings from code-structure-explorer subagent]

## Test Coverage Assessment
[Complete findings from test-coverage-analyzer subagent]

## Dependency Analysis
[Complete findings from dependency-analyzer subagent]

## Documentation Review
[Complete findings from documentation-reviewer subagent]

## Comprehensive Risk Assessment
[Combined risk analysis from all subagents]

## Recommendations
[Specific recommendations for implementation]

## Questions for Planning Phase
[Any open questions or clarifications needed]
```

## Completion Checklist

Before considering exploration complete:

- ✅ Session CLAUDE.md created and populated
- ✅ All subagent analyses completed
- ✅ Findings synthesized cohesively
- ✅ Key insights identified (< 5 most important)
- ✅ Risk factors assessed and prioritized
- ✅ Detailed explore.md saved
- ✅ Implementation considerations documented

## Next Steps

When exploration is complete, inform the user:

```
✅ Exploration complete for session: ${SESSION_ID}

📊 Summary:
- [X] files analyzed
- [X] components identified
- [X] dependencies checked
- [X] tests reviewed

🎯 Key Findings:
1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

🚀 Next: Run `/cc:plan ${SESSION_ID}` to create implementation plan

Session context auto-loaded via: .claude/sessions/${SESSION_ID}_${SESSION_DESC}/CLAUDE.md
```

## Efficiency Notes

- **Parallel execution**: Subagents run simultaneously (3-5x faster)
- **Context isolation**: Each subagent has separate context window
- **Token efficiency**: Main context stays clean (8x better)
- **Auto-loading**: Session CLAUDE.md automatically loaded in future phases

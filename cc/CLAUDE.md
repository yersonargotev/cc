# CC Workflow System

## Project Overview

CC is a Claude Code plugin that implements a senior engineer workflow system with:
- Multi-phase workflow (explore → plan → code → commit)
- Session-based state management
- File-based persistence for context continuity
- Progressive refinement with human-in-the-loop validation

## Session Management

### Session Structure
```
.claude/sessions/{SESSION_ID}_{DESCRIPTION}/
├── CLAUDE.md          # Active session context (auto-loaded)
├── explore.md         # Detailed exploration results
├── plan.md            # Implementation plan
└── code.md            # Implementation summary
```

### Session ID Format
- Pattern: `YYYYMMDD_HHMMSS_randomhex_description`
- Example: `20251109_143045_abc123de_auth_refactor`
- Generation: `$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)`

## Workflow Phases

### 1. Explore (`/cc:explore`)
**Purpose**: Research and context gathering
**Tools**: Read, Glob, Grep, Task, Bash, Write
**Output**: Session CLAUDE.md + explore.md with detailed findings
**Pattern**: Use subagents for parallel exploration

### 2. Plan (`/cc:plan`)
**Purpose**: Strategic planning and design
**Tools**: Read, Write, Task, Bash, ExitPlanMode
**Input**: Auto-loaded session CLAUDE.md
**Output**: plan.md with implementation strategy

### 3. Code (`/cc:code`)
**Purpose**: Implementation following the plan
**Tools**: Read, Write, Edit, Bash, Task
**Input**: Auto-loaded session CLAUDE.md + plan.md
**Output**: code.md + implemented changes
**Validation**: Requires user approval before completion

### 4. Commit (`/cc:commit`)
**Purpose**: Version control with conventional commits
**Tools**: Bash, Read, Edit
**Format**: `<type>[scope]: <description>`

## Memory Guidelines

### Session CLAUDE.md Format
Keep concise and focused on current work:
```markdown
# Session: [Feature/Issue Name]

## Status
Phase: [explore|plan|code|commit]
Started: YYYY-MM-DD HH:MM

## Key Findings
- Critical discovery 1
- Critical discovery 2
- Critical discovery 3

## Current Focus
[What we're working on right now]

## References
@.claude/sessions/{session}/explore.md
@.claude/sessions/{session}/plan.md
```

### Best Practices
- Keep session CLAUDE.md < 200 lines
- Use `@file/path.md` for detailed references
- Update session context as phases progress
- Store verbose details in phase-specific files

## Code Conventions

### Commit Types
- `feat`: New feature or functionality
- `fix`: Bug fix or error correction
- `docs`: Documentation changes
- `refactor`: Code refactoring without functional changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### File Organization
- Commands: `.claude/commands/`
- Subagents: `.claude/agents/`
- Hooks: `.claude/hooks/`
- Sessions: `.claude/sessions/`

## Subagent Usage

### When to Use Subagents
- Complex exploration (parallel investigation)
- Isolated analysis (avoid context pollution)
- Read-heavy operations (preserve main context)

### Available Subagents
- `code-structure-explorer`: Analyze code architecture
- `test-coverage-analyzer`: Assess test coverage
- `dependency-analyzer`: Check dependencies
- `documentation-reviewer`: Review docs

## Hooks

### PreToolUse
- Session validation before plan/code phases
- Input modification for safety

### Stop
- Auto-save session state
- Update timestamps

### UserPromptSubmit
- Load git status for context
- Display session info if active

## Tips

- Always start with exploration phase
- Use subagents for parallel investigation
- Keep main context clean and focused
- Reference detailed docs rather than duplicating
- Update session CLAUDE.md as work progresses

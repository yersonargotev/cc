# CC Workflow System

## Project Overview

CC is a Claude Code plugin that implements a senior engineer workflow system with:
- Multi-phase workflow (explore → plan → code → commit)
- Session-based state management
- File-based persistence for context continuity
- Progressive refinement with human-in-the-loop validation

## Session Management

### Session Structure (v2.0 - Hybrid Exploration)
```
.claude/sessions/{SESSION_ID}_{DESCRIPTION}/
├── CLAUDE.md          # Active session context (auto-loaded)
├── explore.md         # Complete exploration report
├── code-search.md     # Code analysis results
├── web-research.md    # Web research findings
├── synthesis.md       # Integrated insights
├── plan.md            # Implementation plan
└── code.md            # Implementation summary
```

### Session ID Format
- Pattern: `YYYYMMDD_HHMMSS_randomhex_description`
- Example: `20251109_143045_abc123de_auth_refactor`
- Generation: `$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)`

## Workflow Phases

### 1. Explore (`/explore`)
**Purpose**: Hybrid research combining code analysis + web research
**Tools**: Read, Glob, Grep, Task, Bash, Write, WebSearch, WebFetch
**Subagents**: code-search-agent, web-research-agent, context-synthesis-agent
**Output**: Session CLAUDE.md + explore.md + detailed research reports
**Pattern**: Parallel code + web research, then synthesis (3 specialized agents)

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
- Web research (current best practices)
- Synthesis and integration of findings

### Available Subagents (v2.0 - Hybrid Architecture)

#### Exploration Agents
- `code-search-agent` (Haiku): Comprehensive code search combining semantic + structural analysis
  - Analyzes architecture, tests, dependencies, documentation
  - Supports semantic search via Claude Context MCP (optional)
  - Consolidates: code structure, test coverage, dependencies, docs

- `web-research-agent` (Haiku): Web research for current best practices
  - Searches for industry standards and patterns (2024-2025)
  - Finds official documentation and security advisories
  - Discovers similar solutions and implementations
  - Uses native WebSearch + optional Brave/DuckDuckGo MCP

- `context-synthesis-agent` (Sonnet): Integrates code + web findings
  - Combines local codebase state with industry best practices
  - Performs gap analysis (current vs recommended)
  - Generates prioritized, actionable recommendations
  - Creates comprehensive synthesis with risk assessment

#### Legacy Agents (Deprecated - v1.0)
- `code-structure-explorer`: Use `code-search-agent` instead
- `test-coverage-analyzer`: Use `code-search-agent` instead
- `dependency-analyzer`: Use `code-search-agent` instead
- `documentation-reviewer`: Use `code-search-agent` instead

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

## MCP Integration (Optional)

The `/explore` command works out-of-the-box with native tools but can be enhanced with MCP servers:

### Recommended MCP Servers

1. **Brave Search MCP** (Enhanced web research)
   - Privacy-focused web search
   - 2,000 queries/month free
   - Config: `cc/mcp-examples/brave-search.json`

2. **Claude Context MCP** (Semantic code search)
   - Hybrid search: BM25 + vector embeddings
   - ~40% token reduction
   - Supports: TypeScript, Python, Java, Go, Rust, etc.
   - Config: `cc/mcp-examples/claude-context.json`

See `cc/mcp-examples/README.md` for setup instructions.

**Note**: MCP is optional. System gracefully degrades to native tools if MCP not configured.

## Exploration Workflow (v2.0)

The new `/explore` command uses a **hybrid architecture**:

1. **Parallel Phase** (simultaneous):
   - Code Search Agent → analyzes local codebase
   - Web Research Agent → researches best practices online

2. **Sequential Phase** (after both complete):
   - Context Synthesis Agent → integrates findings into actionable insights

**Benefits**:
- Complete context: Code + industry best practices
- Current information: 2024-2025 standards
- Better decisions: Grounded in code reality + modern patterns
- Faster: Parallel execution (2x speedup)

## Tips

- Always start with exploration phase (`/explore`)
- Let hybrid exploration discover both code state AND best practices
- Use MCP for enhanced capabilities (optional)
- Keep main context clean and focused
- Reference detailed docs rather than duplicating
- Update session CLAUDE.md as work progresses
- Review synthesis.md for integrated insights before planning

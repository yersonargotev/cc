# CC Workflow System

## Project Overview

CC is a Claude Code plugin that implements a senior engineer workflow system with:
- Streamlined workflow (explore with integrated planning → code → commit)
- Session-based state management
- File-based persistence for context continuity
- Progressive refinement with human-in-the-loop validation
- Automatic implementation planning during exploration (HYBRID mode)

## Session Management

### Session Structure (v3.0 - Integrated Planning)
```
.claude/sessions/{SESSION_ID}_{DESCRIPTION}/
├── CLAUDE.md          # Active session context (auto-loaded)
├── explore.md         # Complete exploration report
├── code-search.md     # Code analysis results (HYBRID mode)
├── web-research.md    # Web research findings (HYBRID mode)
├── plan.md            # Implementation plan (auto-generated in HYBRID mode)
└── code.md            # Implementation summary
```

**Note**: `synthesis.md` has been replaced by `plan.md` in v3.0. The planning-agent now generates implementation plans directly instead of synthesis documents.

### Session ID Format
- Pattern: `YYYYMMDD_HHMMSS_randomhex_description`
- Example: `20251109_143045_abc123de_auth_refactor`
- Generation: `$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)`

## Workflow Phases

### 1. Explore (`/explore`)
**Purpose**: Hybrid research combining code analysis + web research + implementation planning
**Tools**: Read, Glob, Grep, Task, Bash, Write, WebSearch, WebFetch
**Subagents**: code-search-agent, web-research-agent, planning-agent
**Output**: Session CLAUDE.md + explore.md + plan.md (HYBRID mode)
**Pattern**: Parallel code + web research, then planning (3 specialized agents)

### 2. Code (`/cc:code`)
**Purpose**: Implementation following the auto-generated plan
**Tools**: Read, Write, Edit, Bash, Task
**Input**: Auto-loaded session CLAUDE.md + plan.md
**Output**: code.md + implemented changes
**Validation**: Requires user approval before completion

### 3. Commit (`/cc:commit`)
**Purpose**: Version control with conventional commits
**Tools**: Bash, Read, Edit
**Format**: `<type>[scope]: <description>`

---

### Deprecated: Plan (`/cc:plan`) ⚠️
**Status**: DEPRECATED in v3.0 - Planning now integrated into `/explore`
**Old workflow**: `/explore` → `/plan` → `/code`
**New workflow**: `/explore` (HYBRID) → `/code`
**Migration**: Use `/explore` in HYBRID mode to automatically generate implementation plans

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

### Available Subagents (v3.0 - Integrated Planning)

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

- `planning-agent` (Sonnet): Creates implementation plans from code + web findings
  - Combines local codebase state with industry best practices
  - Performs gap analysis (current vs recommended)
  - Generates detailed implementation plan with step-by-step strategy
  - Includes risk mitigation, testing strategy, and success criteria
  - **Replaces**: `context-synthesis-agent` (deprecated in v3.0)

#### Legacy Agents (v1.0 → v2.0 Migration Complete)
- ✅ **Migration Completed**: v1.0 specialized agents have been consolidated into v2.0 unified agents
- ✅ **Enhanced Capabilities**: `code-search-agent` combines all 4 legacy functions with improved analysis
- ✅ **Documentation Updated**: All references updated to reflect modern architecture
- ✅ **Legacy Files Archived**: Historical agents preserved in `cc/agents/legacy/` for reference

**Previous v1.0 Agents → v2.0 Equivalents:**
- `code-structure-explorer` → **`code-search-agent`** (comprehensive code analysis)
- `test-coverage-analyzer` → **`code-search-agent`** (test coverage analysis included)
- `dependency-analyzer` → **`code-search-agent`** (dependency analysis included)
- `documentation-reviewer` → **`code-search-agent`** (documentation analysis included)

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

## Exploration Workflow (v3.0)

The `/explore` command uses a **hybrid architecture with integrated planning**:

1. **Parallel Phase** (simultaneous):
   - Code Search Agent → analyzes local codebase
   - Web Research Agent → researches best practices online

2. **Sequential Phase** (after both complete):
   - Planning Agent → generates implementation plan directly

**Benefits**:
- Complete context: Code + industry best practices
- Current information: 2024-2025 standards
- Better decisions: Grounded in code reality + modern patterns
- Faster workflow: Plan generated automatically (no separate `/plan` step)
- Parallel execution: 2x speedup in research phase

## Tips

- Always start with exploration phase (`/explore`)
- Let hybrid exploration discover both code state AND best practices
- Use HYBRID mode for automatic plan generation (include keywords like "improve", "migrate", "refactor")
- Use MCP for enhanced capabilities (optional)
- Keep main context clean and focused
- Reference detailed docs rather than duplicating
- Update session CLAUDE.md as work progresses
- Review plan.md for implementation strategy before coding

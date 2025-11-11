# CC Workflow System

## Project Overview

CC is a Claude Code plugin that implements a senior engineer workflow system with:
- Multi-phase workflow (explore → plan → code → commit)
- Session-based state management
- File-based persistence for context continuity
- Progressive refinement with human-in-the-loop validation

## Session Management

### Session Structure (v2.1 - Streamlined Workflow)
```
.claude/sessions/{SESSION_ID}_{DESCRIPTION}/
├── CLAUDE.md          # Active session context (auto-loaded)
├── code-search.md     # Code analysis results (detailed)
├── web-research.md    # Web research findings (detailed)
├── plan.md            # Implementation plan (includes integrated synthesis)
└── code.md            # Implementation summary
```

### Session ID Format
- Pattern: `YYYYMMDD_HHMMSS_randomhex_description`
- Example: `20251109_143045_abc123de_auth_refactor`
- Generation: `$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)`

## Workflow Phases

### 1. Plan (`/plan`)
**Purpose**: Research (code + web in parallel) then create implementation plan in one step
**Tools**: Task, Bash, Read, Write
**Subagents**: code-search-agent (Haiku), web-research-agent (Haiku)
**Model**: Sonnet (for plan generation with integrated synthesis)
**Output**:
- Session CLAUDE.md (key insights)
- plan.md (includes Context Analysis with integrated synthesis)
- code-search.md (detailed code analysis)
- web-research.md (detailed web research)
**Pattern**:
1. Parallel research (code-search + web-research agents)
2. Direct plan generation with synthesis integrated in "Context Analysis" section

### 2. Code (`/code`)
**Purpose**: Implementation following the plan
**Tools**: Read, Write, Edit, Bash, Task
**Input**: Auto-loaded session CLAUDE.md + plan.md
**Output**: code.md + implemented changes
**Validation**: Requires user approval before completion

### 3. Commit (`/commit`)
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
@.claude/sessions/{session}/plan.md (includes integrated analysis)
@.claude/sessions/{session}/code-search.md (detailed code analysis)
@.claude/sessions/{session}/web-research.md (detailed web research)
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

### Available Subagents (v2.1 - Streamlined Architecture)

#### Research Agents (Used by /plan)
- `code-search-agent` (Haiku): Comprehensive code search combining semantic + structural analysis
  - Analyzes architecture, tests, dependencies, documentation
  - Supports semantic search via Claude Context MCP (optional)
  - Consolidates: code structure, test coverage, dependencies, docs
  - Output: Detailed code-search.md for reference

- `web-research-agent` (Haiku): External search for topic-related information
  - Searches for documentation, concepts, examples (2024-2025 content)
  - Finds official docs, API references, implementations
  - Discovers related technologies and ecosystem context
  - Uses native WebSearch + optional Brave/DuckDuckGo MCP
  - Output: Detailed web-research.md for reference

**Note**: Synthesis is now integrated directly in plan.md (Context Analysis section) using Sonnet with extended thinking, eliminating the need for a separate synthesis agent/file.

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

## Planning Workflow (v2.1 - Optimized)

The `/plan` command uses an **integrated research + planning architecture**:

1. **Parallel Research Phase** (simultaneous):
   - Code Search Agent → analyzes local codebase → code-search.md
   - Web Research Agent → researches information → web-research.md

2. **Direct Plan Generation** (after both complete):
   - Sonnet with extended thinking → plan.md (includes Context Analysis with integrated synthesis)

**Benefits**:
- ✅ Fewer steps: 2 commands instead of 3 (plan → code vs explore → plan → code)
- ✅ Same quality: Parallel research preserved, synthesis integrated
- ✅ Faster workflow: 33% reduction in user commands
- ✅ Cleaner structure: 4 files instead of 6 per session
- ✅ More intuitive: "plan" naturally implies research + strategy

## Tips

- Always start with planning phase (`/plan`)
- Parallel research discovers both code state AND available information
- Use MCP for enhanced capabilities (optional)
- Keep main context clean and focused
- Reference detailed docs rather than duplicating
- Update session CLAUDE.md as work progresses
- Review plan.md Context Analysis section for integrated insights

---
allowed-tools: Read, Glob, Grep, Task, Bash, Write, mcp__serena__find_symbol, mcp__serena__find_referencing_symbols, mcp__serena__find_referencing_code_snippets, mcp__serena__get_symbols_overview, mcp__serena__search_for_pattern, mcp__serena__write_memory, mcp__serena__read_memory, mcp__serena__list_memories, mcp__serena__check_onboarding_performed, mcp__serena__get_active_project, mcp__serena__think_about_collected_information
argument-hint: "[feature/issue description] [scope/context]"
description: Explore codebase and understand requirements with session persistence and semantic analysis
---

# Explore: Research and Context Gathering

Analyze the requirements and explore the codebase to understand the current state, architecture, and context for: **$1**$2

## Session Setup

Generate a unique session ID and prepare for exploration:

```bash
# Generate session ID
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)

# Legacy session directory (for backward compatibility)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

echo "Session ID: ${SESSION_ID}"
echo "Session Description: $SESSION_DESC"

# Check if project has been onboarded to Serena
check_onboarding_performed
```

## Your Task

1. **Understand Requirements**: Break down what needs to be accomplished
2. **Explore Codebase**: Find relevant files, patterns, and architecture
3. **Identify Dependencies**: Understand related components and systems
4. **Document Current State**: Assess the existing implementation
5. **Gather Context**: Collect all information needed for planning
6. **Save Session**: Persist all findings to session files

## Context Gathering

### Step 1: Load Project Knowledge

If the project has been onboarded, start by loading existing knowledge:

```bash
# Read project onboarding memory (if available)
read_memory("onboarding")
```

This provides context about:
- Project architecture patterns
- Testing methodologies
- Build systems and conventions
- Coding standards

### Step 2: Semantic Code Exploration

Use Serena's semantic tools for precise code discovery:

```bash
# Find relevant symbols (classes, functions, etc.)
find_symbol("relevant_name")

# Get overview of relevant directories
get_symbols_overview("target/directory/")

# Find what references a particular symbol
find_referencing_symbols("symbol_name")

# Pattern-based search when needed
search_for_pattern("regex_pattern")
```

**Prefer semantic search over text search** when exploring code structures.

### Step 3: Traditional Exploration (Fallback)

Use traditional tools when Serena isn't suitable:
- Configuration files (YAML, JSON, etc.)
- Documentation (README, guides)
- Non-code files
- Quick pattern matching with Grep

## Your Tools Are Your Instruments

Like a virtuoso musician, you have a sophisticated toolkit at your disposal. Each tool serves a specific purpose in your exploration symphony:

### MCP Server Capabilities

Leverage the available MCP servers as specialized instruments:

**Remember**: The most effective explorers use each tool for its strengths, combining them in sequences that reveal deeper insights than any single tool could provide.

## Analysis Focus

Provide a comprehensive analysis covering:

- **Architecture**: How does this fit into the current system?
- **Code Patterns**: What conventions should be followed?
- **Dependencies**: What other components are affected?
- **Risks**: What are the potential challenges?
- **Assumptions**: What are you assuming about the requirements?

## Validation

Before completing exploration, validate completeness:

```bash
# Use Serena's thinking tool to verify you've gathered enough information
think_about_collected_information
```

This helps ensure:
- All relevant code has been discovered
- Dependencies are understood
- Architecture is clear
- Nothing critical was missed

## Session Persistence

Save your findings using both methods for compatibility:

### Method 1: Serena Memory (Primary)

```bash
# Save exploration results to Serena memory
write_memory("session_${SESSION_ID}_explore", "# Exploration Results

## Requirements Analysis
[Your analysis of what needs to be accomplished]

## Codebase Findings
[Relevant files, patterns, architecture discovered]

## Dependencies
[Related components and systems identified]

## Current State Assessment
[Existing implementation analysis]

## Context for Planning
[Key insights and considerations for next phase]
")

# Save session metadata
write_memory("session_${SESSION_ID}_meta", "{
  \"sessionId\": \"${SESSION_ID}\",
  \"description\": \"${SESSION_DESC}\",
  \"state\": \"EXPLORING_COMPLETE\",
  \"created\": \"$(date -Iseconds)\",
  \"phases\": {
    \"explore\": {
      \"status\": \"completed\",
      \"timestamp\": \"$(date -Iseconds)\"
    }
  }
}")
```

### Method 2: Legacy File System (Backup)

```bash
# Also save to file system for backward compatibility
echo "$EXPLORATION_RESULTS" > "$SESSION_DIR/explore.md"
```

**Benefits of Serena Memory**:
- Persistent across conversations
- Easily retrievable with read_memory
- Searchable with list_memories
- Can be shared across projects

## Next Steps

When exploration is complete, run:

```
/cc:plan ${SESSION_ID} [implementation approach] [key constraints]
```

This will use your saved exploration results to create a detailed implementation plan in the same session directory.

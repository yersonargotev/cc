---
allowed-tools: Read, Glob, Grep, Task, Bash, Write
argument-hint: "[feature/issue description] [scope/context]"
description: Explore codebase and understand requirements with session persistence
---

# Explore: Research and Context Gathering

Analyze the requirements and explore the codebase to understand the current state, architecture, and context for: **$1**$2

## Session Setup

Generate a unique session ID and create session directory:

```bash
# Generate session ID and create directory
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(head -c 8 /dev/urandom | od -A n -t x | tr -d ' \n')
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"
echo "Session ID: ${SESSION_ID}"
echo "Session Directory: $SESSION_DIR"
```

## Your Task

1. **Understand Requirements**: Break down what needs to be accomplished
2. **Explore Codebase**: Find relevant files, patterns, and architecture
3. **Identify Dependencies**: Understand related components and systems
4. **Document Current State**: Assess the existing implementation
5. **Gather Context**: Collect all information needed for planning
6. **Save Session**: Persist all findings to session files

## Context Gathering

Start by exploring the codebase structure and finding relevant files:

- What files handle similar functionality?
- What are the current patterns and conventions?
- Are there existing tests or documentation?
- What dependencies or integrations exist?

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

## Session Persistence

Save all your findings to ensure continuity:

- Create exploration results file at $SESSION_DIR/explore.md
- Include: requirements analysis, codebase findings, dependencies,
- current state assessment, and context for planning

The session directory and file structure provide persistent storage for all exploration results and easy reference for subsequent phases.

## Next Steps

When exploration is complete, run:

```
/cc:plan ${SESSION_ID} [implementation approach] [key constraints]
```

This will use your saved exploration results to create a detailed implementation plan in the same session directory.

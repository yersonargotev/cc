# Claude Code Architecture: Complete Reference

> *"The best way to predict the future is to invent it."* — Alan Kay

This document synthesizes the complete architecture of Claude Code based on official documentation and community best practices.

---

## Table of Contents

1. [Overview](#overview)
2. [Core Components](#core-components)
3. [Plugins System](#plugins-system)
4. [Slash Commands](#slash-commands)
5. [Lifecycle Hooks](#lifecycle-hooks)
6. [Subagents & Task Tool](#subagents--task-tool)
7. [Agent Skills](#agent-skills)
8. [Model Context Protocol (MCP)](#model-context-protocol-mcp)
9. [Session Management](#session-management)
10. [Architecture Diagram](#architecture-diagram)
11. [Best Practices](#best-practices)

---

## Overview

Claude Code is an AI-powered development assistant that provides:
- **Autonomous coding** through specialized subagents
- **Extensibility** via plugins, skills, commands, and hooks
- **Tool integration** through Model Context Protocol (MCP)
- **Context management** with intelligent session handling

### Key Philosophy

Claude Code follows a **modular, composable architecture** where:
- **Plugins** = Distribution mechanism (bundles everything)
- **Commands** = User-triggered workflows
- **Hooks** = Lifecycle automation
- **Subagents** = Specialized task execution
- **Skills** = Model-invoked expertise
- **MCP** = External tool integration

---

## Core Components

### Component Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                         PLUGIN                              │
│  (Distribution Container - Bundles Everything)              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  Commands   │  │   Hooks     │  │   Skills    │       │
│  │  (User)     │  │  (Auto)     │  │  (Model)    │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
│         │                │                 │               │
│         └────────────────┴─────────────────┘               │
│                          │                                  │
│                  ┌───────▼───────┐                         │
│                  │   Subagents   │                         │
│                  │  (Task Tool)  │                         │
│                  └───────────────┘                         │
│                          │                                  │
│                  ┌───────▼───────┐                         │
│                  │  MCP Servers  │                         │
│                  │  (External)   │                         │
│                  └───────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### Component Comparison

| Component | Activation | Scope | Context | Use Case |
|-----------|-----------|-------|---------|----------|
| **Commands** | User triggers (`/cmd`) | Project or User | Main agent | Frequent workflows |
| **Hooks** | Lifecycle event | Project or User | Main agent | Automation, validation |
| **Skills** | Model decides | All Claude apps | Isolated read | Domain expertise |
| **Subagents** | Main agent delegates | Task-specific | Isolated window | Complex research |
| **MCP** | Tool call | External services | API integration | Database, APIs, tools |
| **Plugins** | Installation | Bundle of above | N/A | Distribution |

---

## Plugins System

### What Are Plugins?

**Plugins** are custom collections of slash commands, agents, MCP servers, hooks, and skills that install with a single command.

> *Think of plugins as npm packages for Claude Code.*

### Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/                # Slash commands
│   ├── review.md
│   └── test.md
├── hooks/                   # Lifecycle hooks
│   ├── pre-tool-use/
│   │   └── validate.sh
│   └── stop/
│       └── cleanup.sh
├── skills/                  # Agent skills
│   └── my-skill/
│       ├── SKILL.md
│       └── resources/
├── subagents/              # Custom subagents
│   └── reviewer.md
└── README.md
```

### Plugin Manifest (`plugin.json`)

```json
{
  "$schema": "https://anthropic.com/claude-code/plugin.schema.json",
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Description of what the plugin does",
  "author": {
    "name": "Your Name",
    "email": "[email protected]"
  },
  "category": "development",
  "keywords": ["testing", "review"],
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/user/my-plugin"
  }
}
```

### Plugin Marketplace

A marketplace is a JSON file listing available plugins:

**`.claude-plugin/marketplace.json`**
```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "my-marketplace",
  "version": "1.0.0",
  "description": "Collection of development plugins",
  "owner": {
    "name": "Marketplace Owner",
    "email": "[email protected]"
  },
  "plugins": [
    {
      "name": "formatter",
      "description": "Code formatting utilities",
      "source": "./plugins/formatter",
      "category": "development",
      "version": "1.0.0"
    },
    {
      "name": "security-scanner",
      "description": "Security vulnerability detection",
      "source": {
        "type": "github",
        "repo": "user/security-scanner"
      },
      "category": "security",
      "version": "2.1.0"
    }
  ]
}
```

### Installing Plugins

```bash
# Add a marketplace
/plugin marketplace add user-or-org/repo-name

# Browse available plugins
/plugin

# Install a plugin
/plugin install plugin-name

# List installed plugins
/plugin list

# Remove a plugin
/plugin remove plugin-name
```

### Plugin Locations

- **Project plugins**: `.claude/plugins/`
- **User plugins**: `~/.claude/plugins/`
- **Marketplace URLs**: GitHub, GitLab, or any git repository

---

## Slash Commands

### What Are Slash Commands?

**Slash commands** are user-triggered workflows defined as Markdown files that contain prompts and instructions for Claude.

### Creating Commands

#### Basic Command

**File**: `.claude/commands/optimize.md`
```markdown
Analyze this code for performance issues and suggest optimizations:
- Identify O(n²) or worse complexity
- Look for unnecessary loops or iterations
- Suggest caching opportunities
- Recommend algorithmic improvements

Please be specific and show code examples.
```

**Usage**: `/optimize`

#### Command with Arguments

**File**: `.claude/commands/create-feature.md`
```markdown
Create a new feature: $1

Requirements:
- Follow the project's architecture patterns
- Add unit tests
- Update documentation
- Include error handling

Feature name: $1
Additional requirements: $ARGUMENTS
```

**Usage**:
```bash
/create-feature "User authentication" include OAuth support
```

**Variables**:
- `$1`, `$2`, `$3`, etc. = Positional arguments
- `$ARGUMENTS` = All arguments as a single string

#### Command with Bash Execution

**File**: `.claude/commands/analyze-deps.md`
```bash
#!/bin/bash

# Analyze project dependencies
echo "## Dependency Analysis"
echo ""
echo "### Package.json Dependencies"
jq '.dependencies' package.json

echo ""
echo "### Outdated Packages"
npm outdated

echo ""
echo "Please review these dependencies and suggest:
1. Security vulnerabilities
2. Outdated packages that should be updated
3. Unused dependencies that can be removed"
```

### Command Namespacing

Organize commands using directories:

```
.claude/commands/
├── git/
│   ├── commit.md
│   ├── pr.md
│   └── sync.md
├── test/
│   ├── unit.md
│   ├── integration.md
│   └── e2e.md
└── optimize.md
```

**Usage**:
```bash
/git:commit
/git:pr
/test:unit
/optimize
```

### Command Locations

1. **Project commands**: `.claude/commands/` (version controlled, shared with team)
2. **User commands**: `~/.claude/commands/` (personal shortcuts)

**Priority**: Project commands override user commands with the same name.

---

## Lifecycle Hooks

### What Are Hooks?

**Hooks** are shell scripts that execute automatically at specific points in Claude Code's lifecycle, providing deterministic control over behavior.

### Available Hook Events

| Hook | When It Runs | Can Block? | Stdout Visible? |
|------|--------------|------------|-----------------|
| `PreToolUse` | Before any tool execution | ✅ Yes | ✅ Yes (feedback to Claude) |
| `PostToolUse` | After tool completes | ❌ No | ✅ Yes |
| `UserPromptSubmit` | When user submits prompt | ❌ No | ✅ Yes (injected as context) |
| `Notification` | When notification sent | ❌ No | ❌ No |
| `Stop` | When Claude finishes responding | ❌ No | ❌ No |
| `SubagentStop` | When subagent task completes | ❌ No | ✅ Yes |
| `PreCompact` | Before context compaction | ✅ Yes | ✅ Yes |
| `SessionStart` | Session starts/resumes | ❌ No | ✅ Yes (injected) |
| `SessionEnd` | Session ends | ❌ No | ❌ No |

### Hook Configuration

**File**: `.claude/settings.json`
```json
{
  "hooks": {
    "PreToolUse": [
      ".claude/hooks/pre-tool-use/validate-session.sh",
      ".claude/hooks/pre-tool-use/security-check.sh"
    ],
    "UserPromptSubmit": [
      ".claude/hooks/user-prompt-submit/load-context.sh"
    ],
    "Stop": [
      ".claude/hooks/stop/auto-save-session.sh",
      ".claude/hooks/stop/git-check.sh"
    ],
    "SessionStart": [
      ".claude/hooks/session-start/load-env.sh"
    ]
  }
}
```

### Hook Examples

#### PreToolUse: Validation Hook

**File**: `.claude/hooks/pre-tool-use/validate-session.sh`
```bash
#!/bin/bash

# Validate session exists before planning/coding
COMMAND="$1"  # Full tool command

if echo "$COMMAND" | grep -q "/cc:plan\|/cc:code"; then
  SESSION_REF=$(echo "$COMMAND" | awk '{print $2}')

  if [ -z "$SESSION_REF" ]; then
    echo "❌ Error: Session reference required"
    echo "Usage: /cc:plan <session-id>"
    exit 1  # Non-zero exit blocks the tool call
  fi

  # Validate session exists
  if [ ! -d ".claude/sessions/${SESSION_REF}"* ]; then
    echo "❌ Session not found: $SESSION_REF"
    echo ""
    echo "Available sessions:"
    ls -1 .claude/sessions/ | head -5
    exit 1
  fi
fi

exit 0  # Allow tool execution
```

#### UserPromptSubmit: Context Injection

**File**: `.claude/hooks/user-prompt-submit/load-context.sh`
```bash
#!/bin/bash

# Inject session context into every prompt
USER_PROMPT="$1"

# Find active session
LATEST_SESSION=$(find .claude/sessions -maxdepth 1 -type d -name "20*" | sort -r | head -1)

if [ -n "$LATEST_SESSION" ]; then
  SESSION_NAME=$(basename "$LATEST_SESSION")
  SESSION_ID=$(echo "$SESSION_NAME" | cut -d'_' -f1,2,3)

  # Output is injected as context to Claude
  echo "📁 Active Session: $SESSION_ID"
  echo "   Phase: explore → plan → implementation"
  echo "   Context: Auto-loaded from $LATEST_SESSION/CLAUDE.md"
fi
```

#### Stop: Auto-save Hook

**File**: `.claude/hooks/stop/auto-save-session.sh`
```bash
#!/bin/bash

# Update session metadata after each response
LATEST_SESSION=$(find .claude/sessions -maxdepth 1 -type d -name "20*" | sort -r | head -1)

if [ -n "$LATEST_SESSION" ]; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Update CLAUDE.md
  sed -i "s/Last Updated:.*/Last Updated: $TIMESTAMP/" "$LATEST_SESSION/CLAUDE.md"

  # Log activity
  echo "[$(date)] Session updated" >> "$LATEST_SESSION/activity.log"
fi
```

### Hook Best Practices

1. **Keep hooks fast** (< 100ms) to avoid slowing down workflow
2. **Use PreToolUse for validation** (can block execution)
3. **Use UserPromptSubmit for context injection** (stdout becomes context)
4. **Use Stop for cleanup/persistence** (runs after each response)
5. **Exit codes matter**: Non-zero exits block PreToolUse/PreCompact
6. **Test hooks in isolation** before deploying

---

## Subagents & Task Tool

### What Are Subagents?

**Subagents** are specialized, autonomous AI assistants that:
- Have their own isolated context window
- Execute specific, well-defined tasks
- Can run in parallel (max 10 concurrent)
- Provide summaries back to the main agent
- **Cannot spawn other subagents** (prevents infinite nesting)

### Built-in Subagents

Claude Code has several built-in subagents:

| Subagent | Purpose | Tools | When Used |
|----------|---------|-------|-----------|
| `Explore` | Codebase exploration | Read, Grep, Glob, WebFetch | Understanding code structure |
| `Plan` | Research for planning | Read, Grep, Glob, WebSearch | Gathering info for plans |
| `general-purpose` | Multi-step tasks | All tools | Complex operations |

### Using the Task Tool

```markdown
I need you to use the Task tool to research these three topics in parallel:

1. How authentication works in this codebase
2. Where API endpoints are defined
3. What testing frameworks we use

For each, provide a summary of your findings.
```

Claude will launch 3 subagents in parallel, each with isolated context.

### Creating Custom Subagents

**File**: `.claude/subagents/security-reviewer.md`
```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities
tools: ["Read", "Grep", "Glob"]
---

# Security Review Agent

You are a security-focused code reviewer. Your task is to:

1. Analyze code for common vulnerabilities:
   - SQL injection
   - XSS (Cross-site scripting)
   - CSRF (Cross-site request forgery)
   - Authentication/authorization issues
   - Secrets in code
   - Insecure dependencies

2. Check against OWASP Top 10

3. Provide specific, actionable recommendations

## Output Format

For each file reviewed:
- **File**: path/to/file
- **Severity**: Critical | High | Medium | Low
- **Issue**: Description
- **Recommendation**: How to fix
- **Example**: Code snippet (if applicable)

## Final Summary

Provide an executive summary with:
- Total issues found by severity
- Top 3 priorities
- Overall security posture assessment
```

### Subagent Best Practices

1. **Use subagents for research** to preserve main context
2. **Run parallel subagents** for independent tasks (max 10)
3. **Provide clear objectives** in the task description
4. **Request summaries** to save main context window
5. **Avoid overuse** - subagents add latency
6. **Use early in conversation** before main context fills up

### When to Use Subagents

✅ **Use subagents for:**
- Large codebase exploration
- Parallel independent research
- Focused specialized analysis
- Early-conversation investigation

❌ **Don't use subagents for:**
- Simple file reads (use Read tool directly)
- Sequential dependent tasks
- When main context is nearly full
- Quick one-off questions

---

## Agent Skills

### What Are Skills?

**Agent Skills** are model-invoked capabilities that:
- Claude decides when to use (based on description)
- Work across all Claude platforms (web, API, CLI)
- Package domain expertise and workflows
- Include instructions, scripts, and resources

> *"Skills are like custom onboarding materials for Claude."*

### Skill vs Command vs Subagent

| Feature | Command | Skill | Subagent |
|---------|---------|-------|----------|
| **Activation** | User types `/cmd` | Claude decides | Main agent delegates |
| **Platform** | Claude Code only | All Claude apps | Claude Code only |
| **Context** | Main agent | Isolated read | Isolated window |
| **Use Case** | Frequent workflows | Domain expertise | Complex research |

### Creating a Skill

**Directory structure**:
```
~/.claude/skills/python-best-practices/
├── SKILL.md
├── resources/
│   ├── style-guide.md
│   ├── common-patterns.py
│   └── anti-patterns.py
└── scripts/
    └── lint.sh
```

**File**: `~/.claude/skills/python-best-practices/SKILL.md`
```markdown
---
name: python-best-practices
description: Python code review and refactoring using PEP 8, type hints, and modern patterns
---

# Python Best Practices Skill

## Purpose
Provide expert Python code review and refactoring suggestions following modern Python standards.

## When to Use
- Reviewing Python code
- Refactoring legacy Python
- Implementing type hints
- Optimizing performance
- Applying design patterns

## Instructions

### 1. Code Review Checklist
- [ ] PEP 8 compliance (use resources/style-guide.md)
- [ ] Type hints for all functions
- [ ] Docstrings (Google or NumPy style)
- [ ] Error handling (specific exceptions)
- [ ] List comprehensions where appropriate
- [ ] Context managers for resources
- [ ] Dataclasses for data structures

### 2. Common Patterns
Reference `resources/common-patterns.py` for:
- Factory pattern
- Singleton pattern
- Decorator pattern
- Context managers
- Iterators and generators

### 3. Anti-patterns to Avoid
Reference `resources/anti-patterns.py` for:
- Mutable default arguments
- Bare except clauses
- Missing __init__.py
- Global state
- String concatenation in loops

### 4. Running Linters
Use `scripts/lint.sh` to run:
```bash
#!/bin/bash
pylint "$1"
mypy "$1"
black --check "$1"
```

## Output Format

Provide feedback as:

**Issues Found**
1. [Line X] Issue description
   - Current code: `...`
   - Recommendation: `...`
   - Reason: Why this is better

**Refactored Code**
```python
# Show complete refactored version
```

**Summary**
- X issues addressed
- Performance improvements: [if applicable]
- Type safety: [improved/complete]
```

**Resources file**: `resources/style-guide.md`
```markdown
# Python Style Guide (PEP 8 Summary)

## Naming Conventions
- `snake_case` for functions and variables
- `PascalCase` for classes
- `UPPER_CASE` for constants
- `_private` for internal methods

## Line Length
- Max 88 characters (Black formatter default)
- Max 79 for docstrings/comments

## Imports
```python
# Standard library
import os
import sys

# Third-party
import numpy as np
import pandas as pd

# Local
from myapp import utils
```

...
```

### Skill Locations

1. **Personal skills**: `~/.claude/skills/my-skill/SKILL.md`
2. **Project skills**: `.claude/skills/my-skill/SKILL.md`
3. **Plugin-provided skills**: Automatically available when plugin installed

### SKILL.md Format

**Required structure**:
```markdown
---
name: skill-name-here
description: When Claude should use this skill (max 1024 chars)
---

# Skill Title

## Instructions

Step-by-step guidance for Claude.

## Resources

Reference other files in the skill directory.
```

**Constraints**:
- `name`: lowercase, hyphens, max 64 chars
- `description`: max 1024 chars (be specific!)
- Use relative paths for resources
- Can include executable scripts

### How Skills Are Invoked

1. User makes a request to Claude
2. Claude reads all skill descriptions (from YAML frontmatter)
3. Claude decides if a skill is relevant
4. Claude uses bash to read `SKILL.md` into context
5. Claude follows instructions and may read additional resources
6. Claude executes any scripts if needed

### Skill Best Practices

1. **Write clear descriptions** - This determines when skills are triggered
2. **Be specific about "when to use"** - Helps Claude decide
3. **Include examples** - Show desired output format
4. **Reference external files** - Keep SKILL.md concise
5. **Test with realistic prompts** - Ensure skill gets triggered
6. **Version control skills** - Especially project skills
7. **Share via plugins** - Distribute across team

---

## Model Context Protocol (MCP)

### What Is MCP?

**Model Context Protocol (MCP)** is an open standard for connecting AI assistants to external tools, databases, and APIs.

> *"MCP is the USB-C for AI"* - Universal connection standard

### Why MCP?

Without MCP:
```
Claude Code ──custom integration──▶ Postgres
Claude Code ──custom integration──▶ Stripe
Claude Code ──custom integration──▶ Figma
Claude Code ──custom integration──▶ Every other tool
```

With MCP:
```
Claude Code ──MCP──▶ MCP Server ──▶ Postgres
                 ──▶ MCP Server ──▶ Stripe
                 ──▶ MCP Server ──▶ Figma
                 ──▶ MCP Server ──▶ Any other tool
```

### Adding MCP Servers

```bash
# Add HTTP MCP server (recommended for remote)
claude mcp add --transport http plaid https://api.example.com/mcp

# Add stdio MCP server (for local tools)
claude mcp add --transport stdio my-db "node /path/to/mcp-server.js"

# List configured MCP servers
claude mcp list

# Remove MCP server
claude mcp remove plaid
```

### Popular MCP Servers

**Official Anthropic Servers**:
- `@modelcontextprotocol/server-filesystem` - File system access
- `@modelcontextprotocol/server-github` - GitHub API
- `@modelcontextprotocol/server-postgres` - PostgreSQL database
- `@modelcontextprotocol/server-sqlite` - SQLite database

**Third-party Servers**:
- Plaid (banking data)
- Stripe (payments)
- Square (commerce)
- Figma (design)
- Cloudinary (media)
- Zapier (automation)
- Workato (integration)

### MCP in Plugins

Plugins can bundle MCP server configurations:

**File**: `.claude-plugin/plugin.json`
```json
{
  "name": "database-toolkit",
  "version": "1.0.0",
  "mcp_servers": [
    {
      "name": "postgres",
      "transport": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://localhost/mydb"]
    },
    {
      "name": "sqlite",
      "transport": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "./data.db"]
    }
  ]
}
```

### MCP Best Practices

1. **Use HTTP transport for remote services** (more reliable)
2. **Use stdio for local tools** (faster, no network)
3. **Monitor token usage** - MCP can produce large outputs
4. **Configure limits** in `.claude/settings.json`
5. **Disable unused servers** - Use `/context` to see what's active
6. **Test MCP servers independently** before adding to Claude Code

---

## Session Management

### Understanding Context Window

Claude Code uses a **200K token context window** (approximately 150K words or 600 pages).

**Context consumption**:
- Your messages
- Claude's responses
- Tool outputs (file reads, command outputs)
- CLAUDE.md files
- MCP server data
- Hook outputs (UserPromptSubmit, SessionStart)

### Context Compaction

**Auto-compact** triggers at ~95% capacity (or 25% remaining) and:
- Summarizes conversation
- Preserves key decisions
- Discards intermediate steps
- **Consumes 20-45K tokens** (10-22% of window)

⚠️ **Expert consensus**: Disable auto-compact, use manual compaction strategically.

### Manual Compaction Strategies

```bash
# View context usage
/context

# Manual compact with instructions
/compact keep authentication logic and API design decisions

# Compact at strategic times
# - When pivoting to new feature
# - At ~70% context capacity
# - Before long research task
# - After completing a major milestone

# Clear completely (fresh start)
/clear
```

### When to Clear vs Compact

| Scenario | Action | Reason |
|----------|--------|--------|
| Starting new unrelated feature | `/clear` | No need for previous context |
| Feature complete, moving to next | `/clear` | Clean slate improves focus |
| Need to remember key decisions | `/compact keep <what>` | Preserves specific context |
| Context at 70%+ capacity | `/compact` | Prevent auto-compact |
| Compaction went wrong | `/clear` | Restart with right context |
| Session spiraling/confused | `/clear` | Break the confusion loop |

### Session Continuity

```bash
# Continue most recent session
claude -c
claude --continue

# Resume specific session by ID
claude -r abc123
claude --resume abc123

# List recent sessions
claude --resume
```

### Memory File Management

**Claude Code reads memory files at session start**:
- `CLAUDE.md` (project context)
- `.claude/settings.json` (configuration)
- Skill descriptions (for model invocation)
- MCP server metadata

**Best practices**:
1. **Keep CLAUDE.md lean** - It occupies context from start
2. **Be specific, not verbose** - Every token counts
3. **Update regularly** - Remove outdated information
4. **Use hierarchy** - Split into multiple files if needed

### Avoiding Context Issues

1. **Disable auto-compact**: `/config` → Auto-compact → toggle off
2. **Use CLAUDE.md effectively**: Document patterns, not history
3. **Leverage subagents early**: Research before main context fills
4. **Disable unused MCP servers**: Free up context space
5. **Break large tasks**: If needs compaction, it's too big
6. **Monitor context meter**: Act at 70%, not 95%

### Session Management Architecture

Your current implementation (from codebase):
```
.claude/sessions/
├── YYYYMMDD_HHMMSS_randomhex_description/
│   ├── CLAUDE.md          # Session context (auto-loaded)
│   ├── explore.md         # Exploration phase output
│   ├── plan.md            # Planning phase output
│   ├── code.md            # Implementation summary
│   ├── activity.log       # Session events
│   └── ...
```

**Hooks manage lifecycle**:
- `UserPromptSubmit` → Load active session context
- `Stop` → Update session metadata
- `PreToolUse` → Validate session for plan/code commands

---

## Architecture Diagram

### Complete System Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        CLAUDE CODE                             │
│                   (Main Agent - 200K Context)                  │
└────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │   PLUGINS   │  │   SESSION   │  │  CONTEXT    │
    │ (Container) │  │ MANAGEMENT  │  │  WINDOW     │
    └─────────────┘  └─────────────┘  └─────────────┘
              │               │               │
              │               │               │
    ┌─────────┴─────────┬─────┴─────┐       │
    │         │         │           │       │
    ▼         ▼         ▼           ▼       ▼
┌────────┐┌────────┐┌────────┐┌─────────┐┌──────────┐
│Commands││ Hooks  ││ Skills ││Subagents││   MCP    │
│(User)  ││(Auto)  ││(Model) ││(Task)   ││(External)│
└────────┘└────────┘└────────┘└─────────┘└──────────┘
    │         │         │           │          │
    └─────────┴─────────┴───────────┴──────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │      TOOL LAYER       │
            │  Read, Write, Edit,   │
            │  Bash, Grep, Glob,    │
            │  WebFetch, WebSearch  │
            └───────────────────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │    FILESYSTEM /       │
            │   EXTERNAL APIS       │
            └───────────────────────┘
```

### Request Flow Examples

#### Example 1: User types `/review`

```
User types: /review

  1. Command Lookup
     → Search .claude/commands/review.md
     → Load markdown content

  2. Pre-Hook Execution
     → Run PreToolUse hooks (validation)
     → If any hook exits non-zero, block command

  3. Command Execution
     → Claude processes command instructions
     → May call tools (Read, Grep, etc.)
     → May invoke skills (based on description match)
     → May spawn subagents (for parallel research)

  4. Post-Hook Execution
     → Run PostToolUse hooks (logging)
     → Run Stop hooks (cleanup, save session)

  5. Response to User
```

#### Example 2: Claude decides to use a skill

```
User asks: "Review this Python code for best practices"

  1. Skill Discovery
     → Claude scans all SKILL.md descriptions
     → Finds "python-best-practices" skill (matches description)

  2. Skill Loading
     → Bash: cat ~/.claude/skills/python-best-practices/SKILL.md
     → Content added to context window

  3. Resource Access
     → Skill references resources/style-guide.md
     → Bash: cat ~/.claude/skills/python-best-practices/resources/style-guide.md
     → Content added to context

  4. Execution
     → Claude follows skill instructions
     → May run scripts (e.g., lint.sh)
     → Provides structured output per skill format

  5. Response
     → User sees code review following skill template
```

#### Example 3: Subagent research

```
User asks: "Understand how authentication works in this codebase"

  1. Main Agent Decision
     → Task is complex, codebase exploration needed
     → Decides to use subagent

  2. Subagent Launch
     → Task tool invoked with Explore subagent
     → New isolated 200K context window created
     → Tools: Read, Grep, Glob, WebFetch

  3. Subagent Research
     → Searches for auth-related files
     → Reads authentication code
     → Analyzes patterns
     → Prepares summary

  4. Subagent Return
     → Summary sent back to main agent
     → Subagent context discarded
     → Main agent preserves space

  5. Main Agent Response
     → Synthesizes subagent findings
     → Provides user-friendly explanation
```

---

## Best Practices

### 1. Plugin Development

✅ **Do:**
- Bundle related functionality together
- Provide clear, specific descriptions
- Include comprehensive README
- Version your plugin semantically
- Test on fresh project before publishing
- Document all commands, hooks, skills

❌ **Don't:**
- Create plugin for single command (overkill)
- Mix unrelated functionality
- Forget to specify tool permissions
- Hardcode paths (use relative paths)

### 2. Command Design

✅ **Do:**
- Name commands after their action (e.g., `/review`, `/test`)
- Use namespaces for related commands (`/git:commit`)
- Provide argument help in command
- Make commands idempotent when possible
- Include examples in command description

❌ **Don't:**
- Create commands that need long explanations
- Use confusing abbreviations
- Forget to handle missing arguments
- Make commands with side effects unclear

### 3. Hook Implementation

✅ **Do:**
- Keep hooks fast (< 100ms)
- Use PreToolUse for validation only
- Return meaningful error messages
- Log to files, not stdout (except UserPromptSubmit)
- Test exit codes carefully
- Handle hook failures gracefully

❌ **Don't:**
- Make slow API calls in hooks
- Use Stop hook for user feedback (they won't see it)
- Create circular dependencies between hooks
- Forget exit codes (0 = success, non-zero = block)

### 4. Subagent Usage

✅ **Do:**
- Use for large codebase exploration
- Run parallel for independent tasks (max 10)
- Provide clear, specific task descriptions
- Request summaries to save main context
- Use early in conversation

❌ **Don't:**
- Overuse (adds latency)
- Use for simple file reads
- Launch when main context nearly full
- Create dependent sequential subagents
- Expect subagents to spawn other subagents

### 5. Skill Creation

✅ **Do:**
- Write specific, actionable descriptions
- Include clear "when to use" section
- Provide examples of expected output
- Reference external resources for detail
- Test that skill gets triggered appropriately
- Version control project skills

❌ **Don't:**
- Write vague descriptions
- Make SKILL.md too long (use resources/)
- Forget YAML frontmatter
- Hardcode absolute paths
- Duplicate built-in Claude knowledge

### 6. Session Management

✅ **Do:**
- Disable auto-compact
- Use `/compact` manually at 70% capacity
- Use `/clear` when starting unrelated features
- Monitor context with `/context`
- Keep CLAUDE.md lean and current
- Leverage subagents to preserve context
- Break large tasks into sessions

❌ **Don't:**
- Let auto-compact surprise you
- Wait until 95% to think about context
- Try to cram entire project history in one session
- Keep outdated info in CLAUDE.md
- Ignore context warnings
- Fight compaction by adding more context

### 7. MCP Integration

✅ **Do:**
- Use HTTP transport for remote services
- Test MCP servers independently first
- Monitor token consumption
- Disable unused servers to save context
- Document MCP requirements in plugin

❌ **Don't:**
- Add every available MCP server
- Ignore MCP output size
- Expect MCP to work without configuration
- Forget to handle MCP errors

---

## Comparison to Other Systems

### Claude Code vs GitHub Copilot

| Feature | Claude Code | GitHub Copilot |
|---------|-------------|----------------|
| **Approach** | Agentic (autonomous) | Autocomplete |
| **Context** | Full codebase + web | Current file + neighbors |
| **Extensibility** | Plugins, commands, hooks | Limited extensions |
| **Multi-step** | Yes (subagents) | No |
| **Custom workflows** | Yes (commands, skills) | No |

### Claude Code vs Cursor

| Feature | Claude Code | Cursor |
|---------|-------------|--------|
| **Interface** | CLI + IDE | IDE only |
| **Plugins** | Yes (full system) | Limited |
| **Hooks** | Yes (lifecycle events) | Limited |
| **Subagents** | Yes (parallel tasks) | No |
| **MCP** | Yes (open standard) | Proprietary |

---

## Future Considerations

### Session ID System Integration

Given this architecture research, the Session ID v2 design should integrate with:

1. **Plugin system**: Session commands as plugin
2. **Hooks**: SessionStart/SessionEnd for lifecycle management
3. **Skills**: Session discovery and management as skill
4. **Index in MCP**: Expose session index via MCP server
5. **Context optimization**: Session metadata shouldn't bloat context

**Recommendations**:
- Create `session-management` plugin bundling v2 system
- Add SessionStart hook to load active session
- Add SessionEnd hook to update session index
- Create `session-finder` skill for intelligent session lookup
- Keep session index.json out of main context (load on-demand)

### Evolution Path

**Near-term** (Next 6 months):
- More official Anthropic plugins
- Enhanced subagent coordination
- Better context window management
- Skills marketplace growth

**Long-term** (12+ months):
- Multi-agent collaboration (agents talking to agents)
- Persistent agent memory across sessions
- Visual plugin builder
- Enterprise plugin management
- Cross-project context sharing

---

## Summary

Claude Code's architecture is **modular and composable**:

1. **Plugins** distribute bundles of functionality
2. **Commands** provide user-triggered workflows
3. **Hooks** automate lifecycle events
4. **Subagents** execute specialized parallel tasks
5. **Skills** add model-invoked domain expertise
6. **MCP** integrates external tools and services

This design enables:
- **Extensibility** without modifying core
- **Composability** through plugin bundling
- **Determinism** via hooks
- **Scalability** with subagents
- **Context efficiency** through isolation

**Key insight**: Each component serves a distinct purpose in the activation spectrum:
- **User-triggered** → Commands
- **Auto-triggered** → Hooks
- **Model-triggered** → Skills
- **Delegated** → Subagents
- **External** → MCP

Understanding this architecture enables building sophisticated, production-ready workflows that leverage Claude Code's full power.

---

*"Simplicity is prerequisite for reliability."* — Edsger W. Dijkstra

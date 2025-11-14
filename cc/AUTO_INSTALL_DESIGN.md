# Automated Installation System Design - Semantic Search v3.0.0

## Design Overview

Create a **multi-layer automated installation system** that uses Claude Code's SessionStart hooks to:
1. Detect missing dependencies
2. Install what can be auto-installed
3. Guide users through manual steps if needed
4. Validate everything is working

## Architecture

```
Plugin Installation
        ↓
SessionStart Hook Triggers
        ↓
┌─────────────────────────────────────┐
│  Dependency Detection & Installation│
│                                     │
│  1. Check Ollama                    │
│     ├─ Not installed?               │
│     │  └─ Show install script       │
│     └─ Installed?                   │
│        ├─ Check jina model          │
│        └─ Auto-pull if missing      │
│                                     │
│  2. Check Code Context MCP          │
│     ├─ Not installed?               │
│     │  └─ Auto npm install          │
│     └─ Installed?                   │
│        └─ Verify build              │
│                                     │
│  3. Check Node.js                   │
│     └─ Validate version 20+         │
│                                     │
│  4. Setup directories               │
│     └─ Create .code-context/        │
└─────────────────────────────────────┘
        ↓
Status Report to User
        ↓
Ready to Use / Needs Action
```

## Components

### 1. SessionStart Hook (`hooks/SessionStart.json`)

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/setup-semantic-search.sh",
            "description": "Auto-setup semantic search dependencies"
          }
        ]
      }
    ]
  }
}
```

### 2. Main Setup Script (`scripts/setup-semantic-search.sh`)

**Responsibilities:**
- Check all dependencies
- Install what can be auto-installed
- Generate install commands for manual steps
- Report status to user

**Flow:**
```bash
#!/bin/bash
set -e

# 1. Check Node.js (required)
# 2. Check/Install Code Context MCP (auto via npm)
# 3. Check Ollama (guide user if missing)
# 4. Check/Pull Jina model (auto if Ollama exists)
# 5. Setup directories
# 6. Report status
```

### 3. Ollama Installation Helper (`scripts/install-ollama.sh`)

**Platform-specific installers:**
```bash
# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: Use official script
    curl -fsSL https://ollama.com/install.sh | sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Download app
    echo "Download from: https://ollama.com/download/mac"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows: Download installer
    echo "Download from: https://ollama.com/download/windows"
fi
```

### 4. Code Context MCP Installer (`scripts/install-code-context.sh`)

**Auto-installation:**
```bash
#!/bin/bash
INSTALL_DIR="${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp"

# Clone if not exists
if [ ! -d "$INSTALL_DIR" ]; then
    git clone https://github.com/fkesheh/code-context-mcp.git "$INSTALL_DIR"
fi

# Install & build
cd "$INSTALL_DIR"
npm install
npm run build

echo "✅ Code Context MCP installed"
```

### 5. Dependency Validator (`scripts/validate-deps.sh`)

**Checks:**
```bash
#!/bin/bash

check_node() {
    if command -v node >/dev/null 2>&1; then
        version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$version" -ge 20 ]; then
            echo "✅ Node.js v$version"
            return 0
        fi
    fi
    echo "❌ Node.js 20+ required"
    return 1
}

check_ollama() {
    if command -v ollama >/dev/null 2>&1; then
        echo "✅ Ollama installed"
        return 0
    fi
    echo "⚠️  Ollama not installed"
    return 1
}

check_jina_model() {
    if ollama list | grep -q "jina-embeddings-v2-base-code"; then
        echo "✅ Jina model ready"
        return 0
    fi
    echo "⚠️  Jina model not pulled"
    return 1
}

check_code_context() {
    if [ -f "${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp/dist/index.js" ]; then
        echo "✅ Code Context MCP built"
        return 0
    fi
    echo "❌ Code Context MCP not installed"
    return 1
}
```

## Plugin Structure

```
cc/
├── .claude-plugin/
│   └── plugin.json (with hooks config)
├── hooks/
│   └── SessionStart.json (hook configuration)
├── scripts/
│   ├── setup-semantic-search.sh (main setup)
│   ├── install-ollama.sh (Ollama installer)
│   ├── install-code-context.sh (Code Context installer)
│   ├── validate-deps.sh (dependency checker)
│   └── one-click-install.sh (user-facing quick install)
├── .mcp-servers/
│   └── code-context-mcp/ (auto-cloned)
└── docs/
    ├── SETUP_GUIDE.md (step-by-step)
    └── TROUBLESHOOTING.md (common issues)
```

## Installation Flows

### Flow A: First-Time Setup (All Auto)
```
User installs plugin
    ↓
SessionStart hook runs
    ↓
Detects: Node.js ✅, Ollama ✅, Code Context ❌
    ↓
Auto-installs Code Context MCP (npm)
    ↓
Auto-pulls Jina model (ollama pull)
    ↓
✅ Ready to use immediately
```

### Flow B: Partial Setup (Ollama Missing)
```
User installs plugin
    ↓
SessionStart hook runs
    ↓
Detects: Node.js ✅, Ollama ❌, Code Context ❌
    ↓
Shows message:
"⚠️  Semantic search requires Ollama. Install now?"
    ↓
Displays install command:
"Run: /plugin run install-ollama"
    ↓
User runs command
    ↓
Ollama installed + Jina pulled + Code Context installed
    ↓
✅ Ready to use
```

### Flow C: Manual Verification
```
User runs: /plugin run validate-deps
    ↓
Script checks everything:
✅ Node.js 20.10.0
✅ Ollama 0.1.44
✅ Jina model downloaded
✅ Code Context MCP built
✅ Directories configured
    ↓
Status: ALL SYSTEMS GO 🚀
```

## User-Facing Commands

Add to `commands/` directory:

### `/setup-semantic-search`
```markdown
---
description: "Setup semantic search dependencies automatically"
---

Runs automated setup for semantic search:
1. Checks dependencies
2. Installs what's missing
3. Validates configuration
4. Reports status

Usage: `/setup-semantic-search`
```

### `/validate-semantic-search`
```markdown
---
description: "Validate semantic search setup"
---

Checks all dependencies and reports status:
- Node.js version
- Ollama installation
- Jina model availability
- Code Context MCP build
- Directory structure

Usage: `/validate-semantic-search`
```

## Smart Status Reporting

SessionStart hook outputs JSON for context injection:

```json
{
  "additionalContext": "## Semantic Search Status\n\n✅ **Fully Configured**\n- Serena MCP (LSP)\n- Code Context MCP (Semantic)\n- Ollama + Jina embeddings\n\nYou can now use natural language queries in `/plan` command.\n\nExamples:\n- \"find authentication functions\"\n- \"similar error handlers\"\n- \"API endpoint implementations\"\n\nType `/help semantic-search` for more info."
}
```

Or if setup needed:

```json
{
  "additionalContext": "## Semantic Search Setup Required\n\n⚠️  Missing dependencies:\n- Ollama (embeddings engine)\n- Jina model\n\n**Quick Install:**\n```bash\n/setup-semantic-search\n```\n\nOr see full guide: `/help setup-semantic-search`"
}
```

## Progressive Enhancement Strategy

### Level 1: Core (Always Works)
- Serena MCP (existing)
- Grep/Glob fallback
- No additional dependencies

### Level 2: Enhanced (Node.js + Code Context)
- Serena MCP
- Code Context MCP (no embeddings yet)
- AST-based code chunking
- Better than grep

### Level 3: Full Semantic (+ Ollama + Jina)
- Serena MCP
- Code Context MCP with embeddings
- Natural language queries
- Similarity search
- Hybrid RRF fusion

**Key Insight:** Plugin works at ALL levels, gets better as dependencies are added.

## Installation Time Estimates

| Component | Auto? | Time | Network |
|-----------|-------|------|---------|
| Code Context MCP | ✅ Yes | ~1 min | ~50MB |
| Ollama (Linux) | ✅ Yes | ~2 min | ~500MB |
| Ollama (Mac/Win) | ⚠️  Guided | ~3 min | ~500MB |
| Jina model | ✅ Yes | ~1 min | ~300MB |
| **Total** | Mostly | **5-7 min** | **~850MB** |

## Error Handling

### Network Failures
```bash
if ! git clone ...; then
    echo "❌ Network error. Retry with:"
    echo "  /setup-semantic-search"
    exit 1
fi
```

### Permission Issues
```bash
if ! npm install; then
    echo "❌ Permission denied. Try:"
    echo "  sudo chown -R $(whoami) ~/.npm"
    exit 1
fi
```

### Missing System Tools
```bash
if ! command -v git; then
    echo "❌ Git required. Install:"
    echo "  Linux: sudo apt install git"
    echo "  Mac: xcode-select --install"
    exit 1
fi
```

## Testing Strategy

### Unit Tests
- [ ] validate-deps.sh detects all dependencies
- [ ] install-code-context.sh installs correctly
- [ ] install-ollama.sh works on all platforms

### Integration Tests
- [ ] SessionStart hook triggers on startup
- [ ] Full install completes successfully
- [ ] Status report shows correct info

### User Acceptance Tests
- [ ] Fresh install works end-to-end
- [ ] Partial install guides user correctly
- [ ] Validation command reports accurately

## Documentation Requirements

### SETUP_GUIDE.md
- Prerequisites (Node.js, Git, ~1GB disk space)
- Automated installation steps
- Manual installation (if auto fails)
- Platform-specific notes
- Troubleshooting

### TROUBLESHOOTING.md
- "Ollama not found"
- "npm install fails"
- "Model pull timeout"
- "Permission denied"
- "Network errors"

### README.md Updates
- Quick start: `/setup-semantic-search`
- Feature levels (Core/Enhanced/Full)
- System requirements
- Installation time estimate

## Success Criteria

- [ ] ≥90% users can auto-install everything
- [ ] <10 minutes total setup time
- [ ] Clear error messages for failures
- [ ] Works on Linux, macOS, Windows
- [ ] No manual config file editing
- [ ] Graceful degradation if partial setup

## Rollout Plan

### Phase 1: Infrastructure
- Create hooks structure
- Build installation scripts
- Test on multiple platforms

### Phase 2: Integration
- Add SessionStart hook
- Update plugin.json
- Create user commands

### Phase 3: Documentation
- Write setup guides
- Create troubleshooting docs
- Add video/screenshots

### Phase 4: Release
- Tag v3.0.0-beta
- Test with beta users
- Iterate on feedback
- Release v3.0.0 stable

---

**Design Status**: Complete
**Next Step**: Implementation
**Estimated Dev Time**: 2-3 days

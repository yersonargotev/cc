# Semantic Search Setup Guide v3.0.0

Complete guide to installing and configuring dual-layer semantic search for Claude Code.

---

## Overview

This plugin adds **dual-layer semantic intelligence** to your Claude Code workflow:

1. **Serena MCP** (existing) - LSP-based symbol analysis
2. **Code Context MCP** (new) - Semantic search with embeddings

**Benefits:**
- 📝 Natural language code queries
- 🎯 60-80% improved search relevance
- 🔍 Similarity search capabilities
- 💰 Local-first (zero API costs)
- 🔒 Privacy-preserving (no code sent externally)

---

## Quick Start (Recommended)

### One-Command Installation

```bash
/setup-semantic-search
```

That's it! The automated setup will:
1. Install Code Context MCP
2. Install Ollama + Jina embeddings
3. Configure .mcp.json
4. Validate everything

**Time:** 5-10 minutes
**Download:** ~850MB

After completion, restart Claude Code.

---

## Prerequisites

Before running setup, ensure you have:

### Required
- ✅ **Node.js 20+** ([download](https://nodejs.org/))
  ```bash
  node -v  # Should show v20.0.0 or higher
  ```

- ✅ **Git** ([download](https://git-scm.com/))
  ```bash
  git --version
  ```

- ✅ **~1GB free disk space**

- ✅ **Internet connection** (for downloads)

### Optional (but recommended)
- **Ollama** - For full semantic search
  - Without: Basic LSP search (Serena) works
  - With: Full semantic search with embeddings

---

## Installation Methods

### Method 1: Automated (Recommended)

Run the setup command from Claude Code:

```bash
/setup-semantic-search
```

Or from terminal:

```bash
cd ${CLAUDE_PLUGIN_ROOT}
./scripts/setup-semantic-search.sh
```

**What it does:**
- ✅ Validates prerequisites
- ✅ Clones & builds Code Context MCP
- ✅ Installs Ollama (platform-specific)
- ✅ Downloads Jina embeddings model
- ✅ Updates .mcp.json configuration
- ✅ Creates data directories
- ✅ Validates installation

**Platform Notes:**

**Linux:** Fully automated
```bash
# Everything installs automatically
./scripts/setup-semantic-search.sh
```

**macOS:** Ollama requires manual download
```bash
# 1. Download Ollama from: https://ollama.com/download/mac
# 2. Install Ollama.app
# 3. Run setup script:
./scripts/setup-semantic-search.sh
```

**Windows:** Ollama requires manual download
```bash
# 1. Download from: https://ollama.com/download/windows
# 2. Run OllamaSetup.exe
# 3. Run setup script:
./scripts/setup-semantic-search.sh
```

---

### Method 2: Manual Installation

If you prefer to install components separately:

#### Step 1: Install Node.js (if needed)
```bash
# Check current version
node -v

# If < v20, download from:
https://nodejs.org/
```

#### Step 2: Install Code Context MCP
```bash
cd ${CLAUDE_PLUGIN_ROOT}
./scripts/install-code-context.sh
```

This will:
- Clone https://github.com/fkesheh/code-context-mcp
- Run `npm install`
- Build TypeScript (`npm run build`)
- Create data directories

#### Step 3: Install Ollama
```bash
# Linux (automated)
./scripts/install-ollama.sh

# macOS / Windows (follow prompts)
./scripts/install-ollama.sh
# Then download from: https://ollama.com/download
```

#### Step 4: Download Jina Model
```bash
ollama pull unclemusclez/jina-embeddings-v2-base-code
```

#### Step 5: Update Configuration

The `.mcp.json` file should contain:

```json
{
  "serena": {
    "command": "uvx",
    "args": [
      "--from",
      "git+https://github.com/oraios/serena",
      "serena",
      "start-mcp-server",
      "--context",
      "ide-assistant",
      "--project",
      "${CLAUDE_PROJECT_DIR}"
    ],
    "env": {
      "SERENA_LOG_LEVEL": "info"
    }
  },
  "code-context": {
    "command": "node",
    "args": [
      "${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp/dist/index.js"
    ],
    "env": {
      "DATA_DIR": "${CLAUDE_PROJECT_DIR}/.code-context/data",
      "REPO_CACHE_DIR": "${CLAUDE_PROJECT_DIR}/.code-context/repos"
    }
  }
}
```

---

## Validation

After installation, validate everything is working:

```bash
/validate-semantic-search
```

Or from terminal:

```bash
./scripts/validate-deps.sh
```

**Expected output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Semantic Search Dependency Validation v3.0.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

═══ Core Dependencies ═══
Checking Node.js... ✅ v20.10.0
Checking Git... ✅ v2.43.0

═══ Semantic Search Components ═══
Checking Ollama... ✅ v0.1.44
Checking Jina embeddings model... ✅ Downloaded
Checking Code Context MCP... ✅ Installed & built
Checking Serena MCP (LSP)... ✅ Available (via uvx)

═══ Configuration ═══
Checking .mcp.json configuration... ✅ Configured
Checking data directories... ✅ Created

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL SYSTEMS GO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Usage

After installation and restart, semantic search is automatically available in the `/plan` command.

### Natural Language Queries

Instead of grep patterns, use natural language:

**Before (v2.2.0):**
```bash
# Had to use exact symbols
/plan "Analyze the authenticate function"
```

**After (v3.0.0):**
```bash
# Natural language works!
/plan "find authentication functions"
/plan "show me error handling patterns"
/plan "similar validation logic to validateEmail"
/plan "API endpoint implementations"
/plan "database connection code"
```

### How It Works

```
Your Query → code-search-agent
                ↓
         Query Routing:
         ├─ Exact symbol? → Serena MCP (LSP)
         ├─ Conceptual? → Code Context (Semantic)
         └─ Hybrid? → Both + RRF Fusion
                ↓
         Ranked Results → plan.md
```

### Search Types

| Type | Example | Tool Used |
|------|---------|-----------|
| **Exact Symbol** | "find `authenticate` function" | Serena MCP |
| **Conceptual** | "find auth logic" | Code Context |
| **Dependency** | "what calls `login`?" | Serena MCP |
| **Similarity** | "similar to error handler X" | Code Context |
| **Hybrid** | "auth functions in API layer" | Both (RRF fusion) |

---

## Verification & Testing

### Test Semantic Search

Try these queries in `/plan`:

```bash
# 1. Conceptual search
/plan "find error handling code"

# 2. Similarity search
/plan "similar functions to validateEmail"

# 3. Natural language
/plan "show me how authentication works"

# 4. Pattern discovery
/plan "find all API endpoints"
```

### Check MCP Servers

Verify both MCP servers are loaded:

```bash
# In Claude Code, check available tools
# You should see:
# - mcp__serena__* (LSP tools)
# - mcp__code_context__* (Semantic tools)
```

---

## Architecture Levels

The plugin works at multiple capability levels:

### Level 1: Core (Always Available)
- ✅ Serena MCP (LSP symbols)
- ✅ Grep/Glob fallback
- ✅ No additional dependencies

**Capabilities:**
- Exact symbol search
- Type-aware analysis
- Fast, precise results

### Level 2: Enhanced (+ Code Context)
- ✅ Serena MCP
- ✅ Code Context MCP (no embeddings yet)
- ✅ AST-based code chunking

**Capabilities:**
- All Level 1 features
- Better code structure analysis
- Improved search precision

### Level 3: Full Semantic (+ Ollama + Jina)
- ✅ Serena MCP
- ✅ Code Context MCP with embeddings
- ✅ Natural language queries
- ✅ Similarity search

**Capabilities:**
- All Level 1 & 2 features
- Natural language queries
- Conceptual code discovery
- Similarity matching
- Hybrid RRF fusion

**Key Insight:** The plugin works at ALL levels and gets progressively better as you add components.

---

## Performance Expectations

### Indexing
- **Initial index:** <2 min for 10K files
- **Incremental:** <5s per changed file
- **Storage:** ~500MB for large projects

### Query Latency
- **Cold query:** <5s (first time)
- **Warm query:** <500ms (cached)
- **Hybrid query:** <3s (both tools)

### Resource Usage
- **Memory:** <1GB total (Ollama + Serena + Code Context)
- **Disk:** ~850MB (Ollama + Jina + Code Context)
- **CPU:** Low (idle), Medium (indexing/querying)

---

## Updating

### Update Plugin to Latest
```bash
cd ${CLAUDE_PLUGIN_ROOT}
git pull origin main
```

### Update Code Context MCP
```bash
cd ${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp
git pull
npm install
npm run build
```

### Update Jina Model
```bash
ollama pull unclemusclez/jina-embeddings-v2-base-code
```

---

## Uninstallation

To remove semantic search components:

### Remove Code Context MCP
```bash
rm -rf ${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp
```

### Remove Ollama
**Linux:**
```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm /usr/local/bin/ollama
sudo rm -rf /usr/share/ollama
```

**macOS:**
```bash
# Remove Ollama.app from Applications
rm -rf /Applications/Ollama.app
rm -rf ~/.ollama
```

**Windows:**
```
# Uninstall via Windows Settings > Apps > Ollama
```

### Revert .mcp.json
```bash
# Edit .mcp.json and remove "code-context" section
# Keep only "serena" configuration
```

### Revert Plugin Version
```bash
cd ${CLAUDE_PLUGIN_ROOT}
git checkout v2.2.0
```

---

## Next Steps

After successful setup:

1. ✅ **Restart Claude Code** to load new MCP servers
2. ✅ **Run validation:** `/validate-semantic-search`
3. ✅ **Try queries:** `/plan "find auth code"`
4. ✅ **Read research:** `SEMANTIC_SEARCH_RESEARCH.md`
5. ✅ **Check troubleshooting:** `docs/TROUBLESHOOTING.md`

---

## Support & Resources

- **Setup Issues:** See `docs/TROUBLESHOOTING.md`
- **Commands:** `/setup-semantic-search`, `/validate-semantic-search`
- **Research:** `SEMANTIC_SEARCH_RESEARCH.md`
- **Implementation:** `SEMANTIC_SEARCH_IMPLEMENTATION_PLAN.md`
- **GitHub:** https://github.com/yersonargotev/cc-mkp

---

## FAQ

### Q: Do I need Ollama for semantic search?
**A:** Ollama is optional but recommended. Without it, you get LSP-based search (Serena) which is still excellent. With Ollama, you unlock natural language queries and similarity search.

### Q: How much disk space is needed?
**A:** ~850MB total:
- Code Context MCP: ~50MB
- Ollama: ~500MB
- Jina model: ~300MB

### Q: Can I use a different embedding model?
**A:** Yes! Code Context MCP supports multiple providers. See implementation plan for details on using OpenAI, VoyageAI, or other models.

### Q: Will this slow down Claude Code?
**A:** No. MCP servers run in background. Query latency is <500ms (warm) to <5s (cold). Indexing is one-time per project.

### Q: Is my code sent to external servers?
**A:** No! Everything runs locally. Ollama + Jina embeddings are 100% local. No code ever leaves your machine.

### Q: Can I use this on multiple projects?
**A:** Yes! Code Context indexes each project separately. Data is stored in `${CLAUDE_PROJECT_DIR}/.code-context/`.

### Q: What if setup fails?
**A:** See `docs/TROUBLESHOOTING.md` for common issues. Or run `/validate-semantic-search` to see specific error messages.

---

**Setup Guide v3.0.0** | Last updated: November 14, 2025

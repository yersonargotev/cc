---
description: "Validate semantic search installation and configuration"
---

# Validate Semantic Search

Checks all dependencies and reports detailed status of your semantic search setup.

## Usage

```bash
/validate-semantic-search
```

## What It Checks

### Core Dependencies
- ✅ Node.js version (v20+)
- ✅ Git installation

### Semantic Search Components
- ✅ Ollama installation & service status
- ✅ Jina embeddings model download
- ✅ Code Context MCP build
- ✅ Serena MCP (uv/uvx)

### Configuration
- ✅ .mcp.json configuration
- ✅ Data directories

## Output Levels

### 🟢 All Systems Go
All dependencies installed and configured correctly.
Full semantic search capabilities available.

### 🟡 Core Ready, Semantic Optional
Core functionality works (Serena + Grep).
Ollama not installed - semantic search unavailable.

### 🔴 Setup Required
Critical dependencies missing.
Run `/setup-semantic-search` to install.

## Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Semantic Search Dependency Validation v3.0.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

═══ Core Dependencies ═══
Checking Node.js... ✅ v20.10.0
Checking Git... ✅ v2.43.0

═══ Semantic Search Components ═══
Checking Ollama... ✅ v0.1.44
   Service: Running
Checking Jina embeddings model... ✅ Downloaded
Checking Code Context MCP... ✅ Installed & built
Checking Serena MCP (LSP)... ✅ Available (via uvx)

═══ Configuration ═══
Checking .mcp.json configuration... ✅ Configured
Checking data directories... ✅ Created

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL SYSTEMS GO!

Your semantic search stack is fully configured.
Try: /plan "find authentication functions"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Troubleshooting

If validation fails, check the specific error messages.
Common fixes:

**Ollama not found:**
```bash
./scripts/install-ollama.sh
```

**Code Context MCP not built:**
```bash
cd ${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp
npm install && npm run build
```

**Jina model missing:**
```bash
ollama pull unclemusclez/jina-embeddings-v2-base-code
```

## Manual Validation

Run the validation script directly:
```bash
cd ${CLAUDE_PLUGIN_ROOT}
./scripts/validate-deps.sh
```

## See Also

- `/setup-semantic-search` - Run automated setup
- `SEMANTIC_SEARCH_RESEARCH.md` - Technical details
- `docs/TROUBLESHOOTING.md` - Common issues

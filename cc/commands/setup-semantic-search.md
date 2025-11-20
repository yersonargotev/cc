---
description: "Automated setup for semantic search dependencies"
---

# Setup Semantic Search

Runs automated installation and configuration for dual-layer semantic search.

## What Gets Installed

1. **Code Context MCP** - Semantic search server (~50MB)
2. **Ollama** - Local embeddings engine (~500MB)
3. **Jina Model** - Code embeddings (~300MB)
4. **Configuration** - Updates .mcp.json automatically

## Requirements

- Node.js 20+ (check with: `node -v`)
- Git
- ~1GB free disk space
- Internet connection (for downloads)

## Usage

```bash
/setup-semantic-search
```

## What It Does

1. ✅ Validates Node.js version
2. 📦 Clones & builds Code Context MCP
3. 🔧 Installs Ollama (platform-specific)
4. ⬇️  Downloads Jina embeddings model
5. ⚙️  Configures .mcp.json
6. ✅ Validates installation

## Estimated Time

- **Linux**: 5-7 minutes (fully automated)
- **macOS/Windows**: 8-10 minutes (some manual steps)

## After Setup

Restart Claude Code to load new MCP servers, then try:

```
/plan "find authentication functions"
/plan "show me error handling patterns"
```

## Troubleshooting

If setup fails, run manual validation:
```bash
./scripts/validate-deps.sh
```

See `docs/TROUBLESHOOTING.md` for common issues.

## Advanced

**Manual installation:**
```bash
cd ${CLAUDE_PLUGIN_ROOT}
./scripts/setup-semantic-search.sh
```

**Install only Code Context:**
```bash
./scripts/install-code-context.sh
```

**Install only Ollama:**
```bash
./scripts/install-ollama.sh
```

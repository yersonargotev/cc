#!/bin/bash
#
# SessionStart Hook - Dependency Checker
# Runs on session startup to validate semantic search configuration
# Returns JSON with additionalContext for user notification
#

set -e

# Silent mode - no colors for JSON output
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Check critical dependencies silently
HAS_NODE=false
HAS_CODE_CONTEXT=false
HAS_OLLAMA=false
HAS_JINA=false

# Check Node.js
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 20 ]; then
        HAS_NODE=true
    fi
fi

# Check Code Context MCP
if [ -f "$PLUGIN_ROOT/.mcp-servers/code-context-mcp/dist/index.js" ]; then
    HAS_CODE_CONTEXT=true
fi

# Check Ollama
if command -v ollama >/dev/null 2>&1; then
    HAS_OLLAMA=true

    # Check Jina model
    if ollama list 2>/dev/null | grep -q "jina-embeddings-v2-base-code"; then
        HAS_JINA=true
    fi
fi

# Build status message
STATUS_MESSAGE=""

if $HAS_CODE_CONTEXT && $HAS_OLLAMA && $HAS_JINA; then
    # All systems go - full semantic search available
    STATUS_MESSAGE="## 🔍 Semantic Search: Fully Configured

**Dual-Layer Intelligence Active:**
- ✅ **Serena MCP** (LSP) - Symbol-level analysis
- ✅ **Code Context MCP** (Semantic) - Natural language queries
- ✅ **Ollama + Jina** - Local embeddings engine

**Try natural language queries in \`/plan\`:**
\`\`\`
/plan \"find authentication functions\"
/plan \"show me error handling patterns\"
/plan \"similar validation logic to validateEmail\"
\`\`\`

Run \`/validate-semantic-search\` to see full status.
"

elif $HAS_CODE_CONTEXT; then
    # Code Context available but no Ollama
    STATUS_MESSAGE="## 🔍 Semantic Search: Partially Configured

**Available:**
- ✅ **Serena MCP** (LSP) - Symbol-level analysis
- ✅ **Code Context MCP** - AST-based code chunking

**Optional Enhancement:**
- ⚠️  **Ollama** - For full semantic search capabilities

**To enable full semantic search:**
\`\`\`bash
./scripts/install-ollama.sh
\`\`\`

Or run: \`/setup-semantic-search\`
"

elif $HAS_NODE; then
    # Node available, can install Code Context
    STATUS_MESSAGE="## 🔍 Semantic Search: Setup Available

**Current:**
- ✅ **Serena MCP** (LSP) - Symbol-level analysis (active)
- ⚠️  **Semantic search** - Not configured

**Quick Setup (5-10 min):**
\`\`\`bash
/setup-semantic-search
\`\`\`

This adds natural language code queries with embeddings.

**Manual setup:**
\`\`\`bash
./scripts/setup-semantic-search.sh
\`\`\`

See \`SEMANTIC_SEARCH_RESEARCH.md\` for details.
"

else
    # Missing Node.js - critical dependency
    STATUS_MESSAGE="## 🔍 Semantic Search: Setup Required

**Prerequisites needed:**
- ❌ **Node.js 20+** - Required for Code Context MCP

**Install Node.js:**
Visit https://nodejs.org/ and install v20 or newer.

**Then run:**
\`\`\`bash
/setup-semantic-search
\`\`\`

Current functionality: Serena MCP (LSP) + Grep/Glob
"

fi

# Output JSON for Claude Code to inject as context
cat <<EOF
{
  "additionalContext": "$STATUS_MESSAGE"
}
EOF

exit 0

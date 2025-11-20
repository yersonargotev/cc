#!/bin/bash
#
# Semantic Search Setup Orchestrator
# Main setup script that installs all dependencies automatically
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║   Semantic Search Setup - Automated Installation v3.0.0   ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "This script will install and configure:"
echo "  • Code Context MCP (semantic search server)"
echo "  • Ollama (embeddings engine)"
echo "  • Jina embeddings model (~300MB)"
echo ""
echo "Estimated time: 5-10 minutes"
echo "Estimated download: ~850MB"
echo ""

# Check if running in non-interactive mode
if [ -t 0 ]; then
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    echo ""
fi

# Track what was installed
INSTALLED_COMPONENTS=()
SKIPPED_COMPONENTS=()
FAILED_COMPONENTS=()

# Step 1: Check/Install Node.js
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Step 1/4: Checking Node.js${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 20 ]; then
        echo -e "${GREEN}✅ Node.js $(node -v) is installed${NC}"
        SKIPPED_COMPONENTS+=("Node.js (already installed)")
    else
        echo -e "${RED}❌ Node.js v$NODE_VERSION is too old (need v20+)${NC}"
        echo ""
        echo "Please upgrade Node.js:"
        echo "  https://nodejs.org/"
        echo ""
        FAILED_COMPONENTS+=("Node.js (version too old)")
        exit 1
    fi
else
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo ""
    echo "Please install Node.js 20+:"
    echo "  https://nodejs.org/"
    echo ""
    FAILED_COMPONENTS+=("Node.js (not installed)")
    exit 1
fi

echo ""

# Step 2: Install Code Context MCP
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Step 2/4: Installing Code Context MCP${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -f "$PLUGIN_ROOT/.mcp-servers/code-context-mcp/dist/index.js" ]; then
    echo -e "${GREEN}✅ Code Context MCP already installed${NC}"
    SKIPPED_COMPONENTS+=("Code Context MCP (already installed)")
else
    echo "Installing Code Context MCP..."
    if bash "$SCRIPT_DIR/install-code-context.sh"; then
        echo -e "${GREEN}✅ Code Context MCP installed successfully${NC}"
        INSTALLED_COMPONENTS+=("Code Context MCP")
    else
        echo -e "${RED}❌ Code Context MCP installation failed${NC}"
        FAILED_COMPONENTS+=("Code Context MCP")
        exit 1
    fi
fi

echo ""

# Step 3: Install Ollama (optional but recommended)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Step 3/4: Installing Ollama${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v ollama >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama is already installed${NC}"
    SKIPPED_COMPONENTS+=("Ollama (already installed)")

    # Check if Jina model is downloaded
    if ollama list 2>/dev/null | grep -q "jina-embeddings-v2-base-code"; then
        echo -e "${GREEN}✅ Jina model already downloaded${NC}"
        SKIPPED_COMPONENTS+=("Jina model (already downloaded)")
    else
        echo "Downloading Jina embeddings model..."
        if ollama pull unclemusclez/jina-embeddings-v2-base-code; then
            echo -e "${GREEN}✅ Jina model downloaded${NC}"
            INSTALLED_COMPONENTS+=("Jina embeddings model")
        else
            echo -e "${YELLOW}⚠️  Jina model download failed (can retry later)${NC}"
            FAILED_COMPONENTS+=("Jina model (download failed)")
        fi
    fi
else
    echo "Ollama is not installed. Installing..."
    echo ""

    if bash "$SCRIPT_DIR/install-ollama.sh"; then
        echo -e "${GREEN}✅ Ollama installed successfully${NC}"
        INSTALLED_COMPONENTS+=("Ollama + Jina model")
    else
        echo -e "${YELLOW}⚠️  Ollama installation requires manual steps${NC}"
        echo ""
        echo "Ollama is optional but recommended for semantic search."
        echo "You can install it later by running:"
        echo "  ./scripts/install-ollama.sh"
        echo ""
        echo "Or download from: https://ollama.com/download"
        echo ""
        SKIPPED_COMPONENTS+=("Ollama (manual installation required)")
    fi
fi

echo ""

# Step 4: Configure .mcp.json
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Step 4/4: Configuring MCP Servers${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

MCP_CONFIG="$PLUGIN_ROOT/.mcp.json"

# Check if code-context is already in config
if [ -f "$MCP_CONFIG" ] && grep -q "code-context" "$MCP_CONFIG"; then
    echo -e "${GREEN}✅ .mcp.json already configured${NC}"
    SKIPPED_COMPONENTS+=(".mcp.json (already configured)")
else
    echo "Updating .mcp.json with Code Context MCP..."

    # Backup existing config
    if [ -f "$MCP_CONFIG" ]; then
        cp "$MCP_CONFIG" "$MCP_CONFIG.backup"
        echo "Backed up existing .mcp.json"
    fi

    # Add code-context to config
    # This creates a new config or updates existing one
    cat > "$MCP_CONFIG" <<'EOF'
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
EOF

    echo -e "${GREEN}✅ .mcp.json configured${NC}"
    INSTALLED_COMPONENTS+=(".mcp.json configuration")
fi

echo ""

# Final validation
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Validating Installation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

bash "$SCRIPT_DIR/validate-deps.sh" || true

echo ""

# Installation summary
echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║                   Installation Summary                     ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

if [ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]; then
    echo -e "${GREEN}${BOLD}Installed:${NC}"
    for component in "${INSTALLED_COMPONENTS[@]}"; do
        echo -e "  ${GREEN}✅${NC} $component"
    done
    echo ""
fi

if [ ${#SKIPPED_COMPONENTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}Skipped (already present):${NC}"
    for component in "${SKIPPED_COMPONENTS[@]}"; do
        echo -e "  ${YELLOW}⊘${NC} $component"
    done
    echo ""
fi

if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
    echo -e "${RED}${BOLD}Failed/Manual:${NC}"
    for component in "${FAILED_COMPONENTS[@]}"; do
        echo -e "  ${RED}❌${NC} $component"
    done
    echo ""
fi

# Next steps
echo -e "${CYAN}${BOLD}Next Steps:${NC}"
echo ""

if command -v ollama >/dev/null 2>&1 && [ -f "$PLUGIN_ROOT/.mcp-servers/code-context-mcp/dist/index.js" ]; then
    echo -e "${GREEN}✅ You're ready to use semantic search!${NC}"
    echo ""
    echo "Restart Claude Code to load the new MCP servers."
    echo ""
    echo "Try natural language queries in /plan:"
    echo '  /plan "find authentication functions"'
    echo '  /plan "show me error handling patterns"'
    echo '  /plan "similar validation logic to validateEmail"'
    echo ""
else
    echo "To complete setup:"
    if ! command -v ollama >/dev/null 2>&1; then
        echo "  1. Install Ollama: https://ollama.com/download"
        echo "     Or run: ./scripts/install-ollama.sh"
    fi
    echo "  2. Restart Claude Code"
    echo "  3. Run: ./scripts/validate-deps.sh"
    echo ""
fi

echo "Documentation:"
echo "  • Setup guide: docs/SETUP_GUIDE.md"
echo "  • Research: SEMANTIC_SEARCH_RESEARCH.md"
echo "  • Implementation: SEMANTIC_SEARCH_IMPLEMENTATION_PLAN.md"
echo ""

echo -e "${GREEN}Setup complete!${NC}"
echo ""

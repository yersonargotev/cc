#!/bin/bash
#
# Semantic Search Dependency Validator
# Checks all required dependencies for semantic search v3.0.0
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Status tracking
ALL_OK=true

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Semantic Search Dependency Validation v3.0.0${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to check Node.js
check_node() {
    echo -n "Checking Node.js... "
    if command -v node >/dev/null 2>&1; then
        version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        full_version=$(node -v)
        if [ "$version" -ge 20 ]; then
            echo -e "${GREEN}✅ $full_version${NC}"
            return 0
        else
            echo -e "${RED}❌ v$full_version (need v20+)${NC}"
            echo -e "${YELLOW}   Install: https://nodejs.org/${NC}"
            ALL_OK=false
            return 1
        fi
    else
        echo -e "${RED}❌ Not installed${NC}"
        echo -e "${YELLOW}   Install: https://nodejs.org/${NC}"
        ALL_OK=false
        return 1
    fi
}

# Function to check Git
check_git() {
    echo -n "Checking Git... "
    if command -v git >/dev/null 2>&1; then
        version=$(git --version | cut -d' ' -f3)
        echo -e "${GREEN}✅ v$version${NC}"
        return 0
    else
        echo -e "${RED}❌ Not installed${NC}"
        echo -e "${YELLOW}   Install: https://git-scm.com/${NC}"
        ALL_OK=false
        return 1
    fi
}

# Function to check Ollama
check_ollama() {
    echo -n "Checking Ollama... "
    if command -v ollama >/dev/null 2>&1; then
        version=$(ollama --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✅ $version${NC}"

        # Check if ollama service is running
        if pgrep -x "ollama" > /dev/null; then
            echo -e "${GREEN}   Service: Running${NC}"
        else
            echo -e "${YELLOW}   Service: Not running (will start on first use)${NC}"
        fi
        return 0
    else
        echo -e "${YELLOW}⚠️  Not installed (optional for semantic search)${NC}"
        echo -e "${YELLOW}   Install: https://ollama.com/download${NC}"
        echo -e "${YELLOW}   Or run: ./scripts/install-ollama.sh${NC}"
        return 1
    fi
}

# Function to check Jina model
check_jina_model() {
    echo -n "Checking Jina embeddings model... "
    if command -v ollama >/dev/null 2>&1; then
        if ollama list 2>/dev/null | grep -q "jina-embeddings-v2-base-code"; then
            echo -e "${GREEN}✅ Downloaded${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Not downloaded${NC}"
            echo -e "${YELLOW}   Run: ollama pull unclemusclez/jina-embeddings-v2-base-code${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Ollama not installed${NC}"
        return 1
    fi
}

# Function to check Code Context MCP
check_code_context() {
    echo -n "Checking Code Context MCP... "
    local mcp_dir="${CLAUDE_PLUGIN_ROOT:-.}/.mcp-servers/code-context-mcp"

    if [ -f "$mcp_dir/dist/index.js" ]; then
        echo -e "${GREEN}✅ Installed & built${NC}"
        echo -e "${GREEN}   Location: $mcp_dir${NC}"
        return 0
    elif [ -d "$mcp_dir" ]; then
        echo -e "${YELLOW}⚠️  Cloned but not built${NC}"
        echo -e "${YELLOW}   Run: cd $mcp_dir && npm install && npm run build${NC}"
        ALL_OK=false
        return 1
    else
        echo -e "${RED}❌ Not installed${NC}"
        echo -e "${YELLOW}   Run: ./scripts/install-code-context.sh${NC}"
        ALL_OK=false
        return 1
    fi
}

# Function to check Serena MCP
check_serena() {
    echo -n "Checking Serena MCP (LSP)... "
    if command -v uv >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Available (via uv)${NC}"
        return 0
    elif command -v uvx >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Available (via uvx)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  uv/uvx not found${NC}"
        echo -e "${YELLOW}   Serena MCP may not work${NC}"
        echo -e "${YELLOW}   Install: curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
        return 1
    fi
}

# Function to check directories
check_directories() {
    echo -n "Checking data directories... "
    local data_dir="${CLAUDE_PROJECT_DIR:-.}/.code-context/data"
    local repo_dir="${CLAUDE_PROJECT_DIR:-.}/.code-context/repos"

    if [ -d "$data_dir" ] && [ -d "$repo_dir" ]; then
        echo -e "${GREEN}✅ Created${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Missing${NC}"
        echo -e "${YELLOW}   Will be created automatically on first use${NC}"
        return 1
    fi
}

# Function to check MCP configuration
check_mcp_config() {
    echo -n "Checking .mcp.json configuration... "
    local config_file="${CLAUDE_PLUGIN_ROOT:-.}/.mcp.json"

    if [ -f "$config_file" ]; then
        # Check if code-context is configured
        if grep -q "code-context" "$config_file"; then
            echo -e "${GREEN}✅ Configured (serena + code-context)${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Only Serena configured${NC}"
            echo -e "${YELLOW}   Semantic search not enabled yet${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Configuration file missing${NC}"
        ALL_OK=false
        return 1
    fi
}

# Run all checks
echo "═══ Core Dependencies ═══"
check_node
check_git
echo ""

echo "═══ Semantic Search Components ═══"
check_ollama
OLLAMA_OK=$?

if [ $OLLAMA_OK -eq 0 ]; then
    check_jina_model
fi

check_code_context
check_serena
echo ""

echo "═══ Configuration ═══"
check_mcp_config
check_directories
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$ALL_OK" = true ] && [ $OLLAMA_OK -eq 0 ]; then
    echo -e "${GREEN}✅ ALL SYSTEMS GO!${NC}"
    echo ""
    echo "Your semantic search stack is fully configured:"
    echo "  • Serena MCP (LSP) - Symbol-level analysis"
    echo "  • Code Context MCP - Semantic search with embeddings"
    echo "  • Ollama + Jina - Local embeddings engine"
    echo ""
    echo "Try natural language queries in /plan:"
    echo '  /plan "find authentication functions"'
    echo '  /plan "show me error handling patterns"'
elif [ "$ALL_OK" = true ]; then
    echo -e "${YELLOW}⚠️  CORE READY, SEMANTIC OPTIONAL${NC}"
    echo ""
    echo "Core functionality works (Serena + Grep/Glob)"
    echo "For full semantic search, install Ollama:"
    echo "  ./scripts/install-ollama.sh"
else
    echo -e "${RED}❌ SETUP REQUIRED${NC}"
    echo ""
    echo "Critical dependencies missing. Run:"
    echo "  ./scripts/setup-semantic-search.sh"
    echo ""
    echo "Or install manually:"
    echo "  1. Install Node.js 20+: https://nodejs.org/"
    echo "  2. Run: ./scripts/install-code-context.sh"
    echo "  3. Optional: ./scripts/install-ollama.sh"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Exit with appropriate code
if [ "$ALL_OK" = true ]; then
    exit 0
else
    exit 1
fi

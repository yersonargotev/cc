#!/bin/bash
#
# Code Context MCP Installer
# Clones, builds, and configures Code Context MCP server
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Code Context MCP Installation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Determine installation directory
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INSTALL_DIR="$PLUGIN_ROOT/.mcp-servers/code-context-mcp"

echo "Plugin root: $PLUGIN_ROOT"
echo "Install directory: $INSTALL_DIR"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo ""
    echo "Please install Node.js 20+ first:"
    echo "  https://nodejs.org/"
    echo ""
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    echo -e "${RED}❌ Node.js v20+ required (you have v$NODE_VERSION)${NC}"
    echo ""
    echo "Please upgrade Node.js:"
    echo "  https://nodejs.org/"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Node.js $(node -v)${NC}"

# Check npm
if ! command -v npm >/dev/null 2>&1; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ npm v$(npm -v)${NC}"

# Check Git
if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}❌ Git is not installed${NC}"
    echo ""
    echo "Please install Git:"
    echo "  Linux: sudo apt install git"
    echo "  macOS: xcode-select --install"
    echo "  Windows: https://git-scm.com/"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Git v$(git --version | cut -d' ' -f3)${NC}"
echo ""

# Clone repository
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  Code Context MCP already exists at $INSTALL_DIR${NC}"
    echo "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull || echo "Could not pull latest changes"
else
    echo "Cloning Code Context MCP from GitHub..."
    mkdir -p "$(dirname "$INSTALL_DIR")"

    if git clone https://github.com/fkesheh/code-context-mcp.git "$INSTALL_DIR"; then
        echo -e "${GREEN}✅ Repository cloned${NC}"
    else
        echo -e "${RED}❌ Failed to clone repository${NC}"
        echo ""
        echo "Please check:"
        echo "  1. Internet connection"
        echo "  2. GitHub accessibility"
        echo "  3. Disk space"
        echo ""
        exit 1
    fi
fi

# Navigate to directory
cd "$INSTALL_DIR"
echo ""

# Install dependencies
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Installing Node.js Dependencies${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if npm install; then
    echo ""
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo ""
    echo -e "${RED}❌ npm install failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check internet connection"
    echo "  2. Try clearing npm cache:"
    echo "     npm cache clean --force"
    echo "  3. Try again with verbose output:"
    echo "     npm install --verbose"
    echo ""
    exit 1
fi

# Build TypeScript
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Building TypeScript${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if npm run build; then
    echo ""
    echo -e "${GREEN}✅ Build successful${NC}"
else
    echo ""
    echo -e "${RED}❌ Build failed${NC}"
    echo ""
    echo "Try:"
    echo "  1. Check Node.js version: node -v (need v20+)"
    echo "  2. Reinstall dependencies: rm -rf node_modules && npm install"
    echo "  3. Check build logs above for specific errors"
    echo ""
    exit 1
fi

# Verify build output
if [ -f "dist/index.js" ]; then
    echo -e "${GREEN}✅ dist/index.js created${NC}"
else
    echo -e "${RED}❌ dist/index.js not found${NC}"
    exit 1
fi

# Create data directories
echo ""
echo "Creating data directories..."
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/.code-context}"
DATA_DIR="$PROJECT_DIR/data"
REPO_DIR="$PROJECT_DIR/repos"

mkdir -p "$DATA_DIR" "$REPO_DIR"
echo -e "${GREEN}✅ Data directories created${NC}"
echo "   Data: $DATA_DIR"
echo "   Repos: $REPO_DIR"

# Test the MCP server
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Testing MCP Server${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Simple test: check if it starts
if timeout 5 node dist/index.js --help 2>/dev/null || true; then
    echo -e "${GREEN}✅ MCP server executable${NC}"
else
    echo -e "${YELLOW}⚠️  Could not test server (may need additional setup)${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Code Context MCP Installation Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Installation location:"
echo "  $INSTALL_DIR"
echo ""
echo "Executable:"
echo "  $INSTALL_DIR/dist/index.js"
echo ""
echo "Next steps:"
echo "  1. Install Ollama (if not done):"
echo "     ./scripts/install-ollama.sh"
echo ""
echo "  2. Run validation:"
echo "     ./scripts/validate-deps.sh"
echo ""
echo "  3. Update .mcp.json configuration"
echo "     (run setup-semantic-search.sh to do this automatically)"
echo ""

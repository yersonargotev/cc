#!/bin/bash
#
# Ollama Installation Helper
# Platform-specific Ollama installation with automatic model download
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Ollama Installation for Semantic Search${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if Ollama is already installed
if command -v ollama >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama is already installed!${NC}"
    ollama --version
    echo ""
else
    echo "Detecting operating system..."
    echo ""

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${BLUE}Platform: Linux${NC}"
        echo "Installing Ollama via official script..."
        echo ""

        # Download and run official installer
        if curl -fsSL https://ollama.com/install.sh | sh; then
            echo ""
            echo -e "${GREEN}✅ Ollama installed successfully!${NC}"
        else
            echo ""
            echo -e "${RED}❌ Installation failed${NC}"
            echo ""
            echo "Manual installation options:"
            echo "  1. Try again: curl -fsSL https://ollama.com/install.sh | sh"
            echo "  2. Download from: https://ollama.com/download/linux"
            echo ""
            exit 1
        fi

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}Platform: macOS${NC}"
        echo ""
        echo "Ollama for macOS requires manual installation."
        echo ""
        echo -e "${YELLOW}Please download and install Ollama:${NC}"
        echo "  1. Visit: https://ollama.com/download/mac"
        echo "  2. Download Ollama.app"
        echo "  3. Move to Applications folder"
        echo "  4. Open Ollama to start the service"
        echo ""
        echo "After installation, run this script again to download models."
        echo ""
        exit 1

    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo -e "${BLUE}Platform: Windows${NC}"
        echo ""
        echo "Ollama for Windows requires manual installation."
        echo ""
        echo -e "${YELLOW}Please download and install Ollama:${NC}"
        echo "  1. Visit: https://ollama.com/download/windows"
        echo "  2. Download OllamaSetup.exe"
        echo "  3. Run the installer"
        echo "  4. Ollama will start automatically"
        echo ""
        echo "After installation, run this script again to download models."
        echo ""
        exit 1

    else
        echo -e "${RED}❌ Unsupported operating system: $OSTYPE${NC}"
        echo ""
        echo "Please visit https://ollama.com/download for manual installation."
        echo ""
        exit 1
    fi
fi

# Wait for Ollama service to start
echo ""
echo "Waiting for Ollama service to start..."
sleep 3

# Check if service is running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    # Try to start service
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl start ollama || true
    else
        # Start in background if systemctl not available
        ollama serve > /dev/null 2>&1 &
        sleep 5
    fi
fi

# Pull Jina embeddings model
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Downloading Jina Embeddings Model${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Model: unclemusclez/jina-embeddings-v2-base-code"
echo "Size: ~300MB (optimized for code)"
echo ""
echo "This may take a few minutes..."
echo ""

if ollama pull unclemusclez/jina-embeddings-v2-base-code; then
    echo ""
    echo -e "${GREEN}✅ Jina model downloaded successfully!${NC}"
else
    echo ""
    echo -e "${RED}❌ Failed to download Jina model${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check internet connection"
    echo "  2. Verify Ollama service is running:"
    echo "     ollama list"
    echo "  3. Try manual pull:"
    echo "     ollama pull unclemusclez/jina-embeddings-v2-base-code"
    echo ""
    exit 1
fi

# Verify installation
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Installation Verification${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Installed models:"
ollama list
echo ""

echo -e "${GREEN}✅ Ollama setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Install Code Context MCP:"
echo "     ./scripts/install-code-context.sh"
echo ""
echo "  2. Run full validation:"
echo "     ./scripts/validate-deps.sh"
echo ""
echo "  3. Or run complete setup:"
echo "     ./scripts/setup-semantic-search.sh"
echo ""

# Troubleshooting Guide - Semantic Search v3.0.0

Common issues and solutions for semantic search setup.

---

## Quick Diagnosis

Run the validation command first:

```bash
/validate-semantic-search
```

This will show exactly what's missing or misconfigured.

---

## Common Issues

### 1. "Ollama not found"

**Symptom:**
```
Checking Ollama... ❌ Not installed
```

**Solutions:**

**Linux:**
```bash
# Automated installation
./scripts/install-ollama.sh

# Or manual:
curl -fsSL https://ollama.com/install.sh | sh
```

**macOS:**
1. Download from: https://ollama.com/download/mac
2. Move Ollama.app to Applications
3. Open Ollama (starts service)
4. Verify: `ollama --version`

**Windows:**
1. Download from: https://ollama.com/download/windows
2. Run OllamaSetup.exe
3. Ollama starts automatically
4. Verify: `ollama --version`

---

### 2. "Jina model not downloaded"

**Symptom:**
```
Checking Jina embeddings model... ❌ Not downloaded
```

**Solution:**
```bash
# Pull the model
ollama pull unclemusclez/jina-embeddings-v2-base-code

# Verify
ollama list | grep jina
```

**If pull fails:**
```bash
# Check Ollama service is running
pgrep ollama

# If not running (Linux):
sudo systemctl start ollama

# Or start manually:
ollama serve
```

**Network timeout:**
```bash
# Try with longer timeout
OLLAMA_TIMEOUT=600 ollama pull unclemusclez/jina-embeddings-v2-base-code
```

---

### 3. "Code Context MCP not installed"

**Symptom:**
```
Checking Code Context MCP... ❌ Not installed
```

**Solution:**
```bash
# Run installer
./scripts/install-code-context.sh

# Or manual:
cd ${CLAUDE_PLUGIN_ROOT}
mkdir -p .mcp-servers
cd .mcp-servers
git clone https://github.com/fkesheh/code-context-mcp.git
cd code-context-mcp
npm install
npm run build
```

**If npm install fails:**
```bash
# Clear cache and retry
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

**If build fails:**
```bash
# Check Node.js version
node -v  # Must be v20+

# Reinstall dependencies
rm -rf node_modules
npm install
npm run build
```

---

### 4. "Node.js version too old"

**Symptom:**
```
❌ Node.js v18.x.x is too old (need v20+)
```

**Solution:**

**Using nvm (recommended):**
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node.js 20
nvm install 20
nvm use 20
nvm alias default 20

# Verify
node -v  # Should show v20.x.x
```

**Direct installation:**
- Visit: https://nodejs.org/
- Download LTS version (v20+)
- Install and verify: `node -v`

---

### 5. "Permission denied" errors

**Symptom:**
```
npm ERR! code EACCES
npm ERR! syscall mkdir
npm ERR! path /usr/local/lib/node_modules
npm ERR! errno -13
npm ERR! Error: EACCES: permission denied
```

**Solutions:**

**Option 1: Fix npm permissions (recommended):**
```bash
# Create npm directory in home
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'

# Add to PATH
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Retry installation
./scripts/install-code-context.sh
```

**Option 2: Use sudo (not recommended):**
```bash
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) /usr/local/lib/node_modules
```

---

### 6. "Git clone failed"

**Symptom:**
```
fatal: unable to access 'https://github.com/fkesheh/code-context-mcp.git/':
Could not resolve host: github.com
```

**Solutions:**

**Check internet connection:**
```bash
ping github.com
```

**Check DNS:**
```bash
# Try alternate DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

**Use SSH instead of HTTPS:**
```bash
# If you have SSH keys configured
git clone git@github.com:fkesheh/code-context-mcp.git
```

**Manual download:**
1. Visit: https://github.com/fkesheh/code-context-mcp
2. Click "Code" → "Download ZIP"
3. Extract to `${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp`
4. Run: `npm install && npm run build`

---

### 7. ".mcp.json configuration missing"

**Symptom:**
```
Checking .mcp.json configuration... ❌ Configuration file missing
```

**Solution:**

Create `.mcp.json` in plugin root:

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

### 8. "Ollama service not running"

**Symptom:**
```
Checking Ollama... ✅ v0.1.44
   Service: Not running
```

**Solutions:**

**Linux (systemd):**
```bash
# Start service
sudo systemctl start ollama

# Enable on boot
sudo systemctl enable ollama

# Check status
sudo systemctl status ollama
```

**Linux (manual):**
```bash
# Start in background
ollama serve > /dev/null 2>&1 &

# Verify
pgrep ollama
```

**macOS:**
```bash
# Open Ollama.app
open /Applications/Ollama.app

# Or from terminal
ollama serve
```

**Windows:**
```
# Ollama should start automatically
# If not, search for "Ollama" in Start menu and run it
```

---

### 9. "MCP server not loading in Claude Code"

**Symptom:**
- Setup validation passes
- But semantic search doesn't work in Claude Code

**Solutions:**

**1. Restart Claude Code:**
```
MCP servers only load on startup.
Completely quit and relaunch Claude Code.
```

**2. Check MCP configuration path:**
```bash
# Verify .mcp.json exists
ls -la ${CLAUDE_PLUGIN_ROOT}/.mcp.json

# Check plugin.json points to it
cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json | grep mcpServers
```

**3. Check MCP server logs:**
```bash
# Look for errors in Claude Code output
# Usually in: ~/.claude/logs/ or similar
```

**4. Test MCP server manually:**
```bash
# Test Code Context MCP
cd ${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp
DATA_DIR=/tmp/test REPO_CACHE_DIR=/tmp/repos node dist/index.js
```

---

### 10. "Semantic search queries return no results"

**Symptom:**
- Setup complete
- But queries return empty results

**Solutions:**

**1. Check if project is indexed:**
```bash
# Code Context needs to index your project first
# This happens automatically on first query
# Check index files:
ls -la ${CLAUDE_PROJECT_DIR}/.code-context/data/
```

**2. Verify Ollama is responding:**
```bash
# Test embeddings
ollama run unclemusclez/jina-embeddings-v2-base-code "test query"
```

**3. Check query syntax:**
```bash
# Natural language works best
Good: /plan "find authentication code"
Bad: /plan "grep auth"

# Conceptual queries need semantic search
# Exact symbols can use Serena MCP
```

**4. Review code-search-agent logs:**
```
Check Claude Code output for routing decisions
Should show which tool was used (Serena vs Code Context)
```

---

### 11. "npm install fails with network timeout"

**Symptom:**
```
npm ERR! network request to https://registry.npmjs.org/... failed
npm ERR! network This is a problem related to network connectivity
```

**Solutions:**

**Increase timeout:**
```bash
npm config set fetch-timeout 60000
npm config set fetch-retries 5
npm install
```

**Use different registry:**
```bash
# Try npm mirror
npm config set registry https://registry.npm.taobao.org
npm install

# Reset to default after
npm config set registry https://registry.npmjs.org
```

**Clear cache and retry:**
```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

---

### 12. "uv/uvx not found" (Serena MCP)

**Symptom:**
```
Checking Serena MCP (LSP)... ⚠️  uv/uvx not found
```

**Solution:**
```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or via pip
pip install uv

# Verify
uv --version
```

**Note:** Serena MCP is optional but recommended for symbol-level analysis.

---

## Platform-Specific Issues

### Linux-Specific

**Issue: Ollama installation script fails**
```bash
# May need curl first
sudo apt-get update
sudo apt-get install curl

# Then retry
curl -fsSL https://ollama.com/install.sh | sh
```

**Issue: Systemd service fails**
```bash
# Check journal logs
journalctl -u ollama -n 50

# Manual start
ollama serve
```

### macOS-Specific

**Issue: Ollama.app won't open**
```bash
# Remove from quarantine
xattr -d com.apple.quarantine /Applications/Ollama.app

# Or allow in Security & Privacy settings
```

**Issue: Node.js not in PATH after install**
```bash
# Add to PATH
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Windows-Specific

**Issue: Scripts won't run**
```
Use Git Bash or WSL for running shell scripts.
Or run setup from Claude Code directly: /setup-semantic-search
```

**Issue: Ollama service not starting**
```
Check Windows Services:
1. Press Win+R
2. Type: services.msc
3. Find "Ollama" service
4. Right-click → Start
```

---

## Performance Issues

### Slow indexing

**If initial indexing takes >10 minutes:**

```bash
# Check available RAM
free -h  # Linux
top      # macOS

# Reduce batch size (edit Code Context config)
# Or index smaller directories first
```

### High memory usage

**If Ollama uses too much RAM:**

```bash
# Limit Ollama memory (edit systemd service)
sudo systemctl edit ollama

# Add:
[Service]
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
```

### Slow queries

**If queries take >10 seconds:**

```bash
# Check if Ollama is swapping
# Reduce model size or increase RAM

# Check index size
du -sh ${CLAUDE_PROJECT_DIR}/.code-context/

# Rebuild index if corrupted
rm -rf ${CLAUDE_PROJECT_DIR}/.code-context/
# Re-query to rebuild
```

---

## Getting Help

If none of these solutions work:

1. **Run full validation:**
   ```bash
   ./scripts/validate-deps.sh > validation-output.txt
   ```

2. **Check logs:**
   ```bash
   # Claude Code logs
   ls -la ~/.claude/logs/

   # Ollama logs
   journalctl -u ollama -n 100  # Linux
   ```

3. **Create GitHub issue:**
   - Repository: https://github.com/yersonargotev/cc-mkp
   - Include validation output
   - Include relevant logs
   - Describe what you tried

4. **Workaround:**
   ```bash
   # Revert to core functionality (Serena + Grep)
   # Remove "code-context" from .mcp.json
   # Plugin still works without semantic search
   ```

---

## Clean Reinstall

If all else fails, try clean reinstall:

```bash
# 1. Remove everything
rm -rf ${CLAUDE_PLUGIN_ROOT}/.mcp-servers/code-context-mcp
rm -rf ${CLAUDE_PROJECT_DIR}/.code-context

# 2. Uninstall Ollama (see Uninstallation section)

# 3. Clear npm cache
npm cache clean --force

# 4. Start fresh
./scripts/setup-semantic-search.sh
```

---

**Troubleshooting Guide v3.0.0** | Last updated: November 14, 2025

For more help, see:
- `docs/SETUP_GUIDE.md` - Installation instructions
- `SEMANTIC_SEARCH_RESEARCH.md` - Technical details
- `SEMANTIC_SEARCH_IMPLEMENTATION_PLAN.md` - Architecture

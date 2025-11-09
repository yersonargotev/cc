# MCP Configuration Examples

This directory contains example MCP (Model Context Protocol) server configurations for enhanced `/explore` capabilities.

## Overview

The `/explore` command works out-of-the-box with Claude Code's native tools (WebSearch, WebFetch, Glob, Grep). However, you can optionally enhance it with MCP servers for additional capabilities.

## Available MCP Servers

### 1. Brave Search MCP (Recommended)

**Purpose**: Enhanced web search with privacy-focused Brave Search API

**Benefits**:
- Independent web index (not just Google/Bing)
- Privacy-focused
- 2,000 queries/month free tier
- 1 query per second throughput

**Setup**:

1. Get API key:
   - Sign up at https://brave.com/search/api/
   - Free tier: 2,000 queries/month
   - Paid: $3/1,000 queries for higher capacity

2. Add to `.claude/mcp.json` in your project:
   ```bash
   cp cc/mcp-examples/brave-search.json .claude/mcp.json
   ```

3. Set environment variable:
   ```bash
   export BRAVE_API_KEY="your-api-key-here"
   # Or add to your shell profile (.bashrc, .zshrc, etc.)
   ```

4. Restart Claude Code

**Usage**: The `web-research-agent` will automatically use Brave Search when available.

---

### 2. Claude Context MCP (Advanced)

**Purpose**: Semantic code search for large codebases

**Benefits**:
- Semantic search: "find functions that handle authentication"
- Hybrid search: BM25 (keyword) + dense vector (meaning)
- ~40% token reduction vs traditional search
- Supports multiple languages: TypeScript, JavaScript, Python, Java, C++, Go, Rust, etc.

**Requirements**:
- OpenAI API key (for embeddings)
- Milvus or Zilliz Cloud account (vector database)

**Setup**:

1. Get API keys:
   - OpenAI API: https://platform.openai.com/api-keys
   - Zilliz Cloud: https://cloud.zilliz.com/ (free tier available)

2. Add to `.claude/mcp.json` in your project:
   ```bash
   cp cc/mcp-examples/claude-context.json .claude/mcp.json
   ```

3. Set environment variables:
   ```bash
   export OPENAI_API_KEY="your-openai-key"
   export MILVUS_TOKEN="your-zilliz-token"
   ```

4. Index your codebase (one-time):
   ```bash
   npx @zilliz/claude-context-mcp index
   ```

5. Restart Claude Code

**Usage**: The `code-search-agent` will automatically use semantic search when available.

---

### 3. Combined Configuration

You can use both MCP servers together:

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    },
    "claude-context": {
      "command": "npx",
      "args": ["@zilliz/claude-context-mcp@latest"],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}",
        "MILVUS_TOKEN": "${MILVUS_TOKEN}"
      }
    }
  }
}
```

## Configuration Locations

### Project-level (Recommended)
`.claude/mcp.json` in your project root
- Scoped to this project only
- Can be version-controlled (without secrets)
- Shared with team

### User-level (Global)
`~/.claude/mcp.json`
- Applies to all projects
- Personal configuration
- Not version-controlled

**Best Practice**: Use project-level configuration with environment variables for API keys.

## Environment Variables

Store API keys as environment variables for security:

```bash
# In your shell profile (.bashrc, .zshrc, etc.)
export BRAVE_API_KEY="your-brave-api-key"
export OPENAI_API_KEY="your-openai-api-key"
export MILVUS_TOKEN="your-zilliz-token"
```

## Graceful Degradation

The `/explore` command works without any MCP configuration:

- **Without MCP**:
  - Web research uses native WebSearch/WebFetch
  - Code search uses traditional Glob/Grep
  - Full functionality, no setup required

- **With Brave Search MCP**:
  - Enhanced web search results
  - Privacy-focused engine
  - Additional search capacity

- **With Claude Context MCP**:
  - Semantic code search
  - Better relevance for large codebases
  - ~40% token savings

## Troubleshooting

### MCP Server Not Loading

1. Check `.claude/mcp.json` syntax (valid JSON)
2. Verify environment variables are set:
   ```bash
   echo $BRAVE_API_KEY
   echo $OPENAI_API_KEY
   ```
3. Restart Claude Code after changes
4. Check Claude Code logs for errors

### API Rate Limits

**Brave Search**:
- Free: 2,000 queries/month, 1 req/s
- If exceeded: Falls back to native WebSearch

**OpenAI (for Claude Context)**:
- Depends on your plan
- Embeddings are cached after first indexing
- Re-indexing only needed when code changes significantly

### MCP Not Working

The `/explore` command will continue to work with native tools if MCP fails:
- Check error messages
- Verify API keys
- Ensure MCP servers are installed (npx handles this automatically)
- Try disabling MCP temporarily to isolate the issue

## Cost Considerations

### Free Tier Options

- **Brave Search**: 2,000 queries/month free
- **Zilliz Cloud**: Free tier available for small projects
- **OpenAI**: Pay-per-use (embeddings are one-time cost per code change)

### Estimated Costs

**Brave Search**:
- Free tier usually sufficient for most development workflows
- Paid: $3 per 1,000 additional queries

**Claude Context** (one-time indexing + updates):
- Small project (10K LOC): ~$0.50-1 for initial indexing
- Medium project (100K LOC): ~$2-5 for initial indexing
- Updates: Incremental, much cheaper than full re-index

**Note**: You only pay for what you use. MCP is optional, not required.

## Alternative MCP Servers

### DuckDuckGo Search

Free alternative to Brave Search:

```json
{
  "mcpServers": {
    "duckduckgo": {
      "command": "npx",
      "args": ["-y", "duckduckgo-mcp-server"]
    }
  }
}
```

No API key required, but lower query limits (15,000/month, 1 req/s).

### Tavily Search

AI-optimized search engine:

```json
{
  "mcpServers": {
    "tavily": {
      "command": "npx",
      "args": ["-y", "@tavily/mcp-server"],
      "env": {
        "TAVILY_API_KEY": "${TAVILY_API_KEY}"
      }
    }
  }
}
```

Requires API key. Good for professional use cases.

## Further Reading

- **MCP Documentation**: https://docs.claude.com/en/docs/mcp
- **Brave Search API**: https://brave.com/search/api/
- **Claude Context**: https://github.com/zilliztech/claude-context
- **MCP Server Registry**: https://github.com/modelcontextprotocol/servers

## Questions?

For MCP-specific issues:
- Check Claude Code docs: https://docs.claude.com/en/docs/claude-code
- MCP Community: https://www.claudemcp.com/

For CC workflow issues:
- See main README
- Check CLAUDE.md for project guidelines

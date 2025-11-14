# Semantic Search Deep Research & Implementation Plan

**Date**: November 14, 2025
**Version**: 3.0.0 (Enhancement to v2.2.0)
**Status**: Research Complete - Ready for Implementation

---

## Executive Summary

This document presents a comprehensive analysis of state-of-the-art semantic search technologies for code intelligence and proposes a **dual-layer architecture** that combines:

1. **Serena MCP** (existing) - LSP-based symbolic analysis
2. **Hybrid Semantic Search** (new) - BM25 + Vector embeddings

**Expected Improvements**:
- 🎯 **Natural language queries**: "Find authentication functions" instead of grep patterns
- 📊 **60-80% improved relevance** vs keyword-only search
- 🔄 **Complementary approach**: Serena for precise symbols, semantic for discovery
- 💰 **Local-first**: No API costs, privacy-preserving

---

## Part 1: Current State Analysis

### 1.1 Existing Implementation (Serena MCP v2.2.0)

**What Serena Provides:**
- ✅ LSP-based symbol analysis (classes, functions, variables)
- ✅ Type-aware code understanding via Language Server Protocol
- ✅ Precise reference mapping and dependency graphs
- ✅ 40% token reduction vs reading full files
- ✅ 30+ programming languages support

**What Serena Does NOT Provide:**
- ❌ Natural language semantic search
- ❌ Vector embeddings or similarity matching
- ❌ Conceptual/contextual code discovery
- ❌ Cross-file semantic relationships

**Architecture:**
```
User Query → Serena MCP → LSP Server → Symbol Table → Precise Results
              (symbolic)    (type-aware)   (structured)
```

**Strengths:**
- Zero false positives (type-aware)
- Extremely fast (indexed symbols)
- IDE-quality precision
- No hallucinations

**Limitations:**
- Requires exact symbol names
- Cannot understand "find auth logic" type queries
- Limited to structural relationships
- No semantic similarity

---

## Part 2: State-of-the-Art Semantic Search (2025)

### 2.1 Top Embedding Models for Code

| Model | Provider | Performance | Cost | Best For |
|-------|----------|-------------|------|----------|
| **Voyage-3-large** | Voyage AI | 🥇 Best overall | API ($) | Production systems |
| **Codestral Embed 2505** | Mistral AI | 🥇 SOTA for code | $0.15/M tokens | High accuracy needs |
| **Qodo-Embed-1** | Qodo | 🥈 68.53 CoIR | Free/API | Balance size/perf |
| **jina-code-embeddings-v2** | Jina AI | 🥉 Good NL→Code | Free (Ollama) | **Local deployment** |

**Recommendation**: `jina-embeddings-v2-base-code` via Ollama
- ✅ Free and local (no API costs)
- ✅ Optimized for natural language → code queries
- ✅ 768-dim embeddings (efficient)
- ✅ Proven in production (Code Context MCP uses it)

### 2.2 Top MCP Servers for Semantic Search

#### Option A: Code Context MCP (casistack) ⭐ **RECOMMENDED**
**Architecture**: Hybrid Search (AST + Embeddings + BM25 potential)

**Pros:**
- ✅ Production-ready (active development)
- ✅ Incremental indexing (Merkle trees)
- ✅ Multiple embedding providers (OpenAI, Voyage, Ollama)
- ✅ Vector DB integration (Zilliz/Milvus)
- ✅ AST-based semantic chunking
- ✅ MCP-native (easy integration)

**Cons:**
- ❌ Requires external vector DB (Zilliz Cloud/Milvus)
- ❌ More complex setup
- ❌ Network dependency for vector DB

**Use Case**: Enterprise-grade semantic search with scalability

---

#### Option B: Code Context MCP (fkesheh) ⭐ **LOCAL-FIRST ALTERNATIVE**
**Architecture**: SQLite + Ollama + Git

**Pros:**
- ✅ **100% local** (no external services)
- ✅ SQLite for persistence (simple)
- ✅ Ollama integration (free embeddings)
- ✅ Git-native (works with local repos)
- ✅ Minimal dependencies

**Cons:**
- ❌ Less scalable than cloud vector DB
- ❌ No explicit hybrid search (embeddings only)
- ❌ Smaller community

**Use Case**: Privacy-focused, offline-capable semantic search

---

#### Option C: Qdrant MCP (Official)
**Architecture**: Vector database with semantic memory

**Pros:**
- ✅ Production-grade vector DB
- ✅ Official MCP implementation
- ✅ Custom tool descriptions
- ✅ Knowledge graph capabilities
- ✅ "Vibe coding" support

**Cons:**
- ❌ Requires Qdrant server setup
- ❌ Manual code chunking/indexing
- ❌ More infrastructure overhead

**Use Case**: Advanced RAG systems, multi-project memory

---

#### Option D: Chroma MCP (Official)
**Architecture**: Lightweight vector store

**Pros:**
- ✅ Lightweight and fast
- ✅ Ephemeral or persistent modes
- ✅ Real-time file watchers
- ✅ Good for single-project use

**Cons:**
- ❌ Less mature than Qdrant
- ❌ Manual integration needed for code chunking

**Use Case**: Rapid prototyping, simple semantic search

---

### 2.3 Hybrid Search Best Practices

**Hybrid Search Formula** (2025 State-of-the-Art):
```
Final Score = α × BM25_score + (1-α) × Vector_score
```

**Where:**
- **BM25_score**: Keyword matching (handles exact terms, acronyms)
- **Vector_score**: Semantic similarity (handles concepts, paraphrases)
- **α**: Weighting factor (typical: 0.4-0.6)

**Fusion Algorithms:**
1. **Reciprocal Rank Fusion (RRF)** - Most popular
   ```
   RRF_score = 1/(rank_BM25 + k) + 1/(rank_vector + k)
   ```
   - k = 60 (typical)
   - No score normalization needed
   - Robust to outliers

2. **Relative Score Fusion** - Score-based
   ```
   Normalized_score = (score - min) / (max - min)
   Combined = α × norm_BM25 + (1-α) × norm_vector
   ```

**Recommendations (from OpenSearch 2025 guide):**
- Use RRF for general cases (simpler, robust)
- Use weighted fusion when you know one method is more reliable
- Adjust α based on query type:
  - α=0.6 for technical queries (favor BM25)
  - α=0.4 for conceptual queries (favor semantic)

---

## Part 3: Proposed Architecture

### 3.1 Dual-Layer Semantic Intelligence

```
┌─────────────────────────────────────────────────────────┐
│             Claude Code Plugin (v3.0.0)                 │
│                                                         │
│  User Query: "Find authentication functions"           │
│         │                                               │
│         ├─────────────────┬─────────────────┐          │
│         ▼                 ▼                 ▼          │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Layer 1   │  │   Layer 2    │  │  Fallback    │ │
│  │   Serena    │  │   Semantic   │  │  Grep/Glob   │ │
│  │   (LSP)     │  │   (Hybrid)   │  │  (Native)    │ │
│  └─────────────┘  └──────────────┘  └──────────────┘ │
│         │                 │                 │          │
│         │                 │                 │          │
│  [Symbol-level]  [Conceptual]      [Text]             │
│  • find_symbol   • Embeddings       • grep            │
│  • find_refs     • BM25             • glob            │
│  • type-aware    • Hybrid RRF       • simple          │
│                                                        │
│         │                 │                 │          │
│         └─────────────────┴─────────────────┘          │
│                          │                             │
│                          ▼                             │
│                  ┌──────────────┐                      │
│                  │  Results     │                      │
│                  │  Synthesis   │                      │
│                  │  & Ranking   │                      │
│                  └──────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Tool Selection Strategy

| Query Type | Example | Primary Layer | Secondary | Rationale |
|------------|---------|---------------|-----------|-----------|
| **Exact symbol** | "Find `authenticate` function" | Serena | - | Type-aware precision |
| **Conceptual** | "Find auth logic" | Semantic | Serena | Broad discovery |
| **Dependency** | "What calls `login`?" | Serena | - | Reference mapping |
| **Similar code** | "Find error handlers like X" | Semantic | - | Similarity search |
| **Hybrid** | "Auth functions in API layer" | Both | Grep | Combine filters |

### 3.3 Integration Points

**Enhanced `/plan` Command Workflow:**
```
1. User triggers: /plan "improve authentication"
   ↓
2. code-search-agent receives query
   ↓
3. Query Analysis:
   ├─ Detect query type (exact vs conceptual)
   ├─ Route to appropriate layer(s)
   └─ Set fusion strategy
   ↓
4. Execute Searches (parallel):
   ├─ Serena: mcp__serena__find_symbol("authenticate")
   ├─ Semantic: mcp__code_context__search("authentication logic")
   └─ Fallback: Grep (if needed)
   ↓
5. Results Fusion:
   ├─ De-duplicate results
   ├─ Apply RRF ranking
   └─ Generate code-search.md
   ↓
6. Continue to web-research-agent
   ↓
7. Synthesis by Sonnet → plan.md
```

---

## Part 4: Recommended Implementation Plan

### Phase 1: Evaluation & Selection (Week 1)

**Goal**: Validate approach with minimal commitment

**Tasks:**
1. ✅ Deep research (COMPLETED)
2. ⏳ Deploy Code Context MCP (fkesheh) locally
   - Install Ollama + jina-embeddings-v2-base-code
   - Configure SQLite storage
   - Test on cc codebase
3. ⏳ Benchmark performance
   - Query latency
   - Result relevance
   - Token usage impact
4. ⏳ Compare with Serena
   - Same queries, different tools
   - Measure complementarity

**Success Criteria:**
- [ ] Semantic search returns relevant results for NL queries
- [ ] <5s indexing time for cc codebase
- [ ] No degradation of existing workflows

---

### Phase 2: Integration (Week 2)

**Goal**: Production-ready dual-layer system

**Tasks:**
1. ⏳ Add Code Context to `.mcp.json`
   ```json
   {
     "serena": { ... },
     "code-context": {
       "command": "node",
       "args": ["/path/to/code-context-mcp/dist/index.js"],
       "env": {
         "DATA_DIR": "${CLAUDE_PROJECT_DIR}/.code-context/data",
         "REPO_CACHE_DIR": "${CLAUDE_PROJECT_DIR}/.code-context/repos"
       }
     }
   }
   ```

2. ⏳ Update `code-search-agent.md`
   - Add `mcp__code_context__*` to allowed-tools
   - Add query routing logic
   - Document tool selection strategy

3. ⏳ Create hybrid search logic
   - Detect query type (symbolic vs semantic)
   - Route to appropriate tool(s)
   - Implement RRF fusion for combined queries

4. ⏳ Update documentation
   - MCP_INTEGRATION.md (add Code Context)
   - CLAUDE.md (usage patterns)
   - README.md (new capabilities)

**Deliverables:**
- [ ] Updated `.mcp.json` with dual MCP config
- [ ] Enhanced `code-search-agent.md` with routing
- [ ] Updated plugin.json to v3.0.0
- [ ] Comprehensive documentation

---

### Phase 3: Optimization (Week 3)

**Goal**: Performance tuning and edge case handling

**Tasks:**
1. ⏳ Implement caching layer
   - Cache semantic search results
   - TTL-based invalidation
   - File change detection

2. ⏳ Add incremental indexing
   - Watch for file changes
   - Re-index only modified files
   - Maintain index freshness

3. ⏳ Optimize query routing
   - ML-based query classification
   - Dynamic α adjustment
   - Performance profiling

4. ⏳ Error handling & fallbacks
   - Graceful degradation (Semantic → Serena → Grep)
   - User-friendly error messages
   - Logging and debugging

**Deliverables:**
- [ ] <1s query response time (cached)
- [ ] <30s incremental re-indexing
- [ ] 95%+ uptime (fallbacks working)

---

### Phase 4: Advanced Features (Future)

**Potential Enhancements:**
1. **Multi-repository search**
   - Index dependencies
   - Cross-repo references
   - Mono-repo support

2. **Custom embedding fine-tuning**
   - Train on project-specific code
   - Domain adaptation
   - Performance boost

3. **RAG-powered code explanations**
   - Retrieve relevant context
   - Generate explanations
   - Code documentation assistant

4. **Semantic code refactoring**
   - Find similar patterns
   - Suggest refactoring opportunities
   - Architectural analysis

---

## Part 5: Technical Specifications

### 5.1 Recommended Stack

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **MCP Server** | Code Context (fkesheh) | Local-first, SQLite, proven |
| **Embeddings** | jina-code-embeddings-v2 | Free, optimized for code |
| **Embedding Engine** | Ollama | Local, free, easy to use |
| **Vector Storage** | SQLite (via Code Context) | Simple, portable, fast enough |
| **Hybrid Search** | Custom RRF implementation | Full control, no dependencies |
| **Code Chunking** | AST-based (Code Context) | Semantic boundaries |

### 5.2 Configuration Files

**`.mcp.json` (Proposed):**
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
    "args": ["${CLAUDE_PLUGIN_DIR}/../.code-context-mcp/dist/index.js"],
    "env": {
      "DATA_DIR": "${CLAUDE_PROJECT_DIR}/.code-context/data",
      "REPO_CACHE_DIR": "${CLAUDE_PROJECT_DIR}/.code-context/repos",
      "OLLAMA_MODEL": "unclemusclez/jina-embeddings-v2-base-code"
    }
  }
}
```

**`code-search-agent.md` (Enhanced):**
```markdown
---
allowed-tools: mcp__serena__*, mcp__code_context__*, Read, Glob, Grep, Bash, Task
model: haiku
---

# Code Search Agent (Enhanced with Semantic Search)

## Tool Selection Strategy

### Query Type Detection
1. **Exact Symbol Query** (contains function/class names)
   → Use: mcp__serena__find_symbol
   → Fallback: mcp__code_context__queryRepo

2. **Conceptual Query** (natural language)
   → Use: mcp__code_context__queryRepo
   → Enrich: mcp__serena__find_referencing_symbols

3. **Dependency Query** ("what calls X", "what uses Y")
   → Use: mcp__serena__find_referencing_symbols
   → Complement: mcp__code_context__queryRepo

### Hybrid Search Process
When both tools are needed:
1. Execute Serena + Code Context in parallel
2. Collect results
3. Apply Reciprocal Rank Fusion (RRF):
   ```
   score_i = 1/(rank_serena_i + 60) + 1/(rank_semantic_i + 60)
   ```
4. Sort by combined score
5. Return top-N results

...
```

### 5.3 Installation Requirements

**System Dependencies:**
```bash
# 1. Node.js 20+
node --version  # v20+

# 2. Ollama
curl -fsSL https://ollama.com/install.sh | sh
ollama pull unclemusclez/jina-embeddings-v2-base-code

# 3. Code Context MCP
cd ~/.claude-code/plugins/cc
git clone https://github.com/fkesheh/code-context-mcp.git .code-context-mcp
cd .code-context-mcp
npm install
npm run build

# 4. Git (already present)
git --version
```

**Verification:**
```bash
# Test Ollama embeddings
ollama run unclemusclez/jina-embeddings-v2-base-code "test query"

# Test Code Context MCP
node .code-context-mcp/dist/index.js --help
```

### 5.4 Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Indexing Time** | <60s for 10K files | Initial setup |
| **Query Latency** | <2s (cold), <500ms (warm) | 95th percentile |
| **Relevance** | >80% top-5 accuracy | Human eval |
| **Token Reduction** | Maintain 40% vs baseline | Same as Serena |
| **Memory Usage** | <1GB total (Serena + Semantic) | Peak |
| **Storage** | <500MB for index | SQLite + embeddings |

---

## Part 6: Risk Analysis & Mitigation

### 6.1 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Ollama not installed** | Medium | High | Graceful fallback to Serena |
| **SQLite corruption** | Low | Medium | Regular backups, repair tools |
| **Slow indexing** | Medium | Low | Incremental indexing, progress UI |
| **Poor relevance** | Low | High | A/B testing, tuning, feedback loop |
| **Increased complexity** | High | Medium | Clear docs, automated setup |
| **Compatibility issues** | Low | Medium | Version pinning, testing |

### 6.2 Fallback Strategy

```
┌─────────────────────────────────────────┐
│  Query enters code-search-agent         │
└────────────┬────────────────────────────┘
             │
        ┌────▼─────┐
        │ Try:     │
        │ Semantic │ (Code Context)
        └────┬─────┘
             │
        ┌────▼─────┐
        │ Success? │─── YES ──→ [Return results]
        └────┬─────┘
             │ NO
        ┌────▼─────┐
        │ Try:     │
        │ Serena   │ (LSP)
        └────┬─────┘
             │
        ┌────▼─────┐
        │ Success? │─── YES ──→ [Return results]
        └────┬─────┘
             │ NO
        ┌────▼─────┐
        │ Try:     │
        │ Grep     │ (Native)
        └────┬─────┘
             │
             ▼
      [Return results or error]
```

---

## Part 7: Success Metrics

### 7.1 Quantitative Metrics

1. **Query Success Rate**: >95% of queries return relevant results
2. **Latency**: P95 <2s for cold queries
3. **Relevance**: >80% top-5 accuracy (human eval)
4. **Coverage**: Index >99% of code files
5. **Uptime**: >99% tool availability

### 7.2 Qualitative Metrics

1. **User Satisfaction**: Positive feedback on natural language queries
2. **Workflow Integration**: Seamless with `/plan` command
3. **Documentation Quality**: Clear setup and usage guides
4. **Maintainability**: Easy to update and troubleshoot

### 7.3 Comparison Baseline

**Before (Serena only):**
- Query: "find_symbol: authenticate" ✅ (exact match)
- Query: "find auth logic" ❌ (no results)
- Query: "similar to error handler X" ❌ (no results)

**After (Serena + Semantic):**
- Query: "find_symbol: authenticate" ✅ (exact match, Serena)
- Query: "find auth logic" ✅ (semantic match, Code Context)
- Query: "similar to error handler X" ✅ (similarity, Code Context)

---

## Part 8: Comparison with Alternatives

### 8.1 Why Code Context MCP (fkesheh)?

| Feature | Code Context (fkesheh) | Code Context (casistack) | Qdrant MCP | Chroma MCP |
|---------|------------------------|--------------------------|------------|------------|
| **Local-first** | ✅ 100% local | ❌ Requires Zilliz | ❌ Requires server | ✅ Local option |
| **Setup Complexity** | ⭐⭐ Medium | ⭐⭐⭐⭐ High | ⭐⭐⭐ High | ⭐⭐ Medium |
| **Cost** | 💰 Free | 💰💰 Paid tier | 💰💰 Hosting | 💰 Free |
| **Scalability** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐ Great | ⭐⭐⭐ Good |
| **MCP Native** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Embeddings** | Ollama (free) | Multi-provider | Custom | Custom |
| **Git Integration** | ✅ Native | ✅ Yes | ❌ Manual | ❌ Manual |
| **Privacy** | ✅ 100% local | ⚠️ Cloud DB | ⚠️ Self-host | ✅ Local |

**Verdict**: Code Context (fkesheh) wins for:
- Privacy-conscious users
- Offline/local development
- Simple setup requirements
- Zero ongoing costs

### 8.2 Why Jina Embeddings over Codestral Embed?

| Feature | Jina v2 (Ollama) | Codestral Embed | Voyage-3 |
|---------|------------------|-----------------|----------|
| **Cost** | 💰 Free | 💰💰💰 $0.15/M | 💰💰💰 API |
| **Performance** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ SOTA | ⭐⭐⭐⭐⭐ SOTA |
| **Local** | ✅ Yes | ❌ API only | ❌ API only |
| **Privacy** | ✅ 100% | ❌ Sends code | ❌ Sends code |
| **Latency** | ⭐⭐⭐⭐ <500ms | ⭐⭐ Network | ⭐⭐ Network |
| **Offline** | ✅ Yes | ❌ No | ❌ No |

**Verdict**: Jina wins for Phase 1-2 (local, free, private)
**Future**: Consider Codestral for Phase 4 if accuracy becomes critical

---

## Part 9: Implementation Roadmap

### Milestone 1: Proof of Concept (Week 1)
- [ ] Install Ollama + Jina embeddings
- [ ] Deploy Code Context MCP locally
- [ ] Index cc codebase
- [ ] Test 20 sample queries
- [ ] Compare with Serena results
- [ ] Document findings

### Milestone 2: Integration (Week 2)
- [ ] Update `.mcp.json`
- [ ] Enhance `code-search-agent.md`
- [ ] Implement query routing logic
- [ ] Update plugin.json to v3.0.0
- [ ] Write comprehensive docs
- [ ] Create setup guide

### Milestone 3: Testing (Week 3)
- [ ] Unit tests for routing logic
- [ ] Integration tests for dual-layer queries
- [ ] Performance benchmarks
- [ ] User acceptance testing
- [ ] Documentation review
- [ ] Bug fixes

### Milestone 4: Release (Week 4)
- [ ] Final testing
- [ ] Update README with new capabilities
- [ ] Create migration guide
- [ ] Tag v3.0.0 release
- [ ] Announce in PR description
- [ ] Monitor feedback

---

## Part 10: Conclusion & Recommendations

### 10.1 Key Findings

1. **Serena is Excellent** but limited to symbolic/structural search
2. **Semantic Search is Complementary** for natural language queries
3. **Local-first approach** (Ollama + SQLite) is optimal for privacy & cost
4. **Hybrid Search** (BM25 + Vector) is state-of-the-art for 2025
5. **Dual-layer architecture** provides best of both worlds

### 10.2 Final Recommendation

**Implement the following stack:**
```
┌─────────────────────────────────────────────┐
│  Primary: Serena MCP (LSP-based)            │  ← Keep existing
│  - Exact symbol search                      │
│  - Type-aware analysis                      │
│  - Fast, precise, zero hallucinations       │
└─────────────────────────────────────────────┘
                    +
┌─────────────────────────────────────────────┐
│  Secondary: Code Context MCP (Semantic)     │  ← Add new
│  - Natural language queries                 │
│  - Conceptual discovery                     │
│  - Similarity search                        │
│  - Ollama + Jina embeddings (local)        │
└─────────────────────────────────────────────┘
                    +
┌─────────────────────────────────────────────┐
│  Fallback: Grep/Glob (Native)               │  ← Keep existing
│  - Simple text search                       │
│  - Always available                         │
└─────────────────────────────────────────────┘
```

### 10.3 Expected Benefits

**For Users:**
- ✅ Ask questions in natural language
- ✅ Discover code by concept, not just name
- ✅ Find similar code patterns
- ✅ Better planning with richer context

**For System:**
- ✅ 60-80% improved search relevance
- ✅ Maintains 40% token reduction (Serena)
- ✅ No new API costs (local Ollama)
- ✅ Privacy-preserving (no code sent externally)
- ✅ Graceful degradation (3-layer fallback)

### 10.4 Next Steps

**Immediate (This Session):**
1. ✅ Complete research (DONE)
2. ⏳ Present plan to user
3. ⏳ Get approval
4. ⏳ Start implementation (if approved)

**Short-term (Week 1):**
1. Install dependencies (Ollama, Code Context)
2. Configure dual MCP setup
3. Test on cc codebase
4. Validate approach

**Medium-term (Weeks 2-3):**
1. Full integration with code-search-agent
2. Documentation updates
3. Testing and optimization
4. Release v3.0.0

**Long-term (Future):**
1. Advanced RAG features
2. Multi-repo support
3. Custom fine-tuning
4. Performance optimizations

---

## Appendix A: References

### Research Sources
1. Anthropic MCP Documentation
2. Serena MCP GitHub (oraios/serena)
3. Code Context MCP (casistack/code-context)
4. Code Context MCP (fkesheh/code-context-mcp)
5. Qdrant MCP (qdrant/mcp-server-qdrant)
6. Chroma MCP (chroma-core/chroma-mcp)
7. Mistral Codestral Embed announcement
8. Voyage AI embeddings documentation
9. Jina AI code embeddings
10. Weaviate Hybrid Search guide
11. Pinecone Hybrid Search best practices
12. OpenSearch Hybrid Search guide (2025)

### Technical Papers
1. CodeSearchNet Challenge (Semantic Scholar)
2. Qodo Embed: Efficient Code Embeddings (arXiv)
3. Hybrid Search: Combining BM25 and Semantic Search (Medium)

---

## Appendix B: Glossary

- **AST**: Abstract Syntax Tree (code structure representation)
- **BM25**: Best Matching 25 (keyword ranking algorithm)
- **CoIR**: Code Information Retrieval (benchmark)
- **Embedding**: Dense vector representation of text/code
- **Hybrid Search**: Combination of keyword and semantic search
- **LSP**: Language Server Protocol (IDE intelligence protocol)
- **MCP**: Model Context Protocol (AI tool integration standard)
- **RAG**: Retrieval-Augmented Generation
- **RRF**: Reciprocal Rank Fusion (ranking algorithm)
- **Vector DB**: Database optimized for similarity search

---

**End of Research Document**

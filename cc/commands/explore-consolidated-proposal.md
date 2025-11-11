---
allowed-tools: Task, Bash, Read, Write, Grep
argument-hint: "[query] [--code|--web|--hybrid|--ask] [--force] [--incremental]"
description: Intelligent exploration with confidence-based routing and session awareness
---

# Explore: Intelligent Research Router

Smart exploration for: **$1**

## 0. Pre-Flight Checks

### A. Session Context Loading
```bash
# Check for active session and load context
ACTIVE_SESSION=$(find .claude/sessions -name "CLAUDE.md" -mtime -1 | head -1)
if [ -n "$ACTIVE_SESSION" ]; then
  PREVIOUS_TOPIC=$(grep "^Topic:" "$ACTIVE_SESSION" 2>/dev/null | tail -1 | cut -d: -f2- | xargs)
  PREVIOUS_INTENT=$(grep "^Intent:" "$ACTIVE_SESSION" 2>/dev/null | tail -1 | cut -d: -f2- | xargs)
  SESSION_DIR=$(dirname "$ACTIVE_SESSION")
fi
```

### B. Cache Check (unless --force flag)
```bash
# Compute query fingerprint for deduplication
QUERY_NORMALIZED=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g')
QUERY_HASH=$(echo "$QUERY_NORMALIZED" | md5sum | cut -d' ' -f1)

# Search recent sessions (last 7 days)
RECENT_MATCH=$(find .claude/sessions -name "CLAUDE.md" -mtime -7 -exec grep -l "QueryHash: $QUERY_HASH" {} \; 2>/dev/null | head -1)

if [ -n "$RECENT_MATCH" ] && [ "$FORCE_FLAG" != "true" ]; then
  CACHED_SESSION=$(dirname "$RECENT_MATCH")
  CACHE_AGE=$(stat -c %Y "$RECENT_MATCH")
  CACHE_HOURS=$(( ($(date +%s) - CACHE_AGE) / 3600 ))

  echo "💾 Found similar exploration from ${CACHE_HOURS}h ago"
  echo "Session: $(basename $CACHED_SESSION)"
  echo ""
  echo "Options:"
  echo "(a) Re-use cached results (instant, no tokens)"
  echo "(b) Re-run fresh exploration (costs ~5K-15K tokens)"
  echo "(c) Incremental update (only research new aspects)"
  echo ""
  # Wait for user input, then proceed accordingly
fi
```

### C. Flag Override Detection
```bash
# Check for explicit routing flags
if [[ "$*" =~ --code ]]; then
  FORCED_INTENT="CODE_ONLY"
elif [[ "$*" =~ --web ]]; then
  FORCED_INTENT="WEB_ONLY"
elif [[ "$*" =~ --hybrid ]]; then
  FORCED_INTENT="HYBRID"
elif [[ "$*" =~ --ask ]]; then
  SHOW_ROUTING_DETAILS=true
fi

FORCE_FLAG=$([[ "$*" =~ --force ]] && echo "true" || echo "false")
INCREMENTAL_FLAG=$([[ "$*" =~ --incremental ]] && echo "true" || echo "false")
```

---

## 1. Intent Detection with Confidence Scoring

### A. Multi-Signal Analysis

**Compute scores for each intent (0-100)**:

```python
# Pseudo-code for scoring logic

def score_code_intent(query, context):
    score = 0

    # Primary keywords (40 points max)
    code_keywords = ["where", "find", "show", "locate", "how does", "work", "current", "existing", "implemented", "structure", "architecture"]
    score += sum(15 for kw in code_keywords if kw in query.lower()) # max 40

    # File/path references (30 points max)
    if re.search(r'\.(ts|js|py|java|go|rs|md|json|yml)', query):
        score += 30

    # Code-specific terms (20 points max)
    code_terms = ["function", "class", "component", "module", "API", "endpoint", "service", "controller"]
    score += sum(5 for term in code_terms if term in query.lower()) # max 20

    # Past context bonus (10 points)
    if context.previous_intent == "CODE_ONLY" and similar_topic(query, context.previous_topic):
        score += 10

    return min(score, 100)

def score_web_intent(query, context):
    score = 0

    # Primary keywords (40 points max)
    web_keywords = ["best practice", "how to", "latest", "recommended", "tutorial", "guide", "what is", "industry standard", "documentation"]
    score += sum(15 for kw in web_keywords if kw in query.lower()) # max 40

    # Version/trend terms (30 points max)
    trend_terms = ["2024", "2025", "latest", "new", "modern", "current", "state of the art"]
    score += sum(10 for term in trend_terms if term in query.lower()) # max 30

    # Learning intent (20 points max)
    learning_keywords = ["learn", "explain", "understand", "teach", "documentation for"]
    score += sum(7 for kw in learning_keywords if kw in query.lower()) # max 20

    # No code references bonus (10 points)
    if not re.search(r'\.(ts|js|py|java|go|rs)', query) and not any(t in query.lower() for t in ["function", "class", "file"]):
        score += 10

    return min(score, 100)

def score_hybrid_intent(query, context):
    score = 0

    # Comparison keywords (50 points max)
    hybrid_keywords = ["improve", "migrate", "upgrade", "refactor", "modernize", "compare", "gap", "analysis", "align", "enhance", "versus", "vs"]
    score += sum(12 for kw in hybrid_keywords if kw in query.lower()) # max 50

    # Dual intent markers (30 points)
    has_code_markers = any(kw in query.lower() for kw in ["current", "existing", "our", "codebase"])
    has_web_markers = any(kw in query.lower() for kw in ["best practice", "recommended", "should", "better"])
    if has_code_markers and has_web_markers:
        score += 30

    # Action verbs (20 points max)
    action_verbs = ["replace", "update", "enhance", "optimize", "adopt", "integrate"]
    score += sum(7 for verb in action_verbs if verb in query.lower()) # max 20

    return min(score, 100)

def detect_unclear(query, scores):
    # Immediate unclear triggers
    if len(query.strip()) < 15 and len(query.split()) == 1:
        return True

    # No strong signal
    if max(scores.values()) < 60:
        return True

    # Contradictory signals (multiple high scores)
    high_scores = [s for s in scores.values() if s >= 70]
    if len(high_scores) > 1:
        return True

    return False

# Main detection logic
scores = {
    "CODE_ONLY": score_code_intent(query, session_context),
    "WEB_ONLY": score_web_intent(query, session_context),
    "HYBRID": score_hybrid_intent(query, session_context)
}

if detect_unclear(query, scores):
    intent = "UNCLEAR"
    confidence = 0
else:
    intent = max(scores, key=scores.get)
    confidence = scores[intent]

    # Override: If both CODE and WEB >70, force HYBRID
    if scores["CODE_ONLY"] >= 70 and scores["WEB_ONLY"] >= 70 and intent != "HYBRID":
        intent = "HYBRID"
        confidence = (scores["CODE_ONLY"] + scores["WEB_ONLY"]) / 2
```

### B. Confidence Thresholds

| Confidence | Behavior | User Feedback |
|------------|----------|---------------|
| ≥ 80 (HIGH) | Execute silently | Minimal: "🔍 Analyzing codebase..." |
| 60-79 (MEDIUM) | Execute with explanation | Show routing decision + override options |
| < 60 (LOW) | Ask user (UNCLEAR path) | Present options (a/b/c) |

### C. User Feedback for MEDIUM Confidence

```markdown
🔍 Interpreted as **[INTENT]** (confidence: [score]%)

Why: [brief 1-line explanation based on detected keywords]

Proceeding... Override if needed:
  /explore "$1" --code     Force code-only search
  /explore "$1" --web      Force web research
  /explore "$1" --hybrid   Force full hybrid analysis
  /explore "$1" --ask      Show detailed routing logic
```

### D. Show Routing Details (--ask flag)

```markdown
🤖 Routing Analysis for: "$1"

Intent Scores:
  CODE_ONLY:  [score]/100  [████████░░] → [reasons]
  WEB_ONLY:   [score]/100  [██████░░░░] → [reasons]
  HYBRID:     [score]/100  [███████░░░] → [reasons]

Decision: **[FINAL_INTENT]** (confidence: [%])
Reasoning: [detailed explanation]

Session Context:
  Previous topic: [topic] (intent: [previous])
  Cached results: [yes/no]

Proceed? (y/n/override):
```

---

## 2. Route Execution

### If UNCLEAR (or --ask with user input needed):

```markdown
🤔 To explore **"$1"**, I need to understand your intent:

(a) **Analyze codebase** - Search existing code, architecture, implementation
    Best for: "Where is X?", "How does Y work?", "Show me Z component"

(b) **Research best practices** - Find documentation, guides, recommendations
    Best for: "What's the latest for X?", "Best way to do Y?", "Industry standard for Z?"

(c) **Both (hybrid)** - Compare code vs best practices, gap analysis
    Best for: "Improve X", "Migrate to Y", "Align Z with standards"

Choose [a/b/c]:
```

Wait for response, then set `FINAL_INTENT` accordingly and proceed.

---

### If CODE_ONLY:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 30)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

# Create session metadata
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1
Intent: CODE_ONLY
Confidence: ${CONFIDENCE}%
Started: $(date '+%Y-%m-%d %H:%M')
ID: ${SESSION_ID}
QueryHash: ${QUERY_HASH}

## Status
Phase: explore-code
EOF

echo "📁 Code Analysis: ${SESSION_ID}"
echo "Confidence: ${CONFIDENCE}% | Estimated tokens: ~5,000"
```

**Launch code-search-agent**:
- Subagent: `code-search-agent`
- Model: `haiku`
- Description: "Analyze codebase for: $1"
- Prompt: `Analyze codebase for: "$1". Context: ${PREVIOUS_TOPIC}. Save comprehensive results to: ${SESSION_DIR}/code-search.md`

**After completion**:

```bash
# Extract key findings
KEY_COMPONENTS=$(grep -A 5 "### Key Components" "$SESSION_DIR/code-search.md" | tail -5)
COVERAGE=$(grep "Coverage:" "$SESSION_DIR/code-search.md" | head -1)
RISKS=$(grep "🔴" "$SESSION_DIR/code-search.md")

# Update session CLAUDE.md
cat >> "$SESSION_DIR/CLAUDE.md" << EOF

## Findings Summary
${KEY_COMPONENTS}

Coverage: ${COVERAGE}
Critical risks: $(echo "$RISKS" | wc -l)

## Next Steps
- Deep dive: /explore "[specific component]" --code
- Add research: /explore "$1" --web
- Full analysis: /explore "$1" --hybrid

@${SESSION_DIR}/code-search.md
EOF

# Display results
echo "✅ Code search complete: ${SESSION_ID}"
echo ""
echo "📊 FINDINGS:"
echo "$KEY_COMPONENTS" | head -3
echo ""
if [ -n "$RISKS" ]; then
  echo "⚠️  RISKS FOUND: $(echo "$RISKS" | wc -l)"
  echo "$RISKS" | head -2
  echo ""
fi
echo "📁 Full results: ${SESSION_DIR}/code-search.md"
echo ""
echo "💡 Suggestions:"
echo "   • Review complete findings: Read ${SESSION_DIR}/code-search.md"
echo "   • Add best practices research: /explore \"$1\" --web"
echo "   • Compare vs industry standards: /explore \"$1\" --hybrid"
```

---

### If WEB_ONLY:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 30)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

# Create session metadata
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1
Intent: WEB_ONLY
Confidence: ${CONFIDENCE}%
Started: $(date '+%Y-%m-%d %H:%M')
ID: ${SESSION_ID}
QueryHash: ${QUERY_HASH}

## Status
Phase: explore-web
EOF

echo "🌐 Web Research: ${SESSION_ID}"
echo "Confidence: ${CONFIDENCE}% | Estimated tokens: ~5,000"
```

**Launch web-research-agent**:
- Subagent: `web-research-agent`
- Model: `haiku`
- Description: "Research best practices for: $1"
- Prompt: `Research 2024-2025 best practices for: "$1". Focus on official docs, recent guides, and security updates. Save to: ${SESSION_DIR}/web-research.md`

**After completion**:

```bash
# Extract key findings
BEST_PRACTICES=$(grep -A 10 "### Best Practices" "$SESSION_DIR/web-research.md" | tail -10)
SOURCES=$(grep -c "http" "$SESSION_DIR/web-research.md")

# Update session CLAUDE.md
cat >> "$SESSION_DIR/CLAUDE.md" << EOF

## Research Summary
Best practices found: $(echo "$BEST_PRACTICES" | grep -c "^-")
Sources reviewed: ${SOURCES}

Top recommendations:
${BEST_PRACTICES}

## Next Steps
- Apply to code: /explore "$1" --code
- Full comparison: /explore "$1" --hybrid
- Create plan: /plan ${SESSION_ID}

@${SESSION_DIR}/web-research.md
EOF

# Display results
echo "✅ Web research complete: ${SESSION_ID}"
echo ""
echo "🌐 BEST PRACTICES (2024-2025):"
echo "$BEST_PRACTICES" | head -5
echo ""
echo "📁 Full research: ${SESSION_DIR}/web-research.md"
echo ""
echo "💡 Suggestions:"
echo "   • Review complete research: Read ${SESSION_DIR}/web-research.md"
echo "   • Analyze current code: /explore \"$1\" --code"
echo "   • Compare vs current implementation: /explore \"$1\" --hybrid"
```

---

### If HYBRID:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 30)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

# Create full session metadata
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1
Intent: HYBRID
Confidence: ${CONFIDENCE}%
Started: $(date '+%Y-%m-%d %H:%M')
ID: ${SESSION_ID}
QueryHash: ${QUERY_HASH}

## Objective
$1

## Context
Previous session: ${PREVIOUS_TOPIC:-None}
Incremental: ${INCREMENTAL_FLAG}

## Status
Phase: explore-hybrid
Progress: 0/3 (code, web, synthesis)
EOF

echo "🔀 Hybrid Analysis: ${SESSION_ID}"
echo "Confidence: ${CONFIDENCE}% | Estimated tokens: ~15,000"
echo ""
echo "Phase 1/3: Launching parallel research (code + web)..."
```

**Launch BOTH agents in parallel** (single message, two Task calls):

1. **code-search-agent**:
   - Subagent: `code-search-agent`
   - Model: `haiku`
   - Description: "Analyze codebase for: $1"
   - Prompt: `Analyze codebase for: "$1". ${INCREMENTAL_FLAG:+Focus on changes since last analysis.} Save to: ${SESSION_DIR}/code-search.md`

2. **web-research-agent**:
   - Subagent: `web-research-agent`
   - Model: `haiku`
   - Description: "Research best practices for: $1"
   - Prompt: `Research 2024-2025 best practices for: "$1". ${INCREMENTAL_FLAG:+Focus on recent updates since last research.} Save to: ${SESSION_DIR}/web-research.md`

**After BOTH complete**:

```bash
echo "✅ Phase 1 complete: Code and web research done"
echo "Phase 2/3: Synthesizing findings..."

# Update session progress
sed -i 's/Progress: 0\/3/Progress: 2\/3/' "$SESSION_DIR/CLAUDE.md"
```

**Launch synthesis agent**:

3. **context-synthesis-agent**:
   - Subagent: `context-synthesis-agent`
   - Model: `sonnet`
   - Description: "Synthesize findings for: $1"
   - Prompt: `Synthesize exploration for: "$1". Read ${SESSION_DIR}/code-search.md and ${SESSION_DIR}/web-research.md. Create unified analysis with gap analysis, priorities, and recommendations. Save to: ${SESSION_DIR}/synthesis.md`

**After synthesis**:

```bash
# Extract synthesis highlights
EXEC_SUMMARY=$(grep -A 3 "## Executive Summary" "$SESSION_DIR/synthesis.md" | tail -3)
GAPS=$(grep "^1\." "$SESSION_DIR/synthesis.md" | grep "🔴\|🟡" | head -3)
PRIORITIES=$(grep -A 5 "### Immediate" "$SESSION_DIR/synthesis.md" | grep "^1\." | head -3)

# Update session CLAUDE.md
cat >> "$SESSION_DIR/CLAUDE.md" << EOF

## Status
Phase: synthesis-complete
Progress: 3/3

## Executive Summary
${EXEC_SUMMARY}

## Critical Gaps
${GAPS}

## Immediate Actions
${PRIORITIES}

## Next Steps
Recommended: /plan ${SESSION_ID}

## References
@${SESSION_DIR}/code-search.md
@${SESSION_DIR}/web-research.md
@${SESSION_DIR}/synthesis.md
EOF

# Display final results
echo "✅ Phase 2 complete: Synthesis done"
echo ""
echo "═══════════════════════════════════════════════════"
echo "🎯 HYBRID EXPLORATION COMPLETE: ${SESSION_ID}"
echo "═══════════════════════════════════════════════════"
echo ""
echo "📊 CODE ANALYSIS:"
CODE_FILES=$(grep "Files analyzed:" "$SESSION_DIR/code-search.md" | head -1)
echo "   ${CODE_FILES}"
echo ""
echo "🌐 WEB RESEARCH:"
WEB_SOURCES=$(grep -c "http" "$SESSION_DIR/web-research.md")
echo "   Sources reviewed: ${WEB_SOURCES}"
echo ""
echo "🎯 KEY GAPS:"
echo "$GAPS" | sed 's/^/   /'
echo ""
echo "⚡ IMMEDIATE PRIORITIES:"
echo "$PRIORITIES" | sed 's/^/   /'
echo ""
echo "📁 SESSION FILES:"
echo "   • Summary: ${SESSION_DIR}/CLAUDE.md"
echo "   • Code: ${SESSION_DIR}/code-search.md"
echo "   • Web: ${SESSION_DIR}/web-research.md"
echo "   • Synthesis: ${SESSION_DIR}/synthesis.md"
echo ""
echo "═══════════════════════════════════════════════════"
echo "🚀 RECOMMENDED NEXT STEP: /plan ${SESSION_ID}"
echo "═══════════════════════════════════════════════════"
```

---

## 3. Post-Execution Enhancements

### A. Smart Suggestions Based on Results

```bash
# Analyze results to provide intelligent next steps
if [ "$FINAL_INTENT" = "CODE_ONLY" ]; then
  RISK_COUNT=$(grep -c "🔴" "$SESSION_DIR/code-search.md")

  if [ "$RISK_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️  NOTICE: Found ${RISK_COUNT} critical issues"
    echo "   Consider: /explore \"$1\" --web to research best practices for mitigation"
  fi

  # Check if related web research would be valuable
  SECURITY_MENTIONS=$(grep -ic "security\|vulnerability\|CVE" "$SESSION_DIR/code-search.md")
  if [ "$SECURITY_MENTIONS" -gt 2 ]; then
    echo ""
    echo "🔒 Security concerns detected"
    echo "   Recommended: /explore \"$1 security best practices\" --web"
  fi
fi

if [ "$FINAL_INTENT" = "WEB_ONLY" ]; then
  # Check if user has code that could benefit
  echo ""
  echo "💡 To apply these practices to your codebase:"
  echo "   • Analyze current code: /explore \"$1\" --code"
  echo "   • Full comparison: /explore \"$1\" --hybrid"
fi

if [ "$FINAL_INTENT" = "HYBRID" ]; then
  GAP_COUNT=$(grep -c "🔴" "$SESSION_DIR/synthesis.md")

  if [ "$GAP_COUNT" -gt 0 ]; then
    echo ""
    echo "🎯 Next: Create implementation plan to address ${GAP_COUNT} critical gaps"
    echo "   Command: /plan ${SESSION_ID}"
  else
    echo ""
    echo "✅ Code aligns well with best practices!"
    echo "   Review synthesis for optimization opportunities: Read ${SESSION_DIR}/synthesis.md"
  fi
fi
```

### B. Session Linking

```bash
# If this is a follow-up exploration, link to previous session
if [ -n "$PREVIOUS_TOPIC" ] && [ "$PREVIOUS_TOPIC" != "$1" ]; then
  cat >> "$SESSION_DIR/CLAUDE.md" << EOF

## Related Sessions
Previous: ${SESSION_DIR_PREVIOUS} - "${PREVIOUS_TOPIC}"
Connection: [Detected as follow-up/refinement]
EOF
fi
```

### C. Quality Metrics

```bash
# Add metrics for transparency
cat >> "$SESSION_DIR/CLAUDE.md" << EOF

## Session Metrics
Intent: ${FINAL_INTENT}
Confidence: ${CONFIDENCE}%
Agents used: [list]
Estimated token cost: ~[calculated]
Execution time: [duration]
Cache hit: ${CACHE_HIT:-No}
EOF
```

---

## 4. Advanced Features

### A. Incremental Mode (--incremental flag)

When `--incremental` is set and previous session exists:

```bash
# Load previous results
PREV_CODE="$CACHED_SESSION/code-search.md"
PREV_WEB="$CACHED_SESSION/web-research.md"

# Prompt agents to focus only on deltas
CODE_PROMPT="Previous analysis: [summary from $PREV_CODE]. Focus ONLY on: 1) New/changed files since last session, 2) New aspects of query: '$1'"

WEB_PROMPT="Previous research: [summary from $PREV_WEB]. Focus ONLY on: 1) Updates/changes in best practices since last session, 2) New aspects of query: '$1'"

# Use minimal synthesis (only new findings)
SYNTHESIS_PROMPT="Previous synthesis: [summary]. Update with ONLY new findings. Highlight what changed."
```

**Benefits**:
- ⚡ Faster execution
- 💰 Lower token cost (60-80% reduction on repeat queries)
- 📈 Progressive knowledge building

---

### B. Watch Mode (future enhancement)

```bash
# /explore "$1" --watch
# Auto-rerun when code changes detected
# Useful for: "monitor auth security" → rerun on auth/ changes
```

---

### C. Comparison Mode

```bash
# /explore "auth" --compare-sessions SESSION1 SESSION2
# Compare two exploration sessions
# Useful for: before/after migration analysis
```

---

## 5. Error Handling & Fallbacks

### Agent Failure Handling

```bash
if [ "$CODE_AGENT_FAILED" = "true" ]; then
  echo "❌ Code search failed. Possible reasons:"
  echo "   • MCP server unavailable (trying fallback...)"
  echo "   • Codebase too large (try narrowing scope: /explore 'src/auth' --code)"

  # Attempt fallback with traditional tools
  echo "🔄 Retrying with traditional search (Glob+Grep)..."
fi
```

### Graceful Degradation

```bash
# If web-research-agent fails (no MCP, no internet)
if [ "$WEB_AGENT_FAILED" = "true" ]; then
  echo "⚠️  Web research unavailable"
  echo "   • Check MCP servers: mcp__tavily, mcp__context7"
  echo "   • Check internet connectivity"
  echo ""
  echo "Continuing with code-only analysis..."
  FINAL_INTENT="CODE_ONLY"  # Degrade gracefully
fi
```

---

## Summary

This consolidated `/explore` command provides:

✅ **Intelligent routing** with confidence scoring
✅ **Session-aware** context loading and caching
✅ **User transparency** with override flags
✅ **Token efficiency** (~50% average reduction)
✅ **Seamless integration** with /plan, /code, /commit
✅ **Smart suggestions** based on findings
✅ **Incremental mode** for progressive exploration
✅ **Graceful fallbacks** for robustness

**Estimated Performance**:
- Intent detection: <100ms (local scoring)
- Cache check: <200ms (file search)
- CODE_ONLY: ~5K tokens, 15-30s
- WEB_ONLY: ~5K tokens, 20-40s (depends on web latency)
- HYBRID: ~15K tokens, 45-90s

**User Experience**:
- Clear confidence indicators
- Override options when needed
- Contextual suggestions
- Progressive disclosure of complexity

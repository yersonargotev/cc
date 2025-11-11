---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[feature/issue description] [scope/context]"
description: Smart exploration with automatic routing to code/web/hybrid agents
---

# Explore: Smart Research Router

Intelligent exploration for: **$1**$2

## 1. Intent Detection

Analyze query to determine research scope:

**CODE_ONLY** - Match any:
- Keywords: `where|find|show|locate|how does.*(?:work|function)|current|existing|implemented|structure|architecture`
- Phrases: `in (?:this|our|the) (?:codebase|project|code|repo)|where is|how is.*implemented`

**WEB_ONLY** - Match any:
- Keywords: `best practice|how to|latest|recommended|tutorial|guide|what is|industry standard|external|documentation for|security (?:update|vulnerability)|learn|explain`
- Phrases: `recommended (?:way|approach|pattern)|latest version|common practice`

**HYBRID** - Match any:
- Keywords: `improve|migrate|upgrade|refactor|modernize|compare|gap analysis|align|enhance|versus|vs\.|better than`
- Phrases: `current (?:vs|versus)|align with (?:best|industry)|improve.*(?:to match|using)|migrate.*(?:to|from)`

**UNCLEAR** - Any:
- Query length < 15 chars AND single word OR no specific intent markers

## 2. Route Execution

### If UNCLEAR:
Ask user: "To explore **$1**, should I: **(a)** analyze codebase, **(b)** research web best practices, or **(c)** both (hybrid)?"

Wait for response, then proceed as CODE_ONLY, WEB_ONLY, or HYBRID based on answer.

---

### If CODE_ONLY:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"
echo "📁 Code Search: ${SESSION_ID}"
```

**Spawn code-search-agent**:
- Subagent: `code-search-agent`
- Model: `haiku`
- Description: "Analyze codebase"
- Prompt: `Analyze codebase for: $1. Context: $2. Save to: ${SESSION_DIR}/code-search.md`

After completion, report:
```
✅ Code search complete: ${SESSION_ID}

📊 FINDINGS:
[Extract key points from code-search.md]

📁 Results: ${SESSION_DIR}/code-search.md
```

---

### If WEB_ONLY:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"
echo "🌐 Web Research: ${SESSION_ID}"
```

**Spawn web-research-agent**:
- Subagent: `web-research-agent`
- Model: `haiku`
- Description: "Research web best practices"
- Prompt: `Research best practices for: $1. Context: $2. Save to: ${SESSION_DIR}/web-research.md`

After completion, report:
```
✅ Web research complete: ${SESSION_ID}

🌐 FINDINGS:
[Extract key points from web-research.md]

📁 Results: ${SESSION_DIR}/web-research.md
```

---

### If HYBRID:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1
Phase: explore | Started: $(date '+%Y-%m-%d %H:%M') | ID: ${SESSION_ID}
Objective: $1
Context: $2
EOF

echo "🔀 Hybrid Research: ${SESSION_ID}"
```

**Launch both agents in parallel** (single message with two Task calls):

1. **code-search-agent**:
   - Subagent: `code-search-agent`
   - Model: `haiku`
   - Description: "Analyze codebase"
   - Prompt: `Analyze codebase for: $1. Context: $2. Save to: ${SESSION_DIR}/code-search.md`

2. **web-research-agent**:
   - Subagent: `web-research-agent`
   - Model: `haiku`
   - Description: "Research web best practices"
   - Prompt: `Research best practices for: $1. Context: $2. Save to: ${SESSION_DIR}/web-research.md`

After BOTH complete, spawn synthesis:

3. **context-synthesis-agent**:
   - Subagent: `context-synthesis-agent`
   - Model: `sonnet`
   - Description: "Synthesize findings"
   - Prompt: `Synthesize for: $1. Read ${SESSION_DIR}/code-search.md and ${SESSION_DIR}/web-research.md. Save to: ${SESSION_DIR}/synthesis.md`

After synthesis, update `${SESSION_DIR}/CLAUDE.md`:
- Status: explore → plan complete
- Key Findings: Top 3-5 insights
- Gap Analysis: 2-3 critical gaps
- Next Steps: `/plan ${SESSION_ID}`

Report:
```
✅ Hybrid exploration complete: ${SESSION_ID}

📊 CODE: [X files, Y components analyzed]
🌐 WEB: [X sources, Y best practices found]
🎯 KEY GAPS: [Top 2-3 from synthesis]
⚡ PRIORITIES: [Top 2-3 from synthesis]

📁 SESSION: ${SESSION_ID}
Files: CLAUDE.md | code-search.md | web-research.md | synthesis.md

🚀 NEXT: /plan ${SESSION_ID}
```

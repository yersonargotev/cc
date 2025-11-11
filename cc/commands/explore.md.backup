---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[feature/issue description] [scope/context]"
description: Hybrid exploration using code search + web research + synthesis
---

# Explore: Hybrid Research

Comprehensive exploration combining codebase analysis + web research for: **$1**$2

## Session Setup

Create session with unique ID:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore | Started: $(date '+%Y-%m-%d %H:%M') | ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Key Findings
[Populated after synthesis]

## Next Steps
Run \`/plan ${SESSION_ID}\`
EOF

echo "✅ Session: ${SESSION_ID}"
echo "📁 $SESSION_DIR"
```

## Phase 1: Parallel Research

Launch code-search-agent and web-research-agent simultaneously using Task tool.

### Code Search Agent

Use Task tool to spawn `code-search-agent`:

- **Subagent**: `code-search-agent`
- **Model**: haiku
- **Description**: "Analyze codebase for comprehensive code search"
- **Prompt**: `Analyze codebase for: $1. Context: $2. Save complete analysis to: ${SESSION_DIR}/code-search.md`

### Web Research Agent

SIMULTANEOUSLY, use Task tool to spawn `web-research-agent`:

- **Subagent**: `web-research-agent`
- **Model**: haiku
- **Description**: "Research web for best practices and solutions"
- **Prompt**: `Research best practices and documentation for: $1. Context: $2. Save complete research to: ${SESSION_DIR}/web-research.md`

**Important**: Launch both agents in parallel (single message with multiple Task calls).

## Phase 2: Synthesis

After BOTH agents complete, spawn synthesis agent.

### Context Synthesis Agent

Use Task tool to spawn `context-synthesis-agent`:

- **Subagent**: `context-synthesis-agent`
- **Model**: sonnet
- **Description**: "Synthesize code and web research into actionable insights"
- **Prompt**: `Synthesize findings for: $1. Read ${SESSION_DIR}/code-search.md and ${SESSION_DIR}/web-research.md. Save synthesis to: ${SESSION_DIR}/synthesis.md`

Wait for synthesis to complete before session persistence.

## Session Persistence

After synthesis completes, update session files.

### 1. Update CLAUDE.md

Read synthesis and update `${SESSION_DIR}/CLAUDE.md` with:

- **Status**: Update phase to "explore → plan" with completion timestamp
- **Key Findings**: Top 3-5 insights (code + web, mixed)
- **Gap Analysis**: 2-3 critical gaps (current → recommended)
- **Implementation Priorities**: Immediate (Week 1) + Short-term (Weeks 2-4) actions
- **Risk Factors**: 🔴 High + 🟡 Medium priorities
- **Next Steps**: Run `/plan ${SESSION_ID}`
- **References**: Links to code-search.md, web-research.md, synthesis.md, explore.md

### 2. Create explore.md

Combine all outputs into `${SESSION_DIR}/explore.md`:

```markdown
# Exploration: $1

**Session**: ${SESSION_ID} | **Date**: $(date '+%Y-%m-%d %H:%M') | **Scope**: $1 $2

---

## Executive Summary
[Extract from synthesis.md]

---

## Table of Contents
1. Code Search Results
2. Web Research Results
3. Integrated Synthesis
4. Next Steps

---

## Code Search Results
[Include full content from code-search.md]

---

## Web Research Results
[Include full content from web-research.md]

---

## Integrated Synthesis
[Include full content from synthesis.md]

---

## Next Steps

### For Planning Phase
**Immediate Actions**: [From synthesis]
**Short-term Actions**: [From synthesis]
**Long-term Considerations**: [From synthesis]

### Questions to Address
[Extract from synthesis]

---

## Session Information
- **ID**: ${SESSION_ID}
- **Directory**: .claude/sessions/${SESSION_ID}_${SESSION_DESC}/
- **Completed**: $(date '+%Y-%m-%d %H:%M')
- **Files**: CLAUDE.md | code-search.md | web-research.md | synthesis.md | explore.md
```

## Completion

Report results to user:

```
✅ Exploration complete: ${SESSION_ID}

📊 CODE ANALYSIS:
- Files: [X from code-search.md]
- Components: [X from code-search.md]
- Coverage: ~[X]% from code-search.md
- Dependencies: [X from code-search.md]

🌐 WEB RESEARCH:
- Sources: [X from web-research.md]
- Best practices: [X from web-research.md]
- Official docs: [X from web-research.md]
- Solutions: [X from web-research.md]

🎯 KEY INTEGRATED FINDINGS:
1. [Top finding from synthesis]
2. [Second finding from synthesis]
3. [Third finding from synthesis]

🔴 CRITICAL GAPS:
- [Gap 1]: Current [state] → Recommended [state]
- [Gap 2]: Current [state] → Recommended [state]

⚡ IMMEDIATE PRIORITIES:
1. [Priority 1 from synthesis]
2. [Priority 2 from synthesis]

📁 SESSION: ${SESSION_ID}
Directory: .claude/sessions/${SESSION_ID}_${SESSION_DESC}/
Files: CLAUDE.md (auto-loads) | code-search.md | web-research.md | synthesis.md | explore.md

🚀 NEXT: /plan ${SESSION_ID}
```

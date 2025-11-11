---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[query] [context]"
description: Smart exploration with automatic routing to code/web/hybrid agents
---

# Explore: Smart Research Router

Intelligent exploration for: **$1**$2

## 1. Intent Detection

Analyze query to determine optimal research scope:

**CODE_ONLY** - Match any:
- Keywords: `where|find|show|locate|current|existing|implemented|structure|architecture`
- Phrases: `in (?:this|our|the) (?:codebase|project|code|repo)|where is|how is.*implemented|how does.*(?:work|function)`
- Intent: User wants to understand/locate existing code

**WEB_ONLY** - Match any:
- Keywords: `best practice|how to|latest|recommended|tutorial|guide|what is|industry standard|documentation for|learn|explain`
- Phrases: `recommended (?:way|approach|pattern)|latest version|common practice|security (?:update|vulnerability)`
- Intent: User wants external knowledge/best practices

**HYBRID** - Match any:
- Keywords: `improve|migrate|upgrade|refactor|modernize|compare|gap analysis|align|enhance|versus|vs\.|better`
- Phrases: `current (?:vs|versus)|align with (?:best|industry)|improve.*(?:to match|using)|migrate.*(?:to|from)`
- Intent: User wants to compare current state vs recommended practices

**UNCLEAR** - Any:
- Query length < 15 chars AND single word OR no specific intent markers
- Intent: Needs clarification

## 2. Session Setup

Create unique session for tracking:

```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
mkdir -p "$SESSION_DIR"
```

## 3. Route Execution

### If UNCLEAR:

Ask user for clarification:
```
To explore **$1**, should I:
  (a) analyze codebase
  (b) research web best practices
  (c) both (hybrid)
```

Wait for response (a/b/c), then route to CODE_ONLY, WEB_ONLY, or HYBRID.

---

### If CODE_ONLY:

**Setup**:
```bash
echo "📊 Code Analysis: ${SESSION_ID}"
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore-code | Started: $(date '+%Y-%m-%d %H:%M') | ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Findings
[Populated after code search]

## Next Steps
Review findings or run \`/plan ${SESSION_ID}\` to create implementation plan
EOF
```

**Execute**:
Use Task tool to spawn `code-search-agent`:
- **Subagent**: `code-search-agent`
- **Model**: `haiku`
- **Description**: "Analyze codebase for code search"
- **Prompt**: `Analyze codebase for: $1. Context: $2. Save complete analysis to: ${SESSION_DIR}/code-search.md. Include file:line references, components, architecture, tests, dependencies, and documentation.`

**Update Session**:
After completion, read `${SESSION_DIR}/code-search.md` and update `${SESSION_DIR}/CLAUDE.md`:
- Extract top 3-5 key findings
- Add to "Findings" section
- Update status to "explore-code → complete"

**Report**:
```
✅ Code search complete: ${SESSION_ID}

📊 ANALYSIS:
- Files: [X] analyzed
- Components: [X] identified
- Architecture: [pattern]
- Tests: ~[X]% coverage
- Dependencies: [X] external, [X] internal

🎯 KEY FINDINGS:
1. [Top finding with file:line]
2. [Second finding with file:line]
3. [Third finding with file:line]

📁 SESSION: ${SESSION_ID}
   Results: ${SESSION_DIR}/code-search.md
   Context: ${SESSION_DIR}/CLAUDE.md (auto-loads in /plan)

🚀 NEXT: /plan ${SESSION_ID}
```

---

### If WEB_ONLY:

**Setup**:
```bash
echo "🌐 Web Research: ${SESSION_ID}"
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore-web | Started: $(date '+%Y-%m-%d %H:%M') | ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Findings
[Populated after web research]

## Next Steps
Review findings or run \`/plan ${SESSION_ID}\` to create implementation plan
EOF
```

**Execute**:
Use Task tool to spawn `web-research-agent`:
- **Subagent**: `web-research-agent`
- **Model**: `haiku`
- **Description**: "Research web for best practices"
- **Prompt**: `Research best practices and documentation for: $1. Context: $2. Focus on 2024-2025 content. Save complete research to: ${SESSION_DIR}/web-research.md. Include official docs, best practices, security considerations, and implementations.`

**Update Session**:
After completion, read `${SESSION_DIR}/web-research.md` and update `${SESSION_DIR}/CLAUDE.md`:
- Extract top 3-5 key recommendations
- Add to "Findings" section
- Update status to "explore-web → complete"

**Report**:
```
✅ Web research complete: ${SESSION_ID}

🌐 RESEARCH:
- Sources: [X] authoritative
- Best practices: [X] identified
- Official docs: [list]
- Security: [considerations]

🎯 KEY RECOMMENDATIONS:
1. [Top recommendation with source]
2. [Second recommendation with source]
3. [Third recommendation with source]

📁 SESSION: ${SESSION_ID}
   Results: ${SESSION_DIR}/web-research.md
   Context: ${SESSION_DIR}/CLAUDE.md (auto-loads in /plan)

🚀 NEXT: /plan ${SESSION_ID}
```

---

### If HYBRID:

**Setup**:
```bash
echo "🔀 Hybrid Analysis: ${SESSION_ID}"
cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore-hybrid | Started: $(date '+%Y-%m-%d %H:%M') | ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Key Findings
[Populated after planning]

## Gap Analysis
[Current state vs recommended practices]

## Implementation Plan Summary
[Key steps and priorities from plan]

## Next Steps
Implementation plan ready. Run \`/code ${SESSION_ID}\` to begin
EOF
```

**Execute - Parallel Research**:
Launch BOTH agents simultaneously (single message with two Task calls):

1. **code-search-agent**:
   - **Subagent**: `code-search-agent`
   - **Model**: `haiku`
   - **Description**: "Analyze codebase"
   - **Prompt**: `Analyze codebase for: $1. Context: $2. Save complete analysis to: ${SESSION_DIR}/code-search.md. Include file:line references, components, architecture, tests, dependencies, and documentation.`

2. **web-research-agent**:
   - **Subagent**: `web-research-agent`
   - **Model**: `haiku`
   - **Description**: "Research web best practices"
   - **Prompt**: `Research best practices and documentation for: $1. Context: $2. Focus on 2024-2025 content. Save complete research to: ${SESSION_DIR}/web-research.md. Include official docs, best practices, security considerations, and implementations.`

**Execute - Planning**:
After BOTH agents complete, spawn planning agent:

3. **planning-agent**:
   - **Subagent**: `planning-agent`
   - **Model**: `sonnet`
   - **Description**: "Create implementation plan from findings"
   - **Prompt**: `Create implementation plan for: $1. Read ${SESSION_DIR}/code-search.md and ${SESSION_DIR}/web-research.md. Generate comprehensive implementation plan comparing current state vs best practices. Save plan to: ${SESSION_DIR}/plan.md. Include gap analysis, step-by-step implementation, risk mitigation, testing strategy, and success criteria with evidence from both sources.`

**Update Session**:
After planning completes, read `${SESSION_DIR}/plan.md` and update `${SESSION_DIR}/CLAUDE.md`:
- **Key Findings**: Top 3-5 gaps identified (current state → recommended state)
- **Implementation Plan Summary**: High-level approach and key steps
- **Priorities**: Critical priorities (🔴) and short-term actions (🟡)
- **Status**: Update to "explore-hybrid → planning complete"

**Report**:
```
✅ Hybrid exploration + planning complete: ${SESSION_ID}

📊 CODE ANALYSIS:
- Files: [X] | Components: [X] | Coverage: ~[X]%
- Architecture: [pattern]
- Dependencies: [X] external, [X] internal

🌐 WEB RESEARCH:
- Sources: [X] authoritative
- Best practices: [X] (2024-2025)
- Official docs: [list]

🎯 KEY GAPS IDENTIFIED:
1. [Gap]: Current [state] → Recommended [state]
2. [Gap]: Current [state] → Recommended [state]
3. [Gap]: Current [state] → Recommended [state]

📋 IMPLEMENTATION PLAN:
- Steps: [X] defined
- Tests: [X] scenarios
- Risks: 🔴 [X] high | 🟡 [X] medium

⚡ IMMEDIATE PRIORITIES:
1. [Priority 1 from plan]
2. [Priority 2 from plan]

📁 SESSION: ${SESSION_ID}
   Files: CLAUDE.md (auto-loads) | code-search.md | web-research.md | plan.md
   Directory: ${SESSION_DIR}

🚀 NEXT: /code ${SESSION_ID}
```

## 4. Quality Standards

Ensure all agent outputs meet these criteria:

**Evidence-Based**:
- All claims backed by file:line references (code) or URLs (web)
- No vague descriptions or assumptions
- Specific examples with context

**Prioritized**:
- Most relevant/critical findings first
- Clear risk/priority indicators (🔴/🟡/🟢)
- Actionable recommendations

**Comprehensive**:
- Architecture + implementation + tests + dependencies + docs
- Security considerations
- Current state vs best practices (for HYBRID)

**Concise**:
- Focus on actionable insights
- Remove noise and irrelevant details
- Dense information, clear structure

## 5. Integration with Workflow

**Auto-loading Context**:
- `CLAUDE.md` automatically loads in `/plan ${SESSION_ID}`
- Detailed results available in session directory
- Seamless flow: explore → plan → code → commit

**Session Persistence**:
- All sessions stored in `.claude/sessions/`
- Reusable across commands
- Traceable history with unique IDs

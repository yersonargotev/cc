---
allowed-tools: Read, Glob, Grep, Task, Bash, Write, WebSearch, WebFetch
argument-hint: "[feature/issue description] [scope/context]"
description: Hybrid exploration using code search + web research + synthesis
---

# Explore: Hybrid Research and Context Gathering

Orchestrate comprehensive exploration combining codebase analysis with up-to-date web research for: **$1**$2

## Session Setup

Generate v2 session ID and create session directory with CLAUDE.md:

```bash
# Generate v2 session ID (zero dependencies)
echo "🔨 Generating session ID..."
SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/generate-session-id.sh" "$1")

if [ $? -ne 0 ] || [ -z "$SESSION_ID" ]; then
  echo "❌ Failed to generate session ID"
  exit 1
fi

echo "✅ Generated: $SESSION_ID"
echo ""

# Extract slug from v2 ID (format: v2-YYYYMMDDTHHmmss-base32-slug)
SLUG=$(echo "$SESSION_ID" | cut -d'-' -f4-)

# Get current git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Create session directory
SESSION_DIR=".claude/sessions/${SESSION_ID}"
mkdir -p "$SESSION_DIR"

# Initialize session CLAUDE.md
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

cat > "$SESSION_DIR/CLAUDE.md" << EOF
# Session: $1

## Status
Phase: explore
Started: $(date '+%Y-%m-%d %H:%M')
Last Updated: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Technical Details
- Session Format: v2
- Branch: $BRANCH
- Short ID: $(echo "$SESSION_ID" | cut -d'-' -f3)
- Slug: $SLUG

## Objective
$1

## Context
$2

## Key Findings
[To be populated during exploration]

## Next Steps
Run \`/cc:plan @latest\` to create implementation plan

## References
@.claude/sessions/${SESSION_ID}/explore.md
EOF

# Initialize activity log
cat > "$SESSION_DIR/activity.log" << EOF
[$TIMESTAMP] Session created
[$TIMESTAMP] Description: $1
[$TIMESTAMP] Branch: $BRANCH
EOF

# Add session to index
echo "📇 Adding to session index..."
if [ -x "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" ]; then
  bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" add \
    "$SESSION_ID" \
    "$SLUG" \
    "exploration" \
    "in_progress" \
    "$BRANCH" || echo "⚠️  Warning: Failed to add to index"

  # Set as @latest
  bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" set-ref "@latest" "$SESSION_ID" || true
fi

echo ""
echo "✅ Session created successfully!"
echo ""
echo "📋 Session Details:"
echo "  ID: $SESSION_ID"
echo "  Name: $SLUG"
echo "  Phase: Exploration"
echo "  Branch: $BRANCH"
echo ""
echo "💡 Quick references:"
echo "  @latest              - Always refers to this session (until next session)"
echo "  @                    - Shorthand for @latest"
echo "  $(echo "$SESSION_ID" | cut -d'-' -f3)             - Short ID (8 chars)"
echo "  @/$SLUG - Slug search"
echo ""
echo "📁 Directory: $SESSION_DIR"
```

## Hybrid Exploration with Specialized Subagents

Launch 2 specialized subagents in PARALLEL for comprehensive research, then synthesize results.

### Phase 1: Parallel Research (Code + Web)

Execute code search and web research simultaneously for maximum efficiency.

#### 1A. Code Search Agent

Use the Task tool to spawn the `code-search-agent` subagent:

**Subagent**: `code-search-agent`
**Description**: "Analyze codebase for comprehensive code search"
**Model**: haiku

**Prompt**:
```
Analyze the codebase to find components, patterns, and information related to: $1

Additional context: $2

## Your Task

Perform comprehensive code search covering:

1. **Semantic/Structural Search**
   - Find relevant code components using semantic search (if MCP available) or Glob/Grep
   - Identify key classes, functions, modules related to the feature
   - Map component relationships and dependencies

2. **Architecture Analysis**
   - Identify architectural patterns used
   - Document code organization and structure
   - Note design patterns and conventions

3. **Test Coverage**
   - Find test files and assess coverage
   - Identify well-tested vs untested areas
   - Evaluate test quality and patterns

4. **Dependency Analysis**
   - Analyze external dependencies (package files)
   - Map internal dependencies and imports
   - Check for outdated or vulnerable dependencies

5. **Documentation**
   - Find README, docs, and inline comments
   - Extract requirements and specifications
   - Note documentation gaps

## Output

Save your complete analysis to: ${SESSION_DIR}/code-search.md

Use the structured format defined in your agent specification.
Focus on relevance - prioritize components directly related to: $1
```

#### 1B. Web Research Agent

SIMULTANEOUSLY, use the Task tool to spawn the `web-research-agent` subagent:

**Subagent**: `web-research-agent`
**Description**: "Research web for best practices and solutions"
**Model**: haiku

**Prompt**:
```
Research current best practices, official documentation, and industry solutions for: $1

Additional context: $2

## Your Task

Perform targeted web research covering:

1. **Best Practices (2024-2025)**
   - Search for current industry standards and patterns
   - Find recommended approaches for this type of implementation
   - Identify common pitfalls and how to avoid them

2. **Official Documentation**
   - Locate official docs for relevant technologies/frameworks
   - Find API references and guides
   - Check for migration guides or upgrade paths

3. **Similar Solutions**
   - Search for open source implementations
   - Find blog posts and tutorials
   - Discover how others have solved similar problems

4. **Security & Updates**
   - Check for security advisories and CVEs
   - Find latest stable versions
   - Identify breaking changes or deprecations

## Search Strategy

Use WebSearch for discovery (3-5 targeted searches):
- "[technology/framework] best practices 2025"
- "how to implement [feature] in [technology]"
- "[dependency] security vulnerabilities latest"

Use WebFetch for detailed information from specific sources.

## Output

Save your complete research to: ${SESSION_DIR}/web-research.md

Use the structured format defined in your agent specification.
Focus on actionable information relevant to: $1
Prioritize official sources and recent content (2024-2025).
```

**Important**: Launch both subagents in parallel using separate Task tool calls. This enables simultaneous execution for faster results.

### Phase 2: Sequential Synthesis

After BOTH subagents complete, spawn the synthesis agent to integrate findings.

#### 2. Context Synthesis Agent

Use the Task tool to spawn the `context-synthesis-agent` subagent:

**Subagent**: `context-synthesis-agent`
**Description**: "Synthesize code and web research into actionable insights"
**Model**: sonnet

**Prompt**:
```
Synthesize exploration findings from code search and web research for: $1

## Your Inputs

Read and analyze these two reports:

1. **Code Search Results**: ${SESSION_DIR}/code-search.md
   - What the codebase currently contains
   - Architecture, tests, dependencies, documentation

2. **Web Research Results**: ${SESSION_DIR}/web-research.md
   - Best practices and industry standards
   - Official documentation and guidance
   - Similar solutions and approaches

## Your Task

Create a comprehensive synthesis that:

1. **Integrates Findings**
   - Connect code state with industry best practices
   - Identify gaps between current and recommended approaches
   - Find opportunities for improvement

2. **Assesses Risks**
   - Evaluate technical, security, and maintenance risks
   - Prioritize by severity and likelihood
   - Propose mitigation strategies

3. **Generates Recommendations**
   - Specific, actionable next steps
   - Prioritized by impact and effort (Immediate/Short-term/Long-term)
   - Grounded in both code reality and best practices

4. **Enables Planning**
   - Provide clear direction for implementation
   - Identify trade-offs and decisions needed
   - Define success metrics

## Output

Save your complete synthesis to: ${SESSION_DIR}/synthesis.md

Use the structured format defined in your agent specification.

Focus on:
- Executive summary that captures key insights
- Clear gap analysis (current vs recommended)
- Prioritized findings (Critical/Important/Notable)
- Actionable recommendations with rationale
- Questions for the planning phase
```

Wait for synthesis to complete before proceeding to session persistence.

## Session Persistence

After all subagents complete, update session files with integrated results.

### 1. Update Session CLAUDE.md

Extract key information from the synthesis and update session CLAUDE.md:

Read the synthesis report from `${SESSION_DIR}/synthesis.md` and update `${SESSION_DIR}/CLAUDE.md`:

```markdown
# Session: $1

## Status
Phase: explore → plan
Completed: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Objective
$1

## Context
$2

## Key Findings

[Extract top 3-5 key findings from synthesis - mix of code and web insights]

### From Code Analysis
- [Key component or pattern] (file:line)
- [Test coverage status]
- [Critical dependency or risk]

### From Web Research
- [Best practice or recommendation] (source URL)
- [Security consideration] (source URL)
- [Modern approach to consider] (source URL)

## Gap Analysis

[Extract 2-3 most critical gaps from synthesis]

**Gap 1**: [Current state] → [Recommended state]
**Gap 2**: [Current state] → [Recommended state]

## Critical Insights

[Extract 3-5 most important integrated insights from synthesis]

1. [Insight combining code + web findings]
2. [Insight combining code + web findings]
3. [Insight combining code + web findings]

## Implementation Priorities

### Immediate (Week 1)
1. [Action from synthesis]
2. [Action from synthesis]

### Short-term (Weeks 2-4)
1. [Action from synthesis]
2. [Action from synthesis]

## Risk Factors

🔴 **High**: [Critical risk from synthesis]
🟡 **Medium**: [Important concern from synthesis]

## Next Steps

Run \`/plan ${SESSION_ID}\` to create detailed implementation plan

## References

- Code Analysis: @.claude/sessions/${SESSION_ID}/code-search.md
- Web Research: @.claude/sessions/${SESSION_ID}/web-research.md
- Synthesis: @.claude/sessions/${SESSION_ID}/synthesis.md
- Full Report: @.claude/sessions/${SESSION_ID}/explore.md
```

### 2. Create Comprehensive explore.md

Combine all research outputs into a single comprehensive report:

```markdown
# Exploration Results: $1

**Session ID**: ${SESSION_ID}
**Date**: $(date '+%Y-%m-%d %H:%M')
**Scope**: $1 $2

---

## Executive Summary

[Extract executive summary from synthesis.md]

---

## Table of Contents

1. [Code Search Results](#code-search-results)
2. [Web Research Results](#web-research-results)
3. [Integrated Synthesis](#integrated-synthesis)
4. [Next Steps](#next-steps)

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

The synthesis has identified the following priorities for implementation planning:

**Immediate Actions (Week 1)**:
[List from synthesis]

**Short-term Actions (Weeks 2-4)**:
[List from synthesis]

**Long-term Considerations (Month+)**:
[List from synthesis]

### Questions to Address

[Extract questions from synthesis that need to be resolved during planning]

---

## Session Information

**Session ID**: ${SESSION_ID}
**Session Directory**: .claude/sessions/${SESSION_ID}/
**Completed**: $(date '+%Y-%m-%d %H:%M')

**Files Generated**:
- Session context: CLAUDE.md (auto-loaded in future phases)
- Code analysis: code-search.md
- Web research: web-research.md
- Synthesis: synthesis.md
- Full report: explore.md (this file)

**Tools Used**:
- Code Search: Glob, Grep, Read, Bash [+ MCP if available]
- Web Research: WebSearch, WebFetch [+ MCP if configured]
- Synthesis: Integration and analysis (Sonnet model)

---

**Note**: This exploration used hybrid research combining local codebase analysis with current industry best practices from web research. The synthesis integrates both perspectives to provide actionable, well-grounded recommendations.
```

Save this to `${SESSION_DIR}/explore.md`.

## Completion Checklist

Before considering exploration complete, verify:

- ✅ Session CLAUDE.md created and initialized
- ✅ Code search agent completed successfully
- ✅ Web research agent completed successfully
- ✅ Synthesis agent integrated both sources
- ✅ Key findings identified and prioritized (< 5 most critical)
- ✅ Gap analysis documented (current vs recommended)
- ✅ Recommendations are specific and actionable
- ✅ Risk assessment completed with priorities
- ✅ Session CLAUDE.md updated with synthesis
- ✅ Comprehensive explore.md created
- ✅ All outputs saved to session directory

## User Communication

When exploration is complete, inform the user:

```
✅ Exploration complete for session: ${SESSION_ID}

📊 EXPLORATION SUMMARY

CODE ANALYSIS:
- Files analyzed: [X from code-search.md]
- Components identified: [X from code-search.md]
- Test coverage: ~[X]% from code-search.md]
- Dependencies checked: [X from code-search.md]

WEB RESEARCH:
- Sources consulted: [X from web-research.md]
- Best practices found: [X from web-research.md]
- Official docs reviewed: [X from web-research.md]
- Similar solutions: [X from web-research.md]

🎯 KEY INTEGRATED FINDINGS:

1. [Top finding from synthesis combining code + web]
2. [Second finding from synthesis combining code + web]
3. [Third finding from synthesis combining code + web]

🔴 CRITICAL GAPS IDENTIFIED:

- [Gap 1 from synthesis]: Current [state] → Recommended [state]
- [Gap 2 from synthesis]: Current [state] → Recommended [state]

⚡ IMMEDIATE PRIORITIES:

1. [Priority 1 from synthesis]
2. [Priority 2 from synthesis]

📁 SESSION DETAILS:

Session ID: ${SESSION_ID}
Directory: .claude/sessions/${SESSION_ID}/

Files:
- CLAUDE.md (session context - auto-loads in next phase)
- code-search.md (codebase analysis)
- web-research.md (industry research)
- synthesis.md (integrated insights)
- explore.md (complete report)

🚀 NEXT STEP:

Run `/cc:plan @latest` to create detailed implementation plan based on these findings.

Session context will auto-load from: .claude/sessions/${SESSION_ID}/CLAUDE.md
```

## Optional Flags (Future Enhancement)

The following flags can be implemented for specialized use cases:

### --code-only
Skip web research, only perform code search:
```bash
/explore --code-only <feature> <context>
```

### --web-only
Skip code search, only perform web research:
```bash
/explore --web-only <feature> <context>
```

### --no-synthesis
Skip synthesis, return separate code + web results:
```bash
/explore --no-synthesis <feature> <context>
```

**Note**: These flags are not yet implemented. Current version always performs full hybrid exploration.

## Error Handling

### Web Search Fails

If WebSearch or web research agent encounters errors:
1. Continue with code search only
2. Note limitation in session CLAUDE.md
3. Suggest manual research topics
4. Synthesis will work with code findings only

### Code Search Issues

If codebase is too large or complex:
1. Focus on specific directories (ask user to narrow scope)
2. Use semantic search if MCP is available
3. Document scope limitations
4. Suggest iterative exploration

### MCP Not Available

System gracefully degrades when MCP is not configured:
- **Code search**: Uses traditional Glob/Grep (still effective)
- **Web research**: Uses native WebSearch/WebFetch (built-in)
- **No additional setup required**: Works out of the box

### Synthesis Fails

If synthesis agent encounters errors:
1. Attempt to complete with partial synthesis
2. Save code-search.md and web-research.md as-is
3. Provide basic recommendations
4. Note incomplete synthesis in CLAUDE.md

## Performance Notes

- **Parallel execution**: Code search + Web research run simultaneously (~2x faster than sequential)
- **Context isolation**: Each subagent has separate context window (preserves main context)
- **Token efficiency**:
  - Code search: ~40% reduction if using semantic MCP
  - Web research: Targeted queries vs broad exploration
  - Synthesis: Sonnet only for integration, not discovery
- **Estimated duration**:
  - Code search: 30-60s
  - Web research: 30-90s (in parallel)
  - Synthesis: 20-40s (sequential)
  - Total: ~80-190s for complete exploration

## Architecture Benefits

This hybrid approach provides:

- ✅ **Complete context**: Local code + industry best practices
- ✅ **Current information**: Best practices from 2024-2025
- ✅ **Better decisions**: Grounded in both code reality and modern standards
- ✅ **Risk awareness**: Security advisories and known issues
- ✅ **Actionable insights**: Specific next steps with rationale
- ✅ **Quality synthesis**: Dedicated Sonnet agent for integration
- ✅ **Extensibility**: Optional MCP support for advanced features
- ✅ **Efficiency**: Parallel execution + context isolation

---

**Workflow Pattern**: This command implements the Research-Plan-Execute pattern recommended by Anthropic, with hybrid research combining local codebase analysis and web-based industry research.

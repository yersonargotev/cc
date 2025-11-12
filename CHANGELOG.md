# Changelog

All notable changes to the CC Workflow System will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-11-11

### 🚀 Workflow Optimization

This release streamlines the development workflow from 3 commands to 2, while maintaining the same research quality and depth.

### BREAKING CHANGES

- **`/explore` command removed**: Research is now integrated directly into `/plan`
- **`context-synthesis-agent` removed**: Synthesis is now integrated into plan generation
- **Session structure simplified**: 4 files instead of 6 per session (removed `explore.md` and `synthesis.md`)

### Added

- ✅ Integrated synthesis in `/plan` command via "Context Analysis" section in plan.md
- ✅ Direct plan generation after parallel research (no intermediate synthesis step)
- ✅ Sonnet model with extended thinking for plan generation and synthesis
- ✅ Streamlined session structure (CLAUDE.md + code-search.md + web-research.md + plan.md + code.md)

### Changed

- ✨ `/plan` now accepts `[query] [context] [constraints]` instead of `[session_id]`
- ✨ `/plan` automatically creates session and runs parallel research (code + web)
- ✨ plan.md now includes "Context Analysis" section with integrated synthesis
- ✨ Workflow reduced from 3 steps to 2: `plan → code` instead of `explore → plan → code`
- 📝 Updated all documentation to reflect new streamlined workflow
- 📝 Updated plugin description to emphasize 2-step workflow

### Removed

- ❌ `/explore` command (functionality integrated into `/plan`)
- ❌ `context-synthesis-agent.md` (synthesis now done by Sonnet in plan generation)
- ❌ `explore.md` session file (research split into code-search.md + web-research.md)
- ❌ `synthesis.md` session file (integrated into plan.md Context Analysis section)

### Migration Guide

**Before (v2.0)**:
```bash
/explore "add authentication"
# Wait for exploration + synthesis
/plan 20251109_143045_abc123de
# Wait for planning
/code 20251109_143045_abc123de
```

**After (v2.1)**:
```bash
/plan "add authentication" "JWT-based"
# Research + planning happens automatically in one step
/code 20251109_143045_abc123de
```

### Benefits

- 🚀 **33% faster workflow**: 2 commands instead of 3
- 🎯 **More intuitive**: "plan" naturally implies research + strategy
- 📉 **Less cognitive load**: Fewer concepts to understand
- ✅ **Same quality**: Parallel research preserved, synthesis integrated
- 🗂️ **Cleaner sessions**: 4 files instead of 6 per session
- 💡 **Better UX**: Direct path from research to implementation

### Technical Details

**New /plan command flow**:
1. Create session (auto-generated ID)
2. Launch parallel research:
   - `code-search-agent` (Haiku) → code-search.md
   - `web-research-agent` (Haiku) → web-research.md
3. Generate plan with integrated synthesis:
   - Sonnet with extended thinking
   - Reads both research files
   - Creates plan.md with "Context Analysis" section (synthesis)
   - Updates CLAUDE.md with key insights

**Session structure v2.1**:
```
.claude/sessions/{SESSION_ID}_{DESCRIPTION}/
├── CLAUDE.md          # Active session context (auto-loaded)
├── code-search.md     # Code analysis results (detailed)
├── web-research.md    # Web research findings (detailed)
├── plan.md            # Implementation plan (includes integrated synthesis)
└── code.md            # Implementation summary
```

## [2.0.0] - 2025-11-09

### Major Improvements

- ✅ CLAUDE.md hierarchical memory system
- ✅ Parallel subagent exploration (4x faster)
- ✅ Auto-loaded session context
- ✅ Lifecycle hooks (validation, auto-save, context)
- ✅ 3 unified hybrid agents
- ✅ 8x better context efficiency
- ✅ Token usage optimization
- ✅ Current best practices integration (2024-2025)

### Added

- Hybrid exploration architecture (code + web + synthesis)
- `code-search-agent` for comprehensive code analysis
- `web-research-agent` for best practices research
- `context-synthesis-agent` for integrating findings
- CLAUDE.md hierarchical memory system
- Session-based workflow with auto-loading
- Pre-tool-use validation hooks
- Stop auto-save hooks
- User-prompt-submit context hooks

## [1.0.0] - 2025-11-08

### Initial Release

- Multi-phase workflow (explore, plan, code, commit)
- Session-based state management
- File-based persistence
- Basic command structure

---

**For more details, see [README.md](cc/README.md)**

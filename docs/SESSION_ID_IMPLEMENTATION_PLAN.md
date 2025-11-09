# Session ID v2: Implementation Plan

## Executive Summary

This plan outlines the implementation of the redesigned session ID system (v2) with:
- **Zero breaking changes**: Full backward compatibility with v1
- **Incremental rollout**: Phase-by-phase implementation
- **Safety first**: Extensive testing and validation
- **Developer UX**: Intuitive references and smart lookup

**Estimated timeline**: 2-3 days for core implementation + 1 day testing

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Session ID System v2                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐      ┌──────────────┐      ┌───────────┐ │
│  │  Generator   │─────▶│   Resolver   │─────▶│   Index   │ │
│  └──────────────┘      └──────────────┘      └───────────┘ │
│        │                      │                      │      │
│        │                      │                      │      │
│        ▼                      ▼                      ▼      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Session Directory Structure                  │  │
│  │  .claude/sessions/                                   │  │
│  │  ├── v2-20251109T114715-n7c3fa9k-feature/          │  │
│  │  ├── index.json                                     │  │
│  │  └── refs/                                          │  │
│  │      ├── latest → v2-20251109T114715-n7c3fa9k      │  │
│  │      └── cleanup → ...                              │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Core Infrastructure (Day 1)

### 1.1 Session ID Generator

**File**: `.claude/scripts/generate-session-id.sh`

**Purpose**: Generate v2 session IDs with no external dependencies

**Features**:
- Base32 random ID (8 chars, human-friendly)
- ISO8601 timestamp format
- Kebab-case slug generation
- Fallback random sources (`/dev/urandom` → `$RANDOM`)

**Interface**:
```bash
# Usage
generate_session_id "Remove legacy commands"

# Output
v2-20251109T114715-n7c3fa9k-remove-legacy-commands
```

**Implementation checklist**:
- [ ] Base32 charset definition (exclude ambiguous: 0,1,i,l,o)
- [ ] Random generation with `/dev/urandom`
- [ ] Fallback to `$RANDOM` if urandom unavailable
- [ ] ISO8601 timestamp formatting
- [ ] Slug sanitization (lowercase, hyphens, alphanumeric)
- [ ] Format validation (ensure output matches spec)
- [ ] Unit tests (collision resistance, format compliance)

**Code structure**:
```bash
#!/bin/bash

generate_base32_random() {
  # 8-char base32 ID using /dev/urandom or $RANDOM
}

format_timestamp() {
  # YYYYMMDDTHHmmss format
}

sanitize_slug() {
  # Convert to kebab-case, remove special chars
}

generate_session_id() {
  local description="$1"
  local timestamp=$(format_timestamp)
  local random=$(generate_base32_random)
  local slug=$(sanitize_slug "$description")

  echo "v2-${timestamp}-${random}-${slug}"
}
```

---

### 1.2 Session ID Resolver

**File**: `.claude/scripts/resolve-session-id.sh`

**Purpose**: Resolve user input to full session ID (supports references, short IDs, slugs)

**Features**:
- Exact ID matching
- Reference lookup (`@latest`, `@{1}`, etc.)
- Short ID prefix matching
- Slug fuzzy search
- v1 format compatibility
- Error handling with suggestions

**Interface**:
```bash
# Usage
resolve_session_id "@latest"
resolve_session_id "n7c3f"
resolve_session_id "@/legacy"
resolve_session_id "20251108_093012_k2m9pq8x"  # v1 format

# Output (stdout)
v2-20251109T114715-n7c3fa9k-remove-legacy-commands

# Exit codes
# 0 = success (exactly one match)
# 1 = no match found
# 2 = multiple matches (ambiguous)
```

**Implementation checklist**:
- [ ] Exact match detection (v2 format regex)
- [ ] Reference resolution (`@latest` → lookup in index)
- [ ] Short ID prefix matching (4-16 chars)
- [ ] Slug search (substring or fuzzy)
- [ ] v1 format detection and handling
- [ ] Multiple match disambiguation
- [ ] Error messages with suggestions
- [ ] Integration tests (all reference types)

**Resolution priority**:
1. Exact v2 format → return as-is
2. Reference starting with `@` → lookup refs table
3. Short ID (hex/base32) → prefix match in index
4. Contains `/` → slug search
5. v1 format → legacy lookup
6. Error → show recent sessions

---

### 1.3 Session Index Manager

**File**: `.claude/scripts/session-index.sh`

**Purpose**: Maintain `.claude/sessions/index.json` catalog

**Features**:
- Add new session to index
- Update session metadata
- Lookup by ID, ref, or slug
- Rebuild entire index from directories
- Garbage collection (remove deleted sessions)

**Interface**:
```bash
# Add session
session_index_add "v2-..." "slug" "phase" "status" "branch"

# Update session
session_index_update "v2-..." "phase=implementation" "updated=2025-11-09T12:30:45Z"

# Lookup
session_index_lookup "@latest"
session_index_lookup "n7c3f"

# Rebuild from scratch
session_index_rebuild

# Cleanup
session_index_gc
```

**Index schema**:
```json
{
  "version": "1.0",
  "sessions": {
    "v2-20251109T114715-n7c3fa9k": {
      "slug": "remove-legacy-commands",
      "created": "2025-11-09T11:47:15Z",
      "updated": "2025-11-09T12:30:45Z",
      "phase": "implementation",
      "status": "active",
      "branch": "claude/ultrathink-excellence-011CUxmhrdQBEEfgvNVWvFGq",
      "tags": [],
      "description": ""
    }
  },
  "refs": {
    "@latest": "v2-20251109T114715-n7c3fa9k",
    "@{1}": "v2-20251108T093012-k2m9pq8x"
  },
  "settings": {
    "retention_days": 90,
    "auto_archive": true
  }
}
```

**Implementation checklist**:
- [ ] JSON read/write utilities (using `jq` or pure bash)
- [ ] Add session function
- [ ] Update session function
- [ ] Lookup functions (by ID, ref, slug)
- [ ] Rebuild index from directories
- [ ] Update refs (`@latest`, `@{N}`)
- [ ] Garbage collection
- [ ] Atomic file updates (write to temp, then move)
- [ ] Lock mechanism (prevent concurrent writes)

---

## Phase 2: Integration (Day 2)

### 2.1 Update Session Creation

**File**: `.claude/commands/explore.md`

**Changes**:
```diff
- SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
- SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
- SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
+ SESSION_ID=$(bash .claude/scripts/generate-session-id.sh "$1")
+ SESSION_DIR=".claude/sessions/${SESSION_ID}"
```

**Additional updates**:
- [ ] Call `session_index_add` after creating directory
- [ ] Update `CLAUDE.md` template with session ID field
- [ ] Set initial refs (`@latest` → new session)
- [ ] Test session creation end-to-end

---

### 2.2 Update Session Lookup (Hooks)

#### **File**: `.claude/hooks/pre-tool-use/validate-session.sh`

**Changes**:
```diff
- SESSION_ID=$(echo "$COMMAND" | awk '{for(i=1;i<=NF;i++) if($i ~ /^\/cc:(plan|code)$/ && i<NF) print $(i+1)}')
- SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d 2>/dev/null | head -1)
+ SESSION_REF=$(echo "$COMMAND" | awk '{for(i=1;i<=NF;i++) if($i ~ /^\/cc:(plan|code)$/ && i<NF) print $(i+1)}')
+ SESSION_ID=$(bash .claude/scripts/resolve-session-id.sh "$SESSION_REF")
+ SESSION_DIR=".claude/sessions/${SESSION_ID}"
```

**Implementation checklist**:
- [ ] Use resolver for all session lookups
- [ ] Handle resolution errors gracefully
- [ ] Show suggestions if session not found
- [ ] Test with various reference formats

#### **File**: `.claude/hooks/user-prompt-submit/load-context.sh`

**Changes**:
```diff
- LATEST_SESSION=$(find .claude/sessions -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
- SESSION_ID=$(echo "$SESSION_NAME" | cut -d'_' -f1,2,3)
+ SESSION_ID=$(bash .claude/scripts/session-index.sh lookup "@latest")
+ SESSION_DIR=".claude/sessions/${SESSION_ID}"
```

**Implementation checklist**:
- [ ] Use index for `@latest` lookup (no `find` command)
- [ ] Update session last-accessed timestamp
- [ ] Test auto-loading behavior

#### **File**: `.claude/hooks/stop/auto-save-session.sh`

**Changes**:
```diff
- LATEST_SESSION=$(find .claude/sessions -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
+ SESSION_ID=$(bash .claude/scripts/session-index.sh lookup "@latest")
```

**Additional updates**:
- [ ] Update index with "Last Updated" timestamp
- [ ] Update session status if appropriate
- [ ] Test auto-save updates index correctly

---

### 2.3 Update Commands

#### **File**: `.claude/commands/plan.md`

**Changes**:
```diff
- SESSION_ID="$1"
+ SESSION_REF="$1"
+ SESSION_ID=$(bash .claude/scripts/resolve-session-id.sh "$SESSION_REF")
```

**Implementation checklist**:
- [ ] Support all reference formats
- [ ] Show resolved session ID to user
- [ ] Update session phase to "planning"
- [ ] Test with `@latest`, short IDs, slugs

#### **File**: `.claude/commands/code.md`

**Changes**:
```diff
- SESSION_ID="$1"
+ SESSION_REF="$1"
+ SESSION_ID=$(bash .claude/scripts/resolve-session-id.sh "$SESSION_REF")
```

**Implementation checklist**:
- [ ] Support all reference formats
- [ ] Show resolved session ID to user
- [ ] Update session phase to "implementation"
- [ ] Test with various reference types

---

## Phase 3: Migration & Tooling (Day 2-3)

### 3.1 Migration Command

**File**: `.claude/commands/migrate-sessions.md`

**Purpose**: Convert v1 sessions to v2 format

**Features**:
- Scan for v1 directories
- Parse v1 format components
- Rename to v2 format
- Update index
- Dry-run mode (preview changes)

**Interface**:
```bash
# Dry run (show what would happen)
/migrate-sessions --dry-run

# Execute migration
/migrate-sessions

# Migrate specific session
/migrate-sessions 20251108_093012_k2m9pq8x
```

**Implementation checklist**:
- [ ] Detect v1 directories (regex pattern)
- [ ] Parse v1 components (date, time, random, description)
- [ ] Convert to v2 format
- [ ] Preserve all files in directory
- [ ] Update index after migration
- [ ] Dry-run mode
- [ ] Progress reporting
- [ ] Rollback on error

---

### 3.2 Session Browser

**File**: `.claude/commands/list-sessions.md`

**Purpose**: User-friendly session browsing and management

**Features**:
- List all sessions (recent first)
- Filter by status, phase, tags
- Show session details
- Pretty formatting

**Interface**:
```bash
# List all sessions
/list-sessions

# Filter by phase
/list-sessions --phase=implementation

# Show details
/list-sessions --verbose

# Limit results
/list-sessions --limit=10
```

**Output format**:
```
📋 Sessions (5 total)

  🟢 v2-20251109T114715-n7c3fa9k (remove-legacy-commands)
     Phase: implementation | Updated: 2h ago
     Branch: claude/ultrathink-excellence-011CUxmhrdQBEEfgvNVWvFGq

  ⚪ v2-20251108T093012-k2m9pq8x (add-session-refs)
     Phase: completed | Updated: 1d ago
     Branch: main

References:
  @latest → v2-20251109T114715-n7c3fa9k
  @{1}    → v2-20251108T093012-k2m9pq8x
```

**Implementation checklist**:
- [ ] Read from index (fast, no directory scans)
- [ ] Sort by updated timestamp
- [ ] Filter by phase, status, tags
- [ ] Format output with colors/emojis
- [ ] Show references and shortcuts
- [ ] Test with large session counts

---

### 3.3 Index Rebuild Tool

**File**: `.claude/commands/rebuild-index.md`

**Purpose**: Rebuild session index from directory structure (recovery tool)

**Features**:
- Scan all session directories
- Parse CLAUDE.md for metadata
- Rebuild index.json from scratch
- Update refs based on timestamps

**Interface**:
```bash
# Rebuild index
/rebuild-index

# Verify index integrity
/rebuild-index --verify
```

**Implementation checklist**:
- [ ] Scan `.claude/sessions/` for session directories
- [ ] Detect format (v1 or v2) from directory name
- [ ] Read CLAUDE.md for metadata
- [ ] Rebuild index.json
- [ ] Recalculate refs (@latest, @{N})
- [ ] Verify all sessions are indexed
- [ ] Test with mixed v1/v2 sessions

---

## Phase 4: Testing & Documentation (Day 3)

### 4.1 Unit Tests

**File**: `.claude/tests/test-session-id.sh`

**Coverage**:
- [ ] Session ID generation (format, uniqueness)
- [ ] Base32 random (collision resistance, charset)
- [ ] Slug sanitization (edge cases, unicode)
- [ ] Timestamp formatting (timezone handling)
- [ ] Resolver (all reference types)
- [ ] Index operations (add, update, lookup)
- [ ] Migration (v1 → v2 conversion)

**Test cases**:
```bash
# Generation tests
test_generate_id_format
test_generate_id_unique
test_generate_id_no_dependencies
test_slug_sanitization_edge_cases

# Resolution tests
test_resolve_exact_id
test_resolve_latest_ref
test_resolve_numbered_ref
test_resolve_short_id
test_resolve_slug_search
test_resolve_v1_format
test_resolve_ambiguous
test_resolve_not_found

# Index tests
test_index_add_session
test_index_update_session
test_index_lookup_by_id
test_index_lookup_by_ref
test_index_rebuild
test_index_concurrent_writes

# Migration tests
test_migrate_v1_to_v2
test_migrate_preserves_files
test_migrate_updates_index
```

---

### 4.2 Integration Tests

**File**: `.claude/tests/test-session-workflow.sh`

**Scenarios**:
- [ ] Create session with `/explore`
- [ ] Reference with `@latest`
- [ ] Plan with short ID
- [ ] Code with slug search
- [ ] Migrate old session
- [ ] List and filter sessions
- [ ] Rebuild index

**End-to-end flow**:
```bash
# 1. Create new session
/explore "Test feature implementation"
# → v2-20251109T120000-abc123de-test-feature-implementation

# 2. Reference with @latest
/cc:plan @latest
# → Resolves to v2-20251109T120000-abc123de

# 3. Use short ID
/cc:code abc1
# → Resolves to v2-20251109T120000-abc123de

# 4. List sessions
/list-sessions
# → Shows all sessions with status

# 5. Migrate old session
/migrate-sessions 20251108_093012_k2m9pq8x
# → Converts to v2-20251108T093012-k2m9pq8x-old-feature
```

---

### 4.3 Documentation Updates

#### **File**: `.claude/CLAUDE.md`

**Updates**:
- [ ] Document v2 session ID format
- [ ] Explain reference system (@latest, @{N}, etc.)
- [ ] Show examples of all reference types
- [ ] Migration guide (v1 → v2)
- [ ] Troubleshooting section

#### **File**: `.claude/README.md`

**New section**: "Session Management"
- [ ] Overview of session lifecycle
- [ ] How to create, reference, and manage sessions
- [ ] Advanced features (refs, short IDs, slugs)
- [ ] Best practices

#### **File**: `.claude/MIGRATION.md` (new)

**Content**:
- [ ] Why v2 format is better
- [ ] Backward compatibility guarantees
- [ ] Step-by-step migration guide
- [ ] Rollback procedure (if needed)
- [ ] FAQ

---

## Phase 5: Rollout (Day 3+)

### 5.1 Soft Launch

**Week 1**: Dual-format support
- [ ] Deploy v2 generation for new sessions
- [ ] All hooks support both v1 and v2
- [ ] Index includes both formats
- [ ] Monitor for issues

**Validation**:
- [ ] New sessions use v2 format
- [ ] Old sessions still work
- [ ] References resolve correctly
- [ ] No regressions in existing workflows

### 5.2 Migration Promotion

**Week 2**: Encourage migration
- [ ] Document migration benefits
- [ ] Provide migration command
- [ ] Show migration status in `/list-sessions`
- [ ] Optional: Add warning for v1 usage

### 5.3 (Optional) Deprecation

**Month 2+**: v1 deprecation (optional)
- [ ] Warn on v1 session access
- [ ] Require explicit flag to use v1
- [ ] Eventually remove v1 support (or keep for compatibility)

---

## Success Metrics

### Performance
- [ ] Session ID generation: < 10ms
- [ ] Reference resolution: < 50ms (index lookup)
- [ ] Index updates: < 100ms

### Reliability
- [ ] Zero collisions in 10,000 generated IDs
- [ ] 100% backward compatibility with v1
- [ ] No data loss during migration

### Usability
- [ ] Users prefer `@latest` over full IDs (survey)
- [ ] Short IDs work in 95%+ of cases (no ambiguity)
- [ ] Migration completes in < 1 minute for 100 sessions

---

## Risk Mitigation

### Risk: Index corruption
- **Mitigation**: Rebuild tool, atomic writes, backups
- **Recovery**: `/rebuild-index` restores from directories

### Risk: Migration data loss
- **Mitigation**: Dry-run mode, backup recommendation
- **Recovery**: Keep original directories until verified

### Risk: Performance degradation
- **Mitigation**: Index-based lookups (no directory scans)
- **Monitoring**: Track resolution times

### Risk: User confusion
- **Mitigation**: Clear documentation, examples, error messages
- **Support**: Troubleshooting guide, FAQ

---

## Open Questions

1. **Session archival**: Should old sessions auto-archive after N days?
   - **Proposal**: Add `retention_days` setting in index
   - **Action**: Implement in Phase 3 if needed

2. **Custom refs**: Should users create named refs (like git tags)?
   - **Proposal**: Allow `/.claude-tag <name> <session-id>`
   - **Action**: Add in Phase 3 if requested

3. **Session search**: Full-text search across session content?
   - **Proposal**: Index session descriptions and objectives
   - **Action**: Defer to Phase 4 (future enhancement)

4. **Multi-project support**: Different index per project?
   - **Proposal**: Keep index in `.claude/sessions/` (local to repo)
   - **Action**: Current design handles this

---

## Timeline Summary

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1: Core Infrastructure | 1 day | Generator, Resolver, Index manager |
| Phase 2: Integration | 1 day | Updated commands and hooks |
| Phase 3: Migration & Tooling | 0.5 day | Migration, list, rebuild commands |
| Phase 4: Testing & Docs | 0.5 day | Tests, documentation |
| Phase 5: Rollout | Ongoing | Deployment and monitoring |

**Total**: 3 days for implementation, 1+ week for rollout and validation

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Prioritize features**: Must-have vs. nice-to-have
3. **Create implementation branch**: `feature/session-id-v2`
4. **Begin Phase 1**: Core infrastructure
5. **Iterate and refine** based on feedback

---

*"The details are not the details. They make the design."* — Charles Eames

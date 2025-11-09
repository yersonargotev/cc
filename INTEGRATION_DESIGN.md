# Session Manager v2 → CC Workflow Integration Design

**Document Version**: 1.0
**Date**: 2025-11-09
**Status**: Phase 1 - Design & Preparation
**Branch**: `claude/integrate-session-manager-v2-011CUxmhrdQBEEfgvNVWvFGq`

---

## Executive Summary

This document details the technical design for integrating **Session Manager v2** infrastructure into the **CC Workflow System**, creating a unified plugin that combines:
- Robust session ID management (v2 format)
- Multi-phase workflow (explore → plan → code → commit)
- Git-like references and intelligent search
- Zero external dependencies

**Status**: ✅ **APPROVED FOR IMPLEMENTATION**

---

## Table of Contents

1. [Integration Architecture](#integration-architecture)
2. [Component Mapping](#component-mapping)
3. [File Structure Changes](#file-structure-changes)
4. [Script Integration](#script-integration)
5. [Command Updates](#command-updates)
6. [Hook Integration](#hook-integration)
7. [Migration Strategy](#migration-strategy)
8. [Testing Strategy](#testing-strategy)
9. [Rollback Plan](#rollback-plan)

---

## Integration Architecture

### Current State

**CC Workflow System**:
```
cc/
├── .claude-plugin/plugin.json
├── commands/
│   ├── explore.md          # Uses v1 format (OpenSSL)
│   ├── plan.md             # Uses find with wildcard
│   ├── code.md             # Uses find with wildcard
│   └── commit.md
├── hooks/
│   ├── hooks.json
│   ├── pre-tool-use/
│   ├── stop/
│   └── user-prompt-submit/
└── agents/
    ├── code-search-agent.md
    ├── web-research-agent.md
    └── context-synthesis-agent.md
```

**Session Manager v2**:
```
session-manager/
├── .claude-plugin/plugin.json
├── scripts/
│   ├── generate-session-id.sh    # v2 ID generation
│   ├── resolve-session-id.sh     # Reference resolver
│   └── session-index.sh          # Index management
├── commands/
│   ├── explore.md                # v2 session creation
│   ├── session-list.md
│   ├── session-migrate.md
│   └── session-rebuild-index.md
├── hooks/
│   ├── session-start/
│   ├── session-end/
│   ├── pre-tool-use/
│   └── stop/
└── skills/
    └── session-finder/
```

### Target State

**CC Unified System**:
```
cc/
├── .claude-plugin/plugin.json     # Updated metadata
├── scripts/                       # ← NEW from Session Manager v2
│   ├── generate-session-id.sh
│   ├── resolve-session-id.sh
│   └── session-index.sh
├── commands/
│   ├── explore.md                 # UPDATED: uses v2 IDs
│   ├── plan.md                    # UPDATED: uses resolver
│   ├── code.md                    # UPDATED: uses resolver
│   ├── commit.md                  # NO CHANGE
│   ├── session-list.md            # ← NEW
│   ├── session-migrate.md         # ← NEW
│   └── session-rebuild-index.md   # ← NEW
├── hooks/
│   ├── hooks.json                 # UPDATED: add new hooks
│   ├── session-start/             # ← NEW
│   ├── session-end/               # ← NEW
│   ├── pre-tool-use/              # UPDATED: merge logic
│   ├── stop/                      # UPDATED: merge logic
│   └── user-prompt-submit/        # NO CHANGE
├── skills/                        # ← NEW
│   └── session-finder/
└── agents/                        # NO CHANGE
    ├── code-search-agent.md
    ├── web-research-agent.md
    └── context-synthesis-agent.md
```

---

## Component Mapping

### Session ID Format

**Before (v1)**:
```
Format: YYYYMMDD_HHMMSS_hex_description
Example: 20251109_114715_f0903a7c_remove_legacy_comman
Components:
  - Date: YYYYMMDD
  - Time: HHMMSS
  - Random: 8-char hex (OpenSSL)
  - Desc: 20-char truncated
```

**After (v2)**:
```
Format: v2-YYYYMMDDTHHmmss-base32random-kebab-slug
Example: v2-20251109T114715-n7c3fa9k-remove-legacy-commands
Components:
  - Version: v2
  - Timestamp: ISO8601 compact
  - Random: 8-char base32 (no deps)
  - Slug: Unlimited kebab-case
```

### Session Directory Structure

**Before**:
```
.claude/sessions/20251109_114715_f0903a7c_remove_legacy_comman/
├── CLAUDE.md
├── activity.log
├── explore.md
├── code-search.md
├── web-research.md
├── synthesis.md
├── plan.md
└── code.md
```

**After**:
```
.claude/sessions/v2-20251109T114715-n7c3fa9k-remove-legacy-commands/
├── CLAUDE.md           # UPDATED: new metadata format
├── activity.log        # NO CHANGE
├── explore.md          # NO CHANGE
├── code-search.md      # NO CHANGE
├── web-research.md     # NO CHANGE
├── synthesis.md        # NO CHANGE
├── plan.md             # NO CHANGE
└── code.md             # NO CHANGE
```

**NEW**: Index file
```
.claude/sessions/index.json
{
  "version": "1.0",
  "created": "2025-11-09T19:25:00Z",
  "sessions": {
    "v2-20251109T114715-n7c3fa9k-remove-legacy-commands": {
      "slug": "remove-legacy-commands",
      "created": "2025-11-09T11:47:15Z",
      "updated": "2025-11-09T19:20:00Z",
      "phase": "implementation",
      "status": "completed",
      "branch": "claude/ultrathink-excellence-011CUxmhrdQBEEfgvNVWvFGq",
      "tags": []
    }
  },
  "refs": {
    "@latest": "v2-20251109T114715-n7c3fa9k-remove-legacy-commands"
  },
  "settings": {
    "retention_days": 90,
    "auto_archive": true
  }
}
```

---

## File Structure Changes

### Phase 1: Add Scripts Directory

```bash
# Copy scripts from session-manager to cc
mkdir -p cc/scripts
cp session-manager/scripts/generate-session-id.sh cc/scripts/
cp session-manager/scripts/resolve-session-id.sh cc/scripts/
cp session-manager/scripts/session-index.sh cc/scripts/

# Make executable
chmod +x cc/scripts/*.sh
```

### Phase 2: Add New Commands

```bash
# Copy new commands
cp session-manager/commands/session-list.md cc/commands/
cp session-manager/commands/session-migrate.md cc/commands/
cp session-manager/commands/session-rebuild-index.md cc/commands/
```

### Phase 3: Add Skills Directory

```bash
# Copy session-finder skill
mkdir -p cc/skills
cp -r session-manager/skills/session-finder cc/skills/
```

### Phase 4: Add New Hooks

```bash
# Copy new hook directories
mkdir -p cc/hooks/session-start
mkdir -p cc/hooks/session-end

cp session-manager/hooks/session-start/load-active-session.sh cc/hooks/session-start/
cp session-manager/hooks/session-end/save-session-state.sh cc/hooks/session-end/
```

---

## Script Integration

### 1. generate-session-id.sh

**Purpose**: Generate v2 format session IDs without OpenSSL

**Integration Points**:
- `/cc:explore` command
- Session creation workflows

**Usage**:
```bash
SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/generate-session-id.sh" "$DESCRIPTION")
```

**Changes Required**: None (copy as-is)

### 2. resolve-session-id.sh

**Purpose**: Resolve session references to full IDs

**Integration Points**:
- `/cc:plan` command
- `/cc:code` command
- PreToolUse hook

**Supported References**:
- `@latest` → Most recent session
- `@` → Shorthand for @latest
- `@{1}` → Second most recent
- `n7c3fa9k` → Short ID (8 chars)
- `@/auth` → Slug search
- Full ID → Pass through

**Usage**:
```bash
RESOLVED_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" "$SESSION_REF")
if [ $? -ne 0 ]; then
  echo "❌ Failed to resolve: $SESSION_REF"
  exit 1
fi
```

**Changes Required**: None (copy as-is)

### 3. session-index.sh

**Purpose**: Manage `.claude/sessions/index.json`

**Operations**:
- `init` - Initialize index
- `add <id> <slug> <phase> <status> <branch>` - Add session
- `update <id> --phase <phase>` - Update metadata
- `set-ref <ref> <id>` - Set reference (@latest)
- `lookup <ref>` - Find session by reference
- `rebuild` - Rebuild index from directories

**Integration Points**:
- `/cc:explore` - Add new session
- `/cc:plan` - Update phase
- `/cc:code` - Update phase
- Stop hook - Update timestamps

**Usage**:
```bash
# Add session
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" add \
  "$SESSION_ID" "$SLUG" "exploration" "in_progress" "$BRANCH"

# Update phase
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" update "$SESSION_ID" \
  --phase "planning"

# Set @latest
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" set-ref "@latest" "$SESSION_ID"
```

**Changes Required**: None (copy as-is)

---

## Command Updates

### /cc:explore

**Current Implementation** (lines 16-19):
```bash
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
SESSION_DESC=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | head -c 20)
SESSION_DIR=".claude/sessions/${SESSION_ID}_${SESSION_DESC}"
```

**New Implementation**:
```bash
# Generate v2 session ID
echo "🔨 Generating session ID..."
SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/generate-session-id.sh" "$1")

if [ $? -ne 0 ] || [ -z "$SESSION_ID" ]; then
  echo "❌ Failed to generate session ID"
  exit 1
fi

echo "✅ Generated: $SESSION_ID"
echo ""

# Extract slug from v2 ID
SLUG=$(echo "$SESSION_ID" | cut -d'-' -f4-)

# Create session directory
SESSION_DIR=".claude/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
```

**Additional Changes** (after CLAUDE.md creation):
```bash
# Add to session index
echo "📇 Adding to session index..."
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" add \
  "$SESSION_ID" \
  "$SLUG" \
  "exploration" \
  "in_progress" \
  "$BRANCH" || echo "⚠️  Warning: Failed to add to index"

# Set as @latest
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" set-ref "@latest" "$SESSION_ID" || true

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
echo "  @latest              - Always refers to this session"
echo "  @                    - Shorthand for @latest"
echo "  $(echo "$SESSION_ID" | cut -d'-' -f3)             - Short ID (8 chars)"
echo "  @/$SLUG - Slug search"
echo ""
```

**CLAUDE.md Template Updates**:
```markdown
# Session: $1

## Status
Phase: explore
Started: $(date '+%Y-%m-%d %H:%M')
Last Updated: $(date '+%Y-%m-%d %H:%M')
Session ID: ${SESSION_ID}

## Technical Details
- Session Format: v2
- Branch: $BRANCH
- Quick References: @latest, $(echo "$SESSION_ID" | cut -d'-' -f3), @/$SLUG

## Objective
$1

## Context
$2

## Key Findings
[To be populated during exploration]

## Next Steps
Run `/cc:plan @latest` to create implementation plan

## References
@.claude/sessions/${SESSION_ID}/explore.md
```

### /cc:plan

**Current Implementation** (lines 16-24):
```bash
SESSION_ID="$1"
SESSION_DIR=$(find .claude/sessions -name "${SESSION_ID}_*" -type d | head -1)

if [ -z "$SESSION_DIR" ]; then
    echo "❌ Error: Session $SESSION_ID not found"
    exit 1
fi
```

**New Implementation**:
```bash
SESSION_REF="$1"

# Resolve session reference
echo "🔍 Resolving session reference: $SESSION_REF"
SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" "$SESSION_REF" 2>&1)

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to resolve session reference '$SESSION_REF'"
    echo ""
    echo "$SESSION_ID"  # Error message from resolver
    echo ""
    echo "💡 Tip: Use /session-list to see available sessions"
    exit 1
fi

echo "✅ Resolved: $SESSION_REF → $SESSION_ID"
echo ""

# Session directory (no wildcard needed with v2)
SESSION_DIR=".claude/sessions/${SESSION_ID}"

if [ ! -d "$SESSION_DIR" ]; then
    echo "❌ Error: Session directory not found: $SESSION_DIR"
    exit 1
fi
```

**Additional Changes** (after planning):
```bash
# Update session index - change phase to planning
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" update "$SESSION_ID" \
  --phase "planning" || echo "⚠️  Warning: Failed to update index"
```

### /cc:code

**Same changes as /cc:plan**, plus:

```bash
# After implementation, update to implementation phase
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" update "$SESSION_ID" \
  --phase "implementation" || echo "⚠️  Warning: Failed to update index"
```

### /cc:commit

**No changes required** - commit command doesn't use session IDs

---

## Hook Integration

### PreToolUse Hook

**Current** (cc/hooks/pre-tool-use/validate-session.sh):
- Validates session exists for plan/code
- Uses `find` with wildcard matching

**New** (session-manager/hooks/pre-tool-use/validate-session.sh):
- Validates session references using resolver
- Provides helpful error messages

**Merged Implementation**:
```bash
#!/bin/bash
# PreToolUse Hook: Unified Session Validation
# Combines CC workflow validation + Session Manager v2 resolver

set -euo pipefail

COMMAND="$1"
PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"

# Only validate session-related commands
if ! echo "$COMMAND" | grep -qE "/cc:(plan|code)"; then
  exit 0  # Not a session command, allow
fi

# Extract session reference from command
SESSION_REF=$(echo "$COMMAND" | awk '{print $2}')

# Default to @latest if not provided
if [ -z "$SESSION_REF" ]; then
  SESSION_REF="@latest"
fi

# Resolve session reference
if [ ! -x "$PLUGIN_DIR/scripts/resolve-session-id.sh" ]; then
  echo "⚠️  Session resolver not available"
  exit 0  # Don't block if resolver missing
fi

RESOLVED_ID=$(bash "$PLUGIN_DIR/scripts/resolve-session-id.sh" "$SESSION_REF" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "❌ Session reference '$SESSION_REF' could not be resolved"
  echo ""
  echo "$RESOLVED_ID"  # Error message from resolver
  echo ""
  echo "💡 Available commands:"
  echo "   /session-list              - View all sessions"
  echo "   /cc:explore <description>  - Create new session"
  exit 1  # Block tool execution
fi

# Validation succeeded - check workflow requirements
SESSION_DIR=".claude/sessions/${RESOLVED_ID}"

# For code phase, ensure plan exists
if echo "$COMMAND" | grep -q '/cc:code'; then
  if [ ! -f "$SESSION_DIR/plan.md" ]; then
    echo "❌ Validation Error: No plan found for session"
    echo ""
    echo "💡 Run /cc:plan $SESSION_REF to create implementation plan first"
    exit 1
  fi
fi

echo "✅ Session resolved: $SESSION_REF → $RESOLVED_ID"
exit 0  # Allow tool execution
```

### Stop Hook

**Current** (cc/hooks/stop/auto-save-session.sh):
- Updates timestamps in CLAUDE.md
- Appends to activity.log

**New** (session-manager/hooks/stop/update-session-metadata.sh):
- Updates session index with timestamps

**Merged Implementation**:
```bash
#!/bin/bash
# Stop Hook: Unified Session State Management
# Updates both CLAUDE.md and session index

set -euo pipefail

PLUGIN_DIR="${CLAUDE_PLUGIN_DIR}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Find active session (most recently modified CLAUDE.md)
ACTIVE_SESSION=$(find .claude/sessions -name "CLAUDE.md" -type f -printf '%T@ %p\n' 2>/dev/null | \
  sort -rn | head -1 | awk '{print $2}' | xargs dirname 2>/dev/null)

if [ -z "$ACTIVE_SESSION" ] || [ ! -d "$ACTIVE_SESSION" ]; then
  exit 0  # No active session
fi

SESSION_ID=$(basename "$ACTIVE_SESSION")

# Update CLAUDE.md timestamp
if [ -f "$ACTIVE_SESSION/CLAUDE.md" ]; then
  sed -i "s/^Last Updated:.*/Last Updated: $(date '+%Y-%m-%d %H:%M')/" \
    "$ACTIVE_SESSION/CLAUDE.md" 2>/dev/null || true
fi

# Update activity log
if [ -f "$ACTIVE_SESSION/activity.log" ]; then
  echo "[$TIMESTAMP] Session checkpoint" >> "$ACTIVE_SESSION/activity.log"
fi

# Update session index
if [ -x "$PLUGIN_DIR/scripts/session-index.sh" ]; then
  bash "$PLUGIN_DIR/scripts/session-index.sh" update "$SESSION_ID" \
    --updated "$TIMESTAMP" 2>/dev/null || true
fi

exit 0
```

### SessionStart Hook (NEW)

**Source**: session-manager/hooks/session-start/load-active-session.sh

**Purpose**: Auto-load active session context on Claude Code startup

**Implementation**:
```bash
#!/bin/bash
# SessionStart Hook: Load Active Session
# Displays active session info on startup

set -euo pipefail

# Find @latest session
if [ -f ".claude/sessions/index.json" ]; then
  LATEST_ID=$(jq -r '.refs["@latest"] // empty' .claude/sessions/index.json 2>/dev/null)

  if [ -n "$LATEST_ID" ]; then
    SESSION_DATA=$(jq -r ".sessions[\"$LATEST_ID\"] // empty" .claude/sessions/index.json 2>/dev/null)

    if [ -n "$SESSION_DATA" ]; then
      SLUG=$(echo "$SESSION_DATA" | jq -r '.slug')
      PHASE=$(echo "$SESSION_DATA" | jq -r '.phase')
      STATUS=$(echo "$SESSION_DATA" | jq -r '.status')
      BRANCH=$(echo "$SESSION_DATA" | jq -r '.branch')

      echo "📊 Active Session Loaded"
      echo ""
      echo "  🟢 $LATEST_ID"
      echo ""
      echo "  Name: $SLUG"
      echo "  Phase: $PHASE"
      echo "  Status: $STATUS"
      echo "  Branch: $BRANCH"
      echo ""
      echo "💡 Quick references:"
      echo "   @latest, @, $(echo "$LATEST_ID" | cut -d'-' -f3), @/$SLUG"
      echo ""
    fi
  fi
fi

exit 0
```

### SessionEnd Hook (NEW)

**Source**: session-manager/hooks/session-end/save-session-state.sh

**Purpose**: Save session state on Claude Code exit

**Implementation**: Similar to Stop hook but runs on exit

### hooks.json Update

```json
{
  "SessionStart": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/session-start/load-active-session.sh"
        }
      ]
    }
  ],
  "SessionEnd": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/session-end/save-session-state.sh"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "SlashCommand",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/pre-tool-use/validate-session.sh"
        }
      ]
    }
  ],
  "Stop": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/stop/update-metadata.sh"
        }
      ]
    }
  ],
  "UserPromptSubmit": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$CLAUDE_PLUGIN_DIR\"/hooks/user-prompt-submit/load-context.sh"
        }
      ]
    }
  ]
}
```

---

## Migration Strategy

### Automatic Migration Tool

**Command**: `/session-migrate`

**Process**:
1. Scan `.claude/sessions/` for v1 format directories
2. For each v1 session:
   - Parse v1 ID components
   - Generate equivalent v2 ID
   - Create symlink or rename directory
   - Update CLAUDE.md with new metadata
   - Add to session index
3. Verify all migrations succeeded
4. Update @latest reference

**Example**:
```
v1: 20251109_114715_f0903a7c_remove_legacy_comman
v2: v2-20251109T114715-n7c3fa9k-remove-legacy-commands
```

**Migration Script Logic**:
```bash
# Extract v1 components
DATE=$(echo "$V1_ID" | cut -d'_' -f1)     # 20251109
TIME=$(echo "$V1_ID" | cut -d'_' -f2)     # 114715
HEX=$(echo "$V1_ID" | cut -d'_' -f3)      # f0903a7c
DESC=$(echo "$V1_ID" | cut -d'_' -f4-)    # remove_legacy_comman

# Convert to v2 components
TIMESTAMP="${DATE}T${TIME}"                # 20251109T114715
BASE32=$(convert_hex_to_base32 "$HEX")    # n7c3fa9k
SLUG=$(echo "$DESC" | tr '_' '-')         # remove-legacy-comman

# Construct v2 ID
V2_ID="v2-${TIMESTAMP}-${BASE32}-${SLUG}"
```

### Manual Migration (Fallback)

If automatic migration fails:

```bash
# List v1 sessions
ls -1 .claude/sessions/ | grep -v '^v2-'

# Manually rename
mv .claude/sessions/OLD_ID .claude/sessions/NEW_ID

# Rebuild index
/session-rebuild-index
```

---

## Testing Strategy

### Unit Tests

**Script Tests**:
```bash
# Test generate-session-id.sh
test_generate_valid_id() {
  ID=$(bash scripts/generate-session-id.sh "Test Description")
  assert_matches "$ID" "^v2-[0-9]{8}T[0-9]{6}-[a-z0-9]{8}-.+"
}

# Test resolve-session-id.sh
test_resolve_latest() {
  ID=$(bash scripts/resolve-session-id.sh "@latest")
  assert_not_empty "$ID"
}

# Test session-index.sh
test_add_session() {
  bash scripts/session-index.sh add "v2-test-id" "test" "explore" "active" "main"
  assert_exists ".claude/sessions/index.json"
}
```

### Integration Tests

**Command Tests**:
```bash
# Test /cc:explore with v2 IDs
test_explore_creates_v2_session() {
  /cc:explore "Test Feature"

  # Verify v2 format created
  LATEST=$(ls -t .claude/sessions/ | head -1)
  assert_matches "$LATEST" "^v2-"

  # Verify index updated
  assert_json_has ".claude/sessions/index.json" ".refs[\"@latest\"]"
}

# Test /cc:plan with resolver
test_plan_resolves_latest() {
  /cc:plan @latest

  # Should not error
  assert_success
}
```

### E2E Tests

**Full Workflow**:
```bash
test_full_workflow_v2() {
  # 1. Create session
  /cc:explore "E2E Test Feature"
  SESSION_ID=$(jq -r '.refs["@latest"]' .claude/sessions/index.json)

  # 2. Create plan
  /cc:plan @latest
  assert_exists ".claude/sessions/$SESSION_ID/plan.md"

  # 3. Implement
  /cc:code @latest
  assert_exists ".claude/sessions/$SESSION_ID/code.md"

  # 4. Verify references work
  SHORT_ID=$(echo "$SESSION_ID" | cut -d'-' -f3)
  /cc:plan $SHORT_ID
  assert_success
}
```

---

## Rollback Plan

### If Integration Fails

**Step 1**: Restore from backup
```bash
# Remove integrated changes
git reset --hard HEAD~N

# Restore sessions backup
rm -rf .claude/sessions/
tar -xzf .claude/sessions-backup-phase1.tar.gz
```

**Step 2**: Verify restoration
```bash
# Check sessions exist
ls -l .claude/sessions/

# Verify commands work
/cc:explore "Rollback Test"
```

**Step 3**: Document issues
```bash
# Create rollback report
echo "Rollback performed: $(date)" >> INTEGRATION_ROLLBACK.md
echo "Reason: [FILL IN]" >> INTEGRATION_ROLLBACK.md
```

### Partial Rollback

If only specific components fail:

```bash
# Rollback scripts only
rm -rf cc/scripts
git checkout HEAD -- cc/scripts

# Rollback commands only
git checkout HEAD -- cc/commands/explore.md
git checkout HEAD -- cc/commands/plan.md
git checkout HEAD -- cc/commands/code.md
```

---

## Success Criteria

### Phase 1 Complete When:
- [x] Branch created
- [x] Backup created
- [x] Integration design documented
- [ ] Structure planned and approved

### Phase 2 Complete When:
- [ ] Scripts copied and tested
- [ ] Commands updated and functional
- [ ] Index creation working
- [ ] v2 session creation tested

### Phase 3 Complete When:
- [ ] Hooks merged and configured
- [ ] hooks.json updated
- [ ] Hook tests passing

### Phase 4 Complete When:
- [ ] New commands added
- [ ] /session-list functional
- [ ] /session-migrate tested

### Phase 5 Complete When:
- [ ] session-finder skill integrated
- [ ] Natural language search working

### Phase 6 Complete When:
- [ ] Existing sessions migrated
- [ ] No v1 sessions remaining
- [ ] Index complete

### Phase 7 Complete When:
- [ ] Documentation updated
- [ ] All tests passing
- [ ] Examples updated
- [ ] Ready for release

---

## Next Steps

**Immediate** (Phase 1 Completion):
1. Review this design document
2. Get approval to proceed
3. Create base structure (scripts/, skills/ directories)

**Phase 2 Start**:
1. Copy scripts from session-manager
2. Update /cc:explore command
3. Test v2 session creation
4. Verify index creation

---

**Document Status**: ✅ **READY FOR REVIEW**
**Branch**: `claude/integrate-session-manager-v2-011CUxmhrdQBEEfgvNVWvFGq`
**Backup**: `.claude/sessions-backup-phase1.tar.gz`

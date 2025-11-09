# Session Manager v2 Integration Checklist

**Branch**: `claude/integrate-session-manager-v2-011CUxmhrdQBEEfgvNVWvFGq`
**Started**: 2025-11-09
**Status**: Phase 1 - Preparation

---

## Phase 1: Preparation ✅

**Timeline**: Days 1-3 (Complete)

- [x] Create integration branch
- [x] Create backup of existing sessions
- [x] Document integration design (`INTEGRATION_DESIGN.md`)
- [x] Create base directory structure (scripts/, skills/)
- [x] Create tracking documents
- [ ] **Review and approve design** ← PENDING USER APPROVAL

**Deliverables**:
- ✅ Branch: `claude/integrate-session-manager-v2-011CUxmhrdQBEEfgvNVWvFGq`
- ✅ Backup: `.claude/sessions-backup-phase1.tar.gz`
- ✅ Design: `INTEGRATION_DESIGN.md`
- ✅ Directories: `cc/scripts/`, `cc/skills/`

---

## Phase 2: Script Integration

**Timeline**: Days 4-7

### 2.1 Copy Scripts
- [ ] Copy `generate-session-id.sh` to `cc/scripts/`
- [ ] Copy `resolve-session-id.sh` to `cc/scripts/`
- [ ] Copy `session-index.sh` to `cc/scripts/`
- [ ] Make all scripts executable (`chmod +x`)

### 2.2 Test Scripts Independently
- [ ] Test `generate-session-id.sh` with various descriptions
- [ ] Test `resolve-session-id.sh` with different references
- [ ] Test `session-index.sh` operations (init, add, update)
- [ ] Verify zero external dependencies

### 2.3 Update /cc:explore Command
- [ ] Replace OpenSSL-based ID generation
- [ ] Use `generate-session-id.sh` for session IDs
- [ ] Update directory structure (no underscore suffix)
- [ ] Add session to index after creation
- [ ] Set @latest reference
- [ ] Update CLAUDE.md template with v2 metadata
- [ ] Update output messages with quick references

### 2.4 Test v2 Session Creation
- [ ] Create test session with /cc:explore
- [ ] Verify v2 format: `v2-YYYYMMDDTHHmmss-base32-slug`
- [ ] Verify session directory created
- [ ] Verify index.json created/updated
- [ ] Verify @latest reference set

**Deliverables**:
- [ ] Working scripts in `cc/scripts/`
- [ ] Updated `/cc:explore` command
- [ ] Passing tests for session creation
- [ ] Session index functional

---

## Phase 3: Hook Integration

**Timeline**: Days 8-10

### 3.1 Merge PreToolUse Hook
- [ ] Backup current `pre-tool-use/validate-session.sh`
- [ ] Create unified validation logic
- [ ] Integrate resolver for reference validation
- [ ] Maintain workflow validation (plan before code)
- [ ] Test with various session references

### 3.2 Merge Stop Hook
- [ ] Backup current `stop/auto-save-session.sh`
- [ ] Add index update to stop hook
- [ ] Maintain CLAUDE.md timestamp updates
- [ ] Maintain activity.log appending
- [ ] Test hook execution

### 3.3 Add New Hooks
- [ ] Create `hooks/session-start/` directory
- [ ] Copy `load-active-session.sh` from session-manager
- [ ] Create `hooks/session-end/` directory
- [ ] Copy `save-session-state.sh` from session-manager
- [ ] Make hooks executable

### 3.4 Update hooks.json
- [ ] Add SessionStart hook configuration
- [ ] Add SessionEnd hook configuration
- [ ] Update PreToolUse hook path
- [ ] Update Stop hook path
- [ ] Verify JSON syntax

### 3.5 Test Hooks
- [ ] Test SessionStart displays active session
- [ ] Test PreToolUse validates references
- [ ] Test Stop updates index
- [ ] Test SessionEnd saves state
- [ ] Test UserPromptSubmit unchanged

**Deliverables**:
- [ ] Unified hook implementations
- [ ] Updated `hooks.json`
- [ ] All hooks passing tests

---

## Phase 4: Command Integration

**Timeline**: Days 11-13

### 4.1 Update /cc:plan Command
- [ ] Replace `find` with resolver
- [ ] Accept reference arguments (@latest, short IDs, etc.)
- [ ] Update session directory path (no wildcard)
- [ ] Add index update (phase = planning)
- [ ] Update output messages
- [ ] Test with various references

### 4.2 Update /cc:code Command
- [ ] Replace `find` with resolver
- [ ] Accept reference arguments
- [ ] Update session directory path
- [ ] Add index update (phase = implementation)
- [ ] Update output messages
- [ ] Test with various references

### 4.3 Add New Commands
- [ ] Copy `session-list.md` from session-manager
- [ ] Copy `session-migrate.md` from session-manager
- [ ] Copy `session-rebuild-index.md` from session-manager
- [ ] Update commands for CC workflow context
- [ ] Test each new command

### 4.4 Test Command Integration
- [ ] Test /cc:explore → /cc:plan → /cc:code workflow
- [ ] Test using @latest reference
- [ ] Test using short ID reference
- [ ] Test using slug search
- [ ] Test /session-list shows all sessions

**Deliverables**:
- [ ] All commands updated and working
- [ ] New session management commands functional
- [ ] Full workflow test passing

---

## Phase 5: Skills Integration

**Timeline**: Days 14-15

### 5.1 Copy session-finder Skill
- [ ] Copy `session-manager/skills/session-finder/` directory
- [ ] Copy SKILL.md
- [ ] Copy resources/ directory
- [ ] Verify directory structure

### 5.2 Test Skill Functionality
- [ ] Test natural language queries
- [ ] Test temporal search ("yesterday's work")
- [ ] Test keyword search ("auth feature")
- [ ] Test status filtering ("unfinished work")
- [ ] Verify skill invokes correctly

### 5.3 Update Skill for CC Workflow
- [ ] Add phase filtering (exploration, planning, implementation)
- [ ] Update pattern library for CC terminology
- [ ] Test phase-specific searches

**Deliverables**:
- [ ] session-finder skill functional
- [ ] Natural language search working
- [ ] CC workflow integration verified

---

## Phase 6: Migration

**Timeline**: Days 16-18

### 6.1 Test Migration Tool
- [ ] Test /session-migrate in dry-run mode
- [ ] Verify v1 session detection
- [ ] Verify v2 ID generation
- [ ] Test on single session first

### 6.2 Migrate Existing Sessions
- [ ] Backup current sessions (additional backup)
- [ ] Run /session-migrate --execute
- [ ] Verify all v1 sessions migrated
- [ ] Verify CLAUDE.md updated
- [ ] Verify index complete

### 6.3 Validate Migration
- [ ] Test accessing migrated sessions
- [ ] Verify all files intact
- [ ] Verify references work
- [ ] Check for any broken links

### 6.4 Cleanup
- [ ] Remove v1 session directories (if safe)
- [ ] Update @latest to most recent v2 session
- [ ] Rebuild index for verification

**Deliverables**:
- [ ] All sessions in v2 format
- [ ] Complete session index
- [ ] Migration verified successful

---

## Phase 7: Documentation & Testing

**Timeline**: Days 19-21

### 7.1 Update Documentation
- [ ] Update `cc/README.md` with v2 format
- [ ] Update `cc/CLAUDE.md` with new commands
- [ ] Update `cc/IMPLEMENTATION_GUIDE.md`
- [ ] Create migration guide for users
- [ ] Add troubleshooting section

### 7.2 Create Examples
- [ ] Example: Create v2 session
- [ ] Example: Use references (@latest, short ID)
- [ ] Example: Search sessions naturally
- [ ] Example: Migrate old sessions

### 7.3 Comprehensive Testing
- [ ] Unit tests for scripts
- [ ] Integration tests for commands
- [ ] E2E test: full workflow
- [ ] Hook execution tests
- [ ] Skill invocation tests

### 7.4 Performance Testing
- [ ] Test with 10+ sessions
- [ ] Test with 50+ sessions
- [ ] Verify index lookup speed
- [ ] Test reference resolution speed

### 7.5 Update Plugin Metadata
- [ ] Update `plugin.json` version (3.0.0)
- [ ] Update description
- [ ] Update changelog
- [ ] Update permissions if needed

**Deliverables**:
- [ ] Complete documentation update
- [ ] Test suite passing
- [ ] Examples working
- [ ] Ready for release

---

## Final Checks

### Pre-Release Checklist
- [ ] All phases completed
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Examples verified
- [ ] No breaking changes (except v1 format)
- [ ] Backup and rollback tested
- [ ] Performance acceptable
- [ ] User feedback incorporated

### Release Preparation
- [ ] Create changelog entry
- [ ] Tag version 3.0.0
- [ ] Create GitHub release
- [ ] Update marketplace listing
- [ ] Notify users of upgrade

---

## Rollback Criteria

Trigger rollback if:
- [ ] More than 3 critical bugs found
- [ ] Session data loss occurs
- [ ] Performance degradation > 50%
- [ ] Migration fails for > 10% of sessions
- [ ] Breaking changes not documented

**Rollback Process**:
1. Restore from backup: `.claude/sessions-backup-phase1.tar.gz`
2. Revert git branch
3. Document issues
4. Plan fixes

---

## Progress Summary

**Current Phase**: Phase 1 - Preparation
**Completed**: 5/6 tasks
**Pending**: User approval to proceed

**Overall Progress**: 8% (5/63 total tasks)

**Next Steps**:
1. Get user approval on integration design
2. Begin Phase 2: Script Integration
3. Copy and test scripts
4. Update /cc:explore command

---

**Last Updated**: 2025-11-09 19:28 UTC
**Branch**: `claude/integrate-session-manager-v2-011CUxmhrdQBEEfgvNVWvFGq`

# Session Manager v2 Plugin

> *"Simplicity is the ultimate sophistication."* — Leonardo da Vinci

Smart session ID management for Claude Code with Git-like references, automatic lifecycle hooks, and intelligent session discovery.

## 🎯 Why v2?

The original v1 session system had critical limitations:
- ❌ Fragile parsing (breaks on underscores)
- ❌ OpenSSL dependency
- ❌ Description truncation (20 chars)
- ❌ No validation
- ❌ Manual reference management
- ❌ Context pollution

Session Manager v2 transforms session management into an **elegant, robust system**:
- ✅ Unambiguous format with version prefix
- ✅ Zero dependencies (pure bash)
- ✅ Unlimited slug length
- ✅ Smart validation
- ✅ Git-like references (@latest, @{1}, short IDs, slug search)
- ✅ Automatic lifecycle management
- ✅ Context-optimized (99.9% less pollution)

---

## 📦 Installation

### Requirements
- Claude Code >= 0.6.0
- `jq` (JSON processor)
- `bash` 4.0+

**Install jq**:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Verify
jq --version
```

### Install Plugin

**From this repository**:
```bash
# Copy plugin to Claude Code plugins directory
cp -r .claude/plugins/session-manager ~/.claude/plugins/

# Or install as project plugin (current repo only)
# Already installed in this repo at: .claude/plugins/session-manager
```

**Configure hooks** (add to `.claude/settings.json`):
```json
{
  "hooks": {
    "SessionStart": [
      ".claude/plugins/session-manager/hooks/session-start/load-active-session.sh"
    ],
    "SessionEnd": [
      ".claude/plugins/session-manager/hooks/session-end/save-session-state.sh"
    ],
    "PreToolUse": [
      ".claude/plugins/session-manager/hooks/pre-tool-use/validate-session.sh"
    ],
    "Stop": [
      ".claude/plugins/session-manager/hooks/stop/update-session-metadata.sh"
    ]
  }
}
```

---

## 🚀 Quick Start

### 1. Create Your First Session

```bash
/explore Implement user authentication with OAuth
```

**What happens**:
- Generates v2 session ID: `v2-20251109T183846-n7c3fa9k-implement-user-authentication-with-oauth`
- Creates session directory with CLAUDE.md
- Adds to index
- Sets as `@latest`

### 2. List Sessions

```bash
/session-list
```

### 3. Continue Latest Session

```bash
# Using @latest
/cc:plan @latest

# Using @ (shorthand)
/cc:code @

# Using short ID
/cc:plan n7c3fa9k

# Using slug search
/cc:code @/implement-user-auth
```

### 4. Migrate Existing v1 Sessions (optional)

```bash
# Preview migration
/session-migrate

# Apply migration
/session-migrate --execute
```

---

## 📚 Session ID Format

### v2 Format Specification

```
v2-YYYYMMDDTHHmmss-base32random-kebab-slug

Example:
v2-20251109T183846-n7c3fa9k-implement-user-authentication-with-oauth

Components:
  v2              - Version prefix (enables future evolution)
  20251109T183846 - ISO8601 compact timestamp (sortable)
  n7c3fa9k        - 8-char base32 random ID (human-friendly)
  implement-...   - Kebab-case slug (unlimited length)
```

### Why This Format?

| Decision | Rationale |
|----------|-----------|
| **v2 prefix** | Version evolution without breaking changes |
| **ISO8601 timestamp** | International standard, unambiguous |
| **Base32 random** | Human-friendly (no 0/O, 1/l confusion) |
| **Hyphen delimiters** | Clear parsing, web-standard |
| **Kebab-case slug** | Readable, no truncation |

---

## 🎨 Reference System

### Git-Like References

| Reference | Description | Example |
|-----------|-------------|---------|
| `@latest` | Most recent session | `/cc:plan @latest` |
| `@` | Shorthand for @latest | `/cc:code @` |
| `@{N}` | Nth previous session | `/cc:plan @{1}` |
| Short ID | 8-char prefix match | `/cc:code n7c3fa9k` |
| `@/slug` | Slug search | `/cc:plan @/auth` |
| Full ID | Complete session ID | `/cc:code v2-20251109T...` |

### Reference Resolution

The resolver tries strategies in this order:

1. **Exact v2 format** → Return as-is
2. **@latest or @** → Lookup in refs
3. **@{N}** → Numbered ref
4. **@/slug** → Slug search
5. **Short ID** → Prefix match
6. **v1 format** → Legacy lookup

---

## 🔧 Commands

### /explore

Create a new exploration session.

```bash
/explore <description>

Example:
/explore Add dark mode toggle to settings
```

**Features**:
- Generates v2 session ID
- Initializes CLAUDE.md with metadata
- Adds to index
- Sets as @latest
- Creates activity log

---

### /session-list

Browse and filter sessions.

```bash
/session-list [filter] [--limit N]

Examples:
/session-list                  # List recent sessions
/session-list auth             # Filter by keyword
/session-list --limit 20       # Show 20 sessions
/session-list feature --limit 10  # Combined
```

**Output**:
- Status icons (🟢 in progress, ✅ completed, 📦 archived)
- Phase indicators (🔍 exploration, 📋 planning, ⚙️ implementation)
- Relative timestamps (2h ago, 1d ago)
- Quick references for each session
- Current @latest marker

---

### /session-migrate

Migrate v1 sessions to v2 format.

```bash
/session-migrate [--dry-run|--execute] [session-id]

Examples:
/session-migrate                    # Preview all migrations
/session-migrate --execute          # Apply all migrations
/session-migrate 20251109_114715_f0903a7c  # Specific session
```

**Features**:
- Dry-run mode (safe preview)
- Preserves all session files
- Updates CLAUDE.md references
- Rebuilds index after migration
- Backup original format

---

### /session-rebuild-index

Rebuild session index from directories (recovery tool).

```bash
/session-rebuild-index [--verify]

Examples:
/session-rebuild-index           # Rebuild index
/session-rebuild-index --verify  # Check integrity
```

**When to use**:
- Index file missing or corrupted
- Sessions not appearing in /session-list
- After manual directory changes
- Reference resolution failures

---

## 🪝 Lifecycle Hooks

### SessionStart Hook

**Runs**: When Claude Code starts or resumes
**Purpose**: Auto-load active session context
**Output**: Injected into Claude's context

```
📊 Active Session Loaded

  🟢 v2-20251109T183846-n7c3fa9k-implement-user-auth

  Name: implement-user-auth
  Phase: ⚙️ implementation
  Status: in_progress
  Updated: 2h ago
  Branch: feature/oauth

📁 Session context auto-loaded from:
   .claude/sessions/v2-.../CLAUDE.md

💡 Quick references:
   @latest, @, n7c3fa9k, @/implement-user-auth
```

### SessionEnd Hook

**Runs**: When Claude Code session ends
**Purpose**: Auto-save session state

- Updates `updated` timestamp
- Records session end time
- Appends to activity log

### PreToolUse Hook

**Runs**: Before tool execution (can block)
**Purpose**: Validate session references

```bash
# Valid reference
✅ Session resolved: @latest → v2-20251109T183846-n7c3fa9k

# Invalid reference
❌ Session reference 'xyz' could not be resolved

Error: No session found matching short ID: xyz
Hint: Short IDs are the 3rd part of session ID

💡 Available commands:
   /session-list              - View all sessions
   /explore <description>     - Create new session
```

### Stop Hook

**Runs**: After each Claude response
**Purpose**: Update session metadata

- Updates `updated` timestamp
- Appends activity to log
- Keeps index current

---

## 🧠 Session Finder Skill

### What is it?

A **model-invoked skill** that Claude uses automatically to help you find sessions through natural language.

### When does it trigger?

Claude uses this skill when you:
- Say "continue where I left off"
- Mention "that auth feature" or past work
- Ask "what was I working on?"
- Need to find a specific session
- Reference work from the past

### How it works

```
User: "What was I working on yesterday?"

Claude (internally):
  1. Triggers session-finder skill
  2. Loads session index
  3. Filters by temporal: yesterday
  4. Finds matching sessions
  5. Presents results with quick actions

Claude (to user):
✅ Found 2 sessions from yesterday:

1. 🟢 v2-20251109T183846-n7c3fa9k (implement-user-auth)
   Phase: implementation | Updated: 2h ago
   📌 /cc:code n7c3fa9k

2. ✅ v2-20251109T103022-k8m2pq7x (fix-payment-bug)
   Phase: completed | Updated: 8h ago
   📌 /cc:code k8m2pq7x

Would you like to continue one of these?
```

### Natural Language Examples

| You say | Skill finds |
|---------|------------|
| "What was I working on?" | @latest session |
| "Show recent work" | Last 5 sessions |
| "Find the auth feature" | Keyword search: auth |
| "Unfinished work" | status == in_progress |
| "Yesterday's sessions" | Temporal filter |
| "Continue payment fix" | Keywords: payment + fix |
| "That bug from last week" | Keyword + temporal |

---

## 🏗️ Architecture

### Component Overview

```
Session Manager v2 Plugin
├── Scripts (Core Logic)
│   ├── generate-session-id.sh     - v2 ID generation
│   ├── resolve-session-id.sh      - Reference resolution
│   └── session-index.sh            - Index management
├── Hooks (Lifecycle Automation)
│   ├── SessionStart                - Auto-load context
│   ├── SessionEnd                  - Auto-save state
│   ├── PreToolUse                  - Validate references
│   └── Stop                        - Update metadata
├── Commands (User Interface)
│   ├── explore.md                  - Create session
│   ├── session-list.md             - Browse sessions
│   ├── session-migrate.md          - v1 → v2 migration
│   └── session-rebuild-index.md    - Index recovery
└── Skills (AI-Invoked)
    └── session-finder              - Intelligent discovery
```

### Data Flow

```
User action
    │
    ▼
PreToolUse Hook ──→ Validate reference
    │
    ▼
Command execution ──→ Uses scripts
    │
    ▼
Session created/modified
    │
    ▼
Stop Hook ──→ Update index
    │
    ▼
SessionEnd Hook ──→ Save state on exit
```

### Index Structure

```json
{
  "version": "1.0",
  "created": "2025-11-09T18:38:46Z",
  "sessions": {
    "v2-20251109T183846-n7c3fa9k-implement-user-auth": {
      "slug": "implement-user-auth",
      "created": "2025-11-09T18:38:46Z",
      "updated": "2025-11-09T20:15:30Z",
      "phase": "implementation",
      "status": "in_progress",
      "branch": "feature/oauth",
      "tags": [],
      "description": ""
    }
  },
  "refs": {
    "@latest": "v2-20251109T183846-n7c3fa9k-implement-user-auth",
    "@{1}": "v2-20251108T093012-k2m9pq8x-add-dark-mode"
  },
  "settings": {
    "retention_days": 90,
    "auto_archive": true
  }
}
```

---

## 💡 Best Practices

### Session Creation

✅ **Do**:
- Use descriptive, action-oriented names
- Start with /explore for new work
- Keep session scope focused

❌ **Don't**:
- Create sessions for trivial changes
- Use vague descriptions
- Mix unrelated work in one session

### Reference Usage

✅ **Do**:
- Use @latest for current work
- Use short IDs when sharing with team
- Use slug search for quick lookup

❌ **Don't**:
- Type full IDs manually
- Remember random hex strings
- Search directories with find/grep

### Index Management

✅ **Do**:
- Let hooks manage index automatically
- Run /session-rebuild-index after manual changes
- Use /session-list to browse

❌ **Don't**:
- Manually edit index.json
- Delete session directories without updating index
- Skip migration if using v1 sessions

---

## 🐛 Troubleshooting

### Sessions not appearing in /session-list

**Solution**:
```bash
/session-rebuild-index
```

### Reference resolution failing

**Check**:
1. Index exists: `ls .claude/sessions/index.json`
2. jq installed: `jq --version`
3. Session directory exists

**Fix**:
```bash
/session-rebuild-index
/session-list  # Verify sessions appear
```

### Hook not running

**Check hooks configuration** in `.claude/settings.json`:
```bash
cat .claude/settings.json | jq '.hooks'
```

**Verify hook is executable**:
```bash
ls -l .claude/plugins/session-manager/hooks/session-start/*.sh
# Should show: -rwxr-xr-x (executable)
```

**Make executable if needed**:
```bash
chmod +x .claude/plugins/session-manager/hooks/**/*.sh
```

### Migration fails

**Common issues**:
- Target directory already exists
- Insufficient permissions
- Corrupted source directory

**Solution**:
```bash
# Dry run first
/session-migrate

# Check specific session
ls -la .claude/sessions/<session-id>

# Apply migration
/session-migrate --execute
```

---

## 📊 Comparison: v1 vs v2

| Feature | v1 | v2 |
|---------|----|----|
| **Format** | `YYYYMMDD_HHMMSS_hex_desc` | `v2-YYYYMMDDTHHmmss-base32-slug` |
| **Parsing** | Fragile (`cut -d'_'`) | Robust (unambiguous) |
| **Dependencies** | OpenSSL | None (pure bash) |
| **Slug length** | 20 chars (truncated) | Unlimited |
| **References** | Full ID only | @latest, @{N}, short IDs, slug search |
| **Validation** | None | Pre-execution validation |
| **Context impact** | High (repeated index loads) | Low (cached, on-demand) |
| **Lifecycle** | Manual | Automatic hooks |
| **Discovery** | Manual grep/find | Skill-based intelligent search |

---

## 🎓 Advanced Usage

### Custom References

Add custom named references:
```bash
bash .claude/plugins/session-manager/scripts/session-index.sh \
  set-ref "@cleanup" "v2-20251109T183846-n7c3fa9k"

# Use it
/cc:code @cleanup
```

### Programmatic Access

```bash
# Get latest session ID
LATEST=$(jq -r '.refs["@latest"]' .claude/sessions/index.json)

# List in-progress sessions
jq -r '.sessions | to_entries[] |
       select(.value.status == "in_progress") |
       .key' .claude/sessions/index.json

# Count sessions by phase
jq '.sessions | group_by(.phase) |
    map({phase: .[0].phase, count: length})' \
    .claude/sessions/index.json
```

### Backup & Restore

```bash
# Backup index
cp .claude/sessions/index.json .claude/sessions/index.backup.$(date +%Y%m%d)

# Backup all sessions
tar -czf sessions-backup-$(date +%Y%m%d).tar.gz .claude/sessions/

# Restore
tar -xzf sessions-backup-YYYYMMDD.tar.gz
```

---

## 📈 Roadmap

### v2.1 (Planned)
- [ ] Session tagging system
- [ ] Session archival after N days
- [ ] Session templates
- [ ] Export session reports

### v2.2 (Future)
- [ ] Multi-project session support
- [ ] Session collaboration (team)
- [ ] Session analytics dashboard
- [ ] Git integration (auto-branch per session)

---

## 🤝 Contributing

This plugin is part of the `yersonargotev/cc` repository.

**Report issues**:
```bash
# Create issue with details:
# - Session ID
# - Command that failed
# - Error message
# - Output of /session-rebuild-index --verify
```

---

## 📜 License

MIT License - See repository LICENSE file

---

## 🙏 Acknowledgments

Built with the **ultrathink excellence** philosophy:
- First principles thinking
- Obsessive attention to detail
- Ruthless simplification
- User experience first
- Production-ready quality

Inspired by Git's elegant reference system and Apple's design philosophy.

---

**Version**: 2.0.0
**Author**: Claude Code Session Manager
**Repository**: https://github.com/yersonargotev/cc

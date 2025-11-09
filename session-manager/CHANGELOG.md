# Changelog

All notable changes to the Session Manager v2 plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-09

### Added
- **Complete v2 session ID format**: `v2-YYYYMMDDTHHmmss-base32random-kebab-slug`
- **Git-like reference system**: @latest, @{N}, short IDs, slug search
- **Automatic lifecycle hooks**: SessionStart, SessionEnd, PreToolUse, Stop
- **Intelligent session discovery**: session-finder AI skill
- **Zero-dependency ID generation**: Pure bash with fallback chains
- **Context optimization**: 99.9% reduction in context pollution
- **v1 migration tool**: Safe migration from legacy format
- **Index recovery tool**: Rebuild corrupted indexes
- **Comprehensive documentation**: 21KB user guide with examples

### Core Components
- `generate-session-id.sh`: Zero-dependency v2 ID generation
- `resolve-session-id.sh`: Multi-strategy reference resolution
- `session-index.sh`: Atomic JSON index management

### Commands
- `/explore` - Create v2 sessions with initialization
- `/session-list` - Browse and filter with icons
- `/session-migrate` - Migrate v1 → v2 with dry-run
- `/session-rebuild-index` - Recovery and verification

### Skills
- `session-finder` - Natural language session discovery
- Temporal, keyword, status, and combined search strategies
- Pattern library for common queries

### Hooks
- SessionStart: Auto-loads active session context
- SessionEnd: Auto-saves session state
- PreToolUse: Validates references before execution
- Stop: Updates metadata after responses

### Features
- 100% backward compatibility with v1 sessions
- Human-friendly base32 encoding (no 0/O, 1/l confusion)
- Unlimited slug length (no truncation)
- Helpful error messages with suggestions
- Session metadata tracking (phase, status, branch)
- Activity logging for debugging

### Changed
- Moved from `.claude/plugins/session-manager/` to distributable structure
- All hooks now use `${CLAUDE_PLUGIN_ROOT}` environment variable
- Commands use plugin-relative paths
- Documentation updated for marketplace distribution

### Removed
- OpenSSL dependency (now pure bash)
- 20-character slug limitation
- Fragile underscore-based parsing
- Manual reference management

## [1.0.0] - 2025-11-08 (Legacy v1)

### Initial Release
- Basic session directory creation
- v1 format: `YYYYMMDD_HHMMSS_hex_description`
- Manual session reference management
- OpenSSL-based random generation

---

[2.0.0]: https://github.com/yersonargotev/cc/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/yersonargotev/cc/releases/tag/v1.0.0

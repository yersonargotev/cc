# CC Scripts Directory

**Status**: Phase 1 - Integration Preparation
**Source**: Session Manager v2

## Purpose

This directory contains core session management scripts integrated from Session Manager v2:

- `generate-session-id.sh` - v2 session ID generation (zero dependencies)
- `resolve-session-id.sh` - Reference resolver (@latest, short IDs, slug search)
- `session-index.sh` - JSON index management

## Integration Status

- [ ] Scripts copied from session-manager
- [ ] Scripts made executable
- [ ] Scripts tested independently
- [ ] Integrated into commands

## Usage

Scripts are called from commands and hooks:

```bash
# From commands
SESSION_ID=$(bash "$CLAUDE_PLUGIN_DIR/scripts/generate-session-id.sh" "$DESCRIPTION")
RESOLVED=$(bash "$CLAUDE_PLUGIN_DIR/scripts/resolve-session-id.sh" "@latest")

# Index operations
bash "$CLAUDE_PLUGIN_DIR/scripts/session-index.sh" add "$ID" "$SLUG" "phase" "status" "branch"
```

## Next Steps

1. Copy scripts from `session-manager/scripts/`
2. Make executable: `chmod +x *.sh`
3. Test each script independently
4. Update commands to use new scripts

# Claude Code Hooks

This directory contains custom hooks that extend Claude Code's behavior at various lifecycle points.

## Configuration

Hooks are registered in `.claude/settings.json` at the project root. See the configuration file for the complete setup.

## Available Hooks

### 1. PreToolUse: `validate-session.sh`

**Event:** `PreToolUse` (runs before tool calls)  
**Matcher:** `SlashCommand`  
**Purpose:** Validates that sessions exist before running plan/code phases

**Features:**
- ✅ Validates session existence for `/cc:plan` and `/cc:code` commands
- ✅ Checks that plans exist before code phase
- ✅ Provides helpful error messages with available sessions
- ✅ Blocks invalid operations (exit code 2)

**Input:** JSON via stdin with `tool_name` and `tool_input` fields  
**Exit Codes:**
- `0` = Allow operation (pass through)
- `2` = Block operation and show feedback to Claude

### 2. Stop: `auto-save-session.sh`

**Event:** `Stop` (runs when Claude finishes responding)  
**Matcher:** `*` (all tools)  
**Purpose:** Auto-saves session state with timestamps

**Features:**
- ✅ Updates "Last Updated" timestamp in `CLAUDE.md`
- ✅ Creates activity log with timestamps
- ✅ Finds and updates most recent session automatically
- ✅ macOS compatible (uses `sed -i ''`)

**Input:** JSON via stdin (consumed but not processed)  
**Exit Code:** Always `0` (success)

### 3. UserPromptSubmit: `load-context.sh`

**Event:** `UserPromptSubmit` (runs when user submits a prompt)  
**Matcher:** `` (empty = all prompts)  
**Purpose:** Injects helpful context about git and sessions

**Features:**
- ✅ Shows git status if there are changes
- ✅ Displays active session information
- ✅ Shows current phase from `CLAUDE.md`
- ✅ Only shows relevant information (silent when nothing to show)

**Input:** JSON via stdin (consumed but not processed)  
**Exit Code:** Always `0` (success, output shown to user)

## Testing Hooks

Run the test script to verify all hooks are working:

```bash
bash cc/hooks/test-hooks.sh
```

This will:
1. ✅ Check that configuration file exists
2. ✅ Verify all hook scripts are executable
3. ✅ Test JSON input/output for each hook
4. ✅ Validate hook behavior with sample data

## Hook Data Format

According to [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks-guide), hooks receive JSON data via stdin:

### PreToolUse Hook Input
```json
{
  "tool_name": "SlashCommand",
  "tool_input": {
    "command": "/cc:plan session-id",
    "description": "Run plan phase"
  }
}
```

### Stop Hook Input
```json
{
  "session_id": "...",
  "timestamp": "..."
}
```

### UserPromptSubmit Hook Input
```json
{
  "prompt": "user message here",
  "timestamp": "..."
}
```

## Best Practices

1. **Always read stdin**: Even if you don't use the data, consume stdin to prevent blocking
2. **Use correct exit codes**: 
   - `0` for success/allow
   - `2` for blocking with feedback (PreToolUse only)
3. **Be platform-aware**: These hooks use macOS-compatible commands (e.g., `sed -i ''`)
4. **Handle errors gracefully**: Use `2>/dev/null` for optional operations
5. **Provide helpful feedback**: When blocking, explain why and suggest alternatives

## Security Considerations

⚠️ **Important**: Hooks run automatically with your environment's credentials:

- Review hook code before installation
- Avoid storing sensitive data in hooks
- Be cautious with network operations
- Use restricted permissions where possible

For full security guidelines, see [Claude Code Security Considerations](https://code.claude.com/docs/en/hooks-reference#security-considerations).

## Debugging

To debug a hook:

1. **Test manually:**
   ```bash
   echo '{"tool_name":"SlashCommand","tool_input":{"command":"/cc:plan test"}}' | bash cc/hooks/pre-tool-use/validate-session.sh
   ```

2. **Check exit codes:**
   ```bash
   echo $?  # Should be 0, 1, or 2
   ```

3. **Enable verbose output:**
   Add `set -x` at the top of the hook script

4. **Check logs:**
   Hooks may write to `.claude/sessions/*/activity.log`

## References

- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks-reference)
- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)


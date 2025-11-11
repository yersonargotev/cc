---
allowed-tools: Task, Bash, Read, Write
argument-hint: "[feature/issue description] [scope/context]"
description: "[DEPRECATED] Use /explore instead - Smart exploration with automatic routing"
---

# ⚠️  DEPRECATED: This Command Has Been Consolidated

**This command has been merged into `/explore`.**

The functionality of `explore-optimized` (smart routing with confidence scoring) is now the default behavior of the main `/explore` command.

## Migration Guide

Instead of using `/explore-optimized`, simply use `/explore` with optional flags:

```bash
# Old way (explore-optimized):
/explore-optimized "authentication system"

# New way (consolidated explore with smart routing):
/explore "authentication system"

# Force specific routing if needed:
/explore "authentication system" --code      # Force code-only
/explore "authentication system" --web       # Force web-only
/explore "authentication system" --hybrid    # Force full hybrid
/explore "authentication system" --ask       # Show routing decision details
```

## What Changed?

The new consolidated `/explore` command includes:

✅ **All explore-optimized features**:
- Smart intent detection with confidence scoring (0-100)
- Automatic routing: CODE_ONLY, WEB_ONLY, HYBRID, or UNCLEAR
- Token efficiency (~50% reduction on average)

✅ **Plus new enhancements**:
- Session awareness (loads previous exploration context)
- Smart caching with query deduplication
- Confidence levels: HIGH (≥80), MEDIUM (60-79), LOW (<60→UNCLEAR)
- Transparent feedback with override options
- Intelligent post-execution suggestions
- Incremental mode (--incremental flag)

## Why Was This Deprecated?

Having two separate explore commands (`/explore` and `/explore-optimized`) created:
- User confusion about which command to use
- Duplicate code maintenance
- Inconsistent behavior

The consolidated `/explore` provides all the smart routing benefits by default while maintaining backward compatibility.

## For More Information

See the main `/explore` command documentation or run:
```bash
/explore "any query" --ask
```

This will show you the routing decision process and available options.

---

**Last Updated**: 2025-11-11
**Replaced By**: `/explore` (cc/commands/explore.md)

---
allowed-tools: Bash, Read, Edit
argument-hint: "[type] [summary]"
description: Create conventional commits with proper formatting
---

# Commit: Conventional Commits

Create commit with type: **$1** and summary: **$2**

## Commit Types

**feat** (new feature) | **fix** (bug fix) | **docs** (documentation) | **style** (formatting) | **refactor** (code refactoring) | **perf** (performance) | **test** (tests) | **chore** (maintenance)

## Process

### 1. Review Changes

```bash
git status
git diff --staged
git diff
```

Verify only intended changes are included.

### 2. Stage Files

```bash
git add <file1> <file2>  # Specific files
# OR
git add .  # All changes (if appropriate)
```

### 3. Create Commit

Format: `<type>[optional scope]: <description>`

```bash
git commit -m "$1: $2"
```

**Examples**:
- `feat(auth): add OAuth2 login`
- `fix(api): handle null response`
- `docs(readme): update installation`
- `refactor: simplify date formatting`

## Best Practices

- **Atomic commits**: One logical change per commit
- **Present tense**: "add feature" not "added feature"
- **Specific**: Describe what changed
- **Focused scope**: Avoid mixing unrelated changes

Wait for user approval before committing.

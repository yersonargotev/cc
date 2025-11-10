---
allowed-tools: Bash, Read, Edit
argument-hint: "[type] [summary]"
description: Create conventional commits with proper formatting
---

# Commit: Conventional Commits

Create conventional commits for changes with type: **$1** and summary: **$2**

## Conventional Commit Types

Choose the appropriate type for your commit:
- **feat**: New feature or functionality
- **fix**: Bug fix or error correction
- **docs**: Documentation changes only
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring without functional changes
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates, etc.

## Your Task

Create conventional commits following these steps:

1. **Review Changes**: Check git status and diff for unintended changes
2. **Stage Appropriately**: Group related changes logically
3. **Format Commit Message**: Use conventional commit format
4. **Create Commit**: Make atomic commit with clear purpose
5. **Verify History**: Ensure git log tells a clear story

## Commit Process

Follow these steps for proper version control:

### 1. Check Current Status
```bash
git status
git diff --staged
git diff
```

### 2. Stage Changes Appropriately
```bash
# Stage specific files
git add <file1> <file2>

# Or stage all changes if appropriate
git add .
```

### 3. Create Conventional Commit
Use this format:
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Examples:
- `feat(auth): add OAuth2 login functionality`
- `fix(api): handle null response in user endpoint`
- `docs(readme): update installation instructions`
- `refactor(utils): simplify date formatting logic`

### 4. Create the Commit
```bash
git commit -m "type: description"
```

## Best Practices

- **Keep it atomic**: One logical change per commit
- **Be specific**: Describe what changed, not why
- **Use present tense**: "add feature" not "added feature"
- **Limit scope**: Avoid mixing unrelated changes
- **Impressive**: Make commits easy to understand and reverse

## Examples

```bash
# Feature commit
git commit -m "feat(ui): add dark mode toggle"

# Bug fix commit
git commit -m "fix(auth): resolve login token expiration issue"

# Documentation commit
git commit -m "docs(api): update authentication endpoint docs"

# Refactoring commit
git commit -m "refactor(components): extract shared button logic"
```

## Validation

Before completing:
- **Review staged changes**: Ensure only intended changes are included
- **Check commit message**: Verify conventional commit format
- **Consider scope**: Is this commit atomic and focused?
- **Wait user approval**: Confirm before creating the commit
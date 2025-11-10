# Common Session Search Patterns

## Temporal Patterns

### Recent Work
- "yesterday" → `updated > (now - 24h)`
- "last week" → `updated > (now - 7d)`
- "today" → `updated > (today 00:00)`
- "recent" / "lately" → Top 5 by updated timestamp
- "latest" / "most recent" → `@latest` reference

### Specific Times
- "this morning" → `updated > (today 00:00)` + `updated < (today 12:00)`
- "this afternoon" → `updated > (today 12:00)`
- "last Friday" → `updated on last Friday date`

## Topic Patterns

### Authentication & Security
- "auth*" → slug contains: auth, login, user, oauth, jwt, session
- "security" → slug contains: security, vulnerability, xss, csrf, injection
- "permission*" → slug contains: permission, role, access, authorization

### API & Backend
- "API" / "api" → slug contains: api, endpoint, rest, graphql, route
- "database" / "db" → slug contains: database, db, sql, query, migration
- "backend" → slug contains: backend, server, service, controller

### Frontend & UI
- "UI" / "ui" → slug contains: ui, interface, component, view
- "frontend" → slug contains: frontend, client, react, vue, angular
- "style*" → slug contains: style, css, theme, design

### Infrastructure
- "deploy*" → slug contains: deploy, deployment, ci, cd, docker, k8s
- "test*" → slug contains: test, testing, spec, unit, integration, e2e
- "build" → slug contains: build, compile, bundle, webpack

### Common Actions
- "bug" / "fix" → slug contains: bug, fix, issue, error, crash
- "feature" / "add" → slug contains: feature, add, implement, create
- "refactor" → slug contains: refactor, cleanup, restructure, improve
- "update" / "upgrade" → slug contains: update, upgrade, migrate, version

## Status Patterns

### Active Work
- "in progress" / "working on" → `status == "in_progress"`
- "current" / "active" → `status == "in_progress"` + most recent

### Completed
- "done" / "finished" / "completed" → `status == "completed"`
- "shipped" / "deployed" → `status == "completed"` + phase=="deployment"

### Planning
- "planning" / "plan" → `phase == "planning"`
- "exploring" / "research" → `phase == "exploration"`

### Paused/Blocked
- "paused" / "on hold" → `status == "paused"`
- "blocked" → `status == "blocked"`

## Phase Patterns

- "exploration" → `phase == "exploration"`
- "planning" → `phase == "planning"`
- "implementation" / "coding" → `phase == "implementation"`
- "testing" → `phase == "testing"`
- "review" → `phase == "review"`

## Reference Patterns

### Direct References
- `@latest` → Most recent session
- `@` → Shorthand for @latest
- `@{N}` → Nth previous session (git-style)
  - `@{1}` → Previous session
  - `@{2}` → Two sessions back
- Short ID (8 chars) → e.g., "n7c3fa9k"
- `@/keyword` → Slug search

### Fuzzy References
- "that auth thing" → Keyword search: auth
- "the payment fix" → Keywords: payment + fix
- "yesterday's work" → Temporal: yesterday

## Combined Patterns

### Topic + Status
- "unfinished auth work" → slug~auth + status==in_progress
- "completed features" → slug~feature + status==completed

### Topic + Time
- "auth work from last week" → slug~auth + updated>(now-7d)
- "recent bug fixes" → slug~(bug|fix) + updated>(now-3d)

### Status + Time
- "work in progress this week" → status==in_progress + updated>(now-7d)
- "completed yesterday" → status==completed + updated>(now-24h)

## Natural Language Examples

| User Query | Interpretation | JQ Query |
|------------|---------------|----------|
| "What was I working on?" | @latest | `.refs["@latest"]` |
| "Show recent work" | Last 5 sessions | `sort_by(.updated) \| reverse \| .[0:5]` |
| "Find the auth feature" | Keyword: auth | `select(.slug \| test("auth"; "i"))` |
| "Unfinished work" | Status filter | `select(.status == "in_progress")` |
| "Yesterday's sessions" | Temporal filter | `select(.updated > $yesterday)` |
| "Continue payment fix" | Keyword + action | Search "payment" + "fix", suggest /cc:code |
| "That bug from last week" | Keyword + temporal | `select(.slug \| test("bug")) + updated>(now-7d)` |

## Priority Order

When multiple interpretations are possible, use this priority:

1. **Exact reference** (@latest, @{N}, full ID)
2. **Short ID match** (8-char prefix)
3. **Slug search** (@/keyword or direct keyword)
4. **Status filter** (in_progress, completed)
5. **Temporal filter** (yesterday, last week)
6. **Phase filter** (exploration, planning, implementation)
7. **Combined filters** (multiple criteria)

## Error Messages

### No Matches
```
No sessions found matching "[query]"

Suggestions:
  - Try broader keywords: "auth" instead of "authentication-oauth-google"
  - Check recent sessions: /session-list
  - Create new session: /explore <description>
```

### Ambiguous Query
```
"[query]" matches multiple sessions. Please be more specific:

Matches:
  1. auth-feature (in progress)
  2. auth-refactor (planning)
  3. auth-tests (completed)

Refine your search:
  - Use specific keywords: "auth refactor"
  - Use short ID: n7c3f
  - Use slug search: @/auth-feature
```

### Corrupted Index
```
Session index may be corrupted.

Try:
  /session-rebuild-index     - Rebuild from directories
  /session-list --verify     - Check integrity
```

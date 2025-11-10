---
name: session-finder
description: Intelligently find and suggest sessions based on user intent, keywords, temporal references, or context. Use when user mentions past work, wants to resume something, needs to find a specific session, or asks about previous sessions.
---

# Session Finder Skill

## Purpose
Help users discover and reference sessions through natural language queries, keywords, temporal references, or context clues.

## When to Use
- User says "continue where we left off" or "resume that work"
- User mentions previous work ("that auth feature", "the bug fix from yesterday")
- User asks "what was I working on?" or "show me recent sessions"
- User wants to find session by topic, status, or timeframe
- User needs help choosing which session to continue
- User references work done in the past

## Instructions

### 1. Load Session Index

First, check if the session index exists and load it:

```bash
if [ ! -f ".claude/sessions/index.json" ]; then
  echo "No sessions found. Run: /explore <description> to create a session"
  exit 0
fi

# Load the index
cat .claude/sessions/index.json
```

### 2. Understand User Intent

Parse the user's query to identify:

**Temporal References**:
- "yesterday", "last week", "recent", "today", "this morning"
- "latest", "most recent", "last one"
- Specific dates: "November 9th", "last Friday"

**Topic Keywords**:
- Technical terms: "authentication", "API", "database", "payment"
- Action words: "bug fix", "feature", "refactor", "implement"
- Domain terms: "user profile", "checkout flow", "dashboard"

**Status/Phase Indicators**:
- "unfinished", "in progress", "incomplete"
- "completed", "done", "finished"
- "planning", "implementation", "testing"

**Reference Formats**:
- "@latest", "most recent"
- Short IDs: partial session IDs
- Slugs: readable names

### 3. Search Strategies

Use the appropriate search based on user intent:

#### A. Temporal Queries

**Recent sessions** (updated in last N days):
```bash
# Last 24 hours
jq -r --arg cutoff "$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ)" \
  '.sessions | to_entries[] |
   select(.value.updated > $cutoff) |
   "\(.key) | \(.value.slug) | \(.value.updated)"' \
  .claude/sessions/index.json

# Last 7 days
jq -r --arg cutoff "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)" \
  '.sessions | to_entries[] |
   select(.value.updated > $cutoff) |
   "\(.key) | \(.value.slug) | \(.value.updated)"' \
  .claude/sessions/index.json
```

**Latest session**:
```bash
jq -r '.refs["@latest"]' .claude/sessions/index.json
```

#### B. Keyword Search

Search in slugs and descriptions:
```bash
# Case-insensitive keyword search
jq -r --arg keyword "auth" \
  '.sessions | to_entries[] |
   select(.value.slug | test($keyword; "i")) |
   "\(.key) | \(.value.slug) | \(.value.phase) | \(.value.status)"' \
  .claude/sessions/index.json
```

#### C. Status/Phase Filters

Filter by status:
```bash
# In-progress sessions
jq -r '.sessions | to_entries[] |
  select(.value.status == "in_progress") |
  "\(.key) | \(.value.slug) | \(.value.phase)"' \
  .claude/sessions/index.json

# Completed sessions
jq -r '.sessions | to_entries[] |
  select(.value.status == "completed") |
  "\(.key) | \(.value.slug)"' \
  .claude/sessions/index.json
```

Filter by phase:
```bash
# Planning phase
jq -r '.sessions | to_entries[] |
  select(.value.phase == "planning") |
  "\(.key) | \(.value.slug)"' \
  .claude/sessions/index.json
```

#### D. Combined Search

Combine multiple criteria:
```bash
# In-progress sessions from last week
jq -r --arg cutoff "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u)" \
  '.sessions | to_entries[] |
   select(.value.status == "in_progress" and .value.updated > $cutoff) |
   "\(.key) | \(.value.slug) | \(.value.phase)"' \
  .claude/sessions/index.json
```

#### E. Reference Resolution

Use the resolver for direct references:
```bash
# Resolve any reference format
bash .claude/plugins/session-manager/scripts/resolve-session-id.sh "@latest"
bash .claude/plugins/session-manager/scripts/resolve-session-id.sh "n7c3f"
bash .claude/plugins/session-manager/scripts/resolve-session-id.sh "@/auth"
```

### 4. Present Results

Format findings in a user-friendly way:

**For single match**:
```
✅ Found session matching "[query]"

📋 v2-20251109T114715-n7c3fa9k-remove-legacy-commands
   Name: remove-legacy-commands
   Phase: implementation
   Status: in_progress
   Updated: 2 hours ago
   Branch: claude/ultrathink-excellence-011CUxmhrdQBEEfgvNVWvFGq

💡 Quick actions:
   /cc:plan @latest       - View/update plan
   /cc:code @latest       - Continue implementation
   /cc:plan n7c3f         - Using short ID
   /cc:plan @/remove      - Using slug search
```

**For multiple matches**:
```
Found 3 sessions matching "[query]":

1. 🟢 v2-20251109T114715-n7c3fa9k (remove-legacy-commands)
   Phase: implementation | Updated: 2h ago
   📌 /cc:code n7c3f

2. 🟢 v2-20251108T093012-k2m9pq8x (add-authentication)
   Phase: planning | Updated: 1d ago
   📌 /cc:plan k2m9p

3. ✅ v2-20251107T151

030-m3k7hq2r (fix-payment-bug)
   Phase: completed | Updated: 2d ago
   📌 /cc:code m3k7h

💡 Use the quick reference to select one
```

**For no matches**:
```
❌ No sessions found matching "[query]"

Recent sessions:
  v2-20251109T114715-n7c3fa9k - remove-legacy-commands (2h ago)
  v2-20251108T093012-k2m9pq8x - add-authentication (1d ago)
  v2-20251107T151030-m3k7hq2r - fix-payment-bug (2d ago)

💡 Try:
   /session-list              - Browse all sessions
   /session-list [keyword]    - Filter by keyword
   /explore <description>     - Create new session
```

### 5. Handle Edge Cases

**No index file**:
```
No sessions found. Create your first session:
  /explore <description>

Example:
  /explore Implement user authentication with OAuth
```

**Corrupted index**:
```
⚠️  Session index appears corrupted.

Try rebuilding:
  /session-rebuild-index
```

**Ambiguous query**:
```
Your query "[query]" could match multiple sessions. Please be more specific:

Matching sessions:
  - auth-feature
  - auth-refactor
  - auth-tests

Try:
  /session-list auth         - See all auth-related sessions
  /cc:plan @/auth-feature    - Specific slug
```

### 6. Intelligent Suggestions

Based on context, suggest relevant sessions:

**After a break**:
```
👋 Welcome back! You were last working on:

🟢 remove-legacy-commands (2 days ago)
   Phase: implementation

Would you like to continue?
  /cc:code @latest
```

**Multiple in-progress**:
```
You have 3 sessions in progress:

1. remove-legacy-commands (2h ago) - implementation
2. add-oauth-support (1d ago) - planning
3. fix-database-migration (3d ago) - exploration

Which would you like to work on?
```

**Suggest related sessions**:
```
This seems related to previous work:
  - fix-payment-bug (completed 2d ago)
  - refactor-payment-flow (in progress)

Would you like to reference that work?
```

## Resources

Reference the common search patterns for guidance:

```bash
cat .claude/plugins/session-manager/skills/session-finder/resources/session-patterns.md
```

## Example Interactions

**User**: "What was I working on yesterday?"
**Skill**: Load index → Filter by yesterday → Present matches

**User**: "Continue the auth feature"
**Skill**: Keyword search "auth" → Resolve reference → Suggest action

**User**: "Show me unfinished work"
**Skill**: Filter status=in_progress → List all → Suggest next steps

**User**: "Find that bug fix from last week"
**Skill**: Keyword "bug" + temporal "last week" → Combined search → Present results

## Output Format

Always provide:
1. ✅ Clear match status
2. 📋 Session details (ID, name, phase, status, age)
3. 💡 Quick action commands
4. 🔍 Alternative search suggestions if no match

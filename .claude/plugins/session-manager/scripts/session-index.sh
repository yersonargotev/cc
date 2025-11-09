#!/bin/bash
# Session Index Manager v2
# Manages .claude/sessions/index.json
# Operations: init, add, update, lookup, rebuild, gc

set -euo pipefail

INDEX_FILE=".claude/sessions/index.json"
INDEX_LOCK="$INDEX_FILE.lock"
LOCK_TIMEOUT=10

#
# Check dependencies
#
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    echo "Install: sudo apt-get install jq  (or brew install jq on macOS)" >&2
    exit 1
  fi
}

#
# Acquire lock for atomic operations
#
acquire_lock() {
  local timeout=$LOCK_TIMEOUT
  local waited=0

  while [ -f "$INDEX_LOCK" ] && [ $waited -lt $timeout ]; do
    sleep 0.1
    waited=$((waited + 1))
  done

  if [ -f "$INDEX_LOCK" ]; then
    echo "Error: Failed to acquire lock after ${timeout}s" >&2
    return 1
  fi

  touch "$INDEX_LOCK"
  return 0
}

#
# Release lock
#
release_lock() {
  rm -f "$INDEX_LOCK"
}

#
# Initialize empty index
#
init_index() {
  check_jq

  if [ -f "$INDEX_FILE" ]; then
    echo "Index already exists: $INDEX_FILE" >&2
    return 0
  fi

  mkdir -p "$(dirname "$INDEX_FILE")"

  cat > "$INDEX_FILE" <<'EOF'
{
  "version": "1.0",
  "created": "",
  "sessions": {},
  "refs": {},
  "settings": {
    "retention_days": 90,
    "auto_archive": true
  }
}
EOF

  # Update created timestamp
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq --arg ts "$timestamp" '.created = $ts' "$INDEX_FILE" > "$INDEX_FILE.tmp"
  mv "$INDEX_FILE.tmp" "$INDEX_FILE"

  echo "Initialized session index: $INDEX_FILE"
  return 0
}

#
# Add session to index
# Usage: add <session_id> <slug> <phase> <status> <branch>
#
add_session() {
  local session_id="$1"
  local slug="$2"
  local phase="${3:-exploration}"
  local status="${4:-in_progress}"
  local branch="${5:-main}"

  check_jq

  if [ ! -f "$INDEX_FILE" ]; then
    init_index
  fi

  acquire_lock || return 1

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Add session entry
  jq --arg id "$session_id" \
     --arg slug "$slug" \
     --arg phase "$phase" \
     --arg status "$status" \
     --arg branch "$branch" \
     --arg ts "$timestamp" \
     '.sessions[$id] = {
        "slug": $slug,
        "created": $ts,
        "updated": $ts,
        "phase": $phase,
        "status": $status,
        "branch": $branch,
        "tags": [],
        "description": ""
      }' \
     "$INDEX_FILE" > "$INDEX_FILE.tmp"

  mv "$INDEX_FILE.tmp" "$INDEX_FILE"

  release_lock

  echo "Added session: $session_id"
  return 0
}

#
# Update session metadata
# Usage: update <session_id> <key=value> [<key=value> ...]
#
update_session() {
  local session_id="$1"
  shift

  check_jq

  if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: Index file not found" >&2
    return 1
  fi

  acquire_lock || return 1

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local jq_updates=". | .sessions[\"$session_id\"].updated = \"$timestamp\""

  # Parse key=value pairs
  for arg in "$@"; do
    if [[ "$arg" =~ ^([^=]+)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"

      jq_updates="$jq_updates | .sessions[\"$session_id\"].$key = \"$value\""
    fi
  done

  jq "$jq_updates" "$INDEX_FILE" > "$INDEX_FILE.tmp"
  mv "$INDEX_FILE.tmp" "$INDEX_FILE"

  release_lock

  echo "Updated session: $session_id"
  return 0
}

#
# Set reference
# Usage: set-ref <ref_name> <session_id>
#
set_ref() {
  local ref_name="$1"
  local session_id="$2"

  check_jq

  if [ ! -f "$INDEX_FILE" ]; then
    init_index
  fi

  acquire_lock || return 1

  jq --arg ref "$ref_name" \
     --arg id "$session_id" \
     '.refs[$ref] = $id' \
     "$INDEX_FILE" > "$INDEX_FILE.tmp"

  mv "$INDEX_FILE.tmp" "$INDEX_FILE"

  release_lock

  return 0
}

#
# Update @{N} references
#
update_numbered_refs() {
  check_jq

  if [ ! -f "$INDEX_FILE" ]; then
    return 0
  fi

  acquire_lock || return 1

  # Get sessions sorted by updated time (descending)
  local sessions=$(jq -r '.sessions | to_entries | sort_by(.value.updated) | reverse | .[].key' "$INDEX_FILE")

  local index=0
  echo "$sessions" | while read -r session_id; do
    if [ $index -gt 0 ]; then
      jq --arg ref "@{$index}" \
         --arg id "$session_id" \
         '.refs[$ref] = $id' \
         "$INDEX_FILE" > "$INDEX_FILE.tmp"
      mv "$INDEX_FILE.tmp" "$INDEX_FILE"
    fi
    index=$((index + 1))
  done

  release_lock

  return 0
}

#
# Lookup session by reference
# Usage: lookup <reference>
#
lookup_session() {
  local ref="$1"

  check_jq

  if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: Index file not found" >&2
    return 1
  fi

  # Try direct ref lookup
  local result=$(jq -r --arg ref "$ref" '.refs[$ref] // empty' "$INDEX_FILE")

  if [ -n "$result" ]; then
    echo "$result"
    return 0
  fi

  # Try session ID lookup
  result=$(jq -r --arg id "$ref" '.sessions[$id] // empty | if . then $id else empty end' "$INDEX_FILE")

  if [ -n "$result" ]; then
    echo "$result"
    return 0
  fi

  echo "Error: Session not found: $ref" >&2
  return 1
}

#
# Rebuild index from session directories
#
rebuild_index() {
  check_jq

  echo "Rebuilding session index..."

  # Backup existing index
  if [ -f "$INDEX_FILE" ]; then
    cp "$INDEX_FILE" "$INDEX_FILE.backup"
    echo "Backed up existing index to: $INDEX_FILE.backup"
  fi

  # Initialize fresh index
  rm -f "$INDEX_FILE"
  init_index

  # Find all session directories (v2 and v1)
  local session_dirs=$(find .claude/sessions -maxdepth 1 -type d \( -name "v2-*" -o -name "20*" \) 2>/dev/null | sort -r)

  if [ -z "$session_dirs" ]; then
    echo "No session directories found"
    return 0
  fi

  local count=0
  local latest_session=""

  echo "$session_dirs" | while read -r dir; do
    local session_id=$(basename "$dir")

    # Extract metadata from CLAUDE.md if exists
    local claude_md="$dir/CLAUDE.md"
    local phase="unknown"
    local status="unknown"
    local slug=""
    local created=""
    local updated=""
    local branch="main"

    if [ -f "$claude_md" ]; then
      # Parse CLAUDE.md for metadata
      phase=$(grep "^**Phase**:" "$claude_md" 2>/dev/null | sed 's/\*\*Phase\*\*: //' | tr -d '\r' || echo "unknown")
      status=$(grep "^**Status**:" "$claude_md" 2>/dev/null | sed 's/\*\*Status\*\*: //' | tr -d '\r' || echo "unknown")
      created=$(grep "^**Created**:" "$claude_md" 2>/dev/null | sed 's/\*\*Created\*\*: //' | tr -d '\r' || date -u +"%Y-%m-%dT%H:%M:%SZ")
      updated=$(grep "^**Last Updated**:" "$claude_md" 2>/dev/null | sed 's/\*\*Last Updated\*\*: //' | tr -d '\r' || date -u +"%Y-%m-%dT%H:%M:%SZ")
    fi

    # Extract slug from session ID
    if [[ "$session_id" =~ ^v2-[0-9]{8}T[0-9]{6}-[a-z0-9]{8}-(.+)$ ]]; then
      slug="${BASH_REMATCH[1]}"
    elif [[ "$session_id" =~ ^[0-9]{8}_[0-9]{6}_[a-f0-9]{8}_(.+)$ ]]; then
      slug=$(echo "${BASH_REMATCH[1]}" | tr '_' '-')
    else
      slug="unknown"
    fi

    # Get git branch if available
    if [ -d ".git" ]; then
      branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    fi

    # Use defaults if metadata missing
    created=${created:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
    updated=${updated:-$created}
    phase=${phase:-"unknown"}
    status=${status:-"unknown"}

    # Add to index
    acquire_lock || continue

    jq --arg id "$session_id" \
       --arg slug "$slug" \
       --arg phase "$phase" \
       --arg status "$status" \
       --arg branch "$branch" \
       --arg created "$created" \
       --arg updated "$updated" \
       '.sessions[$id] = {
          "slug": $slug,
          "created": $created,
          "updated": $updated,
          "phase": $phase,
          "status": $status,
          "branch": $branch,
          "tags": [],
          "description": ""
        }' \
       "$INDEX_FILE" > "$INDEX_FILE.tmp"

    mv "$INDEX_FILE.tmp" "$INDEX_FILE"

    release_lock

    count=$((count + 1))

    # Track latest session (first one since sorted descending)
    if [ -z "$latest_session" ]; then
      latest_session="$session_id"
    fi

    echo "  Indexed: $session_id"
  done

  # Set @latest reference
  if [ -n "$latest_session" ]; then
    set_ref "@latest" "$latest_session"
  fi

  # Update numbered references
  update_numbered_refs

  echo "✅ Rebuilt index: $count sessions"
  return 0
}

#
# Garbage collection - remove sessions that no longer exist
#
gc_index() {
  check_jq

  if [ ! -f "$INDEX_FILE" ]; then
    echo "No index to clean"
    return 0
  fi

  echo "Running garbage collection..."

  local removed=0

  # Get all session IDs from index
  local session_ids=$(jq -r '.sessions | keys[]' "$INDEX_FILE" 2>/dev/null)

  for session_id in $session_ids; do
    local session_dir=".claude/sessions/$session_id"

    if [ ! -d "$session_dir" ]; then
      echo "  Removing deleted session: $session_id"

      acquire_lock || continue

      jq --arg id "$session_id" 'del(.sessions[$id])' "$INDEX_FILE" > "$INDEX_FILE.tmp"
      mv "$INDEX_FILE.tmp" "$INDEX_FILE"

      release_lock

      removed=$((removed + 1))
    fi
  done

  if [ $removed -gt 0 ]; then
    echo "✅ Removed $removed deleted sessions"
    # Update references after cleanup
    update_numbered_refs
  else
    echo "✅ Index is clean"
  fi

  return 0
}

#
# Main command dispatcher
#
main() {
  local command="${1:-}"
  shift || true

  case "$command" in
    init)
      init_index
      ;;
    add)
      if [ $# -lt 2 ]; then
        echo "Usage: session-index.sh add <session_id> <slug> [phase] [status] [branch]" >&2
        exit 1
      fi
      add_session "$@"
      ;;
    update)
      if [ $# -lt 2 ]; then
        echo "Usage: session-index.sh update <session_id> <key=value> [<key=value> ...]" >&2
        exit 1
      fi
      update_session "$@"
      ;;
    set-ref)
      if [ $# -ne 2 ]; then
        echo "Usage: session-index.sh set-ref <ref_name> <session_id>" >&2
        exit 1
      fi
      set_ref "$@"
      ;;
    lookup)
      if [ $# -ne 1 ]; then
        echo "Usage: session-index.sh lookup <reference>" >&2
        exit 1
      fi
      lookup_session "$@"
      ;;
    rebuild)
      rebuild_index
      ;;
    gc)
      gc_index
      ;;
    *)
      echo "Session Index Manager v2" >&2
      echo "" >&2
      echo "Usage: session-index.sh <command> [args...]" >&2
      echo "" >&2
      echo "Commands:" >&2
      echo "  init                                    - Initialize empty index" >&2
      echo "  add <id> <slug> [phase] [status] [branch] - Add session" >&2
      echo "  update <id> <key=value> ...             - Update session metadata" >&2
      echo "  set-ref <ref> <id>                      - Set reference" >&2
      echo "  lookup <ref>                            - Lookup session by ref" >&2
      echo "  rebuild                                 - Rebuild index from directories" >&2
      echo "  gc                                      - Garbage collection" >&2
      exit 1
      ;;
  esac
}

#
# Execute if called directly
#
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi

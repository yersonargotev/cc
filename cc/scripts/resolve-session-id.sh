#!/bin/bash
# Session ID Resolver v2
# Resolves user references to full session IDs
# Supports: @latest, @{N}, short IDs, slug search, v1 format, exact v2

set -euo pipefail

INDEX_FILE=".claude/sessions/index.json"

#
# Check if jq is available
#
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    echo "Install: sudo apt-get install jq  (or brew install jq on macOS)" >&2
    exit 1
  fi
}

#
# Initialize index if it doesn't exist
#
ensure_index_exists() {
  if [ ! -f "$INDEX_FILE" ]; then
    # Try to create it using the index manager
    if [ -x ".claude/plugins/session-manager/scripts/session-index.sh" ]; then
      bash .claude/plugins/session-manager/scripts/session-index.sh init &>/dev/null || true
    fi
  fi
}

#
# Check if input matches exact v2 format
#
is_exact_v2_format() {
  local input="$1"
  [[ "$input" =~ ^v2-[0-9]{8}T[0-9]{6}-[a-z0-9]{8}-.+$ ]]
}

#
# Check if input matches v1 format (legacy)
#
is_v1_format() {
  local input="$1"
  [[ "$input" =~ ^[0-9]{8}_[0-9]{6}_[a-f0-9]{8}(_.*)?$ ]]
}

#
# Resolve @latest reference
#
resolve_latest() {
  check_jq
  ensure_index_exists

  if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: No session index found" >&2
    echo "Run: /explore <description> to create your first session" >&2
    return 1
  fi

  local latest=$(jq -r '.refs["@latest"] // empty' "$INDEX_FILE" 2>/dev/null)

  if [ -z "$latest" ]; then
    echo "Error: No @latest session found" >&2
    echo "Run: /explore <description> to create a session" >&2
    return 1
  fi

  echo "$latest"
  return 0
}

#
# Resolve @{N} numbered reference (git-style)
#
resolve_numbered_ref() {
  local input="$1"
  check_jq
  ensure_index_exists

  if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: No session index found" >&2
    return 1
  fi

  # Extract number from @{N}
  local num=$(echo "$input" | sed 's/@{\([0-9]*\)}/\1/')

  if [ -z "$num" ] || [ "$num" = "0" ]; then
    # @{0} or @ is same as @latest
    resolve_latest
    return $?
  fi

  # Get Nth previous session (sorted by updated time, descending)
  local session=$(jq -r --arg n "$num" \
    '.sessions | to_entries |
     sort_by(.value.updated) | reverse |
     .[$n | tonumber].key // empty' \
    "$INDEX_FILE" 2>/dev/null)

  if [ -z "$session" ]; then
    echo "Error: No session found at position @{$num}" >&2
    echo "Available sessions:" >&2
    jq -r '.sessions | to_entries | sort_by(.value.updated) | reverse |
           to_entries[] | "  @{\(.key)} - \(.value.value.slug)"' \
           "$INDEX_FILE" 2>/dev/null | head -5 >&2
    return 1
  fi

  echo "$session"
  return 0
}

#
# Resolve short ID (prefix match on random portion)
#
resolve_short_id() {
  local input="$1"
  check_jq
  ensure_index_exists

  if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: No session index found" >&2
    return 1
  fi

  # Find sessions where random part starts with input
  local matches=$(jq -r --arg prefix "$input" \
    '.sessions | to_entries[] |
     select(.key | split("-")[2] // "" | startswith($prefix)) |
     .key' \
    "$INDEX_FILE" 2>/dev/null)

  if [ -z "$matches" ]; then
    echo "Error: No session found matching short ID: $input" >&2
    echo "Hint: Short IDs are the 3rd part of session ID (e.g., 'asp88phq')" >&2
    return 1
  fi

  local count=$(echo "$matches" | wc -l | tr -d ' ')

  if [ "$count" -gt 1 ]; then
    echo "Error: Ambiguous short ID '$input' matches $count sessions:" >&2
    echo "$matches" | while read -r match; do
      local slug=$(jq -r --arg id "$match" '.sessions[$id].slug // "unknown"' "$INDEX_FILE" 2>/dev/null)
      echo "  $match ($slug)" >&2
    done
    echo "Hint: Use more characters to narrow down" >&2
    return 2
  fi

  echo "$matches"
  return 0
}

#
# Resolve slug search (@/keyword)
#
resolve_slug_search() {
  local input="$1"
  local keyword=$(echo "$input" | sed 's|^@/||')  # Remove @/ prefix

  check_jq
  ensure_index_exists

  if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: No session index found" >&2
    return 1
  fi

  # Search slugs containing keyword (case-insensitive)
  local matches=$(jq -r --arg keyword "$keyword" \
    '.sessions | to_entries[] |
     select(.value.slug | ascii_downcase | contains($keyword | ascii_downcase)) |
     .key' \
    "$INDEX_FILE" 2>/dev/null)

  if [ -z "$matches" ]; then
    echo "Error: No session found matching slug: $keyword" >&2
    echo "Recent sessions:" >&2
    jq -r '.sessions | to_entries | sort_by(.value.updated) | reverse |
           .[0:5][] | "  \(.key) - \(.value.slug)"' \
           "$INDEX_FILE" 2>/dev/null >&2
    return 1
  fi

  local count=$(echo "$matches" | wc -l | tr -d ' ')

  if [ "$count" -gt 1 ]; then
    echo "Error: Slug search '$keyword' matches $count sessions:" >&2
    echo "$matches" | while read -r match; do
      local slug=$(jq -r --arg id "$match" '.sessions[$id].slug // "unknown"' "$INDEX_FILE" 2>/dev/null)
      echo "  $match ($slug)" >&2
    done
    echo "Hint: Use more specific keywords" >&2
    return 2
  fi

  echo "$matches"
  return 0
}

#
# Resolve v1 format (legacy compatibility)
#
resolve_v1_format() {
  local input="$1"

  # Try to find v1 directory directly
  local v1_dirs=$(find .claude/sessions -maxdepth 1 -type d -name "${input}*" 2>/dev/null)

  if [ -z "$v1_dirs" ]; then
    echo "Error: No v1 session found: $input" >&2
    echo "Hint: Migrate v1 sessions with: /session-migrate" >&2
    return 1
  fi

  local count=$(echo "$v1_dirs" | wc -l | tr -d ' ')

  if [ "$count" -gt 1 ]; then
    echo "Error: Ambiguous v1 ID matches $count sessions:" >&2
    echo "$v1_dirs" | while read -r dir; do
      echo "  $(basename "$dir")" >&2
    done
    return 2
  fi

  # Return the directory name (which is the v1 ID)
  basename "$v1_dirs"
  return 0
}

#
# Main resolution logic
#
resolve_session_id() {
  local input="$1"

  if [ -z "$input" ]; then
    echo "Error: Session reference required" >&2
    echo "Usage: resolve-session-id.sh <reference>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  @latest              - Most recent session" >&2
    echo "  @                    - Shorthand for @latest" >&2
    echo "  @{1}                 - Previous session" >&2
    echo "  asp88phq             - Short ID (prefix match)" >&2
    echo "  @/auth               - Slug search" >&2
    echo "  v2-20251109T183846-... - Full ID" >&2
    return 1
  fi

  # Strategy 1: Exact v2 format → return as-is
  if is_exact_v2_format "$input"; then
    # Verify session exists
    if [ -d ".claude/sessions/$input" ]; then
      echo "$input"
      return 0
    else
      echo "Error: Session directory not found: $input" >&2
      return 1
    fi
  fi

  # Strategy 2: @latest or @
  if [ "$input" = "@latest" ] || [ "$input" = "@" ]; then
    resolve_latest
    return $?
  fi

  # Strategy 3: @{N} numbered reference
  if [[ "$input" =~ ^@\{[0-9]+\}$ ]]; then
    resolve_numbered_ref "$input"
    return $?
  fi

  # Strategy 4: @/slug search
  if [[ "$input" =~ ^@/ ]]; then
    resolve_slug_search "$input"
    return $?
  fi

  # Strategy 5: Short ID (4-16 alphanumeric chars)
  if [[ "$input" =~ ^[a-z0-9]{4,16}$ ]]; then
    resolve_short_id "$input"
    return $?
  fi

  # Strategy 6: v1 format (legacy)
  if is_v1_format "$input"; then
    resolve_v1_format "$input"
    return $?
  fi

  # Unknown format
  echo "Error: Unknown session reference format: $input" >&2
  echo "" >&2
  echo "Supported formats:" >&2
  echo "  @latest              - Most recent session" >&2
  echo "  @{N}                 - Nth previous session" >&2
  echo "  asp88phq             - Short ID (8 chars)" >&2
  echo "  @/keyword            - Slug search" >&2
  echo "  v2-20251109T...-...  - Full v2 ID" >&2
  echo "" >&2
  echo "Recent sessions:" >&2
  if [ -f "$INDEX_FILE" ] && command -v jq &> /dev/null; then
    jq -r '.sessions | to_entries | sort_by(.value.updated) | reverse |
           .[0:5][] | "  \(.key) - \(.value.slug)"' \
           "$INDEX_FILE" 2>/dev/null >&2 || true
  fi
  return 1
}

#
# Execute if called directly
#
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  resolve_session_id "$1"
fi

#!/bin/bash
# Session ID Generator v2
# Generates format: v2-YYYYMMDDTHHmmss-base32random-kebab-slug
# Zero external dependencies (no OpenSSL required)

set -euo pipefail

# Base32 charset (human-friendly: excludes 0,1,i,l,o for visual clarity)
BASE32_CHARSET="abcdefghjkmnpqrstvwxyz23456789"

#
# Generate 8-character base32 random ID
#
generate_base32_random() {
  local length=8
  local id=""

  # Method 1: /dev/urandom (cryptographically secure, works on all *nix)
  if [ -r /dev/urandom ]; then
    for i in $(seq 1 $length); do
      # Read one byte from urandom
      local byte=$(od -An -N1 -tu1 /dev/urandom 2>/dev/null | tr -d ' ')

      # Map to charset index
      local idx=$((byte % ${#BASE32_CHARSET}))
      id+="${BASE32_CHARSET:$idx:1}"
    done

    echo "$id"
    return 0
  fi

  # Method 2: $RANDOM fallback (bash built-in, less secure but works everywhere)
  if [ -n "${RANDOM:-}" ]; then
    for i in $(seq 1 $length); do
      local idx=$(($RANDOM % ${#BASE32_CHARSET}))
      id+="${BASE32_CHARSET:$idx:1}"
    done

    echo "$id"
    return 0
  fi

  # Method 3: Timestamp-based fallback (last resort)
  # Not cryptographically secure but deterministic enough for session IDs
  local seed=$(date +%s%N 2>/dev/null || date +%s)
  for i in $(seq 1 $length); do
    seed=$((seed * 1103515245 + 12345))  # Linear congruential generator
    local idx=$(( (seed / 65536) % ${#BASE32_CHARSET} ))
    id+="${BASE32_CHARSET:$idx:1}"
  done

  echo "$id"
  return 0
}

#
# Format ISO8601 compact timestamp: YYYYMMDDTHHmmss
#
format_timestamp() {
  date -u +"%Y%m%dT%H%M%S" 2>/dev/null || date +"%Y%m%dT%H%M%S"
}

#
# Sanitize description to kebab-case slug
# - Lowercase
# - Replace non-alphanumeric with hyphens
# - Remove consecutive hyphens
# - Trim leading/trailing hyphens
#
sanitize_slug() {
  local description="$1"

  # Convert to lowercase and replace spaces/underscores with hyphens
  local slug=$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr '_ ' '--')

  # Keep only alphanumeric and hyphens
  slug=$(echo "$slug" | sed 's/[^a-z0-9-]/-/g')

  # Remove consecutive hyphens
  slug=$(echo "$slug" | sed 's/--*/-/g')

  # Trim leading/trailing hyphens
  slug=$(echo "$slug" | sed 's/^-//;s/-$//')

  # Limit to reasonable length (100 chars for readability)
  slug=$(echo "$slug" | head -c 100)

  echo "$slug"
}

#
# Validate session ID format
#
validate_session_id() {
  local id="$1"

  # Format: v2-YYYYMMDDTHHmmss-base32(8)-slug
  if [[ "$id" =~ ^v2-[0-9]{8}T[0-9]{6}-[a-z0-9]{8}-.+$ ]]; then
    return 0
  else
    return 1
  fi
}

#
# Main: Generate complete session ID
#
generate_session_id() {
  local description="$1"

  if [ -z "$description" ]; then
    echo "Error: Description required" >&2
    echo "Usage: generate-session-id.sh <description>" >&2
    exit 1
  fi

  # Generate components
  local timestamp=$(format_timestamp)
  local random=$(generate_base32_random)
  local slug=$(sanitize_slug "$description")

  # Construct session ID
  local session_id="v2-${timestamp}-${random}-${slug}"

  # Validate format
  if ! validate_session_id "$session_id"; then
    echo "Error: Generated invalid session ID format: $session_id" >&2
    exit 1
  fi

  echo "$session_id"
  return 0
}

#
# Execute if called directly
#
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  if [ $# -eq 0 ]; then
    echo "Session ID Generator v2" >&2
    echo "" >&2
    echo "Usage: $0 <description>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 'Implement user authentication'" >&2
    echo "  $0 'Fix bug in payment processing'" >&2
    echo "  $0 'Add feature: Dark mode toggle'" >&2
    echo "" >&2
    echo "Format: v2-YYYYMMDDTHHmmss-base32random-kebab-slug" >&2
    exit 1
  fi

  generate_session_id "$*"
fi

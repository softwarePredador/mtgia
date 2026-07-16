#!/usr/bin/env bash

# Shared fail-closed approval checks for scripts that create, update, or delete
# data through PostgreSQL-backed APIs or direct PostgreSQL access.

MANALOOM_EXPLICIT_APPROVAL_PHRASE="I_HAVE_EXPLICIT_APPROVAL"

manaloom_has_postgres_write_approval() {
  [[ "${MANALOOM_CONFIRM_POSTGRES_WRITES:-}" == "$MANALOOM_EXPLICIT_APPROVAL_PHRASE" ]]
}

manaloom_has_live_mutation_approval() {
  [[ "${MANALOOM_CONFIRM_LIVE_MUTATIONS:-}" == "$MANALOOM_EXPLICIT_APPROVAL_PHRASE" ]]
}

require_postgres_write_approval() {
  local operation="${1:-PostgreSQL-backed mutation}"
  if manaloom_has_postgres_write_approval; then
    return 0
  fi

  echo "BLOCKED: $operation requires explicit PostgreSQL write approval." >&2
  echo "Set MANALOOM_CONFIRM_POSTGRES_WRITES=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after approval was granted for this run." >&2
  return 2
}

require_live_mutation_approval() {
  local operation="${1:-live mutation}"
  if manaloom_has_live_mutation_approval; then
    return 0
  fi

  echo "BLOCKED: $operation creates, updates, or deletes live data." >&2
  echo "Set MANALOOM_CONFIRM_LIVE_MUTATIONS=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after approval was granted for this run." >&2
  return 2
}

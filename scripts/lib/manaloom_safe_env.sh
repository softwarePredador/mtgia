#!/usr/bin/env bash

MANALOOM_SAFE_ENV_ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly MANALOOM_SAFE_ENV_ROOT

load_manaloom_env_key() {
  local env_file="${1:-}"
  local key="${2:-}"
  local value status
  if [[ -z "$env_file" || -z "$key" ]]; then
    echo "load_manaloom_env_key exige arquivo e chave" >&2
    return 2
  fi
  set +e
  value="$(python3 "$MANALOOM_SAFE_ENV_ROOT/scripts/manaloom_read_env.py" \
    --file "$env_file" --key "$key")"
  status=$?
  set -e
  case "$status" in
    0)
      printf -v "$key" '%s' "$value"
      export "${key?}"
      ;;
    3) ;;
    *) return "$status" ;;
  esac
}

load_manaloom_env_keys() {
  local env_file="${1:-}"
  shift || true
  local key
  for key in "$@"; do
    load_manaloom_env_key "$env_file" "$key"
  done
}

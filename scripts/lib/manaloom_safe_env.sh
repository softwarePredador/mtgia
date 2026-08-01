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

resolve_manaloom_path() {
  local root_dir="${1:-}"
  local candidate="${2:-}"
  if [[ -z "$root_dir" || -z "$candidate" ]]; then
    echo "resolve_manaloom_path exige raiz e caminho" >&2
    return 2
  fi
  python3 - "$root_dir" "$candidate" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
candidate = Path(sys.argv[2]).expanduser()
if not candidate.is_absolute():
    candidate = root / candidate
print(candidate.resolve())
PY
}

load_manaloom_legal_policy_versions() {
  local root_dir="${1:-$MANALOOM_SAFE_ENV_ROOT}"
  local policy_file="$root_dir/server/lib/legal_policy.dart"
  local versions
  if [[ ! -f "$policy_file" ]]; then
    echo "contrato legal ausente: $policy_file" >&2
    return 2
  fi
  versions="$(python3 - "$policy_file" <<'PY'
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8")
values = []
for name in ("currentTermsVersion", "currentPrivacyVersion"):
    match = re.search(
        rf"^const {name} = '([0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}})';$",
        source,
        re.MULTILINE,
    )
    if match is None:
        raise SystemExit(f"versao legal invalida ou ausente: {name}")
    values.append(match.group(1))
print("\t".join(values))
PY
)" || return $?
  IFS=$'\t' read -r \
    MANALOOM_CURRENT_TERMS_VERSION \
    MANALOOM_CURRENT_PRIVACY_VERSION <<<"$versions"
  if [[ -z "${MANALOOM_CURRENT_TERMS_VERSION:-}" ||
        -z "${MANALOOM_CURRENT_PRIVACY_VERSION:-}" ]]; then
    echo "nao foi possivel resolver as versoes legais" >&2
    return 2
  fi
  readonly MANALOOM_CURRENT_TERMS_VERSION
  readonly MANALOOM_CURRENT_PRIVACY_VERSION
  export MANALOOM_CURRENT_TERMS_VERSION
  export MANALOOM_CURRENT_PRIVACY_VERSION
}

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:---worktree}"
GITLEAKS_BIN="${MANALOOM_GITLEAKS_BIN:-gitleaks}"
EXPECTED_VERSION="8.30.1"

if ! command -v "$GITLEAKS_BIN" >/dev/null 2>&1; then
  echo "gitleaks $EXPECTED_VERSION obrigatorio" >&2
  exit 2
fi
ACTUAL_VERSION="$($GITLEAKS_BIN version | awk '{print $NF}')"
if [[ "$ACTUAL_VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "gitleaks incompativel: esperado $EXPECTED_VERSION, encontrado $ACTUAL_VERSION" >&2
  exit 2
fi

cd "$ROOT_DIR"
python3 "$ROOT_DIR/scripts/manaloom_live_credential_audit.py"
case "$MODE" in
  --worktree)
    status=0
    while IFS= read -r -d '' file; do
      [[ -f "$file" ]] || continue
      if ! "$GITLEAKS_BIN" dir \
        --config "$ROOT_DIR/.gitleaks.toml" \
        --max-archive-depth 0 \
        --max-decode-depth 2 \
        --max-target-megabytes 20 \
        --no-banner \
        --log-level error \
        --redact \
        "$file"; then
        status=1
      fi
    done < <(
      git diff --name-only --diff-filter=ACMR -z HEAD
      git ls-files --others --exclude-standard -z
    )
    if [[ "$status" != "0" ]]; then
      echo "secret scan recusou o working tree" >&2
      exit 1
    fi
    ;;
  --git-range)
    BASE_REF="${MANALOOM_SECRET_SCAN_BASE_REF:-origin/master}"
    git rev-parse --verify "$BASE_REF^{commit}" >/dev/null
    "$GITLEAKS_BIN" git \
      --config "$ROOT_DIR/.gitleaks.toml" \
      --log-opts="$BASE_REF..HEAD" \
      --max-archive-depth 0 \
      --max-decode-depth 2 \
      --no-banner \
      --log-level error \
      --redact
    ;;
  *)
    echo "uso: $0 --worktree|--git-range" >&2
    exit 2
    ;;
esac

printf '{"status":"passed","mode":"%s","gitleaks_version":"%s"}\n' \
  "$MODE" "$ACTUAL_VERSION"

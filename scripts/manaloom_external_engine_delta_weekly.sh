#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
REPO_ROOT="${MANALOOM_ENGINE_DELTA_REPO_ROOT:-$ROOT_DIR}"
REPORT_DIR="${MANALOOM_ENGINE_DELTA_REPORT_DIR:-${HOME:?}/Library/Application Support/ManaLoom/external-engine-delta}"
RETENTION_DAYS="${MANALOOM_ENGINE_DELTA_RETENTION_DAYS:-180}"
LOCAL_ONLY=0

usage() {
  cat <<'USAGE'
Uso: manaloom_external_engine_delta_weekly.sh [opções]

Executa a auditoria XMage/Forge somente leitura e guarda relatórios fora do
repositório.

Opções:
  --local-only             valida apenas pins/mirrors, sem rede
  --repo-root CAMINHO      checkout ManaLoom a auditar
  --report-dir CAMINHO     diretório terminado em external-engine-delta
  --retention-days DIAS    retenção dos relatórios timestampados (7..730)
  -h, --help               mostra esta ajuda
USAGE
}

while (( "$#" )); do
  case "$1" in
    --local-only)
      LOCAL_ONLY=1
      shift
      ;;
    --repo-root)
      [[ "$#" -ge 2 ]] || {
        echo "--repo-root exige um caminho" >&2
        exit 2
      }
      REPO_ROOT="$2"
      shift 2
      ;;
    --report-dir)
      [[ "$#" -ge 2 ]] || {
        echo "--report-dir exige um caminho" >&2
        exit 2
      }
      REPORT_DIR="$2"
      shift 2
      ;;
    --retention-days)
      [[ "$#" -ge 2 ]] || {
        echo "--retention-days exige um número" >&2
        exit 2
      }
      RETENTION_DAYS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "opção desconhecida: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! "$RETENTION_DAYS" =~ ^[0-9]+$ ]] ||
  (( RETENTION_DAYS < 7 || RETENTION_DAYS > 730 )); then
  echo "retenção deve estar entre 7 e 730 dias" >&2
  exit 2
fi
if [[ "$REPO_ROOT" != /* ]] ||
  ! git -C "$REPO_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "checkout Git ManaLoom inválido: $REPO_ROOT" >&2
  exit 2
fi
REPO_ROOT="$(git -C "$REPO_ROOT" rev-parse --show-toplevel)"
if [[ "$REPORT_DIR" != /* ]]; then
  echo "diretório de relatórios deve ser absoluto" >&2
  exit 2
fi
case "$REPORT_DIR" in
  /|"$HOME"|"$REPO_ROOT"|"$REPO_ROOT"/*)
    echo "diretório de relatórios inseguro ou interno ao checkout: $REPORT_DIR" >&2
    exit 2
    ;;
esac
if [[ "$(basename "$REPORT_DIR")" != "external-engine-delta" ]]; then
  echo "diretório de relatórios deve terminar em external-engine-delta" >&2
  exit 2
fi

umask 077
mkdir -p "$REPORT_DIR"
chmod 700 "$REPORT_DIR"
REPORT_DIR="$(CDPATH='' cd -- "$REPORT_DIR" && pwd -P)"
if [[ "$(basename "$REPORT_DIR")" != "external-engine-delta" ]]; then
  echo "diretório resolvido não termina em external-engine-delta: $REPORT_DIR" >&2
  exit 2
fi
case "$REPORT_DIR" in
  /|"$HOME"|"$REPO_ROOT"|"$REPO_ROOT"/*)
    echo "diretório resolvido de relatórios é inseguro ou interno ao checkout: $REPORT_DIR" >&2
    exit 2
    ;;
esac
case "$REPORT_DIR" in
  "$REPO_ROOT"|"$REPO_ROOT"/*)
    echo "diretório resolvido fica dentro do checkout: $REPORT_DIR" >&2
    exit 2
    ;;
esac

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT_PATH="$REPORT_DIR/external-engine-delta-$STAMP-$$.json"
TEMP_PATH="$REPORT_DIR/.external-engine-delta-$STAMP-$$.json.tmp"
LATEST_PATH="$REPORT_DIR/latest.json"
LATEST_TEMP="$REPORT_DIR/.latest-$$.json.tmp"

trap 'rm -f "$TEMP_PATH" "$LATEST_TEMP"' EXIT INT TERM

publish_latest() {
  local source_path="$1"
  cp "$source_path" "$LATEST_TEMP"
  chmod 600 "$LATEST_TEMP"
  mv -f "$LATEST_TEMP" "$LATEST_PATH"
}

apply_retention() {
  python3 - "$REPORT_DIR" "$RETENTION_DAYS" <<'PY'
import re
import sys
import time
from pathlib import Path

report_dir = Path(sys.argv[1]).resolve()
retention_days = int(sys.argv[2])
if report_dir.name != "external-engine-delta":
    raise SystemExit("unsafe retention directory")
pattern = re.compile(
    r"^external-engine-delta-\d{8}T\d{6}Z-\d+\.json$"
)
cutoff = time.time() - retention_days * 86400
deleted = 0
for candidate in report_dir.iterdir():
    if (
        pattern.fullmatch(candidate.name)
        and candidate.is_file()
        and not candidate.is_symlink()
        and candidate.stat().st_mtime < cutoff
    ):
        candidate.unlink()
        deleted += 1
print(f"retention_deleted={deleted}")
PY
}

write_schedule_report() {
  local status="$1"
  local reason="$2"
  python3 - "$TEMP_PATH" "$status" "$reason" "$REPO_ROOT" "$STAMP" <<'PY'
import json
import sys
from pathlib import Path

path, status, reason, repo_root, stamp = sys.argv[1:]
payload = {
    "schema_version": "external_engine_delta_schedule_event_v1",
    "generated_at_utc": stamp,
    "status": status,
    "reason": reason,
    "repo_root": repo_root,
    "safety": {
        "read_only_product_scope": True,
        "postgres_writes": False,
        "sqlite_or_hermes_writes": False,
        "pin_updates_performed": False,
        "runtime_changes_performed": False,
        "deployment_actions_performed": False,
        "promotion_actions_performed": False,
    },
}
Path(path).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
  chmod 600 "$TEMP_PATH"
  mv "$TEMP_PATH" "$REPORT_PATH"
  publish_latest "$REPORT_PATH"
  apply_retention
  printf 'status=%s reason=%s report=%s\n' "$status" "$reason" "$REPORT_PATH"
}

if [[ -n "$(git -C "$REPO_ROOT" status --porcelain=v1 --untracked-files=normal)" ]]; then
  write_schedule_report "skipped" "dirty_worktree"
  exit 0
fi

audit_args=(--repo-root "$REPO_ROOT")
if (( LOCAL_ONLY == 1 )); then
  audit_args+=(--local-only)
fi

set +e
MANALOOM_ENGINE_DELTA_OUTPUT="$TEMP_PATH" \
  "$ROOT_DIR/scripts/manaloom_external_engine_delta_audit.sh" "${audit_args[@]}"
audit_status="$?"
set -e

if [[ ! -s "$TEMP_PATH" ]] ||
  ! python3 -m json.tool "$TEMP_PATH" >/dev/null 2>&1; then
  rm -f "$TEMP_PATH"
  write_schedule_report "fail" "audit_did_not_produce_valid_json"
  if (( audit_status == 0 )); then
    audit_status=1
  fi
  exit "$audit_status"
fi

chmod 600 "$TEMP_PATH"
mv "$TEMP_PATH" "$REPORT_PATH"
publish_latest "$REPORT_PATH"
apply_retention

python3 - "$REPORT_PATH" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    report = json.load(handle)
print(
    "status={status} review_required={review} report={path}".format(
        status=report.get("status", "unknown"),
        review=str(bool(report.get("review_required"))).lower(),
        path=sys.argv[1],
    )
)
PY
exit "$audit_status"

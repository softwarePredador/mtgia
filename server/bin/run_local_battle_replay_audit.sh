#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="${MANALOOM_REPO:-$(CDPATH= cd -- "$SERVER_BIN_DIR/../.." && pwd)}"
SCRIPT_DIR="${MANALOOM_HERMES_SCRIPT_DIR:-$REPO_ROOT/docs/hermes-analysis/manaloom-knowledge/scripts}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-${MTGIA_ENV_FILE:-$REPO_ROOT/server/.env}}"
SQLITE_DB="${HERMES_KNOWLEDGE_DB:-$SCRIPT_DIR/knowledge.db}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
ARTIFACT_DIR="${MANALOOM_LOCAL_BATTLE_AUDIT_DIR:-$REPO_ROOT/server/test/artifacts/local_battle_replay_audit}"
INCLUDE_NEEDS_REVIEW=0
SKIP_SYNC=0

usage() {
  cat <<'EOF'
Usage: run_local_battle_replay_audit.sh [options]

Options:
  --artifact-dir PATH       Output directory for replay/audit artifacts.
  --skip-sync               Do not refresh local SQLite battle rules from PostgreSQL.
  --include-needs-review    Mirror PG needs_review rows into SQLite before replay.
  -h, --help                Show this help.

This runner exists to avoid trusting a local battle replay generated from a
stale Hermes SQLite cache. By default it:
  1. loads server/.env when available;
  2. refreshes SQLite battle_card_rules from PostgreSQL;
  3. runs battle_replay_v10_3.py;
  4. runs forensic + strategy auditors;
  5. writes a small summary.json for the run.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-dir)
      ARTIFACT_DIR="$2"
      shift 2
      ;;
    --skip-sync)
      SKIP_SYNC=1
      shift
      ;;
    --include-needs-review)
      INCLUDE_NEEDS_REVIEW=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

mkdir -p "$ARTIFACT_DIR"
TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"

if [[ -f "$SECRET_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$SECRET_ENV"
  set +a
fi

SYNC_REPORT=""
CANONICAL_SNAPSHOT_ARTIFACT=""
if [[ "$SKIP_SYNC" != "1" ]]; then
  SYNC_REPORT="$ARTIFACT_DIR/battle_card_rules_cache_sync_${TIMESTAMP}.json"
  CANONICAL_SNAPSHOT_ARTIFACT="$ARTIFACT_DIR/known_cards_canonical_snapshot_${TIMESTAMP}.json"
  sync_args=(
    "$PYTHON_BIN" "$SCRIPT_DIR/sync_battle_card_rules_pg.py"
    --sqlite-db "$SQLITE_DB"
    --apply-sqlite-from-pg
    --export-canonical-fallback-json "$CANONICAL_SNAPSHOT_ARTIFACT"
    --report "$SYNC_REPORT"
  )
  if [[ "$INCLUDE_NEEDS_REVIEW" == "1" ]]; then
    sync_args+=(--include-needs-review)
  fi
  "${sync_args[@]}"
fi

REPLAY_LOG="$ARTIFACT_DIR/battle_replay_${TIMESTAMP}.log"
"$PYTHON_BIN" "$SCRIPT_DIR/battle_replay_v10_3.py" > "$REPLAY_LOG"

EVENTS_FILE="$ARTIFACT_DIR/battle_full_replay_${TIMESTAMP}.jsonl"
TRACE_FILE="$ARTIFACT_DIR/battle_full_replay_${TIMESTAMP}.decision_trace.jsonl"
cp /tmp/battle_full_replay.jsonl "$EVENTS_FILE"
cp /tmp/battle_full_replay.decision_trace.jsonl "$TRACE_FILE"

FORENSIC_MD="$ARTIFACT_DIR/replay_decision_audit_${TIMESTAMP}.md"
STRATEGY_MD="$ARTIFACT_DIR/battle_strategy_audit_${TIMESTAMP}.md"
STRATEGY_JSON="$ARTIFACT_DIR/battle_strategy_audit_${TIMESTAMP}.json"

"$PYTHON_BIN" "$SCRIPT_DIR/replay_decision_auditor.py" \
  --events "$EVENTS_FILE" \
  --decision-trace "$TRACE_FILE" \
  --require-decision-trace > "$FORENSIC_MD"

"$PYTHON_BIN" "$SCRIPT_DIR/battle_decision_strategy_auditor.py" \
  --events "$EVENTS_FILE" \
  --decision-trace "$TRACE_FILE" \
  --output "$STRATEGY_MD" \
  --json-output "$STRATEGY_JSON"

SUMMARY_JSON="$ARTIFACT_DIR/summary_${TIMESTAMP}.json"
FORENSIC_MD="$FORENSIC_MD" \
STRATEGY_JSON="$STRATEGY_JSON" \
SUMMARY_JSON="$SUMMARY_JSON" \
EVENTS_FILE="$EVENTS_FILE" \
TRACE_FILE="$TRACE_FILE" \
SYNC_REPORT="$SYNC_REPORT" \
CANONICAL_SNAPSHOT_ARTIFACT="$CANONICAL_SNAPSHOT_ARTIFACT" \
TIMESTAMP_VALUE="$TIMESTAMP" \
"$PYTHON_BIN" - <<'PY'
import json
import os
from pathlib import Path

forensic_path = Path(os.environ["FORENSIC_MD"])
strategy_path = Path(os.environ["STRATEGY_JSON"])
summary_path = Path(os.environ["SUMMARY_JSON"])
events_path = Path(os.environ["EVENTS_FILE"])
trace_path = Path(os.environ["TRACE_FILE"])
sync_report = os.environ.get("SYNC_REPORT", "")
canonical_snapshot_artifact = os.environ.get("CANONICAL_SNAPSHOT_ARTIFACT", "")
timestamp_value = os.environ["TIMESTAMP_VALUE"]

strategy = json.loads(strategy_path.read_text()) if strategy_path.exists() else {}
forensic_summary = {
    "status": None,
    "turn_findings": None,
    "decision_findings": None,
    "critical": None,
    "high": None,
    "medium": None,
    "low": None,
}
for line in forensic_path.read_text().splitlines():
    if line.startswith("- status:"):
        forensic_summary["status"] = line.split(":", 1)[1].strip()
    elif line.startswith("- turn_findings:"):
        forensic_summary["turn_findings"] = int(line.split(":", 1)[1].strip())
    elif line.startswith("- decision_findings:"):
        forensic_summary["decision_findings"] = int(line.split(":", 1)[1].strip())
    elif line.startswith("- critical:"):
        forensic_summary["critical"] = int(line.split(":", 1)[1].strip())
    elif line.startswith("- high:"):
        forensic_summary["high"] = int(line.split(":", 1)[1].strip())
    elif line.startswith("- medium:"):
        forensic_summary["medium"] = int(line.split(":", 1)[1].strip())
    elif line.startswith("- low:"):
        forensic_summary["low"] = int(line.split(":", 1)[1].strip())

summary = {
    "timestamp_utc": timestamp_value,
    "events_file": str(events_path),
    "decision_trace_file": str(trace_path),
    "forensic_audit_file": str(forensic_path),
    "strategy_audit_file": str(strategy_path),
    "sync_report": sync_report or None,
    "canonical_snapshot_artifact": canonical_snapshot_artifact or None,
    "forensic_summary": forensic_summary,
    "strategy_summary": strategy.get("summary", {}),
}
summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\\n")
print(json.dumps(summary, ensure_ascii=False))
PY

echo "local_battle_replay_audit=ok"
echo "artifact_dir=$ARTIFACT_DIR"
echo "summary_json=$SUMMARY_JSON"

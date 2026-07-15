#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KNOWLEDGE_SCRIPTS="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts"
SERVER_ENV="$ROOT_DIR/server/.env"
NETWORK="${MANALOOM_EASYPANEL_NETWORK:-easypanel-evolution}"
PYTHON_IMAGE="${MANALOOM_CLOSURE_PYTHON_IMAGE:-python:3.13-alpine}"

usage() {
  cat <<'EOF'
Usage:
  scripts/manaloom_global_battle_closure.sh coverage [output_root]
  scripts/manaloom_global_battle_closure.sh battle <registry.json> [state_dir]

coverage
  Rebuilds the PostgreSQL -> XMage -> Forge -> native ledger, reconciles local
  XMage source candidates with live catalogs, and keeps only compact residual
  evidence under output_root (default: /tmp/manaloom-global-closure-output).

battle
  Runs or resumes an external_battle_async_registry_v1 queue. The checkpoint
  and per-job results persist in state_dir (default: /tmp/manaloom-battle-state).
EOF
}

require_file() {
  [[ -f "$1" ]] || {
    echo "Required file not found: $1" >&2
    exit 2
  }
}

load_server_env() {
  require_file "$SERVER_ENV"
  set -a
  # shellcheck disable=SC1090
  source "$SERVER_ENV"
  set +a
  : "${EASYPANEL_SSH_KEY:?EASYPANEL_SSH_KEY is required}"
  : "${EASYPANEL_SSH_USER:?EASYPANEL_SSH_USER is required}"
  : "${EASYPANEL_SERVER_IP:?EASYPANEL_SERVER_IP is required}"
}

remote() {
  ssh -i "$EASYPANEL_SSH_KEY" -o BatchMode=yes \
    "$EASYPANEL_SSH_USER@$EASYPANEL_SERVER_IP" "$@"
}

copy_to_remote() {
  scp -i "$EASYPANEL_SSH_KEY" -o BatchMode=yes "$@" \
    "$EASYPANEL_SSH_USER@$EASYPANEL_SERVER_IP:$REMOTE_DIR/"
}

copy_from_remote() {
  scp -i "$EASYPANEL_SSH_KEY" -o BatchMode=yes \
    "$EASYPANEL_SSH_USER@$EASYPANEL_SERVER_IP:$REMOTE_DIR/$1" "$2"
}

prepare_workdirs() {
  WORK_DIR="$(mktemp -d /tmp/manaloom-global-closure.XXXXXX)"
  REMOTE_DIR="/tmp/manaloom-global-closure-$(date -u +%Y%m%d%H%M%S)-$$"
  remote "mkdir -p '$REMOTE_DIR'"
}

cleanup() {
  local exit_code=$?
  trap - EXIT INT TERM
  if [[ -n "${REMOTE_DIR:-}" ]]; then
    remote "rm -rf '$REMOTE_DIR'" >/dev/null 2>&1 || true
  fi
  if [[ -n "${WORK_DIR:-}" ]]; then
    rm -rf "$WORK_DIR"
  fi
  exit "$exit_code"
}

run_remote_python() {
  local script="$1"
  shift
  local remote_command
  local -a command=(
    docker run --rm
    --network "$NETWORK"
    -v "$REMOTE_DIR:/work"
    -w /work
    "$PYTHON_IMAGE"
    python "$script" "$@"
  )
  printf -v remote_command ' %q' "${command[@]}"
  remote "${remote_command# }"
}

run_coverage() {
  local output_root="${1:-/tmp/manaloom-global-closure-output}"
  local run_id="coverage_$(date -u +%Y%m%d_%H%M%S)"
  local output_dir="$output_root/$run_id"
  mkdir -p "$output_dir"

  "$ROOT_DIR/server/bin/with_new_server_pg.sh" psql -X -A -t \
    -o "$WORK_DIR/cards.json" -c \
    "SELECT COALESCE(json_agg(json_build_object(
      'card_id', id::text,
      'oracle_id', oracle_id::text,
      'name', name,
      'type_line', type_line,
      'set_code', set_code,
      'collector_number', collector_number,
      'layout', layout,
      'oracle_text', oracle_text,
      'card_faces_json', card_faces_json
    ) ORDER BY name, id::text), '[]'::json) FROM cards"

  "$ROOT_DIR/server/bin/with_new_server_pg.sh" psql -X -A -t \
    -o "$WORK_DIR/native.json" -c \
    "SELECT COALESCE(json_agg(DISTINCT card_name ORDER BY card_name), '[]'::json)
     FROM card_battle_rules
     WHERE review_status IN ('verified','active')
       AND execution_status IN ('auto','executable')
       AND COALESCE(effect_json, '{}'::jsonb) <> '{}'::jsonb"

  "$ROOT_DIR/server/bin/with_new_server_pg.sh" python3 \
    "$KNOWLEDGE_SCRIPTS/xmage_authoritative_adaptation_queue.py" \
    --scope all_battle_gap \
    --out-prefix "$WORK_DIR/xmage_source_queue"

  jq '{cards: [.queue[]
    | select(.source_resolution_status == "local_source_candidate")
    | {card_id, oracle_id, name: .card_name}]}' \
    "$WORK_DIR/xmage_source_queue.json" >"$WORK_DIR/xmage_source_cards.json"

  copy_to_remote \
    "$WORK_DIR/cards.json" \
    "$WORK_DIR/native.json" \
    "$WORK_DIR/xmage_source_cards.json" \
    "$KNOWLEDGE_SCRIPTS/external_card_coverage_closure.py"

  run_remote_python external_card_coverage_closure.py \
    --cards cards.json \
    --native-cards native.json \
    --xmage-url http://xmage-sidecar:8080 \
    --forge-url http://forge-sidecar:8080 \
    --timeout-seconds 60 \
    --out-prefix global_coverage

  run_remote_python external_card_coverage_closure.py \
    --cards xmage_source_cards.json \
    --native-cards native.json \
    --xmage-url http://xmage-sidecar:8080 \
    --forge-url http://forge-sidecar:8080 \
    --timeout-seconds 60 \
    --out-prefix xmage_source_coverage

  copy_from_remote global_coverage.json "$WORK_DIR/global_coverage.json"
  copy_from_remote global_coverage.md "$output_dir/global_coverage.md"
  copy_from_remote xmage_source_coverage.json "$WORK_DIR/xmage_source_coverage.json"
  copy_from_remote xmage_source_coverage.md "$output_dir/xmage_source_coverage.md"

  python3 "$KNOWLEDGE_SCRIPTS/xmage_source_catalog_reconciliation.py" \
    --queue "$WORK_DIR/xmage_source_queue.json" \
    --coverage "$WORK_DIR/xmage_source_coverage.json" \
    --out-prefix "$WORK_DIR/source_catalog_reconciliation"

  cp "$WORK_DIR/source_catalog_reconciliation.md" \
    "$output_dir/source_catalog_reconciliation.md"
  jq '{schema_version, generated_at, status, method, summary, family_gates,
       residual: [.ledger[] | select(.covered == false)]}' \
    "$WORK_DIR/global_coverage.json" >"$output_dir/global_residual.json"
  jq '{schema_version, generated_at, status, method, summary,
       residual: [.rows[] | select(.operationally_covered == false)]}' \
    "$WORK_DIR/source_catalog_reconciliation.json" \
    >"$output_dir/source_catalog_residual.json"

  jq -n \
    --slurpfile global "$WORK_DIR/global_coverage.json" \
    --slurpfile source "$WORK_DIR/source_catalog_reconciliation.json" \
    '{schema_version:"global_battle_closure_summary_v1",
      generated_at:($global[0].generated_at),
      global:$global[0].summary,
      source_catalog:$source[0].summary,
      postgres_mutations:[]}' \
    >"$output_dir/summary.json"

  echo "Coverage closure: $output_dir"
  jq . "$output_dir/summary.json"
}

run_battle() {
  local registry="$1"
  local state_dir="${2:-/tmp/manaloom-battle-state}"
  require_file "$registry"
  mkdir -p "$state_dir/results"

  cp "$registry" "$WORK_DIR/registry.json"
  if [[ -f "$state_dir/checkpoint.json" ]]; then
    cp "$state_dir/checkpoint.json" "$WORK_DIR/checkpoint.json"
  fi
  if [[ -d "$state_dir/results" ]]; then
    cp -R "$state_dir/results" "$WORK_DIR/results"
  fi
  copy_to_remote \
    "$WORK_DIR/registry.json" \
    "$KNOWLEDGE_SCRIPTS/external_battle_async_runner.py"
  if [[ -f "$WORK_DIR/checkpoint.json" ]]; then
    copy_to_remote "$WORK_DIR/checkpoint.json"
  fi
  remote "mkdir -p '$REMOTE_DIR/results'"

  run_remote_python external_battle_async_runner.py \
    --registry registry.json \
    --checkpoint checkpoint.json \
    --result-dir results \
    --xmage-url http://xmage-sidecar:8080 \
    --forge-url http://forge-sidecar:8080 \
    --request-timeout-seconds 130 \
    --recovery-timeout-seconds 180 \
    --max-attempts 3

  copy_from_remote checkpoint.json "$state_dir/checkpoint.json"
  scp -r -i "$EASYPANEL_SSH_KEY" -o BatchMode=yes \
    "$EASYPANEL_SSH_USER@$EASYPANEL_SERVER_IP:$REMOTE_DIR/results/." \
    "$state_dir/results/"
  echo "Battle state: $state_dir"
  jq '{status, updated_at, comparison_gates,
       job_status_counts: ([.jobs[].status] | group_by(.) | map({key:.[0],value:length}) | from_entries)}' \
    "$state_dir/checkpoint.json"
}

main() {
  local command="${1:-}"
  case "$command" in
    coverage)
      load_server_env
      trap cleanup EXIT INT TERM
      prepare_workdirs
      run_coverage "${2:-}"
      ;;
    battle)
      [[ $# -ge 2 ]] || {
        usage
        exit 2
      }
      load_server_env
      trap cleanup EXIT INT TERM
      prepare_workdirs
      run_battle "$2" "${3:-}"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"

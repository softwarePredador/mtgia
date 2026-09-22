#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:-quick}"
SCOPE_MODE="${2:-}"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"

if [[ "$#" -gt 2 ]]; then
  echo "uso: $0 quick [--staged-scope]|schema|full|e2e|release" >&2
  exit 2
fi

STAGED_SCOPE=0
if [[ -n "$SCOPE_MODE" ]]; then
  if [[ "$MODE" != "quick" || "$SCOPE_MODE" != "--staged-scope" ]]; then
    echo "--staged-scope é permitido somente com quick" >&2
    exit 2
  fi
  STAGED_SCOPE=1
fi

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"

node_is_supported() {
  "$1" -e '
    const [major, minor] = process.versions.node.split(".").map(Number);
    process.exit(
      major >= 24 || major === 22 && minor >= 13 || major === 20 && minor >= 19
        ? 0
        : 1,
    );
  ' >/dev/null 2>&1
}

resolve_node_bin() {
  local candidate=""
  if [[ -n "${MANALOOM_NODE_BIN:-}" ]]; then
    candidate="$MANALOOM_NODE_BIN"
  else
    candidate="$(command -v node || true)"
  fi
  if [[ -n "$candidate" && -x "$candidate" ]] && node_is_supported "$candidate"; then
    printf '%s\n' "$candidate"
    return 0
  fi
  for candidate in /opt/homebrew/bin/node /usr/local/bin/node; do
    if [[ -x "$candidate" ]] && node_is_supported "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  echo "Node local compatível obrigatório (^20.19, ^22.13 ou >=24)" >&2
  return 2
}

NODE_BIN="$(resolve_node_bin)"

if [[ -n "${MANALOOM_FLUTTER_BIN:-}" ]]; then
  FLUTTER_BIN="$MANALOOM_FLUTTER_BIN"
elif [[ -x "$PINNED_FLUTTER" ]]; then
  FLUTTER_BIN="$PINNED_FLUTTER"
else
  FLUTTER_BIN="$(command -v flutter || true)"
fi
if [[ -z "$FLUTTER_BIN" || ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter local obrigatório não encontrado" >&2
  exit 2
fi

resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

export MANALOOM_FLUTTER_BIN="$FLUTTER_BIN"
export MANALOOM_DART_BIN="$DART_BIN"
export MANALOOM_NODE_BIN="$NODE_BIN"
export PATH="$(dirname "$NODE_BIN"):$(dirname "$FLUTTER_BIN"):$(dirname "$DART_BIN"):$PATH"
export JWT_SECRET="${JWT_SECRET:-local_quality_gate_jwt_secret_not_for_production_20260706}"
export DISABLE_FIREBASE_STARTUP="${DISABLE_FIREBASE_STARTUP:-true}"
export DISABLE_PUSH_INIT="${DISABLE_PUSH_INIT:-true}"
export DISABLE_FIREBASE_PERFORMANCE_INIT="${DISABLE_FIREBASE_PERFORMANCE_INIT:-true}"

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_local_ci.XXXXXX")"
cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  rm -rf "$RUN_DIR"
  exit "$status"
}
trap cleanup EXIT INT TERM

print_header() {
  printf '\n== %s ==\n' "$1"
}

run_shell_contracts() {
  print_header "Contratos dos gates locais"
  bash -n \
    "$ROOT_DIR/scripts/manaloom_local_ci.sh" \
    "$ROOT_DIR/scripts/manaloom_e2e_suite.sh" \
    "$ROOT_DIR/scripts/quality_gate.sh" \
    "$ROOT_DIR/scripts/manaloom_ui_live_evidence_gate.sh" \
    "$ROOT_DIR/scripts/manaloom_ui_source_digest.sh" \
    "$ROOT_DIR/scripts/manaloom_tbls_local_gate.sh" \
    "$ROOT_DIR/scripts/manaloom_install_local_hooks.sh" \
    "$ROOT_DIR/scripts/manaloom_external_engine_delta_weekly.sh" \
    "$ROOT_DIR/scripts/manaloom_install_external_engine_delta_schedule.sh" \
    "$ROOT_DIR/scripts/manaloom_xmage_pin_transition_audit.sh" \
    "$ROOT_DIR/services/xmage-sidecar/bin/verify_product_scope_semantic_tests.sh" \
    "$ROOT_DIR/.githooks/pre-commit" \
    "$ROOT_DIR/.githooks/pre-push"
  "$ROOT_DIR/scripts/manaloom_install_local_hooks.sh" --check
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/server/test/staged_ui_scope_classifier_test.py"
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/server/test/local_ci_staged_scope_dispatcher_test.py"
}

run_mcp_preflight() {
  print_header "Dart/Flutter MCP local"
  "$ROOT_DIR/scripts/manaloom_dart_mcp_preflight.sh" --check
}

run_project_logic() {
  print_header "Manifesto, análise semântica e drift"
  "$ROOT_DIR/scripts/manaloom_project_logic.sh" --check
  # A suíte roda pelo próprio script, não num subshell ao lado: ela valida o
  # binding de PUB_CACHE task-scoped que só existe dentro do ambiente que o
  # script materializa.
  "$ROOT_DIR/scripts/manaloom_project_logic.sh" --test
}

run_commander_game_changer_source() {
  print_header "Fonte oficial de Commander Game Changers"
  python3 \
    "$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/sync_game_changers_to_dart.py" \
    --check
}

run_ui_live_evidence() {
  print_header "Prova UI viva e revisada"
  "$ROOT_DIR/scripts/manaloom_ui_live_evidence_gate.sh" --check
}

classify_staged_ui_scope() {
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/scripts/manaloom_staged_ui_scope.py"
}

parse_staged_ui_scope_record() {
  local record="$1"
  local extra=""
  if [[ "$record" == *$'\n'* ]]; then
    echo "classificador staged de UI retornou mais de um registro" >&2
    return 2
  fi
  PARSED_SCOPE_STATUS=""
  PARSED_SCOPE_HEAD_OID=""
  PARSED_SCOPE_INDEX_TREE_OID=""
  IFS=$'\t' read -r \
    PARSED_SCOPE_STATUS \
    PARSED_SCOPE_HEAD_OID \
    PARSED_SCOPE_INDEX_TREE_OID \
    extra <<<"$record"
  case "$PARSED_SCOPE_STATUS" in
    AFFECTS_UI|N/A_UI_SOURCE_UNCHANGED_STAGED_SCOPE|BOOTSTRAP_STAGED_UI_SCOPE_CONTROL_PLANE)
      ;;
    *)
      echo "classificador staged de UI retornou estado inválido" >&2
      return 2
      ;;
  esac
  if [[ "$PARSED_SCOPE_HEAD_OID" != "UNBORN" ]] && \
    [[ ! "$PARSED_SCOPE_HEAD_OID" =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ ]]; then
    echo "classificador staged de UI retornou HEAD inválido" >&2
    return 2
  fi
  if [[ ! "$PARSED_SCOPE_INDEX_TREE_OID" =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ ]] || \
    [[ -n "$extra" ]]; then
    echo "classificador staged de UI retornou index tree inválido" >&2
    return 2
  fi
}

run_secret_scan() {
  print_header "Secret scan local"
  "$ROOT_DIR/scripts/manaloom_secret_scan.sh" --worktree
}

run_guardrail_audits() {
  print_header "Auditorias determinísticas locais"
  local scripts_dir="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts"
  python3 -m py_compile \
    "$scripts_dir/external_card_rule_reference_harvester.py" \
    "$scripts_dir/external_engine_upstream_delta_audit.py" \
    "$scripts_dir/legacy_contamination_audit.py" \
    "$scripts_dir/operational_surface_alignment_audit.py" \
    "$scripts_dir/report_retention_audit.py" \
    "$scripts_dir/xmage_pin_transition_audit.py" \
    "$scripts_dir/xmage_transition_activation_policy.py" \
    "$scripts_dir/xmage_transition_nominal_review.py" \
    "$scripts_dir/xmage_transition_postgresql_scope_reconciliation.py" \
    "$scripts_dir/xmage_test_scenario_miner.py"
  (
    cd "$scripts_dir"
    python3 -m unittest \
      test_external_card_rule_reference_harvester.py \
      test_external_engine_delta_schedule_contract.py \
      test_external_engine_upstream_delta_audit.py \
      test_legacy_contamination_audit.py \
      test_operational_surface_alignment_audit.py \
      test_report_retention_audit.py \
      test_xmage_pin_transition_audit.py \
      test_xmage_transition_activation_policy.py \
      test_xmage_transition_nominal_review.py \
      test_xmage_transition_postgresql_scope_reconciliation.py \
      test_xmage_test_scenario_miner.py
  )

  python3 - "$RUN_DIR/knowledge.db" <<'PY'
import sqlite3
import sys

with sqlite3.connect(sys.argv[1]) as connection:
    connection.execute(
        "CREATE TABLE battle_card_rules ("
        "id INTEGER PRIMARY KEY, card_id TEXT NOT NULL)"
    )
PY
  MANALOOM_KNOWLEDGE_DB="$RUN_DIR/knowledge.db" \
    python3 "$scripts_dir/legacy_contamination_audit.py" \
      --out-prefix "$RUN_DIR/legacy-contamination"
  python3 "$scripts_dir/external_engine_upstream_delta_audit.py" \
    --local-only \
    --json-output "$RUN_DIR/external-engine-pin.json"
  python3 "$scripts_dir/xmage_pin_transition_audit.py" \
    --output-prefix "$RUN_DIR/xmage-pin-transition"
  python3 "$scripts_dir/operational_surface_alignment_audit.py" \
    --out-prefix "$RUN_DIR/operational-surface"
  python3 "$scripts_dir/report_retention_audit.py" \
    --fail-on-ignored-local \
    --out-prefix "$RUN_DIR/report-retention"
}

run_full_quality() {
  print_header "Qualidade completa local"
  cd "$ROOT_DIR"
  "$DART_BIN" run melos run quality
}

run_schema_gate() {
  print_header "PostgreSQL/tbls descartável"
  "$ROOT_DIR/scripts/manaloom_tbls_local_gate.sh"
}

run_release_contracts() {
  print_header "Contratos operacionais de release"
  "$ROOT_DIR/scripts/manaloom_release_ops_contract_test.sh"
}

run_battle_gate() {
  print_header "Battle canônico local"
  "$ROOT_DIR/services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh"
  "$ROOT_DIR/services/xmage-sidecar/bin/verify_product_scope_semantic_tests.sh"
  "$ROOT_DIR/scripts/quality_gate.sh" battle
}

run_strict_e2e_gate() {
  print_header "E2E integrado estrito"
  # O local CI nunca seleciona --allow-partial. Um SKIP/PARTIAL precisa
  # interromper o wrapper antes da mensagem final de PASS.
  "$ROOT_DIR/scripts/quality_gate.sh" e2e
}

run_quick() {
  local initial_scope_record=""
  local initial_scope_status=""
  local initial_head_oid=""
  local initial_index_tree_oid=""
  if [[ "$STAGED_SCOPE" == "1" ]]; then
    initial_scope_record="$(classify_staged_ui_scope)"
    parse_staged_ui_scope_record "$initial_scope_record"
    initial_scope_status="$PARSED_SCOPE_STATUS"
    initial_head_oid="$PARSED_SCOPE_HEAD_OID"
    initial_index_tree_oid="$PARSED_SCOPE_INDEX_TREE_OID"
  fi
  run_shell_contracts
  run_commander_game_changer_source
  run_mcp_preflight
  run_secret_scan
  run_project_logic
  if [[ "$STAGED_SCOPE" != "1" ]]; then
    run_ui_live_evidence
    return 0
  fi

  if [[ "$initial_scope_status" == "AFFECTS_UI" ]]; then
    print_header "Escopo UI do índice staged"
    run_ui_live_evidence
  fi

  local final_scope_record=""
  final_scope_record="$(classify_staged_ui_scope)"
  parse_staged_ui_scope_record "$final_scope_record"
  if [[ "$final_scope_record" != "$initial_scope_record" ]]; then
    echo "HEAD, index tree, binding ou classificação mudou durante o gate" >&2
    return 2
  fi

  print_header "Escopo UI imutável do índice staged"
  if [[ "$initial_scope_status" == "AFFECTS_UI" ]]; then
    printf \
      '{"status":"AFFECTS_UI","ui_gate_required":true,"head_oid":"%s","index_tree_oid":"%s"}\n' \
      "$initial_head_oid" \
      "$initial_index_tree_oid"
  else
    printf \
      '{"status":"ACCEPTED_STAGED_NON_UI_SCOPE","scope_status":"%s","commit_gate_only":true,"ui_pass_claimed":false,"local_completion_credit":false,"release_credit":false,"head_oid":"%s","index_tree_oid":"%s"}\n' \
      "$initial_scope_status" \
      "$initial_head_oid" \
      "$initial_index_tree_oid"
    staged_non_ui_accepted=1
  fi
}

run_full() {
  run_shell_contracts
  run_commander_game_changer_source
  run_mcp_preflight
  run_secret_scan
  run_guardrail_audits
  run_release_contracts
  run_full_quality
  run_schema_gate
}

case "$MODE" in
  quick)
    run_quick
    ;;
  schema)
    run_shell_contracts
    run_commander_game_changer_source
    run_project_logic
    run_schema_gate
    ;;
  full)
    run_full
    ;;
  e2e)
    run_full
    run_strict_e2e_gate
    ;;
  release)
    run_full
    run_battle_gate
    "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
    ;;
  *)
    echo "uso: $0 quick [--staged-scope]|schema|full|e2e|release" >&2
    exit 2
    ;;
esac

if [[ "$MODE" == "quick" && "$STAGED_SCOPE" == "1" ]] && \
  [[ "${staged_non_ui_accepted:-0}" == "1" ]]; then
  exit 0
fi

printf '\nPASS: gate local gratuito concluído (%s); nenhum GitHub Actions usado.\n' "$MODE"

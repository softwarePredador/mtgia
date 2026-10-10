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

# BT-GATE-001/002: cada etapa nomeada roda por run_named_step, que grava log,
# classifica o resultado (PASS, PARTIAL, BLOCKED ou FAIL) e, fora do escopo
# staged do pre-commit, o estado-fonte ao fim da etapa. O fim do gate fecha o
# receipt forte (manaloom_gate_run_receipt.py) em ~/.manaloom/receipts.
RECEIPT_TOOL="$ROOT_DIR/scripts/manaloom_gate_run_receipt.py"
SKIP_INVENTORY_TOOL="$ROOT_DIR/scripts/manaloom_gate_skip_inventory.py"
SKIP_ALLOWLIST="${MANALOOM_GATE_SKIP_ALLOWLIST:-$ROOT_DIR/server/config/gate_skip_allowlist.json}"
RECEIPT_ROOT="${MANALOOM_GATE_RECEIPT_ROOT:-$HOME/.manaloom/receipts}"
STEPS_FILE="$RUN_DIR/steps.tsv"
STEP_LOG_DIR="$RUN_DIR/step-logs"
STEP_SOURCE_DIR="$RUN_DIR/step-sources"
SOURCE_START_FILE="$RUN_DIR/source-start.json"
RECEIPT_RESULT_FILE="$RUN_DIR/receipt-result.json"
RUN_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_ID="local_ci_${MODE}_$(date -u +%Y%m%dT%H%M%SZ)_$$"
STEP_COUNTER=0
PARTIAL_STEPS=()
RECEIPT_ENABLED=1
if [[ "$MODE" == "quick" && "$STAGED_SCOPE" == "1" ]]; then
  # O quick do pre-commit é aceite de commit, sem crédito local: sem receipt.
  RECEIPT_ENABLED=0
fi
mkdir -p "$STEP_LOG_DIR" "$STEP_SOURCE_DIR"
: >"$STEPS_FILE"

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

capture_source_state_to() {
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$RECEIPT_TOOL" capture --repo "$ROOT_DIR" --out "$1"
}

finalize_receipt() {
  # $1 = PASS|PARTIAL|FAIL|BLOCKED. Escreve o status final do receipt em
  # RECEIPT_FINAL_STATUS. O receipt só diz PASS se todos os passos do catálogo
  # do modo passaram no mesmo SHA, tree e digest do início.
  local requested_status="$1"
  RECEIPT_FINAL_STATUS="$requested_status"
  if [[ "$RECEIPT_ENABLED" != "1" ]]; then
    return 0
  fi
  local finalize_rc=0
  PYTHONDONTWRITEBYTECODE=1 python3 "$RECEIPT_TOOL" finalize \
    --repo "$ROOT_DIR" \
    --gate local_ci \
    --mode "$MODE" \
    --run-id "$RUN_ID" \
    --started-at "$RUN_STARTED_AT" \
    --source-start "$SOURCE_START_FILE" \
    --steps "$STEPS_FILE" \
    --steps-format local-ci-v2 \
    --status "$requested_status" \
    --receipt-root "$RECEIPT_ROOT" >"$RECEIPT_RESULT_FILE" || finalize_rc=$?
  if [[ ! -s "$RECEIPT_RESULT_FILE" ]]; then
    echo "FAIL: receipt do gate não foi gravado" >&2
    RECEIPT_FINAL_STATUS="FAIL"
    return 0
  fi
  RECEIPT_FINAL_STATUS="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status"])' "$RECEIPT_RESULT_FILE")"
  printf 'Receipt (%s): %s\n' "$RECEIPT_FINAL_STATUS" \
    "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["receipt"])' "$RECEIPT_RESULT_FILE")"
  if [[ "$finalize_rc" -ne 0 ]]; then
    echo "FAIL: estado-fonte mudou durante o gate" >&2
  fi
}

run_named_step() {
  # Uso: run_named_step <id-do-catalogo> <comando...>
  # Etapa roda em subshell com errexit próprio; o log vai para arquivo e para o
  # terminal. Resultado: PASS (0), PARTIAL (3), BLOCKED (2) ou FAIL (demais).
  # PARTIAL é inventariado e o gate segue; BLOCKED e FAIL encerram o gate.
  local step_id="$1"
  shift
  local step_rc=0 scan_rc=0 step_status="PASS" log_file source_file
  STEP_COUNTER=$((STEP_COUNTER + 1))
  log_file="$STEP_LOG_DIR/$(printf '%02d' "$STEP_COUNTER")-$step_id.log"
  source_file="$STEP_SOURCE_DIR/$(printf '%02d' "$STEP_COUNTER")-$step_id.json"

  set +e
  ( set -euo pipefail; "$@" ) 2>&1 | tee "$log_file"
  step_rc="${PIPESTATUS[0]}"
  set -e

  if [[ "$step_rc" -eq 0 ]]; then
    PYTHONDONTWRITEBYTECODE=1 python3 "$SKIP_INVENTORY_TOOL" scan-log \
      --log "$log_file" --allowlist "$SKIP_ALLOWLIST" || scan_rc=$?
    case "$scan_rc" in
      0) ;;
      3) step_rc=3 ;;
      *) step_rc=2 ;;
    esac
  fi
  case "$step_rc" in
    0) step_status="PASS" ;;
    3) step_status="PARTIAL" ;;
    2) step_status="BLOCKED" ;;
    *) step_status="FAIL" ;;
  esac

  if [[ "$RECEIPT_ENABLED" == "1" ]]; then
    if ! capture_source_state_to "$source_file"; then
      echo "BLOCKED: estado-fonte da etapa $step_id não pôde ser capturado" >&2
      step_status="BLOCKED"
      step_rc=2
      : >"$source_file"
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$step_id" "$step_status" "$step_rc" "$log_file" "$source_file" >>"$STEPS_FILE"
  fi

  case "$step_status" in
    PASS)
      return 0
      ;;
    PARTIAL)
      echo "PARTIAL: etapa $step_id tem skip fora da allowlist; sem crédito de PASS." >&2
      PARTIAL_STEPS+=("$step_id")
      return 0
      ;;
    BLOCKED)
      echo "BLOCKED: etapa $step_id (exit $step_rc)" >&2
      ;;
    *)
      echo "FAIL: etapa $step_id (exit $step_rc)" >&2
      ;;
  esac
  finalize_receipt "$step_status"
  exit "$step_rc"
}

finish_gate() {
  # Fim do gate: PARTIAL nunca vira sucesso (exit 3); PASS exige receipt PASS.
  local gate_status="PASS"
  if [[ "${#PARTIAL_STEPS[@]}" -gt 0 ]]; then
    gate_status="PARTIAL"
  fi
  finalize_receipt "$gate_status"
  if [[ "$RECEIPT_FINAL_STATUS" == "FAIL" ]]; then
    exit 1
  fi
  if [[ "$gate_status" == "PARTIAL" ]]; then
    printf '\nPARTIAL: gate local (%s) incompleto; etapas com skip: %s. Sem crédito de PASS.\n' \
      "$MODE" "${PARTIAL_STEPS[*]}" >&2
    exit 3
  fi
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
  # BT-GATE-001/002: contratos rápidos de skip estrito e de receipt forte.
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/server/test/gate_skip_inventory_test.py"
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/server/test/gate_run_receipt_test.py"
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

  # BT-GATE-001/002/003: o local_ci estrito de ponta a ponta (dublês) e a mutação
  # que remove cada propagação e exige o teste vermelho. Só no full: são lentos.
  # O produtor do receipt de release roda só contra PostgreSQL descartável em
  # loopback (nunca produção): ele própria sobe e remove o cluster em /tmp.
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/server/test/deck_ai_learning_release_producer_loopback_test.py"
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/server/test/local_ci_strict_gate_test.py"
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$ROOT_DIR/server/test/local_ci_strict_gate_mutation_test.py"
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

run_deck_ai_learning_gate() {
  print_header "Deckbuilder / IA / Learning (cada fatia roda uma vez por SHA)"
  # BT-GATE-003: o gate Deck/IA/Learning entra no full e no release. O full
  # roda o perfil local (PASS_CODE_ONLY). O release exige o receipt do PostgreSQL
  # de produção lido em modo somente leitura; sem ele o gate retorna BLOCKED (2).
  # MANALOOM_GATE_REUSE_STEPS aponta para o ledger deste local_ci: as fatias que
  # ele já provou no mesmo SHA/tree/digest (drift de project logic e auditoria de
  # superfície operacional) são reaproveitadas, não rodadas de novo.
  local profile="local"
  if [[ "$MODE" == "release" ]]; then
    profile="release-read-only"
  fi
  MANALOOM_GATE_REUSE_STEPS="$STEPS_FILE" \
    "$ROOT_DIR/scripts/quality_gate.sh" deck-ai-learning "$profile"
}

require_release_pg_receipt() {
  # Falha cedo, antes de horas de gate: o release não existe sem o receipt do PG
  # de produção (somente leitura). Este script nunca lê credencial nem abre rede.
  if [[ -z "${MANALOOM_DECK_AI_RELEASE_RECEIPT:-}" || ! -r "${MANALOOM_DECK_AI_RELEASE_RECEIPT:-}" ]]; then
    echo "BLOCKED: release exige MANALOOM_DECK_AI_RELEASE_RECEIPT (receipt v2 do PG de produção, somente leitura)" >&2
    exit 2
  fi
  if [[ -z "${MANALOOM_NEW_SERVER_ENV:-}" || ! -r "${MANALOOM_NEW_SERVER_ENV:-}" ]]; then
    echo "BLOCKED: release exige MANALOOM_NEW_SERVER_ENV legível para validar o alvo do receipt" >&2
    exit 2
  fi
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
  run_named_step shell-contracts run_shell_contracts
  run_named_step commander-game-changer-source run_commander_game_changer_source
  run_named_step dart-mcp-preflight run_mcp_preflight
  run_named_step secret-scan run_secret_scan
  run_named_step project-logic run_project_logic
  if [[ "$STAGED_SCOPE" != "1" ]]; then
    run_named_step ui-live-evidence run_ui_live_evidence
    return 0
  fi

  if [[ "$initial_scope_status" == "AFFECTS_UI" ]]; then
    print_header "Escopo UI do índice staged"
    run_named_step ui-live-evidence run_ui_live_evidence
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
  run_named_step shell-contracts run_shell_contracts
  run_named_step commander-game-changer-source run_commander_game_changer_source
  run_named_step dart-mcp-preflight run_mcp_preflight
  run_named_step secret-scan run_secret_scan
  run_named_step guardrail-audits run_guardrail_audits
  run_named_step release-contracts run_release_contracts
  run_named_step full-quality run_full_quality
  run_named_step deck-ai-learning run_deck_ai_learning_gate
  run_named_step schema-gate run_schema_gate
}

if [[ "$RECEIPT_ENABLED" == "1" ]] && \
  ! capture_source_state_to "$SOURCE_START_FILE"; then
  echo "BLOCKED: estado-fonte inicial não pôde ser capturado; sem receipt não há gate" >&2
  exit 2
fi

case "$MODE" in
  quick)
    run_quick
    ;;
  schema)
    run_named_step shell-contracts run_shell_contracts
    run_named_step commander-game-changer-source run_commander_game_changer_source
    run_named_step project-logic run_project_logic
    run_named_step schema-gate run_schema_gate
    ;;
  full)
    run_full
    ;;
  e2e)
    run_full
    run_named_step strict-e2e run_strict_e2e_gate
    ;;
  release)
    require_release_pg_receipt
    run_full
    run_named_step battle-gate run_battle_gate
    run_named_step android-release-build "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
    ;;
  *)
    echo "uso: $0 quick [--staged-scope]|schema|full|e2e|release" >&2
    exit 2
    ;;
esac

finish_gate

if [[ "$MODE" == "quick" && "$STAGED_SCOPE" == "1" ]] && \
  [[ "${staged_non_ui_accepted:-0}" == "1" ]]; then
  exit 0
fi

printf '\nPASS: gate local gratuito concluído (%s); nenhum GitHub Actions usado.\n' "$MODE"

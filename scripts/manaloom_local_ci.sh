#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:-quick}"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"

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
    "$ROOT_DIR/scripts/manaloom_tbls_local_gate.sh" \
    "$ROOT_DIR/scripts/manaloom_install_local_hooks.sh" \
    "$ROOT_DIR/.githooks/pre-commit" \
    "$ROOT_DIR/.githooks/pre-push"
  "$ROOT_DIR/scripts/manaloom_install_local_hooks.sh" --check
}

run_mcp_preflight() {
  print_header "Dart/Flutter MCP local"
  "$ROOT_DIR/scripts/manaloom_dart_mcp_preflight.sh" --check
}

run_project_logic() {
  print_header "Manifesto, análise semântica e drift"
  "$ROOT_DIR/scripts/manaloom_project_logic.sh" --check
  (
    cd "$ROOT_DIR/tools/project_logic"
    "$DART_BIN" test
  )
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
    "$scripts_dir/report_retention_audit.py"
  (
    cd "$scripts_dir"
    python3 -m unittest \
      test_external_card_rule_reference_harvester.py \
      test_external_engine_upstream_delta_audit.py \
      test_legacy_contamination_audit.py \
      test_operational_surface_alignment_audit.py \
      test_report_retention_audit.py
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
  "$ROOT_DIR/scripts/quality_gate.sh" battle
}

run_quick() {
  run_shell_contracts
  run_mcp_preflight
  run_secret_scan
  run_project_logic
}

run_full() {
  run_shell_contracts
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
    run_project_logic
    run_schema_gate
    ;;
  full)
    run_full
    ;;
  e2e)
    run_full
    "$ROOT_DIR/scripts/quality_gate.sh" e2e
    ;;
  release)
    run_full
    run_battle_gate
    "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
    ;;
  *)
    echo "uso: $0 quick|schema|full|e2e|release" >&2
    exit 2
    ;;
esac

printf '\nPASS: gate local gratuito concluído (%s); nenhum GitHub Actions usado.\n' "$MODE"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-quick}"
FLUTTER_TEST_TIMEOUT_SECONDS="${FLUTTER_TEST_TIMEOUT_SECONDS:-1200}"
BACKEND_TEST_JWT_SECRET="${JWT_SECRET:-local_quality_gate_jwt_secret_not_for_production_20260706}"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

if [[ -n "${MANALOOM_FLUTTER_BIN:-}" ]]; then
  FLUTTER_BIN="$MANALOOM_FLUTTER_BIN"
elif [[ -x "$PINNED_FLUTTER" ]]; then
  FLUTTER_BIN="$PINNED_FLUTTER"
else
  FLUTTER_BIN="$(command -v flutter 2>/dev/null || true)"
fi

if [[ -z "$FLUTTER_BIN" || ! -x "$FLUTTER_BIN" ]]; then
  echo "❌ Flutter configurado não é executável: $FLUTTER_BIN" >&2
  exit 2
fi
if [[ "$FLUTTER_BIN" == */* ]]; then
  FLUTTER_BIN="$(cd "$(dirname "$FLUTTER_BIN")" && pwd)/$(basename "$FLUTTER_BIN")"
fi
readonly FLUTTER_BIN

# Nested gates inherit the same Dart and Flutter SDKs selected above.
flutter_bin_dir="$(dirname "$FLUTTER_BIN")"
export MANALOOM_DART_BIN="$DART_BIN"
export PATH="$(dirname "$DART_BIN"):$flutter_bin_dir:$PATH"

trap 'echo "❌ Quality gate interrompido." >&2; exit 130' INT
trap 'echo "❌ Quality gate encerrado." >&2; exit 143' TERM

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

run_backend_quick() {
  print_header "Backend quick checks"
  cd "$ROOT_DIR/server"
  RUN_INTEGRATION_TESTS=0 JWT_SECRET="$BACKEND_TEST_JWT_SECRET" dart test
}

run_backend_full() {
  print_header "Backend full checks"
  cd "$ROOT_DIR/server"
  echo "ℹ️ Perfil determinístico: tags live/live_backend/live_db_write/live_external ficam excluídas."
  RUN_INTEGRATION_TESTS=0 JWT_SECRET="$BACKEND_TEST_JWT_SECRET" dart test -P all-local
}

run_frontend_quick() {
  print_header "Frontend quick checks"
  cd "$ROOT_DIR/app"
  "$FLUTTER_BIN" analyze --no-pub --no-fatal-infos
}

run_flutter_tests_with_proof() {
  if [[ ! "$FLUTTER_TEST_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
    echo "❌ FLUTTER_TEST_TIMEOUT_SECONDS deve ser um inteiro positivo."
    return 2
  fi

  local output_file status tee_status
  output_file="$(mktemp)"
  set +e
  perl -e 'alarm shift; exec @ARGV' \
    "$FLUTTER_TEST_TIMEOUT_SECONDS" \
    "$FLUTTER_BIN" test --no-pub --no-version-check --reporter compact --timeout 2m \
    2>&1 | tee "$output_file"
  local pipeline_status=("${PIPESTATUS[@]}")
  status="${pipeline_status[0]}"
  tee_status="${pipeline_status[1]}"
  set -e
  if [[ "$status" -eq 0 && "$tee_status" -ne 0 ]]; then
    status="$tee_status"
  fi

  if [[ "$status" -ne 0 ]]; then
    echo "❌ Flutter tests falharam ou excederam ${FLUTTER_TEST_TIMEOUT_SECONDS}s."
    rm -f "$output_file"
    return "$status"
  fi
  # Flutter prints "All other tests passed!" when the suite succeeds with one
  # or more declared skips. Keep the process exit status as the primary gate
  # and accept both official success summaries as the explicit proof.
  if ! grep -Eq "All (other )?tests passed!" "$output_file"; then
    echo "❌ Flutter tests terminaram sem prova explícita de conclusão."
    rm -f "$output_file"
    return 1
  fi
  rm -f "$output_file"
}

run_frontend_full() {
  print_header "Frontend full checks"
  cd "$ROOT_DIR/app"
  "$FLUTTER_BIN" analyze --no-pub --no-fatal-infos
  run_flutter_tests_with_proof
}

run_public_web_full() {
  print_header "Public web full checks"
  "$ROOT_DIR/scripts/manaloom_public_web_smoke.sh"
}

run_runtime_performance_contract() {
  print_header "ManaLoom runtime performance harness contract"
  python3 -m py_compile \
    "$ROOT_DIR/app/tool/measure_runtime_startup.py" \
    "$ROOT_DIR/app/tool/test_measure_runtime_startup.py"
  (
    cd "$ROOT_DIR/app/tool"
    python3 -m unittest -v test_measure_runtime_startup.py 2>&1
  )
}

run_ui_audit() {
  print_header "ManaLoom Flutter UI audit"
  cd "$ROOT_DIR/app"
  "$FLUTTER_BIN" analyze lib test --no-pub --no-version-check --no-fatal-infos
  "$FLUTTER_BIN" test test/ui \
    test/core/widgets/debug_accessibility_tools_test.dart \
    test/features/home/onboarding_core_flow_screen_test.dart \
    --no-pub --no-version-check
}

run_dependency_audit() {
  print_header "ManaLoom dependency audit"
  "$ROOT_DIR/scripts/manaloom_dependency_audit.sh"
}

run_custom_lint() {
  print_header "ManaLoom custom lint"
  "$ROOT_DIR/scripts/manaloom_custom_lint.sh"
}

run_patrol_smoke() {
  print_header "ManaLoom Patrol critical E2E"
  "$ROOT_DIR/scripts/manaloom_patrol_smoke.sh"
}

run_resolution_corpus() {
  print_header "Resolution corpus gate"
  "$ROOT_DIR/scripts/quality_gate_resolution_corpus.sh"
}

run_ai_prompt_eval() {
  print_header "Commander AI prompt eval"
  "$ROOT_DIR/scripts/manaloom_ai_prompt_eval.sh"
}

run_app_ai_bridge() {
  run_old_server_reference_audit
  print_header "App AI knowledge bridge audit"
  "$ROOT_DIR/scripts/manaloom_app_ai_bridge_audit.sh"
  run_ai_prompt_eval
}

run_old_server_reference_audit() {
  print_header "ManaLoom server target audit"
  "$ROOT_DIR/scripts/manaloom_old_server_reference_audit.sh"
}

run_report_retention_audit() {
  print_header "ManaLoom report retention audit"
  "$ROOT_DIR/scripts/manaloom_report_retention_audit.sh"
}

run_pg_hermes_sqlite_contract_audit() {
  print_header "ManaLoom PostgreSQL/Hermes/SQLite contract audit"
  "$ROOT_DIR/scripts/manaloom_pg_hermes_sqlite_contract_audit.sh"
}

run_deep_ai_alignment() {
  print_header "ManaLoom deep AI alignment tester"
  "$ROOT_DIR/scripts/manaloom_deep_ai_alignment_tester.sh"
}

run_battle_product_gate() {
  print_header "ManaLoom canonical battle product gate"
  "$ROOT_DIR/scripts/manaloom_battle_product_gate.sh"
}

run_external_engine_delta_audit() {
  print_header "ManaLoom XMage/Forge upstream delta audit (read-only)"
  "$ROOT_DIR/scripts/manaloom_external_engine_delta_audit.sh"
}

run_external_engine_capability_audit() {
  print_header "ManaLoom XMage/Forge capability alignment audit"
  "$ROOT_DIR/scripts/manaloom_external_engine_capability_audit.sh"
}

run_project_logic_docs() {
  print_header "ManaLoom generated project logic and documentation drift"
  "$ROOT_DIR/scripts/manaloom_project_logic.sh" --check
  cd "$ROOT_DIR/tools/project_logic"
  "$DART_BIN" test
  "$ROOT_DIR/scripts/manaloom_dart_doc.sh" --check
}

run_e2e_suite() {
  print_header "ManaLoom E2E suite"
  "$ROOT_DIR/scripts/manaloom_e2e_suite.sh"
}

ensure_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ Comando não encontrado: $1"
    exit 1
  fi
}

ensure_prerequisites() {
  ensure_cmd "$DART_BIN"
  ensure_cmd "$FLUTTER_BIN"
  ensure_cmd perl
  ensure_cmd python3
}

print_usage() {
  cat <<EOF
Uso:
  ./scripts/quality_gate.sh quick   # validação rápida (dart test + flutter analyze)
  ./scripts/quality_gate.sh full    # validação completa (dart test + flutter analyze + flutter test)
  ./scripts/quality_gate.sh performance # contrato determinístico do harness p50/p95
  ./scripts/quality_gate.sh resolution # gate recorrente do corpus de resolução
  ./scripts/quality_gate.sh ui-audit # golden/accessibility audit das telas críticas Flutter
  ./scripts/quality_gate.sh web # lint, build, dependency audit e smoke HTTP do site público
  ./scripts/quality_gate.sh deps # valida dependências declaradas no app/server
  ./scripts/quality_gate.sh custom-lint # roda regras customizadas ManaLoom no app/server
  ./scripts/quality_gate.sh patrol-smoke # valida fluxos E2E criticos do Patrol
  ./scripts/quality_gate.sh ai-eval # eval fixa de prompt/saída da IA Commander
  ./scripts/quality_gate.sh ai-bridge # ponte app/IA: auditoria + eval Commander
  ./scripts/quality_gate.sh server-target # bloqueia referencias ativas ao servidor antigo
  ./scripts/quality_gate.sh report-retention # bloqueia dados brutos/locais sem uso em reports
  ./scripts/quality_gate.sh pg-contract # valida PG/Hermes/SQLite pelo wrapper do servidor novo
  ./scripts/quality_gate.sh deep-ai # tester profundo IA + dados + battle/deckbuilder
  ./scripts/quality_gate.sh battle # gate canônico battle: native, Forge, XMage, Python e Dart
  ./scripts/quality_gate.sh engine-capabilities # uso, limites e evidencias XMage/Forge
  ./scripts/quality_gate.sh engine-delta # auditoria manual/read-only dos pins contra upstream oficial
  ./scripts/quality_gate.sh project-logic # manifesto, Mermaid, OpenAPI, ERD e drift documental
  ./scripts/quality_gate.sh e2e # suite E2E local: app, deckbuilder, battle, IA, contratos e logs

Dica:
  Use 'quick' durante implementação e 'full' antes de concluir item/sprint.
  O modo 'full' é determinístico e exclui tags live/live_backend/live_db_write/live_external.
  O modo 'performance' valida o harness e seus orçamentos sem exigir browser,
  device, fixture autenticada ou executar uma medição runtime.
  Use o perfil E2E live guardado para chamadas contra uma API real.
  Use 'resolution' para validar o corpus estável Commander fim a fim.
  Use 'ui-audit' depois de mexer em visual, paywall, login, home ou shell do app.
  Use 'deps' depois de adicionar/remover pacote no app ou backend.
  Use 'custom-lint' para bloquear regressões específicas do ManaLoom em Dart.
  Use 'patrol-smoke' para validar login, cadastro, paywall, planos, legal, upgrade e checkout no Patrol; exporte MANALOOM_RUN_PATROL_DEVICE_TESTS=1 para rodar no device/emulador.
  Use 'battle' para validar o contrato do produto battle sem chamar serviços live nem escrever em PostgreSQL/SQLite.
  Use 'engine-capabilities' para bloquear drift de papeis, pins, licencas, imports e evidencias XMage/Forge.
  Use 'engine-delta' para consultar explicitamente o GitHub oficial e gerar JSON de revisão; nunca avança pins nem executa deploy/promoção.
  Use 'project-logic' para bloquear drift entre código, rotas, migrations, manifesto e documentação gerada.
  Use 'e2e' para varredura completa local de deckbuilder, battle, IA, logs e contratos; exporte MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1 ou MANALOOM_RUN_LIVE_PRODUCT_E2E=1 para camadas vivas opcionais.

Exemplos:
  ./scripts/quality_gate.sh full
  ./scripts/quality_gate.sh performance
  ./scripts/quality_gate.sh resolution
  ./scripts/quality_gate.sh ui-audit
  ./scripts/quality_gate.sh web
  ./scripts/quality_gate.sh deps
  ./scripts/quality_gate.sh custom-lint
  ./scripts/quality_gate.sh patrol-smoke
  ./scripts/quality_gate.sh ai-eval
  ./scripts/quality_gate.sh ai-bridge
  ./scripts/quality_gate.sh server-target
  ./scripts/quality_gate.sh report-retention
  ./scripts/quality_gate.sh pg-contract
  ./scripts/quality_gate.sh deep-ai
  ./scripts/quality_gate.sh battle
  ./scripts/quality_gate.sh engine-capabilities
  ./scripts/quality_gate.sh engine-delta
  ./scripts/quality_gate.sh project-logic
  ./scripts/quality_gate.sh e2e
EOF
}

main() {
  ensure_prerequisites

  case "$MODE" in
    quick)
      run_backend_quick
      run_frontend_quick
      ;;
    full)
      run_backend_full
      run_frontend_full
      run_public_web_full
      run_runtime_performance_contract
      ;;
    performance)
      run_runtime_performance_contract
      ;;
    resolution)
      run_resolution_corpus
      ;;
    ui-audit)
      run_ui_audit
      ;;
    web)
      run_public_web_full
      ;;
    deps)
      run_dependency_audit
      ;;
    custom-lint)
      run_custom_lint
      ;;
    patrol-smoke)
      run_patrol_smoke
      ;;
    ai-eval)
      run_ai_prompt_eval
      ;;
    ai-bridge)
      run_app_ai_bridge
      ;;
    server-target)
      run_old_server_reference_audit
      ;;
    report-retention)
      run_report_retention_audit
      ;;
    pg-contract)
      run_pg_hermes_sqlite_contract_audit
      ;;
    deep-ai)
      run_deep_ai_alignment
      ;;
    battle)
      run_battle_product_gate
      ;;
    engine-capabilities)
      run_external_engine_capability_audit
      ;;
    engine-delta)
      run_external_engine_delta_audit
      ;;
    project-logic)
      run_project_logic_docs
      ;;
    e2e)
      run_e2e_suite
      ;;
    -h|--help|help)
      print_usage
      exit 0
      ;;
    *)
      echo "❌ Modo inválido: $MODE"
      print_usage
      exit 1
      ;;
  esac

  print_header "Quality gate concluído"
  echo "✅ Todos os checks do modo '$MODE' passaram."
}

main "$@"

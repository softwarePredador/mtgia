#!/usr/bin/env bash
# BT-GATE-007: os integration_test do app entram no gate, cada um na sua trilha.
#
# O manifesto `server/config/integration_test_lanes.json` põe cada arquivo de
# `app/integration_test/*_test.dart` em exatamente uma trilha. Arquivo novo sem
# trilha, ou trilha apontando para arquivo que sumiu, reprova antes de rodar.
#
# Esta etapa roda a trilha `web_hermetic` no Chrome real (flutter drive em
# web-server). A API fica presa num loopback fechado: sem API_BASE_URL o
# ApiClient cai no host de produção, e um teste que registra conta escreveria
# no banco live. Por isso o define é sempre passado e nunca vem do ambiente.
#
# As outras trilhas não rodam aqui e o resumo diz por quê:
# - `web_backend` precisa de API + PostgreSQL descartáveis em loopback;
# - `device` precisa de Android físico/iOS;
# - `ui_proof` pertence à prova de UI (BT-UIEV-001) e roda nos scripts dela.
#
# Uso:
#   scripts/manaloom_integration_lane_gate.sh            # checa e roda web_hermetic
#   scripts/manaloom_integration_lane_gate.sh --check    # só confere o manifesto
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LANES_TOOL="$ROOT_DIR/scripts/manaloom_integration_lanes.py"
MODE="${1:-run}"
LANE="web_hermetic"
# Porta 9 (discard) em loopback: nada escuta, a conexão é recusada na hora.
LOOPBACK_API_BASE_URL="http://127.0.0.1:9"
PER_TEST_TIMEOUT_SECONDS="${MANALOOM_INTEGRATION_TEST_TIMEOUT_SECONDS:-600}"
DRIVER_PORT="${MANALOOM_INTEGRATION_DRIVER_PORT:-4444}"
CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

case "$MODE" in
  --check)
    exec python3 "$LANES_TOOL" check --repo "$ROOT_DIR"
    ;;
  run | --run) ;;
  *)
    echo "uso: $0 [--check]" >&2
    exit 2
    ;;
esac

python3 "$LANES_TOOL" check --repo "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
source "$ROOT_DIR/scripts/lib/manaloom_chromedriver.sh"
resolve_manaloom_flutter_dart_pair
FLUTTER_BIN="$MANALOOM_FLUTTER_BIN_RESOLVED"
if [[ ! -x "$CHROME_EXECUTABLE" ]]; then
  echo "BLOCKED: Chrome nao executa: $CHROME_EXECUTABLE (defina CHROME_EXECUTABLE)." >&2
  exit 2
fi
resolve_manaloom_chromedriver
assert_manaloom_chromedriver_matches_chrome "$CHROME_EXECUTABLE"
export CHROME_EXECUTABLE

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-integration-lanes.XXXXXX")"
SUMMARY="$RUN_DIR/summary.tsv"
printf 'status\tseconds\tpath\tlog\n' >"$SUMMARY"

DRIVER_PID=""
cleanup() {
  if [[ -n "$DRIVER_PID" ]]; then
    kill "$DRIVER_PID" 2>/dev/null || true
    wait "$DRIVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

"$MANALOOM_CHROMEDRIVER_BIN_RESOLVED" --port="$DRIVER_PORT" \
  >"$RUN_DIR/chromedriver.log" 2>&1 &
DRIVER_PID=$!
for _ in $(seq 1 50); do
  if (exec 3<>"/dev/tcp/127.0.0.1/$DRIVER_PORT") 2>/dev/null; then
    break
  fi
  sleep 0.2
done
if ! kill -0 "$DRIVER_PID" 2>/dev/null; then
  echo "ChromeDriver nao subiu na porta $DRIVER_PORT; veja $RUN_DIR/chromedriver.log" >&2
  exit 2
fi

mapfile -t TESTS < <(python3 "$LANES_TOOL" list --repo "$ROOT_DIR" --lane "$LANE")
if [[ "${#TESTS[@]}" -eq 0 ]]; then
  echo "A trilha $LANE nao tem testes; o gate nao aceita trilha vazia." >&2
  exit 1
fi

cd "$ROOT_DIR/app"
failures=0
for test_path in "${TESTS[@]}"; do
  name="$(basename "$test_path" .dart)"
  log="$RUN_DIR/$name.log"
  started="$(date +%s)"
  echo "▶ $test_path"
  set +e
  timeout "$PER_TEST_TIMEOUT_SECONDS" "$FLUTTER_BIN" drive \
    --driver=test_driver/integration_test.dart \
    --target="${test_path#app/}" \
    -d web-server --browser-name=chrome --driver-port="$DRIVER_PORT" \
    --no-web-resources-cdn --no-pub --no-version-check \
    --dart-define=API_BASE_URL="$LOOPBACK_API_BASE_URL" \
    --dart-define=DISABLE_FIREBASE_STARTUP=true \
    --dart-define=DISABLE_PUSH_INIT=true \
    --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
    >"$log" 2>&1
  rc=$?
  set -e
  elapsed=$(($(date +%s) - started))
  if [[ "$rc" -eq 0 ]] && grep -q 'All tests passed' "$log"; then
    status=PASS
  else
    status=FAIL
    failures=$((failures + 1))
  fi
  printf '%s\t%s\t%s\t%s\n' "$status" "$elapsed" "$test_path" "$log" >>"$SUMMARY"
  echo "  $status em ${elapsed}s"
done

echo ""
python3 "$LANES_TOOL" report --repo "$ROOT_DIR"
echo "Resumo: $SUMMARY"
if [[ "$failures" -gt 0 ]]; then
  echo "❌ $failures de ${#TESTS[@]} testes da trilha $LANE falharam." >&2
  exit 1
fi
echo "✅ ${#TESTS[@]} testes da trilha $LANE passaram no Chrome com API em loopback."

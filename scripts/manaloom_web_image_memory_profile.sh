#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
PINNED_FLUTTER="${MANALOOM_PINNED_FLUTTER:-$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter}"
FLUTTER_BIN="${MANALOOM_FLUTTER_BIN:-$PINNED_FLUTTER}"
CHROMEDRIVER_BIN="${MANALOOM_CHROMEDRIVER_BIN:-$(command -v chromedriver 2>/dev/null || true)}"
CHROME_BIN="${MANALOOM_CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
CHROMEDRIVER_PORT="${MANALOOM_CHROMEDRIVER_PORT:-9515}"
FIXTURE_PORT="${MANALOOM_IMAGE_FIXTURE_PORT:-8091}"
BUILD_MODE="${MANALOOM_IMAGE_MEMORY_BUILD_MODE:-release}"
OUTPUT_PATH="${MANALOOM_IMAGE_MEMORY_OUTPUT:-$ROOT_DIR/app/build/manaloom_web_image_memory.json}"
RUNTIME_DIR="$(mktemp -d /tmp/manaloom_web_image_memory.XXXXXX)"
CHROMEDRIVER_PID=""
FIXTURE_PID=""

cleanup() {
  local target_pid
  for target_pid in "$CHROMEDRIVER_PID" "$FIXTURE_PID"; do
    if [[ -n "$target_pid" ]] && kill -0 "$target_pid" 2>/dev/null; then
      kill "$target_pid" 2>/dev/null || true
      wait "$target_pid" 2>/dev/null || true
    fi
  done
  if [[ "$RUNTIME_DIR" == /tmp/manaloom_web_image_memory.* ]] &&
     [[ -d "$RUNTIME_DIR" ]]; then
    rm -r -- "$RUNTIME_DIR"
  fi
}
trap cleanup EXIT

fail() {
  echo "❌ $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Comando não encontrado: $1"
}

validate_port() {
  local name="$1"
  local value="$2"
  if [[ ! "$value" =~ ^[0-9]+$ ]] ||
     (( value < 1024 || value > 65535 )); then
    fail "$name deve ser uma porta entre 1024 e 65535."
  fi
  if lsof -nP -iTCP:"$value" -sTCP:LISTEN >/dev/null 2>&1; then
    fail "$name já está em uso: $value"
  fi
}

wait_for_url() {
  local url="$1"
  local label="$2"
  local attempts=0
  while (( attempts < 100 )); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 0.1
  done
  fail "$label não ficou pronto em $url"
}

[[ -x "$FLUTTER_BIN" ]] || fail "Flutter pinado não é executável: $FLUTTER_BIN"
[[ -n "$CHROMEDRIVER_BIN" && -x "$CHROMEDRIVER_BIN" ]] ||
  fail "ChromeDriver não encontrado; defina MANALOOM_CHROMEDRIVER_BIN."
[[ -x "$CHROME_BIN" ]] ||
  fail "Chrome não encontrado; defina MANALOOM_CHROME_BIN."

require_command curl
require_command jq
require_command lsof
require_command python3
validate_port MANALOOM_CHROMEDRIVER_PORT "$CHROMEDRIVER_PORT"
validate_port MANALOOM_IMAGE_FIXTURE_PORT "$FIXTURE_PORT"

case "$BUILD_MODE" in
  profile | release) ;;
  *) fail "MANALOOM_IMAGE_MEMORY_BUILD_MODE deve ser profile ou release." ;;
esac

chrome_major="$("$CHROME_BIN" --version | sed -E 's/^[^0-9]*([0-9]+).*/\1/')"
chromedriver_major="$("$CHROMEDRIVER_BIN" --version | awk '{print $2}' | cut -d. -f1)"
if [[ -z "$chrome_major" || -z "$chromedriver_major" ]]; then
  fail "Não foi possível identificar as versões de Chrome/ChromeDriver."
fi
if [[ "$chrome_major" != "$chromedriver_major" ]]; then
  fail "Chrome $chrome_major exige ChromeDriver do mesmo major; encontrado $chromedriver_major."
fi

python3 "$ROOT_DIR/app/tool/serve_image_memory_fixture.py" \
  --host 127.0.0.1 \
  --port "$FIXTURE_PORT" \
  >"$RUNTIME_DIR/fixture.log" 2>&1 &
FIXTURE_PID="$!"

"$CHROMEDRIVER_BIN" \
  --port="$CHROMEDRIVER_PORT" \
  --allowed-ips=127.0.0.1 \
  >"$RUNTIME_DIR/chromedriver.log" 2>&1 &
CHROMEDRIVER_PID="$!"

wait_for_url \
  "http://127.0.0.1:$FIXTURE_PORT/healthz" \
  "Fixture de imagem"
wait_for_url \
  "http://127.0.0.1:$CHROMEDRIVER_PORT/status" \
  "ChromeDriver"

mkdir -p "$(dirname "$OUTPUT_PATH")"
rm -f -- "$OUTPUT_PATH"

echo "Chrome: $("$CHROME_BIN" --version)"
echo "ChromeDriver: $("$CHROMEDRIVER_BIN" --version)"
echo "Fixture: http://127.0.0.1:$FIXTURE_PORT/assets/symbols/logo.png"
echo "Saída: $OUTPUT_PATH"

(
  cd "$ROOT_DIR/app"
  MANALOOM_IMAGE_MEMORY_OUTPUT="$OUTPUT_PATH" \
  MANALOOM_IMAGE_FIXTURE_STATS_URL="http://127.0.0.1:$FIXTURE_PORT/stats" \
    "$FLUTTER_BIN" drive \
      --"$BUILD_MODE" \
      --no-pub \
      --device-id=chrome \
      --browser-name=chrome \
      --driver-port="$CHROMEDRIVER_PORT" \
      --headless \
      --browser-dimension=1440x900 \
      --chrome-binary="$CHROME_BIN" \
      --timeout=300 \
      --driver=test_driver/image_memory_cdp_test.dart \
      --target=integration_test/image_memory_runtime_test.dart \
      --dart-define=MANALOOM_ENABLE_WEB_CDP_IMAGE_PROBE=true \
      --dart-define=MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true \
      --dart-define="MANALOOM_IMAGE_FIXTURE_BASE_URL=http://127.0.0.1:$FIXTURE_PORT"
)

jq -e '
  .flutter.image_memory.platform == "web" and
  .flutter.image_memory.metric_source ==
    "external_chrome_cdp_process_tree_and_resource_timing" and
  .web_cdp.schema_version == "manaloom_web_image_memory_v1" and
  .web_cdp.result == "pass"
' "$OUTPUT_PATH" >/dev/null ||
  fail "A evidência final não contém PASS explícito do Flutter + Chrome/CDP."

echo "✅ Perfil Web de memória/imagens aprovado: $OUTPUT_PATH"

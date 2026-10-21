#!/usr/bin/env bash
# Captura o fallback de carta sem arte, que era conduzido a mao.
#
# Ate 2026-09-24 `card-back-fallback-web`, `card-details-navigation-web` e
# `optimization-card-reader-web` nao tinham roteiro: os manifestos registram
# `runtime: in_app_browser` e `generated_at` em julho. Alguem dirigiu um
# navegador e recortou as capturas, o que nao e reproduzivel.
#
# Derivado de `manaloom_binder_import_visual_qa.sh`, que ja resolve o que e
# dificil: ChromeDriver pinado com major conferido contra o Chrome, servidor de
# assets com CORS, porta livre, limpeza em trap. A diferenca e o alvo, o perfil
# (1280x720 em vez de tres larguras) e a divisao em tres pacotes.
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"
PINNED_DART="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/cache/dart-sdk/bin/dart"
FLUTTER_BIN="${MANALOOM_FLUTTER_BIN:-$PINNED_FLUTTER}"
DART_BIN="${MANALOOM_DART_BIN:-$PINNED_DART}"
CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
source "$ROOT_DIR/scripts/lib/manaloom_chromedriver.sh"
resolve_manaloom_chromedriver || exit 2
CHROMEDRIVER_BIN="$MANALOOM_CHROMEDRIVER_BIN_RESOLVED"
RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_card_surfaces_visual.XXXXXX")"
CHROMEDRIVER_PID=""
ASSET_SERVER_PID=""

source "$ROOT_DIR/scripts/lib/manaloom_ui_runtime_contract.sh"

cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  if [[ -n "$CHROMEDRIVER_PID" ]]; then
    kill "$CHROMEDRIVER_PID" >/dev/null 2>&1 || true
    wait "$CHROMEDRIVER_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$ASSET_SERVER_PID" ]]; then
    kill "$ASSET_SERVER_PID" >/dev/null 2>&1 || true
    wait "$ASSET_SERVER_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$RUN_DIR"
  exit "$status"
}
trap cleanup EXIT INT TERM

for executable in "$FLUTTER_BIN" "$DART_BIN" "$CHROME_EXECUTABLE" "$CHROMEDRIVER_BIN"; do
  if [[ -z "$executable" || ! -x "$executable" ]]; then
    echo "Required executable is unavailable: $executable" >&2
    exit 2
  fi
done
for command_name in curl jq python3 sed; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "$command_name is required for Card surfaces visual QA" >&2
    exit 2
  }
done

browser_major="$("$CHROME_EXECUTABLE" --version | sed -E 's/^[^0-9]*([0-9]+).*/\1/')"
driver_major="$("$CHROMEDRIVER_BIN" --version | sed -E 's/^[^0-9]*([0-9]+).*/\1/')"
if [[ -z "$browser_major" || -z "$driver_major" || "$browser_major" != "$driver_major" ]]; then
  echo "ChromeDriver major $driver_major does not match Chrome major $browser_major" >&2
  exit 2
fi
if curl --silent --fail --max-time 1 http://127.0.0.1:4444/status >/dev/null 2>&1; then
  echo "WebDriver port 4444 is already in use" >&2
  exit 2
fi

ASSET_PORT="$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"
(
  cd "$ROOT_DIR"
  python3 "$ROOT_DIR/scripts/lib/manaloom_fixture_asset_server.py" "$ASSET_PORT" --bind 127.0.0.1 \
    >"$RUN_DIR/asset-server.log" 2>&1
) &
ASSET_SERVER_PID="$!"
for _ in {1..50}; do
  if curl --silent --fail --max-time 1 \
    "http://127.0.0.1:$ASSET_PORT/app/assets/branding/visual_fixture_arcane_ring.webp" \
    >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$ASSET_SERVER_PID" >/dev/null 2>&1; then
    echo "Local visual asset server stopped unexpectedly" >&2
    exit 1
  fi
  sleep 0.2
done

"$CHROMEDRIVER_BIN" --port=4444 >"$RUN_DIR/chromedriver.log" 2>&1 &
CHROMEDRIVER_PID="$!"
webdriver_ready="false"
for _ in {1..50}; do
  if curl --silent --fail --max-time 1 http://127.0.0.1:4444/status >/dev/null 2>&1; then
    webdriver_ready="true"
    break
  fi
  if ! kill -0 "$CHROMEDRIVER_PID" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done
if [[ "$webdriver_ready" != "true" ]]; then
  echo "ChromeDriver did not become ready; see $RUN_DIR/chromedriver.log" >&2
  exit 1
fi

SOURCE_DIGEST="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
RING_IMAGE_URL="http://127.0.0.1:$ASSET_PORT/app/assets/branding/visual_fixture_arcane_ring.webp"
STUDY_IMAGE_URL="http://127.0.0.1:$ASSET_PORT/app/assets/branding/visual_fixture_blue_spell.webp"

(
  cd "$ROOT_DIR/app"
  "$FLUTTER_BIN" analyze \
    lib/core/widgets/cached_card_image.dart \
    integration_test/card_surfaces_visual_runtime_proof_test.dart \
    test/core/widgets/cached_card_image_test.dart \
    test/ui/ui_live_evidence_policy_test.dart \
    --no-pub --no-version-check --no-fatal-infos
  "$FLUTTER_BIN" test \
    test/core/widgets/cached_card_image_test.dart \
    --no-pub --no-version-check --reporter compact
  "$FLUTTER_BIN" test \
    integration_test/card_surfaces_visual_runtime_proof_test.dart \
    -d flutter-tester \
    --dart-define=MANALOOM_CAPTURE_RUNTIME_PROOF=false \
    --no-pub --no-version-check --reporter compact
)

capture_profile() {
  local profile="$1"
  local width="$2"
  local height="$3"
  local screenshots="$RUN_DIR/$profile/screenshots"
  local runtime_log="$RUN_DIR/$profile/runtime.log"
  local device_contract drive_status

  mkdir -p "$screenshots"
  device_contract="$(manaloom_web_runtime_device_contract "$profile")"
  set +e
  (
    cd "$ROOT_DIR/app"
    MANALOOM_SCREENSHOT_DIR="$screenshots" "$FLUTTER_BIN" drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/card_surfaces_visual_runtime_proof_test.dart \
      --no-pub --no-version-check \
      --device-connection=attached \
      --timeout=600 \
      --release \
      -d chrome \
      --browser-dimension="${width}x${height}@1" \
      --no-web-resources-cdn \
      --dart-define=MANALOOM_CAPTURE_RUNTIME_PROOF=true \
      --dart-define=MANALOOM_UI_SOURCE_DIGEST="$SOURCE_DIGEST" \
      --dart-define=MANALOOM_UI_PROOF_PROFILE="$profile" \
      --dart-define=MANALOOM_UI_PROOF_TARGET=web_real_build \
      --dart-define=MANALOOM_UI_PROOF_DEVICE_CONTRACT="$device_contract" \
      --dart-define=MANALOOM_VISUAL_WIDTH="$width" \
      --dart-define=MANALOOM_VISUAL_HEIGHT="$height" \
      --dart-define=MANALOOM_VISUAL_RING_IMAGE_URL="$RING_IMAGE_URL" \
      --dart-define=MANALOOM_VISUAL_STUDY_IMAGE_URL="$STUDY_IMAGE_URL" \
      --dart-define=MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true \
      --dart-define=MANALOOM_EMIT_SCREENSHOT_CHUNKS=false \
      --dart-define=DISABLE_FIREBASE_STARTUP=true \
      --dart-define=DISABLE_PUSH_INIT=true \
      --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true
  ) 2>&1 | tee "$runtime_log"
  drive_status="${PIPESTATUS[0]}"
  set -e
  if [[ "$drive_status" -ne 0 ]]; then
    echo "Binder Import runtime proof failed for $profile" >&2
    return "$drive_status"
  fi
  sed '/VISUAL_PROOF_CONTEXT /d' "$runtime_log" >"$runtime_log.clean"
  mv "$runtime_log.clean" "$runtime_log"

  if grep -Eq '(^|[[:space:]])(EXCEPTION CAUGHT|Some tests failed|══╡ EXCEPTION)' "$runtime_log"; then
    echo "Card surfaces runtime log contains a forbidden failure" >&2
    return 1
  fi

  # Uma corrida, tres pacotes. A divisao vem dos manifestos que ja estao no
  # repositorio, nao de uma lista escrita aqui: se um pacote mudar de escopo,
  # este roteiro acompanha sozinho.
  local pacote destino manifesto staging superficie contexto
  for pacote in card-back-fallback-web; do
    destino="$ROOT_DIR/docs/qa/ui-live/current/$pacote"
    manifesto="$destino/capture-manifest.json"
    [[ -f "$manifesto" ]] || { echo "manifesto ausente: $manifesto" >&2; return 2; }

    mapfile -t exigidos < <(python3 - "$manifesto" <<'PY2'
import json, sys
d = json.load(open(sys.argv[1]))
req = d.get('required_checkpoints') or [s.get('name') for s in d.get('screenshots', [])]
for r in req:
    if r:
        print(r)
PY2
)
    (( ${#exigidos[@]} > 0 )) || { echo "manifesto sem checkpoints: $manifesto" >&2; return 2; }

    staging="$RUN_DIR/pack-$pacote"
    mkdir -p "$staging"
    local faltando=()
    for nome in "${exigidos[@]}"; do
      if [[ -f "$screenshots/$nome.png" ]]; then
        cp "$screenshots/$nome.png" "$staging/$nome.png"
      else
        faltando+=("$nome")
      fi
    done
    if (( ${#faltando[@]} > 0 )); then
      echo "$pacote: a corrida nao produziu ${faltando[*]}" >&2
      return 1
    fi

    (cd "$ROOT_DIR/app" && "$DART_BIN" run tool/ui_runtime_evidence.dart \
      validate-directory --screenshots "$staging")

    rm -f "$destino"/*.png
    cp "$staging"/*.png "$destino/"

    superficie="$(python3 - "$manifesto" <<'PY3'
import json, sys
print(json.load(open(sys.argv[1])).get('surface', ''))
PY3
)"
    # O contrato deste pacote nao menciona gesto nenhum -- so build Web real a
    # 1280x720 com a URL de imagem ausente --, entao ele e PRESERVADO como esta
    # no manifesto. Reescrever contrato para caber na corrida seria afrouxar a
    # promessa sem dizer.
    contexto="$(python3 - "$manifesto" <<'PY4'
import json, sys
print(json.load(open(sys.argv[1])).get('device_contract', ''))
PY4
)"
    printf 'VISUAL_PROOF_CONTEXT %s\n' "$(jq --compact-output --null-input \
      --arg source_digest "$SOURCE_DIGEST" \
      --arg profile "$profile" \
      --arg surface "$superficie" \
      --arg device_contract "$contexto" \
      --argjson checkpoints "$(printf '%s\n' "${exigidos[@]}" | jq -R . | jq -s .)" \
      '{schema_version:"manaloom_ui_runtime_context_v1",surface:$surface,source_digest:$source_digest,profile:$profile,runtime:"flutter_drive",target:"web_real_build",device_contract:$device_contract,required_checkpoints:$checkpoints}')" \
      >>"$runtime_log"

    (cd "$ROOT_DIR/app" && "$DART_BIN" run tool/ui_runtime_evidence.dart \
      index-directory \
      --repo-root "$ROOT_DIR" \
      --screenshots "docs/qa/ui-live/current/$pacote" \
      --log "$runtime_log" \
      --manifest "docs/qa/ui-live/current/$pacote/capture-manifest.json" \
      --source-digest "$SOURCE_DIGEST" \
      --surface "$superficie" \
      --profile "$profile" \
      --runtime flutter_drive \
      --target web_real_build \
      --device-contract "$contexto")
    echo "$pacote: ${#exigidos[@]} checkpoints indexados"
  done
}

capture_profile web_in_app_1280x720 1280 720

echo "card-back-fallback-web capturado sem conducao manual."
echo "card-details-navigation-web e optimization-card-reader-web NAO estao aqui:"
echo "os contratos deles exigem gesto real de navegador e ficam na fila do WebDriver."
echo "Abra a captura antes de registrar PASS_VISUAL_REVIEWED."

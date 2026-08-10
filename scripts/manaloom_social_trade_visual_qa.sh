#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"
PINNED_DART="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/cache/dart-sdk/bin/dart"
PINNED_CHROMEDRIVER="$HOME/Library/Caches/manaloom/chromedriver/150.0.7871.124-mac-arm64/unpacked/chromedriver-mac-arm64/chromedriver"
FLUTTER_BIN="${MANALOOM_FLUTTER_BIN:-$PINNED_FLUTTER}"
DART_BIN="${MANALOOM_DART_BIN:-$PINNED_DART}"
CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
if [[ -x "$PINNED_CHROMEDRIVER" ]]; then
  DEFAULT_CHROMEDRIVER="$PINNED_CHROMEDRIVER"
else
  DEFAULT_CHROMEDRIVER="$(command -v chromedriver 2>/dev/null || true)"
fi
CHROMEDRIVER_BIN="${MANALOOM_CHROMEDRIVER_BIN:-$DEFAULT_CHROMEDRIVER}"
RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_social_trade_visual.XXXXXX")"
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
    echo "$command_name is required for Social Trade visual QA" >&2
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
  python3 -m http.server "$ASSET_PORT" --bind 127.0.0.1 \
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
SPELL_IMAGE_URL="http://127.0.0.1:$ASSET_PORT/app/assets/branding/visual_fixture_blue_spell.webp"

(
  cd "$ROOT_DIR/app"
  "$FLUTTER_BIN" analyze \
    lib/features/binder/providers/binder_provider.dart \
    lib/features/binder/screens/marketplace_screen.dart \
    lib/features/community/providers/community_provider.dart \
    lib/features/community/screens/community_deck_detail_screen.dart \
    lib/features/messages/screens/message_inbox_screen.dart \
    lib/features/social/screens/user_search_screen.dart \
    lib/features/trades/providers/trade_provider.dart \
    lib/features/trades/screens/create_trade_screen.dart \
    lib/features/trades/screens/trade_detail_screen.dart \
    lib/features/trades/screens/trade_inbox_screen.dart \
    lib/features/trades/screens/trade_matches_screen.dart \
    lib/features/trades/trade_route_contract.dart \
    integration_test/social_trade_visual_runtime_proof_test.dart \
    test/ui/ui_live_evidence_policy_test.dart \
    --no-pub --no-version-check --no-fatal-infos
  "$FLUTTER_BIN" test \
    integration_test/social_trade_visual_runtime_proof_test.dart \
    -d flutter-tester \
    --dart-define=MANALOOM_CAPTURE_RUNTIME_PROOF=false \
    --no-pub --no-version-check --reporter compact
)

capture_profile() {
  local profile="$1"
  local width="$2"
  local height="$3"
  local output_name="$4"
  local screenshots="$RUN_DIR/$profile/screenshots"
  local runtime_log="$RUN_DIR/$profile/runtime.log"
  local output_dir="$ROOT_DIR/docs/qa/ui-live/current/$output_name"
  local previous_output="$RUN_DIR/$profile/previous-output"
  local device_contract context_json drive_status actual_count

  mkdir -p "$screenshots"
  device_contract="$(manaloom_web_runtime_device_contract "$profile")"
  set +e
  (
    cd "$ROOT_DIR/app"
    MANALOOM_SCREENSHOT_DIR="$screenshots" "$FLUTTER_BIN" drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/social_trade_visual_runtime_proof_test.dart \
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
      --dart-define=MANALOOM_VISUAL_SPELL_IMAGE_URL="$SPELL_IMAGE_URL" \
      --dart-define=MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true \
      --dart-define=MANALOOM_EMIT_SCREENSHOT_CHUNKS=false \
      --dart-define=DISABLE_FIREBASE_STARTUP=true \
      --dart-define=DISABLE_PUSH_INIT=true \
      --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true
  ) 2>&1 | tee "$runtime_log"
  drive_status="${PIPESTATUS[0]}"
  set -e
  if [[ "$drive_status" -ne 0 ]]; then
    echo "Social Trade runtime proof failed for $profile" >&2
    return "$drive_status"
  fi

  sed '/VISUAL_PROOF_CONTEXT /d' "$runtime_log" >"$runtime_log.clean"
  mv "$runtime_log.clean" "$runtime_log"
  context_json="$(
    jq --compact-output --null-input \
      --arg source_digest "$SOURCE_DIGEST" \
      --arg profile "$profile" \
      --arg device_contract "$device_contract" \
      '{
        schema_version: "manaloom_ui_runtime_context_v1",
        surface: "social_trade",
        source_digest: $source_digest,
        profile: $profile,
        runtime: "flutter_drive",
        target: "web_real_build",
        device_contract: $device_contract,
        required_checkpoints: [
          "social_trade_00_matches_populated",
          "social_trade_01_marketplace_populated",
          "social_trade_02_marketplace_empty",
          "social_trade_03_trade_create_rehydrated",
          "social_trade_04_trade_create_review",
          "social_trade_05_trade_create_unavailable",
          "social_trade_06_trade_pending_actions",
          "social_trade_07_trade_counter_draft",
          "social_trade_08_trade_declined",
          "social_trade_09_trade_error",
          "social_trade_10_trade_completed",
          "social_trade_11_trade_inbox_empty",
          "social_trade_12_messages_empty",
          "social_trade_13_users_empty_results",
          "social_trade_14_community_context_comment",
          "social_trade_15_matches_empty"
        ]
      }'
  )"
  printf 'VISUAL_PROOF_CONTEXT %s\n' "$context_json" >>"$runtime_log"
  if grep -Eq '(^|[[:space:]])(EXCEPTION CAUGHT|Some tests failed|══╡ EXCEPTION)' "$runtime_log"; then
    echo "Social Trade runtime log contains a forbidden failure for $profile" >&2
    return 1
  fi

  actual_count="$(find "$screenshots" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d '[:space:]')"
  if [[ "$actual_count" != "16" ]]; then
    echo "Expected 16 Social Trade screenshots for $profile, got $actual_count" >&2
    return 1
  fi
  (
    cd "$ROOT_DIR/app"
    "$DART_BIN" run tool/ui_runtime_evidence.dart validate-directory \
      --screenshots "$screenshots"
  )

  if [[ -d "$output_dir" ]]; then
    mv "$output_dir" "$previous_output"
  fi
  mkdir -p "$output_dir"
  cp "$screenshots"/*.png "$output_dir/"
  if ! (
    cd "$ROOT_DIR/app"
    "$DART_BIN" run tool/ui_runtime_evidence.dart index-directory \
      --repo-root "$ROOT_DIR" \
      --screenshots "docs/qa/ui-live/current/$output_name" \
      --log "$runtime_log" \
      --manifest "docs/qa/ui-live/current/$output_name/capture-manifest.json" \
      --source-digest "$SOURCE_DIGEST" \
      --surface social_trade \
      --profile "$profile" \
      --runtime flutter_drive \
      --target web_real_build \
      --device-contract "$device_contract"
  ); then
    rm -rf "$output_dir"
    if [[ -d "$previous_output" ]]; then
      mv "$previous_output" "$output_dir"
    fi
    return 1
  fi
  if [[ -d "$previous_output" ]]; then
    rm -rf "$previous_output"
  fi
}

capture_profile web_social_trade_mobile_390x844 390 844 ux-pack-05-social-trade-web-mobile
capture_profile web_social_trade_desktop_1440x900 1440 900 ux-pack-05-social-trade-web-desktop
capture_profile web_social_trade_wide_1920x1080 1920 1080 ux-pack-05-social-trade-web-wide

printf 'Social Trade PASS_RUNTIME captured for three real Web release profiles.\n'
printf 'Open all 48 PNGs before recording PASS_VISUAL_REVIEWED.\n'

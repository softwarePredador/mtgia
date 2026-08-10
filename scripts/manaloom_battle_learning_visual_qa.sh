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
RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_battle_learning_visual.XXXXXX")"
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
    echo "$command_name is required for Battle Learning visual QA" >&2
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
COMMANDER_IMAGE_URL="http://127.0.0.1:$ASSET_PORT/app/assets/branding/visual_fixture_arcane_artificer.webp"
ARTIFACT_IMAGE_URL="http://127.0.0.1:$ASSET_PORT/app/assets/branding/visual_fixture_arcane_ring.webp"

(
  cd "$ROOT_DIR/app"
  "$FLUTTER_BIN" analyze \
    lib/features/home/home_screen.dart \
    lib/features/battle/models/battle_live_cursor.dart \
    lib/features/battle/screens/battle_live_spectator_screen.dart \
    lib/features/battle/screens/battle_replays_screen.dart \
    lib/features/retention/models/post_game_note.dart \
    lib/features/retention/screens/post_game_notes_screen.dart \
    lib/features/retention/services/post_game_note_store.dart \
    lib/features/decks/screens/deck_details_screen.dart \
    lib/features/decks/widgets/deck_optimize_dialogs.dart \
    lib/features/decks/widgets/deck_optimize_flow_support.dart \
    lib/features/decks/widgets/deck_optimize_sections.dart \
    lib/features/decks/widgets/deck_optimize_sheet_widgets.dart \
    integration_test/battle_learning_visual_runtime_proof_test.dart \
    test/features/home/home_screen_test.dart \
    test/features/battle/models/battle_live_cursor_test.dart \
    test/features/battle/screens/battle_live_spectator_screen_test.dart \
    test/features/battle/screens/battle_replays_screen_test.dart \
    test/features/retention/post_game_card_evidence_test.dart \
    test/features/retention/post_game_note_store_test.dart \
    test/features/decks/widgets/deck_optimize_post_game_evidence_test.dart \
    test/ui/ui_live_evidence_policy_test.dart \
    --no-pub --no-version-check --no-fatal-infos
  "$FLUTTER_BIN" test \
    integration_test/battle_learning_visual_runtime_proof_test.dart \
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
      --target=integration_test/battle_learning_visual_runtime_proof_test.dart \
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
      --dart-define=MANALOOM_VISUAL_COMMANDER_IMAGE_URL="$COMMANDER_IMAGE_URL" \
      --dart-define=MANALOOM_VISUAL_ARTIFACT_IMAGE_URL="$ARTIFACT_IMAGE_URL" \
      --dart-define=MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true \
      --dart-define=MANALOOM_EMIT_SCREENSHOT_CHUNKS=false \
      --dart-define=DISABLE_FIREBASE_STARTUP=true \
      --dart-define=DISABLE_PUSH_INIT=true \
      --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true
  ) 2>&1 | tee "$runtime_log"
  drive_status="${PIPESTATUS[0]}"
  set -e
  if [[ "$drive_status" -ne 0 ]]; then
    echo "Battle Learning runtime proof failed for $profile" >&2
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
        surface: "battle_learning",
        source_digest: $source_digest,
        profile: $profile,
        runtime: "flutter_drive",
        target: "web_real_build",
        device_contract: $device_contract,
        required_checkpoints: [
          "battle_learning_00_play_entry",
          "battle_learning_01_active_session",
          "battle_learning_02_live_table",
          "battle_learning_03_reconnect",
          "battle_learning_04_timeout",
          "battle_learning_05_completed",
          "battle_learning_06_replay_evidence",
          "battle_learning_07_postgame_signals",
          "battle_learning_08_postgame_receipt",
          "battle_learning_09_optimize_evidence"
        ]
      }'
  )"
  printf 'VISUAL_PROOF_CONTEXT %s\n' "$context_json" >>"$runtime_log"
  if grep -Eq '(^|[[:space:]])(EXCEPTION CAUGHT|Some tests failed|══╡ EXCEPTION)' "$runtime_log"; then
    echo "Battle Learning runtime log contains a forbidden failure for $profile" >&2
    return 1
  fi

  actual_count="$(find "$screenshots" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d '[:space:]')"
  if [[ "$actual_count" != "10" ]]; then
    echo "Expected 10 Battle Learning screenshots for $profile, got $actual_count" >&2
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
      --surface battle_learning \
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

capture_profile web_battle_learning_mobile_390x844 390 844 ux-pack-04-battle-learning-web-mobile
capture_profile web_battle_learning_desktop_1440x900 1440 900 ux-pack-04-battle-learning-web-desktop
capture_profile web_battle_learning_wide_1920x1080 1920 1080 ux-pack-04-battle-learning-web-wide

printf 'Battle Learning PASS_RUNTIME captured for three real Web release profiles.\n'
printf 'Open all 30 PNGs before recording PASS_VISUAL_REVIEWED.\n'

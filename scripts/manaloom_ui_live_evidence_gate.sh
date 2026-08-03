#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:---check}"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"
REVIEW_FILE="$ROOT_DIR/docs/qa/ui-live/latest.json"
CAPTURE_OUTPUT="docs/qa/ui-live/current/battle-coach-android"
BATTLE_LIVE_CAPTURE_OUTPUT="docs/qa/ui-live/current/battle-live-web"
CORE_PRODUCT_CAPTURE_OUTPUT="docs/qa/ui-live/current/core-product-android"
P0_CAPTURE_OUTPUT="docs/qa/ui-live/current/p0-matrix"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
source "$ROOT_DIR/scripts/lib/manaloom_ui_runtime_contract.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

if [[ -n "${MANALOOM_FLUTTER_BIN:-}" ]]; then
  FLUTTER_BIN="$MANALOOM_FLUTTER_BIN"
elif [[ -x "$PINNED_FLUTTER" ]]; then
  FLUTTER_BIN="$PINNED_FLUTTER"
else
  FLUTTER_BIN="$(command -v flutter 2>/dev/null || true)"
fi

print_header() {
  printf '\n== %s ==\n' "$1"
}

attest_android_runtime() {
  local device_id="$1"
  local capture_posture="${2:-portrait-up}"
  local kernel_qemu boot_qemu serial device_model device_android_version
  local device_size emulator_signal physical_signal flutter_devices_json
  local flutter_device_record flutter_reports_emulator
  local requested_kind="${MANALOOM_UI_ANDROID_RUNTIME_KIND:-auto}"

  if [[ -z "$FLUTTER_BIN" || ! -x "$FLUTTER_BIN" ]] ||
     ! command -v jq >/dev/null 2>&1; then
    echo "Flutter and jq are required to cross-check Android attestation" >&2
    exit 2
  fi
  adb -s "$device_id" get-state | grep -qx device || {
    echo "Android runtime is not ready: $device_id" >&2
    exit 1
  }
  kernel_qemu="$(adb -s "$device_id" shell getprop ro.kernel.qemu | tr -d '\r')"
  boot_qemu="$(adb -s "$device_id" shell getprop ro.boot.qemu | tr -d '\r')"
  serial="$(adb -s "$device_id" get-serialno | tr -d '\r')"
  device_model="$(adb -s "$device_id" shell getprop ro.product.model | tr -d '\r')"
  device_android_version="$(
    adb -s "$device_id" shell getprop ro.build.version.release | tr -d '\r'
  )"
  device_size="$(adb -s "$device_id" shell wm size | tr -d '\r' | tail -n 1)"
  if [[ -z "$serial" || "$serial" == "unknown" ||
        -z "$device_model" || -z "$device_android_version" || -z "$device_size" ]]; then
    echo "Could not attest the Android runtime contract" >&2
    exit 1
  fi

  emulator_signal="false"
  physical_signal="false"
  if [[ "$kernel_qemu" == "1" || "$boot_qemu" == "1" ||
        "$serial" == emulator-* ]]; then
    emulator_signal="true"
  fi
  if [[ ( -z "$kernel_qemu" || "$kernel_qemu" == "0" ) &&
        ( -z "$boot_qemu" || "$boot_qemu" == "0" ) &&
        "$serial" != emulator-* ]]; then
    physical_signal="true"
  fi
  if [[ "$emulator_signal" == "$physical_signal" ]]; then
    echo "Android runtime kind is ambiguous; refusing evidence attestation" >&2
    exit 1
  fi

  flutter_devices_json="$(
    "$FLUTTER_BIN" devices --machine --no-version-check 2>/dev/null
  )"
  flutter_device_record="$(
    jq -c --arg device_id "$device_id" \
      '[.[] | select(.id == $device_id)] | if length == 1 then .[0] else empty end' \
      <<<"$flutter_devices_json"
  )"
  flutter_reports_emulator="$(
    jq -r '.emulator | if . == true then "true" elif . == false then "false" else empty end' \
      <<<"$flutter_device_record"
  )"
  if [[ -z "$flutter_device_record" || -z "$flutter_reports_emulator" ||
        "$flutter_reports_emulator" != "$emulator_signal" ]]; then
    echo "ADB and Flutter disagree about Android runtime kind" >&2
    exit 1
  fi

  if [[ "$emulator_signal" == "true" ]]; then
    MANALOOM_ATTESTED_ANDROID_KIND="emulator"
    MANALOOM_ATTESTED_ANDROID_TARGET="android_emulator"
  else
    MANALOOM_ATTESTED_ANDROID_KIND="physical"
    MANALOOM_ATTESTED_ANDROID_TARGET="android_physical"
  fi
  if [[ "$requested_kind" != "auto" &&
        "$requested_kind" != "$MANALOOM_ATTESTED_ANDROID_KIND" ]]; then
    echo "Requested Android runtime kind '$requested_kind' does not match attested '$MANALOOM_ATTESTED_ANDROID_KIND'" >&2
    exit 1
  fi

  MANALOOM_ATTESTED_ANDROID_CONTRACT="$(
    manaloom_android_runtime_device_contract \
      "$device_model" \
      "$device_android_version" \
      "$MANALOOM_ATTESTED_ANDROID_KIND" \
      "$serial" \
      "$device_size" \
      "$capture_posture"
  )"
}

verify_current_evidence() {
  local source_digest
  source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  print_header "UI source digest"
  printf '%s\n' "$source_digest"
  (
    cd "$ROOT_DIR/app"
    "$DART_BIN" run tool/ui_runtime_evidence.dart verify \
      --repo-root "$ROOT_DIR" \
      --review "$REVIEW_FILE" \
      --source-digest "$source_digest"
  )
}

capture_battle_coach() {
  if [[ -z "$FLUTTER_BIN" || ! -x "$FLUTTER_BIN" ]]; then
    echo "Flutter executable is required for runtime capture" >&2
    exit 2
  fi
  command -v adb >/dev/null 2>&1 || {
    echo "adb is required for Android runtime capture" >&2
    exit 2
  }
  command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required for the local card-image fixture" >&2
    exit 2
  }
  local device_id="${MANALOOM_UI_PROOF_DEVICE:-}"
  if [[ -z "$device_id" ]]; then
    echo "MANALOOM_UI_PROOF_DEVICE must identify a connected Android runtime" >&2
    exit 2
  fi
  attest_android_runtime "$device_id" "portrait-up"
  local device_contract="$MANALOOM_ATTESTED_ANDROID_CONTRACT"
  local runtime_target="$MANALOOM_ATTESTED_ANDROID_TARGET"
  local proof_profile="${MANALOOM_UI_PROOF_PROFILE:-android_${MANALOOM_ATTESTED_ANDROID_KIND}_phone}"
  local source_digest run_dir runtime_log status image_port image_server_pid
  source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  run_dir="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_ui_proof.XXXXXX")"
  runtime_log="$run_dir/battle-coach-runtime.log"
  image_port="$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"
  image_server_pid=""

  cleanup_capture() {
    local cleanup_status="$?"
    trap - EXIT INT TERM
    if [[ -n "$image_server_pid" ]] &&
       kill -0 "$image_server_pid" >/dev/null 2>&1; then
      kill -TERM "$image_server_pid" >/dev/null 2>&1
      wait "$image_server_pid" >/dev/null 2>&1
    fi
    adb -s "$device_id" reverse --remove "tcp:$image_port" \
      >/dev/null 2>&1 || true
    rm -rf "$run_dir"
    exit "$cleanup_status"
  }
  trap cleanup_capture EXIT INT TERM

  python3 -m http.server "$image_port" \
    --bind 127.0.0.1 \
    --directory "$ROOT_DIR/app/assets/branding" \
    >"$run_dir/card-image-fixture.log" 2>&1 &
  image_server_pid="$!"
  adb -s "$device_id" reverse "tcp:$image_port" "tcp:$image_port" >/dev/null
  for _ in $(seq 1 40); do
    if curl -fsS --max-time 1 \
      "http://127.0.0.1:$image_port/visual_fixture_arcane_ring.webp" >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
  curl -fsS --max-time 3 \
    "http://127.0.0.1:$image_port/visual_fixture_arcane_ring.webp" >/dev/null

  print_header "Battle Coach automated UI evidence"
  (
    cd "$ROOT_DIR/app"
    "$FLUTTER_BIN" analyze \
      lib/features/battle/screens/battle_coach_screen.dart \
      integration_test/battle_coach_visual_runtime_proof_test.dart \
      tool/ui_runtime_evidence.dart \
      test/tool/ui_runtime_evidence_test.dart \
      test/features/battle/screens/battle_coach_screen_test.dart \
      --no-pub --no-version-check --no-fatal-infos
    "$FLUTTER_BIN" test \
      test/tool/ui_runtime_evidence_test.dart \
      test/features/battle/screens/battle_coach_screen_test.dart \
      --no-pub --no-version-check --reporter compact
  )

  print_header "Battle Coach $MANALOOM_ATTESTED_ANDROID_KIND Android runtime capture"
  set +e
  (
    cd "$ROOT_DIR/app"
    "$FLUTTER_BIN" test \
      integration_test/battle_coach_visual_runtime_proof_test.dart \
      -d "$device_id" \
      --dart-define=MANALOOM_UI_SOURCE_DIGEST="$source_digest" \
      --dart-define=MANALOOM_UI_PROOF_PROFILE="$proof_profile" \
      --dart-define=MANALOOM_UI_PROOF_TARGET="$runtime_target" \
      --dart-define=MANALOOM_UI_PROOF_DEVICE_CONTRACT="$device_contract" \
      --dart-define=MANALOOM_UI_PROOF_CARD_IMAGE_BASE_URL="http://127.0.0.1:$image_port" \
      --dart-define=MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true \
      --dart-define=MANALOOM_VISUAL_FIXTURE_MODE=true \
      --dart-define=DISABLE_FIREBASE_STARTUP=true \
      --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
      --reporter expanded \
      --no-version-check
  ) 2>&1 | tee "$runtime_log" | sed '/SCREENSHOT_CHUNK /d'
  status="${PIPESTATUS[0]}"
  set -e
  if [[ "$status" -ne 0 ]]; then
    echo "Battle Coach runtime proof failed; no evidence was approved" >&2
    exit "$status"
  fi

  print_header "Materialize hashed runtime screenshots"
  (
    cd "$ROOT_DIR/app"
    "$DART_BIN" run tool/ui_runtime_evidence.dart extract \
      --repo-root "$ROOT_DIR" \
      --log "$runtime_log" \
      --output "$CAPTURE_OUTPUT" \
      --source-digest "$source_digest" \
      --replace
  )

  printf '\nRuntime evidence captured. It is not visually approved yet.\n'
  printf 'Inspect every PNG under %s/%s, then update %s and run --check.\n' \
    "$ROOT_DIR" "$CAPTURE_OUTPUT" "$REVIEW_FILE"
  trap - EXIT INT TERM
  rm -rf "$run_dir"
}

capture_battle_live_web() {
  if [[ -z "$FLUTTER_BIN" || ! -x "$FLUTTER_BIN" ]]; then
    echo "Flutter executable is required for Battle Live Web capture" >&2
    exit 2
  fi
  for required_tool in curl jq sed; do
    command -v "$required_tool" >/dev/null 2>&1 || {
      echo "$required_tool is required for Battle Live Web capture" >&2
      exit 2
    }
  done

  local profile="web_battle_live_1440x900"
  local target="web_real_build"
  local device_contract
  local chrome_executable chromedriver_bin browser_major driver_major
  local source_digest run_dir screenshot_dir runtime_log chromedriver_log
  local chromedriver_pid="" drive_status actual_count context_json
  local output_dir="$ROOT_DIR/$BATTLE_LIVE_CAPTURE_OUTPUT"
  local previous_output=""
  local output_mutation_started="false"
  local promoted="false"
  device_contract="$(manaloom_web_runtime_device_contract "$profile")"
  chrome_executable="${CHROME_EXECUTABLE:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
  chromedriver_bin="${MANALOOM_CHROMEDRIVER_BIN:-$(command -v chromedriver 2>/dev/null || true)}"
  if [[ ! -x "$chrome_executable" ]]; then
    echo "Battle Live Web capture requires Chrome: $chrome_executable" >&2
    exit 2
  fi
  if [[ -z "$chromedriver_bin" || ! -x "$chromedriver_bin" ]]; then
    echo "Battle Live Web capture requires an executable ChromeDriver" >&2
    exit 2
  fi
  browser_major="$("$chrome_executable" --version | sed -E 's/^[^0-9]*([0-9]+).*/\1/')"
  driver_major="$("$chromedriver_bin" --version | sed -E 's/^[^0-9]*([0-9]+).*/\1/')"
  if [[ -z "$browser_major" || -z "$driver_major" ||
        "$browser_major" != "$driver_major" ]]; then
    echo "ChromeDriver major $driver_major does not match Chrome major $browser_major" >&2
    exit 2
  fi
  if curl --silent --fail --max-time 1 \
    http://127.0.0.1:4444/status >/dev/null 2>&1; then
    echo "WebDriver port 4444 is already in use" >&2
    exit 2
  fi

  source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  run_dir="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_battle_live_proof.XXXXXX")"
  screenshot_dir="$run_dir/screenshots"
  runtime_log="$run_dir/battle-live-web-runtime.log"
  chromedriver_log="$run_dir/chromedriver.log"
  mkdir -p "$screenshot_dir"

  cleanup_battle_live_capture() {
    local cleanup_status="$?"
    trap - EXIT INT TERM
    if [[ -n "$chromedriver_pid" ]]; then
      kill "$chromedriver_pid" >/dev/null 2>&1 || true
      wait "$chromedriver_pid" >/dev/null 2>&1 || true
    fi
    if [[ "$promoted" != "true" &&
          "$output_mutation_started" == "true" ]]; then
      rm -rf "$output_dir"
      if [[ -n "$previous_output" && -d "$previous_output" ]]; then
        mv "$previous_output" "$output_dir"
      fi
    fi
    rm -rf "$run_dir"
    exit "$cleanup_status"
  }
  trap cleanup_battle_live_capture EXIT INT TERM

  print_header "Battle Live automated UI evidence"
  (
    cd "$ROOT_DIR/app"
    "$FLUTTER_BIN" analyze \
      lib/features/battle/models/battle_job.dart \
      lib/features/battle/models/battle_live_cursor.dart \
      lib/features/battle/screens/battle_live_spectator_screen.dart \
      lib/features/battle/services/battle_job_gateway.dart \
      integration_test/battle_live_visual_runtime_proof_test.dart \
      test/features/battle/screens/battle_live_spectator_screen_test.dart \
      test/ui/ui_live_evidence_policy_test.dart \
      tool/ui_runtime_evidence.dart \
      --no-pub --no-version-check --no-fatal-infos
    "$FLUTTER_BIN" test \
      integration_test/battle_live_visual_runtime_proof_test.dart \
      -d flutter-tester \
      --dart-define=MANALOOM_CAPTURE_RUNTIME_PROOF=false \
      --no-pub --no-version-check --reporter compact
    "$FLUTTER_BIN" test \
      test/features/battle/screens/battle_live_spectator_screen_test.dart \
      test/ui/ui_live_evidence_policy_test.dart \
      --no-pub --no-version-check --reporter compact
  )

  "$chromedriver_bin" --port=4444 >"$chromedriver_log" 2>&1 &
  chromedriver_pid="$!"
  local webdriver_ready="false"
  for _ in {1..50}; do
    if curl --silent --fail --max-time 1 \
      http://127.0.0.1:4444/status >/dev/null 2>&1; then
      webdriver_ready="true"
      break
    fi
    if ! kill -0 "$chromedriver_pid" >/dev/null 2>&1; then
      break
    fi
    sleep 0.2
  done
  if [[ "$webdriver_ready" != "true" ]]; then
    echo "ChromeDriver did not become ready; see $chromedriver_log" >&2
    exit 1
  fi

  print_header "Battle Live real Web release runtime capture"
  set +e
  (
    cd "$ROOT_DIR/app"
    MANALOOM_SCREENSHOT_DIR="$screenshot_dir" "$FLUTTER_BIN" drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/battle_live_visual_runtime_proof_test.dart \
      --no-pub --no-version-check \
      --device-connection=attached \
      --timeout=600 \
      --release \
      -d chrome \
      --browser-dimension=1440x900@1 \
      --no-web-resources-cdn \
      --dart-define=MANALOOM_CAPTURE_RUNTIME_PROOF=true \
      --dart-define=MANALOOM_UI_SOURCE_DIGEST="$source_digest" \
      --dart-define=MANALOOM_UI_PROOF_PROFILE="$profile" \
      --dart-define=MANALOOM_UI_PROOF_TARGET="$target" \
      --dart-define=MANALOOM_UI_PROOF_DEVICE_CONTRACT="$device_contract" \
      --dart-define=MANALOOM_VISUAL_WIDTH=1440 \
      --dart-define=MANALOOM_VISUAL_HEIGHT=900 \
      --dart-define=MANALOOM_EMIT_SCREENSHOT_CHUNKS=false \
      --dart-define=MANALOOM_VISUAL_FIXTURE_MODE=true \
      --dart-define=DISABLE_FIREBASE_STARTUP=true \
      --dart-define=DISABLE_PUSH_INIT=true \
      --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true
  ) 2>&1 | tee "$runtime_log"
  drive_status="${PIPESTATUS[0]}"
  set -e
  if [[ "$drive_status" -ne 0 ]]; then
    echo "Battle Live Web runtime proof failed; no evidence was promoted" >&2
    exit "$drive_status"
  fi

  # Web release can omit print() output. Keep the successful runtime log but
  # bind it to one complete, host-attested context before indexing screenshots.
  sed '/VISUAL_PROOF_CONTEXT /d' "$runtime_log" \
    >"$run_dir/runtime-without-context.log"
  mv "$run_dir/runtime-without-context.log" "$runtime_log"
  context_json="$(
    jq --compact-output --null-input \
      --arg source_digest "$source_digest" \
      --arg profile "$profile" \
      --arg target "$target" \
      --arg device_contract "$device_contract" \
      '{
        schema_version: "manaloom_ui_runtime_context_v1",
        surface: "battle_live",
        source_digest: $source_digest,
        profile: $profile,
        runtime: "flutter_drive",
        target: $target,
        device_contract: $device_contract,
        required_checkpoints: [
          "battle_live_00_waiting",
          "battle_live_01_active_feed",
          "battle_live_02_recoverable_reconnect",
          "battle_live_03_timeout_terminal",
          "battle_live_04_completed_replay"
        ]
      }'
  )"
  printf 'VISUAL_PROOF_CONTEXT %s\n' "$context_json" >>"$runtime_log"
  if grep -Eq \
    '(^|[[:space:]])(EXCEPTION CAUGHT|Some tests failed|══╡ EXCEPTION)' \
    "$runtime_log"; then
    echo "Battle Live runtime log contains a forbidden test failure" >&2
    exit 1
  fi

  actual_count="$(
    find "$screenshot_dir" -maxdepth 1 -type f -name '*.png' | wc -l |
      tr -d '[:space:]'
  )"
  if [[ "$actual_count" != "5" ]]; then
    echo "Expected 5 Battle Live screenshots, got $actual_count" >&2
    exit 1
  fi
  for checkpoint in \
    battle_live_00_waiting \
    battle_live_01_active_feed \
    battle_live_02_recoverable_reconnect \
    battle_live_03_timeout_terminal \
    battle_live_04_completed_replay; do
    if [[ ! -s "$screenshot_dir/$checkpoint.png" ]]; then
      echo "Battle Live checkpoint is missing: $checkpoint" >&2
      exit 1
    fi
  done
  (
    cd "$ROOT_DIR/app"
    "$DART_BIN" run tool/ui_runtime_evidence.dart validate-directory \
      --screenshots "$screenshot_dir"
  )

  if [[ -d "$output_dir" ]]; then
    previous_output="$run_dir/previous-battle-live-web"
    mv "$output_dir" "$previous_output"
  fi
  output_mutation_started="true"
  mkdir -p "$output_dir"
  cp "$screenshot_dir"/*.png "$output_dir/"
  (
    cd "$ROOT_DIR/app"
    "$DART_BIN" run tool/ui_runtime_evidence.dart index-directory \
      --repo-root "$ROOT_DIR" \
      --screenshots "$BATTLE_LIVE_CAPTURE_OUTPUT" \
      --log "$runtime_log" \
      --manifest "$BATTLE_LIVE_CAPTURE_OUTPUT/capture-manifest.json" \
      --source-digest "$source_digest" \
      --surface battle_live \
      --profile "$profile" \
      --runtime flutter_drive \
      --target "$target" \
      --device-contract "$device_contract"
  )
  promoted="true"

  printf '\nBattle Live PASS_RUNTIME captured in a real Web release build.\n'
  printf 'It is not visually approved. Open all 5 PNGs under %s before updating %s.\n' \
    "$output_dir" "$REVIEW_FILE"
  trap - EXIT INT TERM
  if [[ -n "$chromedriver_pid" ]]; then
    kill "$chromedriver_pid" >/dev/null 2>&1 || true
    wait "$chromedriver_pid" >/dev/null 2>&1 || true
  fi
  rm -rf "$run_dir"
}

capture_core_product() {
  if [[ -z "$FLUTTER_BIN" || ! -x "$FLUTTER_BIN" ]]; then
    echo "Flutter executable is required for runtime capture" >&2
    exit 2
  fi
  command -v adb >/dev/null 2>&1 || {
    echo "adb is required for Android runtime capture" >&2
    exit 2
  }
  command -v jq >/dev/null 2>&1 || {
    echo "jq is required to attest portrait runtime screenshots" >&2
    exit 2
  }
  local device_id="${MANALOOM_UI_PROOF_DEVICE:-}"
  if [[ -z "$device_id" ]]; then
    echo "MANALOOM_UI_PROOF_DEVICE must identify a connected Android runtime" >&2
    exit 2
  fi
  attest_android_runtime "$device_id" "portrait-up"
  local device_contract source_digest run_dir runtime_log status
  local runtime_target="$MANALOOM_ATTESTED_ANDROID_TARGET"
  local proof_profile="${MANALOOM_UI_PROOF_PROFILE:-android_${MANALOOM_ATTESTED_ANDROID_KIND}_core_product}"
  device_contract="$MANALOOM_ATTESTED_ANDROID_CONTRACT"
  source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  run_dir="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_core_product_proof.XXXXXX")"
  runtime_log="$run_dir/core-product-runtime.log"

  cleanup_core_capture() {
    local cleanup_status="$?"
    trap - EXIT INT TERM
    rm -rf "$run_dir"
    exit "$cleanup_status"
  }
  trap cleanup_core_capture EXIT INT TERM

  print_header "Core product automated runtime UI acceptance"
  (
    cd "$ROOT_DIR/app"
    "$FLUTTER_BIN" analyze \
      lib/features/binder/widgets/binder_item_editor.dart \
      lib/features/decks/providers/deck_provider.dart \
      lib/features/decks/screens/deck_list_screen.dart \
      lib/features/decks/widgets/deck_optimize_dialogs.dart \
      integration_test/core_product_acceptance_runtime_test.dart \
      test/features/binder/widgets/binder_item_editor_validation_test.dart \
      test/features/decks/providers/deck_provider_test.dart \
      test/features/decks/screens/deck_list_responsive_test.dart \
      test/features/decks/widgets/deck_optimize_dialogs_test.dart \
      --no-pub --no-version-check --no-fatal-infos
    "$FLUTTER_BIN" test \
      integration_test/core_product_acceptance_runtime_test.dart \
      -d flutter-tester \
      --dart-define=MANALOOM_CAPTURE_RUNTIME_PROOF=false \
      --no-pub --no-version-check --reporter compact
    "$FLUTTER_BIN" test \
      test/features/binder/widgets/binder_item_editor_validation_test.dart \
      test/features/decks/providers/deck_provider_test.dart \
      test/features/decks/screens/deck_list_responsive_test.dart \
      test/features/decks/widgets/deck_optimize_dialogs_test.dart \
      --no-pub --no-version-check --reporter compact
  )

  print_header "Core product $MANALOOM_ATTESTED_ANDROID_KIND Android runtime capture"
  set +e
  (
    cd "$ROOT_DIR/app"
    "$FLUTTER_BIN" test \
      integration_test/core_product_acceptance_runtime_test.dart \
      -d "$device_id" \
      --dart-define=MANALOOM_UI_SOURCE_DIGEST="$source_digest" \
      --dart-define=MANALOOM_UI_PROOF_PROFILE="$proof_profile" \
      --dart-define=MANALOOM_UI_PROOF_TARGET="$runtime_target" \
      --dart-define=MANALOOM_UI_PROOF_DEVICE_CONTRACT="$device_contract" \
      --dart-define=DISABLE_FIREBASE_STARTUP=true \
      --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
      --reporter expanded \
      --no-pub --no-version-check
  ) 2>&1 | tee "$runtime_log" | sed '/SCREENSHOT_CHUNK /d'
  status="${PIPESTATUS[0]}"
  set -e
  if [[ "$status" -ne 0 ]]; then
    echo "Core product runtime proof failed; no evidence was approved" >&2
    exit "$status"
  fi

  print_header "Materialize hashed core-product screenshots"
  (
    cd "$ROOT_DIR/app"
    "$DART_BIN" run tool/ui_runtime_evidence.dart extract \
      --repo-root "$ROOT_DIR" \
      --log "$runtime_log" \
      --output "$CORE_PRODUCT_CAPTURE_OUTPUT" \
      --source-digest "$source_digest" \
      --replace
  )
  local capture_manifest="$ROOT_DIR/$CORE_PRODUCT_CAPTURE_OUTPUT/capture-manifest.json"
  if ! jq -e \
    '.screenshots | length > 0 and all(.height > .width)' \
    "$capture_manifest" >/dev/null; then
    echo "Core product proof must contain only portrait screenshots" >&2
    exit 1
  fi

  printf '\nRuntime evidence captured. It is not visually approved yet.\n'
  printf 'Inspect every PNG under %s/%s before recording PASS_VISUAL_REVIEWED.\n' \
    "$ROOT_DIR" "$CORE_PRODUCT_CAPTURE_OUTPUT"
  trap - EXIT INT TERM
  rm -rf "$run_dir"
}

index_p0_matrix() {
  local source_digest android_profile android_target android_device_contract
  local device_id="${MANALOOM_UI_PROOF_DEVICE:-}"
  source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  if [[ -z "$device_id" ]]; then
    echo "MANALOOM_UI_PROOF_DEVICE is required to attest the indexed Android runtime" >&2
    exit 2
  fi
  attest_android_runtime \
    "$device_id" \
    "portrait-up with native Life Counter landscape checkpoint"
  android_target="$MANALOOM_ATTESTED_ANDROID_TARGET"
  android_device_contract="$MANALOOM_ATTESTED_ANDROID_CONTRACT"
  if [[ "$MANALOOM_ATTESTED_ANDROID_KIND" == "emulator" ]]; then
    android_profile="${MANALOOM_P0_ANDROID_PROFILE:-android_emulator_manaloom_api34}"
  else
    android_profile="${MANALOOM_P0_ANDROID_PROFILE:-android_physical_sm_a135m}"
  fi
  if [[ "$android_profile" != android_"$MANALOOM_ATTESTED_ANDROID_KIND"_* ]]; then
    echo "Android P0 profile '$android_profile' contradicts attested runtime kind '$MANALOOM_ATTESTED_ANDROID_KIND'" >&2
    exit 2
  fi

  index_profile() {
    local profile="$1"
    local target="$2"
    local device_contract="$3"
    local screenshot_dir="$4"
    local runtime_log="$5"
    local relative_screenshot_dir

    if [[ -z "$screenshot_dir" || -z "$runtime_log" ]]; then
      echo "P0 profile $profile requires a screenshot directory and runtime log" >&2
      exit 2
    fi
    relative_screenshot_dir="${screenshot_dir#"$ROOT_DIR"/}"
    if [[ "$relative_screenshot_dir" == "$screenshot_dir" ]]; then
      echo "P0 screenshots must already live inside the repository: $screenshot_dir" >&2
      exit 2
    fi

    (
      cd "$ROOT_DIR/app"
      "$DART_BIN" run tool/ui_runtime_evidence.dart index-directory \
        --repo-root "$ROOT_DIR" \
        --screenshots "$relative_screenshot_dir" \
        --log "$runtime_log" \
        --manifest "$P0_CAPTURE_OUTPUT/$profile.json" \
        --source-digest "$source_digest" \
        --surface authenticated_p0_matrix \
        --profile "$profile" \
        --runtime flutter_drive \
        --target "$target" \
        --device-contract "$device_contract"
    )
  }

  print_header "Index complete authenticated P0 matrix"
  index_profile \
    web_mobile_390x844 \
    web_real_build \
    "$(manaloom_web_runtime_device_contract web_mobile_390x844)" \
    "${MANALOOM_P0_WEB_MOBILE_DIR:-}" \
    "${MANALOOM_P0_WEB_MOBILE_LOG:-}"
  index_profile \
    web_desktop_1440x900 \
    web_real_build \
    "$(manaloom_web_runtime_device_contract web_desktop_1440x900)" \
    "${MANALOOM_P0_WEB_DESKTOP_DIR:-}" \
    "${MANALOOM_P0_WEB_DESKTOP_LOG:-}"
  index_profile \
    web_wide_1920x1080 \
    web_real_build \
    "$(manaloom_web_runtime_device_contract web_wide_1920x1080)" \
    "${MANALOOM_P0_WEB_WIDE_DIR:-}" \
    "${MANALOOM_P0_WEB_WIDE_LOG:-}"
  index_profile \
    "$android_profile" \
    "$android_target" \
    "$android_device_contract" \
    "${MANALOOM_P0_ANDROID_DIR:-}" \
    "${MANALOOM_P0_ANDROID_LOG:-}"
}

case "$MODE" in
  --check)
    verify_current_evidence
    ;;
  --capture-battle-coach)
    capture_battle_coach
    ;;
  --capture-battle-live-web)
    capture_battle_live_web
    ;;
  --capture-core-product)
    capture_core_product
    ;;
  --index-p0-matrix)
    index_p0_matrix
    ;;
  -h|--help|help)
    printf '%s\n' \
      "usage: $0 --check" \
      "       MANALOOM_UI_PROOF_DEVICE=<id> [MANALOOM_UI_ANDROID_RUNTIME_KIND=auto|emulator|physical] $0 --capture-battle-coach" \
      "       [MANALOOM_CHROMEDRIVER_BIN=<path>] $0 --capture-battle-live-web" \
      "       MANALOOM_UI_PROOF_DEVICE=<id> [MANALOOM_UI_ANDROID_RUNTIME_KIND=auto|emulator|physical] $0 --capture-core-product" \
      "       MANALOOM_UI_PROOF_DEVICE=<id> MANALOOM_P0_*_DIR=<repo-dir> MANALOOM_P0_*_LOG=<log> $0 --index-p0-matrix"
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 2
    ;;
esac

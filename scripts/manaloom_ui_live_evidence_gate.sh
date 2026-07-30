#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:---check}"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"
REVIEW_FILE="$ROOT_DIR/docs/qa/ui-live/latest.json"
CAPTURE_OUTPUT="docs/qa/ui-live/current/battle-coach-android"
CORE_PRODUCT_CAPTURE_OUTPUT="docs/qa/ui-live/current/core-product-android"
P0_CAPTURE_OUTPUT="docs/qa/ui-live/current/p0-matrix"

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

print_header() {
  printf '\n== %s ==\n' "$1"
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
    echo "adb is required for physical Android runtime capture" >&2
    exit 2
  }
  command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required for the local card-image fixture" >&2
    exit 2
  }
  local device_id="${MANALOOM_UI_PROOF_DEVICE:-}"
  if [[ -z "$device_id" ]]; then
    echo "MANALOOM_UI_PROOF_DEVICE must identify a connected physical Android device" >&2
    exit 2
  fi
  local device_contract="${MANALOOM_UI_PROOF_DEVICE_CONTRACT:-physical_android}"
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
  adb -s "$device_id" get-state | grep -qx device || {
    echo "Android device is not ready: $device_id" >&2
    exit 1
  }
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

  print_header "Battle Coach physical Android runtime capture"
  set +e
  (
    cd "$ROOT_DIR/app"
    "$FLUTTER_BIN" test \
      integration_test/battle_coach_visual_runtime_proof_test.dart \
      -d "$device_id" \
      --dart-define=MANALOOM_UI_SOURCE_DIGEST="$source_digest" \
      --dart-define=MANALOOM_UI_PROOF_PROFILE=android_phone \
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

capture_core_product() {
  if [[ -z "$FLUTTER_BIN" || ! -x "$FLUTTER_BIN" ]]; then
    echo "Flutter executable is required for runtime capture" >&2
    exit 2
  fi
  command -v adb >/dev/null 2>&1 || {
    echo "adb is required for physical Android runtime capture" >&2
    exit 2
  }
  command -v jq >/dev/null 2>&1 || {
    echo "jq is required to attest portrait runtime screenshots" >&2
    exit 2
  }
  local device_id="${MANALOOM_UI_PROOF_DEVICE:-}"
  if [[ -z "$device_id" ]]; then
    echo "MANALOOM_UI_PROOF_DEVICE must identify a connected physical Android device" >&2
    exit 2
  fi
  adb -s "$device_id" get-state | grep -qx device || {
    echo "Android device is not ready: $device_id" >&2
    exit 1
  }
  local is_emulator device_model device_android_version device_size
  is_emulator="$(adb -s "$device_id" shell getprop ro.kernel.qemu | tr -d '\r')"
  if [[ "$is_emulator" == "1" ]]; then
    echo "Core product proof requires a physical Android device" >&2
    exit 1
  fi
  device_model="$(adb -s "$device_id" shell getprop ro.product.model | tr -d '\r')"
  device_android_version="$(adb -s "$device_id" shell getprop ro.build.version.release | tr -d '\r')"
  device_size="$(adb -s "$device_id" shell wm size | tr -d '\r' | tail -n 1)"
  if [[ -z "$device_model" || -z "$device_android_version" || -z "$device_size" ]]; then
    echo "Could not attest the physical Android device contract" >&2
    exit 1
  fi
  local device_contract source_digest run_dir runtime_log status
  device_contract="$device_model, Android $device_android_version, physical device, $device_size; capture posture: portrait-up"
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

  print_header "Core product physical Android runtime capture"
  set +e
  (
    cd "$ROOT_DIR/app"
    "$FLUTTER_BIN" test \
      integration_test/core_product_acceptance_runtime_test.dart \
      -d "$device_id" \
      --dart-define=MANALOOM_UI_SOURCE_DIGEST="$source_digest" \
      --dart-define=MANALOOM_UI_PROOF_PROFILE=android_core_product \
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
  local source_digest
  source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"

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
    "Chrome real build; Flutter surface requested at 390x844; symmetric near-white host margins cropped by the driver when present" \
    "${MANALOOM_P0_WEB_MOBILE_DIR:-}" \
    "${MANALOOM_P0_WEB_MOBILE_LOG:-}"
  index_profile \
    web_desktop_1440x900 \
    web_real_build \
    "Chrome real build; Flutter surface requested at 1440x900; symmetric near-white host margins cropped by the driver when present" \
    "${MANALOOM_P0_WEB_DESKTOP_DIR:-}" \
    "${MANALOOM_P0_WEB_DESKTOP_LOG:-}"
  index_profile \
    web_wide_1920x1080 \
    web_real_build \
    "Chrome real build; Flutter surface requested at 1920x1080; symmetric near-white host margins cropped by the driver when present" \
    "${MANALOOM_P0_WEB_WIDE_DIR:-}" \
    "${MANALOOM_P0_WEB_WIDE_LOG:-}"
  index_profile \
    android_physical_sm_a135m \
    android_physical \
    "Samsung SM-A135M, Android 14, profile mode, 1080x2408" \
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
  --capture-core-product)
    capture_core_product
    ;;
  --index-p0-matrix)
    index_p0_matrix
    ;;
  -h|--help|help)
    printf '%s\n' \
      "usage: $0 --check" \
      "       MANALOOM_UI_PROOF_DEVICE=<id> $0 --capture-battle-coach" \
      "       MANALOOM_UI_PROOF_DEVICE=<id> $0 --capture-core-product" \
      "       MANALOOM_P0_*_DIR=<repo-dir> MANALOOM_P0_*_LOG=<log> $0 --index-p0-matrix"
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 2
    ;;
esac

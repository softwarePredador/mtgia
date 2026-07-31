#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"
PINNED_DART="${PINNED_FLUTTER%/flutter}/dart"
source "$ROOT_DIR/scripts/lib/manaloom_ui_runtime_contract.sh"

PROFILE=""
READY_MANIFEST=""
RUNTIME_LOG=""
DEVICE_ID=""

usage() {
  cat <<'EOF'
usage:
  manaloom_p0_runtime_capture.sh \
    --profile web_mobile_390x844|web_desktop_1440x900|web_wide_1920x1080 \
    --ready-manifest <ready.json> --runtime-log <log>

  manaloom_p0_runtime_capture.sh \
    --profile android_emulator_manaloom_api34 \
    --ready-manifest <ready.json> --runtime-log <log> \
    --device <adb-id>

The ready manifest must come from manaloom_authenticated_visual_qa_isolated.sh.
Screenshots are staged first and replace only the profile's governed golden
directory after the complete runtime journey succeeds.
EOF
}

while (($#)); do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --ready-manifest)
      READY_MANIFEST="${2:-}"
      shift 2
      ;;
    --runtime-log)
      RUNTIME_LOG="${2:-}"
      shift 2
      ;;
    --device)
      DEVICE_ID="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for tool in jq shasum xxd; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "required tool is missing: $tool" >&2
    exit 2
  }
done
if [[ ! -x "$PINNED_FLUTTER" ]]; then
  echo "Pinned Flutter 3.44.6 is required: $PINNED_FLUTTER" >&2
  exit 2
fi
if [[ ! -x "$PINNED_DART" ]]; then
  echo "Pinned Dart from Flutter 3.44.6 is required: $PINNED_DART" >&2
  exit 2
fi
if [[ -z "$READY_MANIFEST" || ! -f "$READY_MANIFEST" ]]; then
  echo "--ready-manifest must identify an existing fixture manifest" >&2
  exit 2
fi
if [[ -z "$RUNTIME_LOG" || "$RUNTIME_LOG" != /* ]]; then
  echo "--runtime-log must be an absolute path" >&2
  exit 2
fi

fixture_status="$(jq -r '.status // empty' "$READY_MANIFEST")"
fixture_scope="$(jq -r '.scope // empty' "$READY_MANIFEST")"
production_allowed="$(jq -r '.production_coordinates_allowed' "$READY_MANIFEST")"
credentials_file="$(jq -r '.credentials_file // empty' "$READY_MANIFEST")"
api_base_url="$(jq -r '.api_base_url // empty' "$READY_MANIFEST")"
web_url="$(jq -r '.web_url // empty' "$READY_MANIFEST")"
if [[ "$fixture_status" != "ready" ||
      "$fixture_scope" != "disposable_loopback_postgresql_api" ||
      "$production_allowed" != "false" ||
      ! "$api_base_url" =~ ^http://127\.0\.0\.1:[0-9]+$ ||
      ! "$web_url" =~ ^http://127\.0\.0\.1:[0-9]+/app/$ ||
      -z "$credentials_file" || ! -f "$credentials_file" ]]; then
  echo "Fixture manifest is not a ready disposable loopback environment" >&2
  exit 2
fi

# The credentials are disposable, owner-scoped and removed by the fixture.
# shellcheck disable=SC1090
source "$credentials_file"
: "${MANALOOM_VISUAL_EMAIL:?fixture email missing}"
: "${MANALOOM_VISUAL_PASSWORD:?fixture password missing}"
: "${MANALOOM_VISUAL_EMPTY_EMAIL:?fixture empty-user email missing}"
: "${MANALOOM_VISUAL_EMPTY_PASSWORD:?fixture empty-user password missing}"

seed_user_id="$(jq -r '.seed_user_id // empty' "$READY_MANIFEST")"
empty_user_id="$(jq -r '.empty_user_id // empty' "$READY_MANIFEST")"
peer_user_id="$(jq -r '.seed_peer_user_id // empty' "$READY_MANIFEST")"
peer_username="$(jq -r '.seed_peer_username // empty' "$READY_MANIFEST")"
seed_card_id="$(jq -r '.seed_card_id // empty' "$READY_MANIFEST")"
seed_deck_id="$(jq -r '.seed_deck_id // empty' "$READY_MANIFEST")"
for required in \
  "$seed_user_id" "$empty_user_id" "$peer_user_id" "$peer_username" \
  "$seed_card_id" "$seed_deck_id"; do
  if [[ -z "$required" ]]; then
    echo "Fixture manifest is missing a required P0 entity" >&2
    exit 2
  fi
done

case "$PROFILE" in
  web_mobile_390x844)
    platform="web"
    width=390
    height=844
    expected_count=54
    target="web_real_build"
    device_contract="$(manaloom_web_runtime_device_contract "$PROFILE")"
    governed_output="$APP_DIR/test/ui/goldens/runtime/web_mobile"
    ;;
  web_desktop_1440x900)
    platform="web"
    width=1440
    height=900
    expected_count=53
    target="web_real_build"
    device_contract="$(manaloom_web_runtime_device_contract "$PROFILE")"
    governed_output="$APP_DIR/test/ui/goldens/runtime/web_desktop"
    ;;
  web_wide_1920x1080)
    platform="web"
    width=1920
    height=1080
    expected_count=53
    target="web_real_build"
    device_contract="$(manaloom_web_runtime_device_contract "$PROFILE")"
    governed_output="$APP_DIR/test/ui/goldens/runtime/web_wide"
    ;;
  android_emulator_manaloom_api34)
    platform="android"
    width=390
    height=844
    expected_count=54
    target="android_emulator"
    governed_output="$APP_DIR/test/ui/goldens/runtime/android_emulator"
    if [[ -z "$DEVICE_ID" ]]; then
      echo "--device is required for the Android emulator profile" >&2
      exit 2
    fi
    command -v adb >/dev/null 2>&1 || {
      echo "adb is required for Android capture" >&2
      exit 2
    }
    adb -s "$DEVICE_ID" get-state | grep -qx device || {
      echo "Android runtime is not ready: $DEVICE_ID" >&2
      exit 1
    }
    kernel_qemu="$(adb -s "$DEVICE_ID" shell getprop ro.kernel.qemu | tr -d '\r')"
    boot_qemu="$(adb -s "$DEVICE_ID" shell getprop ro.boot.qemu | tr -d '\r')"
    serial="$(adb -s "$DEVICE_ID" get-serialno | tr -d '\r')"
    if [[ "$kernel_qemu" != "1" && "$boot_qemu" != "1" &&
          "$serial" != emulator-* ]]; then
      echo "Profile requires an attested Android emulator" >&2
      exit 1
    fi
    model="$(adb -s "$DEVICE_ID" shell getprop ro.product.model | tr -d '\r')"
    android_version="$(
      adb -s "$DEVICE_ID" shell getprop ro.build.version.release | tr -d '\r'
    )"
    device_size="$(adb -s "$DEVICE_ID" shell wm size | tr -d '\r' | tail -n 1)"
    device_contract="$(
      manaloom_android_runtime_device_contract \
        "$model" \
        "$android_version" \
        emulator \
        "$serial" \
        "$device_size" \
        "portrait-up with native Life Counter landscape checkpoint"
    )"
    ;;
  *)
    echo "Unsupported P0 profile: $PROFILE" >&2
    usage >&2
    exit 2
    ;;
esac

source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_p0_capture.XXXXXX")"
mkdir -p "$(dirname "$RUNTIME_LOG")"

api_port="${api_base_url##*:}"
if [[ "$web_url" =~ ^http://127\.0\.0\.1:([0-9]+)/app/$ ]]; then
  fixture_web_port="${BASH_REMATCH[1]}"
else
  echo "Could not resolve fixture Web port" >&2
  exit 2
fi

old_accelerometer_rotation=""
old_user_rotation=""
old_immersive_mode_confirmations=""
chromedriver_pid=""
chromedriver_log=""
cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  if [[ -n "$chromedriver_pid" ]]; then
    kill "$chromedriver_pid" >/dev/null 2>&1 || true
    wait "$chromedriver_pid" >/dev/null 2>&1 || true
  fi
  if [[ "$platform" == "android" ]]; then
    adb -s "$DEVICE_ID" reverse --remove "tcp:$api_port" >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" reverse --remove "tcp:$fixture_web_port" \
      >/dev/null 2>&1 || true
    if [[ -n "$old_accelerometer_rotation" ]]; then
      adb -s "$DEVICE_ID" shell settings put system accelerometer_rotation \
        "$old_accelerometer_rotation" >/dev/null 2>&1 || true
    fi
    if [[ -n "$old_user_rotation" ]]; then
      adb -s "$DEVICE_ID" shell settings put system user_rotation \
        "$old_user_rotation" >/dev/null 2>&1 || true
    fi
    if [[ "$old_immersive_mode_confirmations" == "null" ||
          -z "$old_immersive_mode_confirmations" ]]; then
      adb -s "$DEVICE_ID" shell settings delete secure \
        immersive_mode_confirmations >/dev/null 2>&1 || true
    else
      adb -s "$DEVICE_ID" shell settings put secure \
        immersive_mode_confirmations "$old_immersive_mode_confirmations" \
        >/dev/null 2>&1 || true
    fi
  fi
  rm -rf "$staging_dir"
  exit "$status"
}
trap cleanup EXIT INT TERM

common_defines=(
  "--dart-define=API_BASE_URL=$api_base_url"
  "--dart-define=MANALOOM_VISUAL_EMAIL=$MANALOOM_VISUAL_EMAIL"
  "--dart-define=MANALOOM_VISUAL_PASSWORD=$MANALOOM_VISUAL_PASSWORD"
  "--dart-define=MANALOOM_VISUAL_EMPTY_EMAIL=$MANALOOM_VISUAL_EMPTY_EMAIL"
  "--dart-define=MANALOOM_VISUAL_EMPTY_PASSWORD=$MANALOOM_VISUAL_EMPTY_PASSWORD"
  "--dart-define=MANALOOM_VISUAL_DECK_ID=$seed_deck_id"
  "--dart-define=MANALOOM_VISUAL_CARD_ID=$seed_card_id"
  "--dart-define=MANALOOM_VISUAL_USER_ID=$seed_user_id"
  "--dart-define=MANALOOM_VISUAL_PEER_USER_ID=$peer_user_id"
  "--dart-define=MANALOOM_VISUAL_PEER_USERNAME=$peer_username"
  "--dart-define=MANALOOM_VISUAL_SEGMENT=all"
  "--dart-define=MANALOOM_VISUAL_WIDTH=$width"
  "--dart-define=MANALOOM_VISUAL_HEIGHT=$height"
  "--dart-define=MANALOOM_UI_SOURCE_DIGEST=$source_digest"
  "--dart-define=MANALOOM_UI_PROOF_PROFILE=$PROFILE"
  "--dart-define=MANALOOM_UI_PROOF_TARGET=$target"
  "--dart-define=MANALOOM_UI_PROOF_DEVICE_CONTRACT=$device_contract"
  "--dart-define=MANALOOM_EMIT_SCREENSHOT_CHUNKS=false"
  "--dart-define=MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true"
  "--dart-define=MANALOOM_VISUAL_FIXTURE_MODE=true"
  "--dart-define=ENABLE_INTERACTIVE_BATTLE=true"
  "--dart-define=DISABLE_FIREBASE_STARTUP=true"
  "--dart-define=DISABLE_PUSH_INIT=true"
  "--dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true"
)

drive_command=(
  "$PINNED_FLUTTER" drive
  --driver=test_driver/integration_test.dart
  --target=integration_test/app_existing_user_visual_audit_test.dart
  --no-pub
  --no-version-check
  --device-connection=attached
  --timeout=1200
  "${common_defines[@]}"
)

if [[ "$platform" == "web" ]]; then
  chromedriver_bin="${MANALOOM_CHROMEDRIVER_BIN:-$(command -v chromedriver || true)}"
  chrome_executable="${CHROME_EXECUTABLE:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
  if [[ -z "$chromedriver_bin" || ! -x "$chromedriver_bin" ]]; then
    echo "Web capture requires an executable ChromeDriver" >&2
    exit 2
  fi
  if [[ ! -x "$chrome_executable" ]]; then
    echo "Web capture requires an executable Chrome binary: $chrome_executable" >&2
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
  chromedriver_log="${RUNTIME_LOG%.log}.chromedriver.log"
  "$chromedriver_bin" --port=4444 >"$chromedriver_log" 2>&1 &
  chromedriver_pid="$!"
  webdriver_ready=false
  for _ in {1..50}; do
    if curl --silent --fail --max-time 1 \
      http://127.0.0.1:4444/status >/dev/null 2>&1; then
      webdriver_ready=true
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
  drive_command+=(
    --release
    -d chrome
    "--browser-dimension=${width}x${height}@1"
    --no-web-resources-cdn
  )
  set +e
  (
    cd "$APP_DIR"
    MANALOOM_SCREENSHOT_DIR="$staging_dir" "${drive_command[@]}"
  ) 2>&1 | tee "$RUNTIME_LOG"
  drive_status="${PIPESTATUS[0]}"
  set -e
else
  old_accelerometer_rotation="$(
    adb -s "$DEVICE_ID" shell settings get system accelerometer_rotation |
      tr -d '\r'
  )"
  old_user_rotation="$(
    adb -s "$DEVICE_ID" shell settings get system user_rotation | tr -d '\r'
  )"
  old_immersive_mode_confirmations="$(
    adb -s "$DEVICE_ID" shell settings get secure \
      immersive_mode_confirmations | tr -d '\r'
  )"
  adb -s "$DEVICE_ID" shell settings put system accelerometer_rotation 0 \
    >/dev/null
  adb -s "$DEVICE_ID" shell settings put system user_rotation 0 >/dev/null
  # Prevent Android's first-use fullscreen education overlay from obscuring
  # the governed Life Counter screenshot. The previous emulator setting is
  # restored by cleanup.
  adb -s "$DEVICE_ID" shell settings put secure immersive_mode_confirmations \
    confirmed >/dev/null
  adb -s "$DEVICE_ID" reverse "tcp:$api_port" "tcp:$api_port" >/dev/null
  adb -s "$DEVICE_ID" reverse \
    "tcp:$fixture_web_port" "tcp:$fixture_web_port" >/dev/null
  drive_command+=(
    --profile
    -d "$DEVICE_ID"
    --dart-define=MANALOOM_VISUAL_NATIVE_DECK_DETAIL_CAPTURE=true
  )

  set +e
  (
    cd "$APP_DIR"
    MANALOOM_SCREENSHOT_DIR="$staging_dir" "${drive_command[@]}"
  ) 2>&1 |
    while IFS= read -r line; do
      printf '%s\n' "$line"
      if [[ "$line" =~ NATIVE_SCREENSHOT_READY[[:space:]]+([A-Za-z0-9_.-]+) ]]; then
        checkpoint="${BASH_REMATCH[1]}"
        sleep 1
        adb -s "$DEVICE_ID" exec-out screencap -p \
          >"$staging_dir/$checkpoint.png"
        printf 'ADB_SCREENSHOT_CAPTURED %s\n' "$checkpoint"
      fi
    done | tee "$RUNTIME_LOG"
  drive_status="${PIPESTATUS[0]}"
  set -e
fi

if [[ "$drive_status" -ne 0 ]]; then
  echo "P0 runtime journey failed for $PROFILE" >&2
  exit "$drive_status"
fi
# Web release drives may omit application print() calls, while Android Logcat
# may truncate their long JSON payload. After the runtime journey succeeds,
# replace every host-forwarded copy with exactly one complete runner-attested
# context before the indexer is allowed to consume the log.
sed '/VISUAL_PROOF_CONTEXT /d' "$RUNTIME_LOG" \
  >"$staging_dir/runtime-without-context.log"
mv "$staging_dir/runtime-without-context.log" "$RUNTIME_LOG"
checkpoint_json="$(
  find "$staging_dir" -maxdepth 1 -type f -name '*.png' -print |
    sed -E 's#^.*/##; s#\.png$##' |
    sort |
    jq --raw-input --slurp \
      'split("\n") | map(select(length > 0))'
)"
context_json="$(
  jq --compact-output --null-input \
    --arg source_digest "$source_digest" \
    --arg profile "$PROFILE" \
    --arg target "$target" \
    --arg device_contract "$device_contract" \
    --argjson required_checkpoints "$checkpoint_json" \
    '{
      schema_version: "manaloom_ui_runtime_context_v1",
      surface: "authenticated_p0_matrix",
      source_digest: $source_digest,
      profile: $profile,
      runtime: "flutter_drive",
      target: $target,
      device_contract: $device_contract,
      required_checkpoints: $required_checkpoints
    }'
)"
printf 'VISUAL_PROOF_CONTEXT %s\n' "$context_json" | tee -a "$RUNTIME_LOG"
if ! grep -Fq "VISUAL_PROOF_CONTEXT " "$RUNTIME_LOG"; then
  echo "P0 runtime log is missing its evidence context" >&2
  exit 1
fi
if grep -Eq \
  '(^|[[:space:]])(EXCEPTION CAUGHT|Some tests failed|══╡ EXCEPTION)' \
  "$RUNTIME_LOG"; then
  echo "P0 runtime log contains a forbidden test failure" >&2
  exit 1
fi

actual_count="$(
  find "$staging_dir" -maxdepth 1 -type f -name '*.png' | wc -l |
    tr -d '[:space:]'
)"
if [[ "$actual_count" != "$expected_count" ]]; then
  echo "Expected $expected_count screenshots for $PROFILE, got $actual_count" >&2
  exit 1
fi
while IFS= read -r screenshot; do
  if [[ ! -s "$screenshot" ]] ||
     [[ "$(head -c 8 "$screenshot" | xxd -p)" != "89504e470d0a1a0a" ]]; then
    echo "Invalid PNG captured: $screenshot" >&2
    exit 1
  fi
done < <(find "$staging_dir" -maxdepth 1 -type f -name '*.png' | sort)
(
  cd "$APP_DIR"
  "$PINNED_DART" run tool/ui_runtime_evidence.dart validate-directory \
    --screenshots "$staging_dir"
)

mkdir -p "$governed_output"
find "$governed_output" -maxdepth 1 -type f -name '*.png' -delete
cp "$staging_dir"/*.png "$governed_output/"

printf 'status=PASS_RUNTIME\n'
printf 'profile=%s\n' "$PROFILE"
printf 'source_digest=%s\n' "$source_digest"
printf 'screenshot_count=%s\n' "$actual_count"
printf 'screenshot_dir=%s\n' "$governed_output"
printf 'runtime_log=%s\n' "$RUNTIME_LOG"
if [[ -n "$chromedriver_log" ]]; then
  printf 'chromedriver_log=%s\n' "$chromedriver_log"
fi

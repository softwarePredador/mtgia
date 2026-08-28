#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"
PINNED_DART="${PINNED_FLUTTER%/flutter}/cache/dart-sdk/bin/dart"
ADB_BIN="${MANALOOM_ADB_BIN:-$(command -v adb || true)}"
source "$ROOT_DIR/scripts/lib/manaloom_ui_runtime_contract.sh"

adb() {
  "$ADB_BIN" "$@"
}

PROFILE=""
READY_MANIFEST=""
RUNTIME_LOG=""
DEVICE_ID=""
ANDROID_EGRESS_CHILD="${MANALOOM_ANDROID_EGRESS_CHILD:-0}"
ANDROID_STAGING_DIR="${MANALOOM_ANDROID_STAGING_DIR:-}"
ANDROID_APPLICATION_BINARY="${MANALOOM_ANDROID_APPLICATION_BINARY:-}"
ANDROID_PARENT_RUN_ID="${MANALOOM_ANDROID_EGRESS_RUN_ID:-}"
ANDROID_ADAPTER_RECEIPT_INPUT="${MANALOOM_ANDROID_ADAPTER_RECEIPT:-}"
ANDROID_ADAPTER_RECEIPT_SHA256="${MANALOOM_ANDROID_ADAPTER_RECEIPT_SHA256:-}"
ANDROID_APPLICATION_SHA256="${MANALOOM_ANDROID_APPLICATION_SHA256:-}"
VALIDATE_ANDROID_CHILD_ONLY=false
ANDROID_EGRESS_RECEIPT=""
ANDROID_EGRESS_RUN_ID=""
ANDROID_GRADLE_ADAPTER_RECEIPT=""
ANDROID_GRADLE_ADAPTER_RECEIPT_SHA256=""
ANDROID_GRADLE_ADAPTER_RUN_ID=""
PHYSICAL_APK_PATH=""
PHYSICAL_APK_SHA256=""

usage() {
  cat <<'EOF'
usage:
  manaloom_p0_runtime_capture.sh \
    --profile web_mobile_390x844|web_desktop_1440x900|web_wide_1920x1080 \
    --ready-manifest <ready.json> --runtime-log <log>

  manaloom_p0_runtime_capture.sh \
    --profile android_emulator_manaloom_api34|android_physical_sm_a135m \
    --ready-manifest <ready.json> --runtime-log <log> \
    --device <adb-id>

  manaloom_p0_runtime_capture.sh --validate-android-child-contract

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
    --validate-android-child-contract)
      VALIDATE_ANDROID_CHILD_ONLY=true
      shift
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

for tool in awk jq shasum xxd; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "required tool is missing: $tool" >&2
    exit 2
  }
done

validate_android_child_contract() {
  local temp_root_real resolved_staging resolved_apk resolved_receipt
  [[ "$ANDROID_EGRESS_CHILD" == "1" ]] || {
    echo "Android child validation requires child mode" >&2
    return 1
  }
  [[ "$ANDROID_PARENT_RUN_ID" =~ ^android-egress-[0-9TZ-]+-[0-9]+-[0-9]+$ ]] || {
    echo "Android child run identity is missing or malformed" >&2
    return 1
  }
  [[ "$ANDROID_STAGING_DIR" == /* && -d "$ANDROID_STAGING_DIR" &&
     ! -L "$ANDROID_STAGING_DIR" ]] || {
    echo "Android child staging is missing, unsafe or a symlink" >&2
    return 1
  }
  temp_root_real="$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)" || return 1
  resolved_staging="$(CDPATH='' cd -- "$ANDROID_STAGING_DIR" && pwd -P)" || return 1
  [[ "$(dirname -- "$resolved_staging")" == "$temp_root_real" &&
     "$(basename -- "$resolved_staging")" == manaloom_p0_capture.* ]] || {
    echo "Android child staging is outside the governed temporary root" >&2
    return 1
  }
  [[ "$ANDROID_APPLICATION_BINARY" == /* &&
     -f "$ANDROID_APPLICATION_BINARY" &&
     ! -L "$ANDROID_APPLICATION_BINARY" ]] || {
    echo "Android child APK is missing, unsafe or a symlink" >&2
    return 1
  }
  resolved_apk="$(
    CDPATH='' cd -- "$(dirname -- "$ANDROID_APPLICATION_BINARY")" &&
      printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$ANDROID_APPLICATION_BINARY")"
  )" || return 1
  [[ "$resolved_apk" == "$resolved_staging/profile-app.apk" ]] || {
    echo "Android child APK is not the governed staging artifact" >&2
    return 1
  }
  [[ "$ANDROID_APPLICATION_SHA256" =~ ^[0-9a-f]{64}$ &&
     "$(shasum -a 256 "$resolved_apk" | awk '{print $1}')" == \
       "$ANDROID_APPLICATION_SHA256" ]] || {
    echo "Android child APK hash is missing or mismatched" >&2
    return 1
  }
  [[ "$ANDROID_ADAPTER_RECEIPT_INPUT" == /* &&
     -f "$ANDROID_ADAPTER_RECEIPT_INPUT" &&
     ! -L "$ANDROID_ADAPTER_RECEIPT_INPUT" &&
     "$ANDROID_ADAPTER_RECEIPT_SHA256" =~ ^[0-9a-f]{64}$ ]] || {
    echo "Android child adapter receipt is missing or unsafe" >&2
    return 1
  }
  resolved_receipt="$(
    CDPATH='' cd -- "$(dirname -- "$ANDROID_ADAPTER_RECEIPT_INPUT")" &&
      printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$ANDROID_ADAPTER_RECEIPT_INPUT")"
  )" || return 1
  [[ "$(shasum -a 256 "$resolved_receipt" | awk '{print $1}')" == \
       "$ANDROID_ADAPTER_RECEIPT_SHA256" ]] || {
    echo "Android child adapter receipt hash mismatch" >&2
    return 1
  }
  jq -e \
    --arg apk "$resolved_apk" \
    --arg apk_sha "$ANDROID_APPLICATION_SHA256" '
      .schema_version == "manaloom.gradle_dynamic_selector_adapter_receipt.v1" and
      .status == "PASS_GRADLE_DYNAMIC_SELECTOR_ADAPTER" and
      .artifact.apk_path == $apk and
      .artifact.apk_sha256 == $apk_sha and
      .network.resolver_or_egress_attempts == 0 and
      .network.unified_log.canary_entries == 1 and
      .network.unified_log.network_attempt_entries == 0 and
      .mutation.app_build.restored_exactly == true and
      .build.process_group.waited == true and
      .build.process_group.remaining_processes == 0
    ' "$resolved_receipt" >/dev/null || {
    echo "Android child adapter receipt is non-terminal or cross-artifact" >&2
    return 1
  }
  staging_dir="$resolved_staging"
  ANDROID_APPLICATION_BINARY="$resolved_apk"
  ANDROID_ADAPTER_RECEIPT_INPUT="$resolved_receipt"
}

if [[ "$ANDROID_EGRESS_CHILD" == "1" ||
      "$VALIDATE_ANDROID_CHILD_ONLY" == "true" ]]; then
  validate_android_child_contract || exit 1
fi
if [[ "$VALIDATE_ANDROID_CHILD_ONLY" == "true" ]]; then
  printf 'status=PASS_ANDROID_CHILD_CONTRACT\n'
  exit 0
fi
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

platform=""
target=""
staging_dir=""
api_port=""
fixture_web_port=""
old_accelerometer_rotation=""
old_user_rotation=""
old_immersive_mode_confirmations=""
chromedriver_pid=""
chromedriver_log=""
cleanup_active=false
cleanup() {
  local original_exit="$?" cleanup_failed=0 resolved_staging temp_root_real
  trap - EXIT HUP INT TERM QUIT
  if [[ "$cleanup_active" == "true" ]]; then
    exit 1
  fi
  cleanup_active=true
  if [[ -n "$chromedriver_pid" ]]; then
    kill "$chromedriver_pid" >/dev/null 2>&1 || true
    wait "$chromedriver_pid" >/dev/null 2>&1 || true
  fi
  if [[ "$platform" == "android" && "$target" != "android_physical" ]]; then
    if [[ -n "$api_port" ]]; then
      adb -s "$DEVICE_ID" reverse --remove "tcp:$api_port" >/dev/null 2>&1 || true
    fi
    if [[ -n "$fixture_web_port" ]]; then
      adb -s "$DEVICE_ID" reverse --remove "tcp:$fixture_web_port" \
        >/dev/null 2>&1 || true
    fi
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
  if [[ "$ANDROID_EGRESS_CHILD" != "1" && -n "$staging_dir" ]]; then
    if [[ -d "$staging_dir" && ! -L "$staging_dir" ]]; then
      resolved_staging="$(CDPATH='' cd -- "$staging_dir" && pwd -P)" || cleanup_failed=1
      temp_root_real="$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)" || cleanup_failed=1
      if [[ "$cleanup_failed" -eq 0 &&
            "$resolved_staging" == "$temp_root_real"/manaloom_p0_capture.* ]]; then
        if [[ -n "$(find "$resolved_staging" -type f -name RECOVERY_REQUIRED -print -quit)" ||
              -n "$(find "$resolved_staging" -type d \
                \( -name preexisting-app-build -o -name fresh-app-build-owned \) \
                -print -quit)" ]]; then
          printf 'NO_GO_P0_CLEANUP: preserved adapter recovery at %s\n' \
            "$resolved_staging" >&2
          cleanup_failed=1
        else
          find "$resolved_staging" -depth -delete || cleanup_failed=1
        fi
      else
        cleanup_failed=1
      fi
    elif [[ -e "$staging_dir" || -L "$staging_dir" ]]; then
      cleanup_failed=1
    fi
  fi
  [[ "$cleanup_failed" -eq 0 ]] || exit 1
  exit "$original_exit"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 131' QUIT

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
  android_emulator_manaloom_api34|android_physical_sm_a135m)
    platform="android"
    expected_count=54
    if [[ "$PROFILE" == "android_emulator_manaloom_api34" ]]; then
      width=390
      height=844
      expected_runtime_kind="emulator"
      target="android_emulator"
      governed_output="$APP_DIR/test/ui/goldens/runtime/android_emulator"
    else
      width=360
      height=803
      expected_runtime_kind="physical"
      target="android_physical"
      governed_output="$APP_DIR/test/ui/goldens/runtime/android_physical"
    fi
    if [[ -z "$DEVICE_ID" ]]; then
      echo "--device is required for the Android profile" >&2
      exit 2
    fi
    if [[ "$ADB_BIN" != /* || ! -x "$ADB_BIN" ]]; then
      echo "an absolute executable adb is required for Android capture" >&2
      exit 2
    fi
    adb -s "$DEVICE_ID" get-state | grep -qx device || {
      echo "Android runtime is not ready: $DEVICE_ID" >&2
      exit 1
    }
    kernel_qemu="$(adb -s "$DEVICE_ID" shell getprop ro.kernel.qemu | tr -d '\r')"
    boot_qemu="$(adb -s "$DEVICE_ID" shell getprop ro.boot.qemu | tr -d '\r')"
    serial="$(adb -s "$DEVICE_ID" get-serialno | tr -d '\r')"
    observed_runtime_kind="physical"
    if [[ "$kernel_qemu" == "1" || "$boot_qemu" == "1" ||
          "$serial" == emulator-* ]]; then
      observed_runtime_kind="emulator"
    fi
    if [[ "$observed_runtime_kind" != "$expected_runtime_kind" ]]; then
      echo "Profile requires an attested Android $expected_runtime_kind runtime" >&2
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
        "$observed_runtime_kind" \
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
if [[ "$ANDROID_EGRESS_CHILD" == "1" ]]; then
  [[ "$platform" == "android" && "$target" == "android_physical" ]] || {
    echo "Android egress child mode is restricted to physical capture" >&2
    exit 2
  }
  [[ -n "$staging_dir" && -d "$staging_dir" && ! -L "$staging_dir" &&
     -f "$ANDROID_APPLICATION_BINARY" && ! -L "$ANDROID_APPLICATION_BINARY" ]] || {
    echo "Android egress child contract lost its governed paths" >&2
    exit 2
  }
else
  staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_p0_capture.XXXXXX")"
fi
mkdir -p "$(dirname "$RUNTIME_LOG")"

api_port="${api_base_url##*:}"
if [[ "$web_url" =~ ^http://127\.0\.0\.1:([0-9]+)/app/$ ]]; then
  fixture_web_port="${BASH_REMATCH[1]}"
else
  echo "Could not resolve fixture Web port" >&2
  exit 2
fi

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

build_and_attest_physical_profile_apk() {
  local apk_path="$staging_dir/profile-app.apk"
  local merged_manifest="$staging_dir/profile-merged-manifest.xml"
  local apk_manifest="$staging_dir/profile-apk-manifest.xml"
  local build_log="${RUNTIME_LOG%.log}.profile-build.log"
  local adapter_receipt="${RUNTIME_LOG%.log}.gradle-dynamic-selector-receipt.json"
  local adapter_work="$staging_dir/gradle-dynamic-selector-adapter"
  local apkanalyzer_bin="${MANALOOM_APKANALYZER_BIN:-$HOME/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer}"
  local source_gradle_home="${MANALOOM_GRADLE_CACHE_HOME:-$HOME/.gradle}"
  local sqlite_asset="$APP_DIR/.dart_tool/hooks_runner/shared/sqlite3/build/download-807999cf/libsqlite3.so"
  local sqlite_asset_sha256="807999cfe7e0ccf811e7c820d6b11d31c6bb2388c6659fbc6829cd18dae4f61e"
  local observed_sqlite_sha256
  local device_abis

  [[ -x "$apkanalyzer_bin" ]] || {
    echo "apkanalyzer is required to attest the physical profile APK" >&2
    return 1
  }
  for output in \
    "$build_log" "$adapter_receipt" "$apk_path" \
    "$merged_manifest" "$apk_manifest"; do
    [[ ! -e "$output" && ! -L "$output" ]] || {
      echo "Fresh profile build output already exists: $output" >&2
      return 1
    }
  done
  device_abis="$(adb -s "$DEVICE_ID" shell getprop ro.product.cpu.abilist | tr -d '\r')"
  [[ ",$device_abis," == *,armeabi-v7a,* ]] || {
    echo "Physical device does not support the governed offline android-arm artifact" >&2
    return 1
  }
  [[ -f "$sqlite_asset" && ! -L "$sqlite_asset" ]] || {
    echo "Pinned android-arm sqlite3 native asset cache is absent or corrupt" >&2
    return 1
  }
  observed_sqlite_sha256="$(shasum -a 256 "$sqlite_asset" | awk '{print $1}')"
  [[ "$observed_sqlite_sha256" == "$sqlite_asset_sha256" ]] || {
    echo "Pinned android-arm sqlite3 native asset cache is absent or corrupt" >&2
    return 1
  }
  [[ "$source_gradle_home" == /* && -d "$source_gradle_home/caches/modules-2" &&
     -d "$source_gradle_home/wrapper/dists/gradle-8.14-all" &&
     ! -e "$adapter_work" ]] || {
    echo "Pinned Gradle distribution/dependency cache or adapter workspace is unavailable" >&2
    return 1
  }
  "$ROOT_DIR/scripts/manaloom_gradle_dynamic_selector_adapter.sh" run \
    --flutter-bin "$PINNED_FLUTTER" \
    --app-dir "$APP_DIR" \
    --gradle-source-home "$source_gradle_home" \
    --work-dir "$adapter_work" \
    --build-log "$build_log" \
    --receipt "$adapter_receipt" \
    --apk "$apk_path" \
    --merged-manifest "$merged_manifest" \
    --apk-manifest "$apk_manifest" \
    --apkanalyzer "$apkanalyzer_bin" \
    --policy "$ROOT_DIR/app/test/ui/fixtures/ui_live_evidence_policy.json" \
    -- \
      build apk \
      --profile \
      --no-android-gradle-daemon \
      --target-platform=android-arm \
      --target=integration_test/app_existing_user_visual_audit_test.dart \
      --no-pub \
      --no-version-check \
      "${common_defines[@]}" \
      --dart-define=MANALOOM_VISUAL_NATIVE_DECK_DETAIL_CAPTURE=true
  [[ -f "$apk_path" && ! -L "$apk_path" &&
     -f "$merged_manifest" && ! -L "$merged_manifest" ]] || {
    echo "Governed adapter did not externalize the fresh profile artifacts" >&2
    return 1
  }
  jq -e '
    .schema_version == "manaloom.gradle_dynamic_selector_adapter_receipt.v1" and
    .status == "PASS_GRADLE_DYNAMIC_SELECTOR_ADAPTER" and
    .network.resolver_or_egress_attempts == 0 and
    .network.attempt_detector ==
      "run_bound_sandbox_decision_canary_plus_build_log_v3" and
    .network.unified_log.entries == 0 and
    .mutation.sdk_lock_metadata_cache_changed == false and
    .mutation.global_source_cache_before.sha256 ==
      .mutation.global_source_cache_after.sha256 and
    .mutation.ephemeral_read_only_cache_before.sha256 ==
      .mutation.ephemeral_read_only_cache_after.sha256 and
    .mutation.ephemeral_writable_cache_after.entries == 0 and
    .mutation.app_build.quarantined_before_build == true and
    .mutation.app_build.fresh_tree_removed == true and
    .mutation.app_build.restored_exactly == true and
    .mutation.app_build.before.sha256 ==
      .mutation.app_build.after.sha256 and
    .build.exit == 0 and
    .build.fresh_app_build_tree == true and
    .build.app_build_cleanup == "PASS_EXACT_RESTORE_OR_ABSENCE" and
    .artifact.manifest_attestation.parser ==
      "python.xml.etree.ElementTree.namespace_aware" and
    .artifact.release_semantics.status == "PASS_SOURCE_DEFAULTS_ONLY" and
    .artifact.release_semantics.release_artifact_equivalence == "NOT_CLAIMED" and
    .artifact.release_semantics.release_build == "BLOCKED_NOT_RUN_PROFILE_ONLY"
  ' "$adapter_receipt" >/dev/null || {
    echo "Gradle dynamic-selector adapter receipt is not terminal PASS" >&2
    return 1
  }
  local resolved_apk resolved_merged resolved_packaged
  resolved_apk="$(
    CDPATH='' cd -- "$(dirname -- "$apk_path")" &&
      printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$apk_path")"
  )" || return 1
  resolved_merged="$(
    CDPATH='' cd -- "$(dirname -- "$merged_manifest")" &&
      printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$merged_manifest")"
  )" || return 1
  resolved_packaged="$(
    CDPATH='' cd -- "$(dirname -- "$apk_manifest")" &&
      printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$apk_manifest")"
  )" || return 1
  jq -e \
    --arg apk "$resolved_apk" \
    --arg apk_sha "$(shasum -a 256 "$resolved_apk" | awk '{print $1}')" \
    --arg merged "$resolved_merged" \
    --arg merged_sha "$(shasum -a 256 "$resolved_merged" | awk '{print $1}')" \
    --arg packaged "$resolved_packaged" \
    --arg packaged_sha "$(shasum -a 256 "$resolved_packaged" | awk '{print $1}')" '
      .artifact.apk_path == $apk and
      .artifact.apk_sha256 == $apk_sha and
      .artifact.merged_manifest_path == $merged and
      .artifact.merged_manifest_sha256 == $merged_sha and
      .artifact.packaged_manifest_path == $packaged and
      .artifact.packaged_manifest_sha256 == $packaged_sha
    ' "$adapter_receipt" >/dev/null || {
    echo "Gradle adapter receipt artifact binding failed" >&2
    return 1
  }
  ANDROID_GRADLE_ADAPTER_RECEIPT="$adapter_receipt"
  ANDROID_GRADLE_ADAPTER_RECEIPT_SHA256="$(
    shasum -a 256 "$adapter_receipt" | awk '{print $1}'
  )"
  ANDROID_GRADLE_ADAPTER_RUN_ID="$(jq -r '.run_id // empty' "$adapter_receipt")"
  [[ "$ANDROID_GRADLE_ADAPTER_RUN_ID" =~ ^gradle-profile-[0-9TZ-]+-[0-9]+-[0-9]+$ ]] ||
    return 1
  PHYSICAL_APK_PATH="$resolved_apk"
  PHYSICAL_APK_SHA256="$(shasum -a 256 "$resolved_apk" | awk '{print $1}')"
}

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
  if [[ "$target" == "android_physical" && "$ANDROID_EGRESS_CHILD" != "1" ]]; then
    build_and_attest_physical_profile_apk
    [[ -n "$PHYSICAL_APK_PATH" &&
       "$PHYSICAL_APK_SHA256" =~ ^[0-9a-f]{64}$ &&
       -n "$ANDROID_GRADLE_ADAPTER_RECEIPT" &&
       "$ANDROID_GRADLE_ADAPTER_RECEIPT_SHA256" =~ ^[0-9a-f]{64}$ ]] || {
      echo "Physical profile APK attestation did not return bound artifacts" >&2
      exit 1
    }
    adb -s "$DEVICE_ID" install -t -r "$PHYSICAL_APK_PATH" >/dev/null
    ANDROID_EGRESS_RECEIPT="${RUNTIME_LOG%.log}.android-egress-receipt.json"
    ANDROID_EGRESS_RUN_ID="android-egress-$(date -u +%Y%m%dT%H%M%SZ)-$$-$RANDOM"
    android_native_log="${RUNTIME_LOG%.log}.android-native.log"
    android_pid_trace="${RUNTIME_LOG%.log}.android-pids.tsv"
    for output in "$RUNTIME_LOG" "$ANDROID_EGRESS_RECEIPT" "$android_native_log" \
      "$android_pid_trace"; do
      [[ ! -e "$output" && ! -L "$output" ]] || {
        echo "Fresh physical capture output already exists: $output" >&2
        exit 1
      }
    done
    set +e
    MANALOOM_ADB_BIN="$ADB_BIN" \
    MANALOOM_DART_BIN="$PINNED_DART" \
      "$ROOT_DIR/scripts/manaloom_android_ui_egress_guard.sh" run \
      --run-id "$ANDROID_EGRESS_RUN_ID" \
      --serial "$DEVICE_ID" \
      --package "$(jq -r '.android_physical_egress.package' \
        "$ROOT_DIR/app/test/ui/fixtures/ui_live_evidence_policy.json")" \
      --source-digest "$source_digest" \
      --profile "$PROFILE" \
      --runtime-log "$RUNTIME_LOG" \
      --native-log "$android_native_log" \
      --pid-trace "$android_pid_trace" \
      --receipt "$ANDROID_EGRESS_RECEIPT" \
      --api-port "$api_port" \
      --web-port "$fixture_web_port" \
      -- \
      /usr/bin/env \
        MANALOOM_ADB_BIN="$ADB_BIN" \
        MANALOOM_ANDROID_EGRESS_CHILD=1 \
        MANALOOM_ANDROID_EGRESS_RUN_ID="$ANDROID_EGRESS_RUN_ID" \
        MANALOOM_ANDROID_STAGING_DIR="$staging_dir" \
        MANALOOM_ANDROID_APPLICATION_BINARY="$PHYSICAL_APK_PATH" \
        MANALOOM_ANDROID_APPLICATION_SHA256="$PHYSICAL_APK_SHA256" \
        MANALOOM_ANDROID_ADAPTER_RECEIPT="$ANDROID_GRADLE_ADAPTER_RECEIPT" \
        MANALOOM_ANDROID_ADAPTER_RECEIPT_SHA256="$ANDROID_GRADLE_ADAPTER_RECEIPT_SHA256" \
        /bin/bash "$ROOT_DIR/scripts/manaloom_p0_runtime_capture.sh" \
          --profile "$PROFILE" \
          --ready-manifest "$READY_MANIFEST" \
          --runtime-log "$RUNTIME_LOG" \
          --device "$DEVICE_ID"
    drive_status="$?"
    set -e
    if [[ "$drive_status" -eq 0 ]]; then
      receipt_run_id="$(jq -r '.run_id // empty' "$ANDROID_EGRESS_RECEIPT")"
      [[ "$receipt_run_id" == "$ANDROID_EGRESS_RUN_ID" ]] || {
        echo "Physical capture receipt run identity is stale or cross-run" >&2
        exit 1
      }
      [[ "$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")" == "$source_digest" ]] || {
        echo "UI source digest drifted during physical capture" >&2
        exit 1
      }
      "$PINNED_DART" --packages="$APP_DIR/.dart_tool/package_config.json" \
        "$APP_DIR/tool/ui_runtime_evidence.dart" \
        verify-android-egress-receipt \
        --receipt "$ANDROID_EGRESS_RECEIPT" \
        --runtime-log "$RUNTIME_LOG" \
        --policy "$ROOT_DIR/app/test/ui/fixtures/ui_live_evidence_policy.json" \
        --run-id "$ANDROID_EGRESS_RUN_ID" \
        --source-digest "$source_digest" \
        --profile "$PROFILE" \
        --target "$target" >/dev/null
    fi
  else
    if [[ "$target" != "android_physical" ]]; then
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
      adb -s "$DEVICE_ID" shell settings put secure immersive_mode_confirmations \
        confirmed >/dev/null
      adb -s "$DEVICE_ID" reverse "tcp:$api_port" "tcp:$api_port" >/dev/null
      adb -s "$DEVICE_ID" reverse \
        "tcp:$fixture_web_port" "tcp:$fixture_web_port" >/dev/null
    fi
    drive_command+=(
      --profile
      -d "$DEVICE_ID"
      --dart-define=MANALOOM_VISUAL_NATIVE_DECK_DETAIL_CAPTURE=true
    )
    if [[ "$ANDROID_EGRESS_CHILD" == "1" ]]; then
      drive_command+=(
        "--use-application-binary=$ANDROID_APPLICATION_BINARY"
        --keep-app-running
      )
    fi

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
fi

if [[ "$drive_status" -ne 0 ]]; then
  echo "P0 runtime journey failed for $PROFILE" >&2
  exit "$drive_status"
fi
if [[ ! ("$target" == "android_physical" && "$ANDROID_EGRESS_CHILD" != "1") ]]; then
  # Web release drives may omit application print() calls, while Android
  # Logcat may truncate their long JSON payload. The child journey seals one
  # runner-attested context before the physical guard derives its receipt.
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

if [[ "$ANDROID_EGRESS_CHILD" == "1" ]]; then
  printf 'status=PASS_STAGED_ANDROID_RUNTIME\n'
  printf 'source_digest=%s\n' "$source_digest"
  printf 'screenshot_count=%s\n' "$actual_count"
  exit 0
fi

mkdir -p "$governed_output"
find "$governed_output" -maxdepth 1 -type f -name '*.png' -delete
cp "$staging_dir"/*.png "$governed_output/"

printf 'status=PASS_RUNTIME\n'
printf 'profile=%s\n' "$PROFILE"
printf 'source_digest=%s\n' "$source_digest"
printf 'screenshot_count=%s\n' "$actual_count"
printf 'screenshot_dir=%s\n' "$governed_output"
printf 'runtime_log=%s\n' "$RUNTIME_LOG"
if [[ -n "$ANDROID_EGRESS_RECEIPT" ]]; then
  printf 'android_egress_receipt=%s\n' "$ANDROID_EGRESS_RECEIPT"
  printf 'android_egress_run_id=%s\n' "$ANDROID_EGRESS_RUN_ID"
fi
if [[ -n "$ANDROID_GRADLE_ADAPTER_RECEIPT" ]]; then
  printf 'gradle_dynamic_selector_receipt=%s\n' "$ANDROID_GRADLE_ADAPTER_RECEIPT"
fi
if [[ -n "$chromedriver_log" ]]; then
  printf 'chromedriver_log=%s\n' "$chromedriver_log"
fi

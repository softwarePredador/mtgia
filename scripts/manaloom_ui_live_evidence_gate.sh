#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:---check}"
PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"
REVIEW_FILE="$ROOT_DIR/docs/qa/ui-live/latest.json"
CAPTURE_OUTPUT="docs/qa/ui-live/current/battle-coach-android"

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
  local device_id="${MANALOOM_UI_PROOF_DEVICE:-}"
  if [[ -z "$device_id" ]]; then
    echo "MANALOOM_UI_PROOF_DEVICE must identify a connected physical Android device" >&2
    exit 2
  fi
  local device_contract="${MANALOOM_UI_PROOF_DEVICE_CONTRACT:-physical_android}"
  local source_digest run_dir runtime_log status
  source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  run_dir="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_ui_proof.XXXXXX")"
  runtime_log="$run_dir/battle-coach-runtime.log"

  cleanup_capture() {
    local cleanup_status="$?"
    trap - EXIT INT TERM
    rm -rf "$run_dir"
    exit "$cleanup_status"
  }
  trap cleanup_capture EXIT INT TERM

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

case "$MODE" in
  --check)
    verify_current_evidence
    ;;
  --capture-battle-coach)
    capture_battle_coach
    ;;
  -h|--help|help)
    printf '%s\n' \
      "usage: $0 --check" \
      "       MANALOOM_UI_PROOF_DEVICE=<id> $0 --capture-battle-coach"
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 2
    ;;
esac

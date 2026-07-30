#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_ui_digest.XXXXXX")"

cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  rm -rf "$RUN_DIR"
  exit "$status"
}
trap cleanup EXIT INT TERM

if command -v shasum >/dev/null 2>&1; then
  HASH_COMMAND=(shasum -a 256)
elif command -v sha256sum >/dev/null 2>&1; then
  HASH_COMMAND=(sha256sum)
else
  echo "sha256 tool not found (shasum or sha256sum required)" >&2
  exit 2
fi

cd "$ROOT_DIR"

SOURCE_ROOTS=(
  "app/lib"
  "app/assets"
  "app/web"
  "app/android/app/src/main/res"
  "app/android/settings.gradle.kts"
  "app/android/build.gradle.kts"
  "app/android/app/build.gradle.kts"
  "app/android/app/gradle.lockfile"
  "app/android/gradle/verification-metadata.xml"
  "app/android/gradle/wrapper/gradle-wrapper.properties"
  "app/pubspec.yaml"
  "app/pubspec.lock"
  "app/integration_test/battle_coach_visual_runtime_proof_test.dart"
  "app/integration_test/core_product_acceptance_runtime_test.dart"
  "app/integration_test/app_existing_user_visual_audit_test.dart"
  "app/integration_test/runtime_test_helpers.dart"
  "app/integration_test/visual_capture_helpers.dart"
  "app/test_driver/integration_test.dart"
  "app/test_driver/runtime_screenshot_crop.dart"
  "app/tool/ui_runtime_evidence.dart"
  "app/tool/serve_flutter_web_app.py"
  "app/test/ui/fixtures/ui_authenticated_visual_matrix.json"
  "app/test/ui/fixtures/ui_keyboard_focus_matrix.json"
  "app/test/ui/fixtures/ui_live_evidence_policy.json"
  "server/config/premium_visual_qa_surfaces.json"
  "scripts/manaloom_authenticated_visual_qa_isolated.sh"
  "scripts/manaloom_server_contract_e2e_isolated.sh"
  "scripts/manaloom_ui_live_evidence_gate.sh"
  "scripts/manaloom_ui_source_digest.sh"
)

for source_root in "${SOURCE_ROOTS[@]}"; do
  if [[ -f "$source_root" ]]; then
    printf '%s\n' "$source_root"
  elif [[ -d "$source_root" ]]; then
    find "$source_root" -type f \
      ! -name '.DS_Store' \
      ! -path '*/.dart_tool/*' \
      ! -path '*/build/*'
  else
    echo "UI digest source is missing: $source_root" >&2
    exit 1
  fi
done | LC_ALL=C sort -u >"$RUN_DIR/files.txt"

if [[ ! -s "$RUN_DIR/files.txt" ]]; then
  echo "UI digest source inventory is empty" >&2
  exit 1
fi

while IFS= read -r relative_path; do
  file_hash="$("${HASH_COMMAND[@]}" "$relative_path" | awk '{print $1}')"
  printf '%s  %s\n' "$file_hash" "$relative_path"
done <"$RUN_DIR/files.txt" >"$RUN_DIR/content.txt"

"${HASH_COMMAND[@]}" "$RUN_DIR/content.txt" | awk '{print $1}'

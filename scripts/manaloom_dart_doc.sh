#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:---check}"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
resolve_manaloom_flutter_root
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"
export FLUTTER_ROOT="$MANALOOM_FLUTTER_ROOT_RESOLVED"

if [[ "$MODE" != "--check" ]]; then
  echo "Uso: ./scripts/manaloom_dart_doc.sh --check" >&2
  exit 2
fi

if ! command -v "$DART_BIN" >/dev/null 2>&1; then
  echo "Dart não encontrado: $DART_BIN" >&2
  exit 2
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-dart-doc.XXXXXX")"
cleanup() {
  find "$TMP_DIR" -type f -delete 2>/dev/null || true
  rmdir "$TMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

packages=(
  "app"
  "server"
  "tools/manaloom_lints"
  "tools/project_logic"
)

for package in "${packages[@]}"; do
  package_dir="$ROOT_DIR/$package"
  package_id="${package//\//_}"
  log_file="$TMP_DIR/$package_id.log"

  if [[ ! -f "$package_dir/.dart_tool/package_config.json" ]]; then
    (
      cd "$package_dir"
      "$DART_BIN" pub get --enforce-lockfile
    )
  fi

  if ! (
    cd "$package_dir"
    "$DART_BIN" doc --dry-run
  ) >"$log_file" 2>&1; then
    echo "dart doc falhou em $package:" >&2
    sed -n '1,160p' "$log_file" >&2
    exit 1
  fi

  warnings="$(awk '/^  warning:/{count++} END{print count+0}' "$log_file")"
  errors="$(awk '/^  error:/{count++} END{print count+0}' "$log_file")"
  if [[ "$warnings" -ne 0 || "$errors" -ne 0 ]]; then
    echo "dart doc encontrou $warnings warning(s) e $errors erro(s) em $package:" >&2
    sed -n '1,160p' "$log_file" >&2
    exit 1
  fi
  echo "dart doc: $package sem warnings/erros."
done

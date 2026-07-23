#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:---check}"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

case "$MODE" in
  --check|--write)
    ;;
  *)
    echo "Uso: ./scripts/manaloom_project_logic.sh [--check|--write]" >&2
    exit 2
    ;;
esac

if ! command -v "$DART_BIN" >/dev/null 2>&1; then
  echo "Dart não encontrado: $DART_BIN" >&2
  exit 2
fi

PACKAGE_DIR="$ROOT_DIR/tools/project_logic"
if [[ ! -f "$PACKAGE_DIR/.dart_tool/package_config.json" ]]; then
  (
    cd "$PACKAGE_DIR"
    "$DART_BIN" pub get --enforce-lockfile
  )
fi

(
  cd "$PACKAGE_DIR"
  "$DART_BIN" run bin/manaloom_project_logic.dart \
    "$MODE" \
    --root "$ROOT_DIR"
)

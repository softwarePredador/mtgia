#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

ensure_package_resolved() {
  local package_dir="$1"
  local resolver="$2"

  if [[ ! -f "$package_dir/.dart_tool/package_config.json" ]]; then
    print_header "Resolving dependencies: ${package_dir#"$ROOT_DIR"/}"
    cd "$package_dir"
    "$resolver" pub get
  fi
}

ensure_package_resolved "$ROOT_DIR/tools/manaloom_lints" dart
ensure_package_resolved "$ROOT_DIR/app" flutter
ensure_package_resolved "$ROOT_DIR/server" dart

print_header "ManaLoom custom lint package"
cd "$ROOT_DIR/tools/manaloom_lints"
dart analyze
dart test

print_header "ManaLoom Flutter custom_lint"
cd "$ROOT_DIR/app"
dart run custom_lint

print_header "ManaLoom backend custom_lint"
cd "$ROOT_DIR/server"
SERVER_BUILD_PUBSPEC="$ROOT_DIR/server/build/pubspec.yaml"
SERVER_BUILD_PUBSPEC_HIDDEN=""

restore_server_build_pubspec() {
  if [[ -n "${SERVER_BUILD_PUBSPEC_HIDDEN:-}" && -f "$SERVER_BUILD_PUBSPEC_HIDDEN" ]]; then
    mv "$SERVER_BUILD_PUBSPEC_HIDDEN" "$SERVER_BUILD_PUBSPEC"
  fi
}

trap restore_server_build_pubspec EXIT

if [[ -f "$SERVER_BUILD_PUBSPEC" ]]; then
  SERVER_BUILD_PUBSPEC_HIDDEN="$SERVER_BUILD_PUBSPEC.custom-lint-ignore.$$"
  mv "$SERVER_BUILD_PUBSPEC" "$SERVER_BUILD_PUBSPEC_HIDDEN"
fi

dart run custom_lint
restore_server_build_pubspec
trap - EXIT

print_header "Custom lint concluido"
echo "Regras customizadas do ManaLoom passaram no app e no backend."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

run_dependency_validator() {
  local package_dir="$1"
  local label="$2"
  local resolver="$3"

  print_header "Dependency validator: ${label}"
  cd "$ROOT_DIR/$package_dir"
  if [[ ! -f ".dart_tool/package_config.json" ]]; then
    $resolver pub get
  fi
  dart run dependency_validator
}

run_dependency_validator app "Flutter app" flutter
run_dependency_validator server "Dart Frog server" dart
run_dependency_validator tools/manaloom_lints "ManaLoom custom lint package" dart
run_dependency_validator tools/project_logic "ManaLoom project logic generator" dart

print_header "Dependency audit concluído"
echo "Todos os pacotes auditados declaram apenas dependências coerentes com o uso atual."

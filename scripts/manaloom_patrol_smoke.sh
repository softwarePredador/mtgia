#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

print_header "ManaLoom Patrol critical E2E suite"
cd "$ROOT_DIR/app"
if [[ ! -f ".dart_tool/package_config.json" ]]; then
  flutter pub get
fi
flutter test patrol_test/manaloom_patrol_smoke_test.dart \
  --no-version-check \
  --dart-define=PATROL_HOT_RESTART=true

if [[ "${MANALOOM_RUN_PATROL_DEVICE_TESTS:-0}" == "1" ]]; then
  print_header "ManaLoom Patrol device/web CLI run"
  patrol_args=(
    test
    --target
    patrol_test/manaloom_patrol_smoke_test.dart
    --dart-define=DISABLE_FIREBASE_STARTUP=true
    --dart-define=DISABLE_PUSH_INIT=true
    --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true
  )

  if [[ -n "${MANALOOM_PATROL_DEVICE:-}" ]]; then
    patrol_args+=(--device "$MANALOOM_PATROL_DEVICE")
  fi

  if [[ -n "${MANALOOM_PATROL_WEB_HEADLESS:-}" ]]; then
    patrol_args+=(--web-headless="$MANALOOM_PATROL_WEB_HEADLESS")
  fi

  PATROL_ANALYTICS_ENABLED=false dart run patrol_cli:main test \
    "${patrol_args[@]:1}"
else
  echo ""
  echo "Patrol CLI real nao foi executado porque MANALOOM_RUN_PATROL_DEVICE_TESTS=1 nao foi definido."
  echo "Para rodar em device/emulador: MANALOOM_RUN_PATROL_DEVICE_TESTS=1 ./scripts/quality_gate.sh patrol-smoke"
  echo "Para rodar no Chrome headless: MANALOOM_RUN_PATROL_DEVICE_TESTS=1 MANALOOM_PATROL_DEVICE=chrome MANALOOM_PATROL_WEB_HEADLESS=true ./scripts/quality_gate.sh patrol-smoke"
fi

print_header "Patrol critical E2E suite concluida"
echo "Harness Patrol compilou e executou os fluxos criticos locais."

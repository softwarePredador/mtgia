#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_BIN="${MANALOOM_FLUTTER_BIN:-flutter}"

if [[ "$FLUTTER_BIN" == */* ]]; then
  if [[ ! -x "$FLUTTER_BIN" ]]; then
    echo "Flutter configurado não é executável: $FLUTTER_BIN" >&2
    exit 2
  fi
  FLUTTER_BIN="$(cd "$(dirname "$FLUTTER_BIN")" && pwd)/$(basename "$FLUTTER_BIN")"
fi
readonly FLUTTER_BIN

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

print_header "ManaLoom Patrol critical E2E suite"
cd "$ROOT_DIR/app"
if [[ ! -f ".dart_tool/package_config.json" ]]; then
  "$FLUTTER_BIN" pub get
fi
"$FLUTTER_BIN" test patrol_test/manaloom_patrol_smoke_test.dart \
  --no-pub \
  --no-version-check \
  --dart-define=PATROL_HOT_RESTART=true

if [[ "${MANALOOM_RUN_PATROL_DEVICE_TESTS:-0}" == "1" ]]; then
  print_header "ManaLoom Patrol device/web CLI run"
  patrol_cli_log="$(mktemp /tmp/manaloom_patrol_cli.XXXXXX.log)"
  trap 'rm -f "${patrol_cli_log:-}"' EXIT
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

  set -o pipefail
  PATROL_ANALYTICS_ENABLED=false dart run patrol_cli:main test \
    "${patrol_args[@]:1}" 2>&1 | tee "$patrol_cli_log"

  python3 - "$patrol_cli_log" \
    "$ROOT_DIR/app/patrol_test/manaloom_patrol_smoke_test.dart" <<'PY'
import re
import sys
from pathlib import Path

ansi = re.compile(r"\x1b\[[0-9;]*m")
output = ansi.sub("", Path(sys.argv[1]).read_text(encoding="utf-8"))
source = Path(sys.argv[2]).read_text(encoding="utf-8")
expected = len(re.findall(r"\bpatrolTest\s*\(", source))
summary = re.search(r"Total:\s*(\d+)", output)

if expected <= 0:
    raise SystemExit("BLOCKED: a suite Patrol nao declara testes.")
if summary is None:
    raise SystemExit("BLOCKED: o Patrol CLI nao publicou o total executado.")

actual = int(summary.group(1))
if actual != expected:
    raise SystemExit(
        f"BLOCKED: Patrol executou {actual} de {expected} testes esperados."
    )

print(f"Patrol CLI confirmou {actual}/{expected} testes no alvo real.")
PY

  rm -f "$patrol_cli_log"
  patrol_cli_log=""
else
  echo ""
  echo "Patrol CLI real nao foi executado porque MANALOOM_RUN_PATROL_DEVICE_TESTS=1 nao foi definido."
  echo "Para rodar em device/emulador: MANALOOM_RUN_PATROL_DEVICE_TESTS=1 ./scripts/quality_gate.sh patrol-smoke"
  echo "Para rodar no Chrome headless: MANALOOM_RUN_PATROL_DEVICE_TESTS=1 MANALOOM_PATROL_DEVICE=chrome MANALOOM_PATROL_WEB_HEADLESS=true ./scripts/quality_gate.sh patrol-smoke"
fi

print_header "Patrol critical E2E suite concluida"
echo "Harness Patrol compilou e executou os fluxos criticos locais."

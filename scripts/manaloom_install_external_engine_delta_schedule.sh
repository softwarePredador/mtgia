#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:-}"
LABEL="com.manaloom.external-engine-delta-weekly"
USER_ID="$(id -u)"
DOMAIN="gui/$USER_ID"
LAUNCH_AGENTS_DIR="${MANALOOM_LAUNCH_AGENTS_DIR:-${HOME:?}/Library/LaunchAgents}"
REPORT_DIR="${MANALOOM_ENGINE_DELTA_REPORT_DIR:-${HOME:?}/Library/Application Support/ManaLoom/external-engine-delta}"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$LABEL.plist"
RUNNER="$ROOT_DIR/scripts/manaloom_external_engine_delta_weekly.sh"
LAUNCHCTL_BIN="${MANALOOM_LAUNCHCTL_BIN:-$(command -v launchctl || true)}"
PLUTIL_BIN="${MANALOOM_PLUTIL_BIN:-$(command -v plutil || true)}"

usage() {
  cat <<'USAGE'
Uso: manaloom_install_external_engine_delta_schedule.sh MODO

Modos:
  --install     instala/carrega o LaunchAgent e dispara a primeira auditoria
  --check       valida plist, carga e último relatório disponível
  --run-now     dispara a auditoria instalada imediatamente
  --uninstall   descarrega/remove apenas o LaunchAgent; preserva relatórios
USAGE
}

require_runtime() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "o agendamento launchd exige macOS" >&2
    exit 2
  fi
  if [[ -z "$LAUNCHCTL_BIN" || ! -x "$LAUNCHCTL_BIN" ]]; then
    echo "launchctl não encontrado" >&2
    exit 2
  fi
  if [[ -z "$PLUTIL_BIN" || ! -x "$PLUTIL_BIN" ]]; then
    echo "plutil não encontrado" >&2
    exit 2
  fi
  if [[ ! -x "$RUNNER" ]]; then
    echo "runner ausente ou não executável: $RUNNER" >&2
    exit 2
  fi
  if [[ "$LAUNCH_AGENTS_DIR" != /* || "$REPORT_DIR" != /* ]]; then
    echo "diretórios do LaunchAgent e dos relatórios devem ser absolutos" >&2
    exit 2
  fi
  if [[ "$(basename "$REPORT_DIR")" != "external-engine-delta" ]]; then
    echo "diretório de relatórios deve terminar em external-engine-delta" >&2
    exit 2
  fi
}

render_plist() {
  local destination="$1"
  python3 - \
    "$destination" \
    "$LABEL" \
    "$RUNNER" \
    "$ROOT_DIR" \
    "$REPORT_DIR" <<'PY'
import plistlib
import sys
from pathlib import Path

destination, label, runner, root_dir, report_dir = sys.argv[1:]
payload = {
    "Label": label,
    "ProgramArguments": [
        "/bin/bash",
        runner,
        "--report-dir",
        report_dir,
        "--retention-days",
        "180",
    ],
    "WorkingDirectory": root_dir,
    "StartCalendarInterval": {
        "Weekday": 0,
        "Hour": 9,
        "Minute": 17,
    },
    "ProcessType": "Background",
    "LowPriorityIO": True,
    "Nice": 10,
    "ThrottleInterval": 60,
    "StandardOutPath": str(Path(report_dir) / "scheduler.stdout.log"),
    "StandardErrorPath": str(Path(report_dir) / "scheduler.stderr.log"),
}
with open(destination, "wb") as handle:
    plistlib.dump(payload, handle, fmt=plistlib.FMT_XML, sort_keys=True)
PY
}

validate_installed_plist() {
  if [[ ! -f "$PLIST_PATH" ]]; then
    echo "LaunchAgent não instalado: $PLIST_PATH" >&2
    return 1
  fi
  "$PLUTIL_BIN" -lint "$PLIST_PATH" >/dev/null
  local expected
  expected="$(mktemp "${TMPDIR:-/tmp}/manaloom-engine-delta-plist.XXXXXX")"
  render_plist "$expected"
  if ! cmp -s "$expected" "$PLIST_PATH"; then
    rm -f "$expected"
    echo "plist instalado diverge do contrato versionado" >&2
    return 1
  fi
  rm -f "$expected"
}

show_latest_status() {
  local latest="$REPORT_DIR/latest.json"
  if [[ ! -f "$latest" ]]; then
    echo "último relatório: pendente (use --run-now e repita --check)"
    return 1
  fi
  python3 - "$latest" <<'PY'
import json
import sys
import time
from pathlib import Path

with open(sys.argv[1], encoding="utf-8") as handle:
    report = json.load(handle)
status = str(report.get("status", "unknown"))
age_seconds = max(0, int(time.time() - Path(sys.argv[1]).stat().st_mtime))
print(
    "último relatório: status={status} review_required={review} age_seconds={age} path={path}".format(
        status=status,
        review=str(bool(report.get("review_required"))).lower(),
        age=age_seconds,
        path=sys.argv[1],
    )
)
if age_seconds > 8 * 86400:
    print("último relatório excedeu a janela semanal de 8 dias", file=sys.stderr)
    raise SystemExit(1)
if status not in {"pass", "review_required"}:
    print("último relatório não representa uma execução saudável", file=sys.stderr)
    raise SystemExit(1)
PY
}

install_schedule() {
  mkdir -p "$LAUNCH_AGENTS_DIR" "$REPORT_DIR"
  chmod 700 "$REPORT_DIR"
  local resolved_report_dir
  resolved_report_dir="$(CDPATH='' cd -- "$REPORT_DIR" && pwd -P)"
  case "$resolved_report_dir" in
    "$ROOT_DIR"|"$ROOT_DIR"/*)
      echo "diretório de relatórios não pode ficar dentro do checkout" >&2
      return 2
      ;;
  esac
  local temporary
  temporary="$(mktemp "${TMPDIR:-/tmp}/manaloom-engine-delta-plist.XXXXXX")"
  render_plist "$temporary"
  if ! "$PLUTIL_BIN" -lint "$temporary" >/dev/null; then
    rm -f "$temporary"
    return 1
  fi

  "$LAUNCHCTL_BIN" bootout "$DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
  install -m 600 "$temporary" "$PLIST_PATH"
  rm -f "$temporary"
  "$LAUNCHCTL_BIN" enable "$DOMAIN/$LABEL"
  "$LAUNCHCTL_BIN" bootstrap "$DOMAIN" "$PLIST_PATH"
  "$LAUNCHCTL_BIN" kickstart "$DOMAIN/$LABEL"
  echo "LaunchAgent instalado: $PLIST_PATH"
  echo "Agenda: domingo às 09:17 no horário local; primeira execução disparada."
  echo "Relatórios: $REPORT_DIR"
}

check_schedule() {
  validate_installed_plist
  "$LAUNCHCTL_BIN" print "$DOMAIN/$LABEL" >/dev/null
  echo "LaunchAgent carregado e alinhado: $DOMAIN/$LABEL"
  show_latest_status
}

run_now() {
  validate_installed_plist
  "$LAUNCHCTL_BIN" print "$DOMAIN/$LABEL" >/dev/null
  "$LAUNCHCTL_BIN" kickstart "$DOMAIN/$LABEL"
  echo "Auditoria disparada; acompanhe $REPORT_DIR/latest.json"
}

uninstall_schedule() {
  "$LAUNCHCTL_BIN" bootout "$DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
  "$LAUNCHCTL_BIN" disable "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
  rm -f "$PLIST_PATH"
  echo "LaunchAgent removido; relatórios preservados em $REPORT_DIR"
}

case "$MODE" in
  --install)
    require_runtime
    install_schedule
    ;;
  --check)
    require_runtime
    check_schedule
    ;;
  --run-now)
    require_runtime
    run_now
    ;;
  --uninstall)
    require_runtime
    uninstall_schedule
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

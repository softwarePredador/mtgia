#!/usr/bin/env bash
# BT-DR-001 (D-12, D-81): um ciclo da cadência do backup local, com receipt.
#
# Uso:
#   scripts/manaloom_backup_cycle.sh                       descreve o ciclo, sem conectar
#   scripts/manaloom_backup_cycle.sh --execute [--drill]
#
# --execute roda scripts/manaloom_easypanel_backup.sh, que lê a produção por
# pg_dump e exige a aprovação live própria dele. Com --drill, roda também
# scripts/manaloom_full_restore_drill.sh --execute sobre o dump novo, num
# PostgreSQL 17 isolado e sem rede (exige MANALOOM_RESTORE_DRILL_EXECUTE=1).
# --execute exige MANALOOM_BACKUP_DIR: o diretório durável onde ficam todos os
# dumps, para a cadência enxergar o histórico (nunca /tmp nem worktree). A
# evidência do ensaio fica em <dir>/drills/<carimbo>/ e o receipt em
# <dir>/receipts/<carimbo>.json. No fim confere a cadência da política
# (server/config/backup_policy.json): sai 0 se cumprida e 3 se não.
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
BACKUP_DIR="${MANALOOM_BACKUP_DIR:-}"
CADENCE_TOOL="$ROOT_DIR/scripts/manaloom_backup_cadence.py"
EXECUTE=0
DRILL=0

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

while (( $# > 0 )); do
  case "$1" in
    --execute) EXECUTE=1; shift ;;
    --drill) DRILL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$EXECUTE" != "1" ]]; then
  python3 - "$BACKUP_DIR" "$DRILL" <<'PY'
import json
import sys

print(json.dumps({
    "status": "dry_run",
    "backup_dir": sys.argv[1] or "defina MANALOOM_BACKUP_DIR antes de --execute",
    "steps": [
        "scripts/manaloom_easypanel_backup.sh (pg_dump da produção, aprovação live)",
        *(["scripts/manaloom_full_restore_drill.sh --execute (PostgreSQL isolado, sem rede)"]
          if sys.argv[2] == "1" else []),
        "scripts/manaloom_backup_cadence.py receipt (confere RPO, RTO e cadência)",
    ],
    "execute": "--execute [--drill]",
}, ensure_ascii=False, indent=2))
PY
  exit 0
fi

if [[ -z "$BACKUP_DIR" ]]; then
  echo "defina MANALOOM_BACKUP_DIR com o diretório durável dos backups" >&2
  exit 2
fi
python3 "$CADENCE_TOOL" validate-policy >/dev/null
# O diretório tem de ser durável: nada em /tmp nem em worktree temporária.
# Aqui o check só serve para isso; antes do ciclo, BLOCKED (3) é esperado.
python3 "$CADENCE_TOOL" check --backup-dir "$BACKUP_DIR" >/dev/null || {
  status=$?
  if [[ "$status" != "3" ]]; then
    echo "diretório de backup recusado: $BACKUP_DIR" >&2
    exit 2
  fi
}
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="$(mktemp "${TMPDIR:-/tmp}/manaloom-backup-cycle.XXXXXX")"
trap 'rm -f "$LOG"' EXIT
MANALOOM_BACKUP_DIR="$BACKUP_DIR" "$ROOT_DIR/scripts/manaloom_easypanel_backup.sh" | tee "$LOG"
backup_file="$(sed -n 's/^\[backup\] ok file=\([^ ]*\) bytes=.*$/\1/p' "$LOG" | tail -n 1)"
if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
  echo "o backup não informou o arquivo gerado" >&2
  exit 1
fi

receipt_args=(
  receipt
  --backup-dir "$BACKUP_DIR"
  --backup-file "$backup_file"
  --git-sha "$(git -C "$ROOT_DIR" rev-parse HEAD)"
  --out "$BACKUP_DIR/receipts/$STAMP.json"
)
if [[ "$DRILL" == "1" ]]; then
  evidence_dir="$BACKUP_DIR/drills/$STAMP"
  "$ROOT_DIR/scripts/manaloom_full_restore_drill.sh" \
    --backup "$backup_file" --execute --evidence-dir "$evidence_dir"
  receipt_args+=(--drill-evidence "$evidence_dir/restore-result.json")
fi
python3 "$CADENCE_TOOL" "${receipt_args[@]}"

#!/usr/bin/env bash
# S-05: o passo de migrations do lote de deploy (L-03). Na produção, quem roda é a
# coordenação, no lote, depois do backup e do ensaio de restauração (L-01 e L-02),
# com a palavra do dono.
#
# Uso:
#   scripts/manaloom_lot_apply_migrations.sh [--policy P]
#       descreve o lote e confere com o código deste SHA, sem conectar
#   scripts/manaloom_lot_apply_migrations.sh --execute --read-ledger --out L
#       lê o ledger do banco só para leitura e grava o snapshot que a promoção
#       pede em --schema-snapshot (vale 30 minutos)
#   scripts/manaloom_lot_apply_migrations.sh --execute --apply --receipt-dir D [--policy P]
#       aplica o lote e grava o receipt com o ledger de antes e o de depois
#
# O lote vem de server/config/lot_migrations.json: a migration em que o banco tem de
# estar (from), as do lote em ordem numérica e as que vão juntas (same_lot: a 074 com
# a 067 e a 069, pela BT-DB-007). Antes de qualquer escrita, o passo recusa (código 3,
# nada muda):
#   - lacuna: uma migration do lote que não existe no server/bin/migrate.dart deste SHA,
#     ou uma do código, entre o from e a última do lote, que não está no lote;
#   - lote que não termina na última migration do código, ou que quebra o same_lot;
#   - readiness do backend deste SHA (server/lib/health_readiness_support.dart) que
#     exige outra migration que não a última do lote;
#   - ledger fora do from, com lacuna ou com versão de outro código (inclusive o lote
#     já aplicado).
# Aplicação: server/bin/with_new_server_pg.sh --write-approved dart run
# bin/migrate.dart --target <última>, a partir de server/. O migrate.dart aplica em
# ordem numérica, cada migration numa transação com o seu registro no ledger, e para
# um banco de perfil misto antes de qualquer DDL. As leituras do ledger, antes e
# depois, vão pelo mesmo wrapper no modo --read-only. Depois, o ledger tem de ser o de
# antes mais o lote.
#
# O --apply exige MANALOOM_CONFIRM_LIVE_MUTATIONS e MANALOOM_CONFIRM_POSTGRES_WRITES de
# quem chama, o checkout limpo no origin/master (o mesmo SHA que a promoção sobe) e um
# --receipt-dir durável. O wrapper exige a âncora do host
# (MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256) e lê só as chaves do banco do server/.env.
# No diretório ficam o receipt (lote-migrations-<sha>-<carimbo>.json), a saída do
# migrate.dart (.log, que pode trazer o erro do PostgreSQL; fica fora do git) e o
# ledger de depois no formato do --schema-snapshot (ledger-<sha>-<carimbo>.json).
#
# Janela: o backend antigo responde 503 desde a primeira migration até o backend novo
# (cerca de 5 minutos). Não há volta automática: depois da 059, rollback é restore do
# dump do L-01 (docs/runbooks/BACKUP_E_RESTAURACAO.md), e a promoção recusa voltar o
# backend para uma imagem que exige uma migration menor (S-02).
#
# Códigos: 0 aplicado e conferido (ou plano PASS); 1 o migrate.dart falhou ou o ledger
# de depois não é o esperado (o receipt diz onde parou); 2 entrada ou ambiente
# recusado, nada mudou; 3 BLOCKED pelo plano ou pelo ledger, nada mudou.
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
LOGIC="$ROOT_DIR/scripts/manaloom_lot_migrations.py"
POLICY="$ROOT_DIR/server/config/lot_migrations.json"
LEDGER_SQL="SELECT version || '|' || name FROM public.schema_migrations ORDER BY version"
EXECUTE=0
MODE=""
RECEIPT_DIR=""
OUT=""

usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
}

while (( $# > 0 )); do
  case "$1" in
    --execute) EXECUTE=1; shift ;;
    --apply) MODE=apply; shift ;;
    --read-ledger) MODE=ledger; shift ;;
    --receipt-dir) RECEIPT_DIR="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --policy) POLICY="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -f "$POLICY" ]] || { echo "política do lote não encontrada: $POLICY" >&2; exit 2; }

if [[ "$EXECUTE" != "1" ]]; then
  [[ -z "$MODE" ]] || { echo "--apply e --read-ledger exigem --execute" >&2; exit 2; }
  plan_rc=0
  python3 "$LOGIC" plan --policy "$POLICY" || plan_rc=$?
  exit "$plan_rc"
fi

case "$MODE" in
  ledger) [[ -n "$OUT" ]] || { echo "--read-ledger exige --out" >&2; exit 2; } ;;
  apply) ;;
  *) echo "--execute exige --apply ou --read-ledger" >&2; exit 2 ;;
esac

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-lot-migrations.XXXXXX")"
chmod 700 "$RUN_DIR"
trap 'rm -rf "$RUN_DIR"' EXIT

# O ledger, só para leitura (o wrapper põe default_transaction_read_only=on).
read_ledger() {
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
    psql -X -v ON_ERROR_STOP=1 -qAt -c "$LEDGER_SQL" >"$1"
}

if [[ "$MODE" == "ledger" ]]; then
  read_rc=0
  read_ledger "$RUN_DIR/ledger.txt" || read_rc=$?
  if [[ "$read_rc" != "0" ]]; then
    echo "não li o ledger do banco (o wrapper do PostgreSQL saiu com $read_rc)" >&2
    exit 2
  fi
  python3 "$LOGIC" snapshot --raw "$RUN_DIR/ledger.txt" --out "$OUT"
  exit 0
fi

# ------------------------------------------------------------ --apply

# A aprovação vem só de quem chama, antes de ler o ambiente ou o banco.
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "passo de migrations do lote (S-05)"
require_postgres_write_approval "passo de migrations do lote (S-05)"

[[ -n "$RECEIPT_DIR" && -d "$RECEIPT_DIR" ]] || {
  echo "--apply exige um --receipt-dir existente" >&2; exit 2; }
RECEIPT_DIR="$(cd "$RECEIPT_DIR" && pwd -P)"
if python3 - "$RECEIPT_DIR" <<'PY'
import re
import sys

temporary = re.compile(
    r"(^|/)(tmp|private/tmp|var/folders)/|(^|/)\.claude/worktrees/|(^|/)worktrees?/")
raise SystemExit(0 if temporary.search(sys.argv[1] + "/") else 1)
PY
then
  echo "o receipt tem de ficar num diretório durável, não em $RECEIPT_DIR" >&2
  exit 2
fi

SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)"
[[ -z "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=all)" ]] || {
  echo "checkout sujo: as migrations do lote saem só de SHA limpo" >&2; exit 2; }
[[ "$(git -C "$ROOT_DIR" rev-parse origin/master 2>/dev/null || true)" == "$SHA" ]] || {
  echo "o checkout não é o origin/master (o SHA que a promoção sobe)" >&2; exit 2; }

# shellcheck source=scripts/lib/manaloom_dart_toolchain.sh
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RECEIPT="$RECEIPT_DIR/lote-migrations-${SHA:0:12}-$STAMP.json"
LOG_NAME="lote-migrations-${SHA:0:12}-$STAMP.log"
LEDGER_AFTER="$RECEIPT_DIR/ledger-${SHA:0:12}-$STAMP.json"

receipt() {
  local status="$1"
  shift
  python3 "$LOGIC" receipt --out "$RECEIPT" --status "$status" --sha "$SHA" \
    --started-at "$STARTED_AT" --plan "$RUN_DIR/plan.json" "$@" >/dev/null
}

plan_rc=0
python3 "$LOGIC" plan --policy "$POLICY" >"$RUN_DIR/plan.json" || plan_rc=$?
if [[ "$plan_rc" == "2" ]]; then
  cat "$RUN_DIR/plan.json" >&2
  exit 2
fi
if [[ "$plan_rc" != "0" ]]; then
  receipt blocked
  jq -r '.problems[]' "$RUN_DIR/plan.json" >&2
  echo "BLOCKED: o lote não bate com o código deste SHA; nada mudou ($RECEIPT)" >&2
  exit 3
fi
TO="$(jq -r '.to' "$RUN_DIR/plan.json")"
[[ "$TO" =~ ^[0-9]{3}$ ]] || { echo "plano sem a última migration" >&2; exit 2; }

read_rc=0
read_ledger "$RUN_DIR/before.txt" || read_rc=$?
if [[ "$read_rc" != "0" ]]; then
  echo "não li o ledger do banco antes (o wrapper do PostgreSQL saiu com $read_rc); nada mudou" >&2
  exit 2
fi
before_rc=0
python3 "$LOGIC" check-before --plan "$RUN_DIR/plan.json" \
  --ledger-raw "$RUN_DIR/before.txt" >"$RUN_DIR/before.json" || before_rc=$?
if [[ "$before_rc" != "0" ]]; then
  if [[ "$before_rc" == "3" ]]; then
    receipt blocked --before "$RUN_DIR/before.json"
  else
    receipt blocked --reason "ledger ilegível: $(jq -r '.error // "?"' "$RUN_DIR/before.json")"
  fi
  jq -r '.problems[]? // .error' "$RUN_DIR/before.json" >&2
  echo "BLOCKED: o banco não está onde o lote parte; nada mudou ($RECEIPT)" >&2
  exit 3
fi

echo "== $(date -u +%T) migrations $(jq -r '[.migrations[].version] | join(", ")' \
  "$RUN_DIR/plan.json") até a $TO (log em $RECEIPT_DIR/$LOG_NAME)" >&2
: >"$RECEIPT_DIR/$LOG_NAME"
chmod 600 "$RECEIPT_DIR/$LOG_NAME"
migrate_rc=0
(
  cd "$ROOT_DIR/server"
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" --write-approved \
    "$DART_BIN" run bin/migrate.dart --target "$TO"
) >>"$RECEIPT_DIR/$LOG_NAME" 2>&1 || migrate_rc=$?

after_read_rc=0
read_ledger "$RUN_DIR/after.txt" || after_read_rc=$?
if [[ "$after_read_rc" != "0" ]]; then
  receipt failed --before "$RUN_DIR/before.json" --migrate-exit "$migrate_rc" \
    --log "$LOG_NAME" --reason "não li o ledger depois (o wrapper do PostgreSQL saiu com $after_read_rc)"
  echo "CRITICAL: o migrate.dart saiu com $migrate_rc e o ledger de depois não foi lido;" \
    "confira à mão antes de seguir ($RECEIPT)" >&2
  exit 1
fi
after_rc=0
python3 "$LOGIC" check-after --plan "$RUN_DIR/plan.json" --before-raw "$RUN_DIR/before.txt" \
  --after-raw "$RUN_DIR/after.txt" >"$RUN_DIR/after.json" || after_rc=$?
python3 "$LOGIC" snapshot --raw "$RUN_DIR/after.txt" --out "$LEDGER_AFTER" >/dev/null || true
if [[ "$migrate_rc" == "0" && "$after_rc" == "0" ]]; then
  receipt applied --before "$RUN_DIR/before.json" --after "$RUN_DIR/after.json" \
    --migrate-exit 0 --log "$LOG_NAME"
  jq -cn --arg receipt "$RECEIPT" --arg ledger "$LEDGER_AFTER" \
    --slurpfile before "$RUN_DIR/before.json" --slurpfile after "$RUN_DIR/after.json" \
    '{status:"applied", from:$before[0].ledger.latest, to:$after[0].ledger.latest,
      applied:$after[0].applied, receipt:$receipt, schema_snapshot:$ledger}'
  exit 0
fi
receipt failed --before "$RUN_DIR/before.json" --after "$RUN_DIR/after.json" \
  --migrate-exit "$migrate_rc" --log "$LOG_NAME"
jq -r '.problems[]? // .error' "$RUN_DIR/after.json" >&2
echo "FAIL: o migrate.dart saiu com $migrate_rc e o banco ficou na" \
  "$(jq -r '.ledger.latest // "?"' "$RUN_DIR/after.json"); o receipt diz onde parou ($RECEIPT)" >&2
exit 1

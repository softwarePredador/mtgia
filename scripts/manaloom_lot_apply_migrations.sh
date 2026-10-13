#!/usr/bin/env bash
# S-05: o passo de migrations do lote de deploy (L-03). Na produção, quem roda é a
# coordenação, no lote, depois do backup e do ensaio de restauração (L-01) e do ensaio
# do upgrade (L-02), com a palavra do dono.
#
# Uso:
#   scripts/manaloom_lot_apply_migrations.sh [--policy P]
#       descreve o lote e confere com o código deste SHA, sem conectar
#   scripts/manaloom_lot_apply_migrations.sh --execute --read-ledger --out L
#       lê o ledger do banco só para leitura e grava o snapshot que a promoção
#       pede em --schema-snapshot (vale 30 minutos; L não pode existir)
#   scripts/manaloom_lot_apply_migrations.sh --execute --preview [--policy P]
#       a prévia dos passos antes da primeira migration (o dedupe da D-74): faz e
#       desfaz (ROLLBACK) e imprime as contagens que o --apply exige em --esperado
#   scripts/manaloom_lot_apply_migrations.sh --execute --apply --receipt-dir D
#       --backup-receipt B --upgrade-rehearsal E --esperado PASSO:OBJETO=N ...
#       [--policy P]
#       roda os passos antes da primeira migration com as contagens da prévia, aplica o
#       lote e grava o receipt com os passos e o ledger de antes e o de depois
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
#   - prova do L-01 ou do L-02 que não passou, que tem mais de 24 h (o RPO da D-12) ou
#     que não casa: B é o receipt do scripts/manaloom_backup_cycle.sh --execute --drill
#     (ensaio de restauração aprovado e cadência PASS) e E, o rehearsal.json do
#     scripts/manaloom_migration_rehearsal.py --restore completo com resultado PASS,
#     sobre o dump desse backup (o mesmo SHA-256);
#   - ledger fora do from, com lacuna ou com versão de outro código (inclusive o lote
#     já aplicado);
#   - um script de server/sql/lote/ que uma migration do lote pede no código e que o
#     lote não roda antes da primeira migration (before_first_migration: a 077 pede o
#     dedupe da D-74), ou que não segue o contrato do lote; e, no --apply, uma contagem
#     esperada que falta ou que o script não declara (código 2).
# Antes da primeira migration (D-74): depois da conferência do ledger, com o banco ainda
# no from e o backend antigo no ar (fora da janela de 503), cada passo de
# before_first_migration roda pelo server/bin/with_new_server_pg.sh --write-approved
# psql -X -v ON_ERROR_STOP=1, numa transação. No --preview, sem -v aplicar: faz, imprime
# antes, ação e depois e desfaz (ROLLBACK). No --apply, com -v aplicar=1 e cada
# -v esperado_<objeto>=<n> de --esperado: o script recusa (RAISE, nada gravado) se a ação
# não bater, e o passo para antes do migrate (código 3). A saída vai para o log do lote e
# o resultado de cada passo para o receipt.
# Aplicação: server/bin/with_new_server_pg.sh --write-approved dart run
# bin/migrate.dart --target <última>, a partir de server/. O migrate.dart aplica em
# ordem numérica, cada migration numa transação com o seu registro no ledger, e para
# um banco de perfil misto antes de qualquer DDL. As leituras do ledger, antes e
# depois, vão pelo mesmo wrapper no modo --read-only e começam pela identidade do
# banco (current_database() e o system_identifier do cluster). Depois, o ledger tem de
# ser o de antes mais o lote, no mesmo banco.
#
# O --apply e o --preview exigem MANALOOM_CONFIRM_LIVE_MUTATIONS e
# MANALOOM_CONFIRM_POSTGRES_WRITES de quem chama (a prévia escreve e desfaz) e o checkout
# limpo no origin/master (o mesmo SHA que a promoção sobe). O --apply exige ainda as
# provas B e E, as contagens da prévia e um --receipt-dir durável: fora de /tmp, de
# worktree temporária e do
# repositório (deste checkout e dos outros worktrees dele). O wrapper exige a âncora
# do host (MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256) e lê só as chaves do banco do
# server/.env. No diretório ficam o receipt (lote-migrations-<sha>-<carimbo>-<pid>.json),
# a saída do migrate.dart (o .log de mesmo nome, que pode trazer o erro do PostgreSQL;
# fica fora do git) e o ledger de depois no formato do --schema-snapshot
# (ledger-<sha>-<carimbo>-<pid>.json). Cada arquivo nasce com O_EXCL e chmod 600: um
# nome que já existe é recusado, e nenhuma evidência é sobrescrita.
#
# Janela: o backend antigo responde 503 desde a primeira migration até o backend novo
# (cerca de 5 minutos). Não há volta automática: depois da 059, rollback é restore do
# dump do L-01 (docs/runbooks/BACKUP_E_RESTAURACAO.md), e a promoção recusa voltar o
# backend para uma imagem que exige outra migration (S-02).
#
# Códigos: 0 aplicado e conferido (ou plano PASS, ou prévia feita); 1 o migrate.dart ou
# um passo falhou sem dizer que nada gravou, ou o ledger de depois não é o esperado (o
# receipt diz onde parou); 2 entrada ou ambiente recusado, nada mudou; 3 BLOCKED pelo
# plano, pelas provas, pelo ledger ou pela recusa de um passo, nada mudou.
set -euo pipefail
umask 077

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
LOGIC="$ROOT_DIR/scripts/manaloom_lot_migrations.py"
POLICY="$ROOT_DIR/server/config/lot_migrations.json"
# A identidade do banco na primeira linha, o ledger depois (dois -c, a mesma sessão).
IDENTITY_SQL="SELECT 'database|' || current_database() || '|' || system_identifier FROM pg_control_system()"
LEDGER_SQL="SELECT version || '|' || name FROM public.schema_migrations ORDER BY version"
EXECUTE=0
MODE=""
RECEIPT_DIR=""
OUT=""
BACKUP_RECEIPT=""
UPGRADE_REHEARSAL=""
ESPERADO=()
TAB=$'\t'

usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
}

while (( $# > 0 )); do
  case "$1" in
    --execute) EXECUTE=1; shift ;;
    --apply) MODE=apply; shift ;;
    --read-ledger) MODE=ledger; shift ;;
    --preview) MODE=preview; shift ;;
    --esperado) ESPERADO+=("${2:-}"); shift 2 ;;
    --receipt-dir) RECEIPT_DIR="${2:-}"; shift 2 ;;
    --backup-receipt) BACKUP_RECEIPT="${2:-}"; shift 2 ;;
    --upgrade-rehearsal) UPGRADE_REHEARSAL="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --policy) POLICY="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -f "$POLICY" ]] || { echo "política do lote não encontrada: $POLICY" >&2; exit 2; }

if [[ "$EXECUTE" != "1" ]]; then
  [[ -z "$MODE" && ${#ESPERADO[@]} -eq 0 ]] || {
    echo "--apply, --preview, --read-ledger e --esperado exigem --execute" >&2; exit 2; }
  plan_rc=0
  python3 "$LOGIC" plan --policy "$POLICY" || plan_rc=$?
  exit "$plan_rc"
fi

case "$MODE" in
  ledger)
    [[ -n "$OUT" ]] || { echo "--read-ledger exige --out" >&2; exit 2; }
    [[ ! -e "$OUT" && ! -L "$OUT" ]] || {
      echo "--out já existe; recuso sobrescrever: $OUT" >&2; exit 2; }
    ;;
  apply) ;;
  preview)
    (( ${#ESPERADO[@]} == 0 )) || {
      echo "--esperado é do --apply; a prévia mostra os números" >&2; exit 2; }
    ;;
  *) echo "--execute exige --apply, --preview ou --read-ledger" >&2; exit 2 ;;
esac
(( ${#ESPERADO[@]} == 0 )) || [[ "$MODE" == "apply" ]] || {
  echo "--esperado é do --apply" >&2; exit 2; }

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-lot-migrations.XXXXXX")"
chmod 700 "$RUN_DIR"
trap 'rm -rf "$RUN_DIR"' EXIT

# A identidade do banco e o ledger, só para leitura (o wrapper põe
# default_transaction_read_only=on).
read_ledger() {
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
    psql -X -v ON_ERROR_STOP=1 -qAt -c "$IDENTITY_SQL" -c "$LEDGER_SQL" >"$1"
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

# ------------------------------------------------------------ --apply e --preview

# A aprovação vem só de quem chama, antes de ler o ambiente ou o banco. A prévia também
# a exige: ela escreve e desfaz (ROLLBACK), pelo wrapper de escrita.
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "passo de migrations do lote (S-05)"
require_postgres_write_approval "passo de migrations do lote (S-05)"

# Um passo antes da primeira migration ($1, o id), na prévia ou na gravação ($2), pelo
# wrapper de escrita, numa transação: a saída fica em step-<id>.out e .err, e o
# resultado conferido em step-<id>.json. Devolve o código do step-result: 0 feito, 3
# recusado sem gravar, 1 falha sem a prova de que nada gravou.
run_step() {
  local id="$1" mode="$2" script psql_rc=0 result_rc=0 variable
  local variables=() expected_args=()
  script="$(jq -r --arg id "$id" \
    '.before_first_migration[] | select(.id == $id) | .script' "$RUN_DIR/plan.json")"
  if [[ "$mode" == "gravacao" ]]; then
    while IFS= read -r variable; do
      variables+=(-v "$variable")
    done < <(jq -r --arg id "$id" \
      '.steps[] | select(.id == $id) | .psql_variables[]' "$RUN_DIR/expected.json")
    expected_args=(--expected "$RUN_DIR/expected.json")
  fi
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" --write-approved \
    psql -X -v ON_ERROR_STOP=1 -At -F "$TAB" ${variables[@]+"${variables[@]}"} \
    -f "$ROOT_DIR/$script" >"$RUN_DIR/step-$id.out" 2>"$RUN_DIR/step-$id.err" || psql_rc=$?
  python3 "$LOGIC" step-result --plan "$RUN_DIR/plan.json" --id "$id" --mode "$mode" \
    --exit "$psql_rc" --stdout "$RUN_DIR/step-$id.out" --stderr "$RUN_DIR/step-$id.err" \
    ${expected_args[@]+"${expected_args[@]}"} >"$RUN_DIR/step-$id.json" || result_rc=$?
  return "$result_rc"
}

step_ids() {
  jq -r '.before_first_migration[].id' "$RUN_DIR/plan.json"
}

if [[ "$MODE" == "preview" ]]; then
  SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)"
  [[ -z "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=all)" ]] || {
    echo "checkout sujo: a prévia do lote sai só de SHA limpo" >&2; exit 2; }
  [[ "$(git -C "$ROOT_DIR" rev-parse origin/master 2>/dev/null || true)" == "$SHA" ]] || {
    echo "o checkout não é o origin/master (o SHA que a promoção sobe)" >&2; exit 2; }
  plan_rc=0
  python3 "$LOGIC" plan --policy "$POLICY" >"$RUN_DIR/plan.json" || plan_rc=$?
  if [[ "$plan_rc" != "0" ]]; then
    jq -r '.problems[]? // .error' "$RUN_DIR/plan.json" >&2
    echo "BLOCKED: o lote não bate com o código deste SHA; a prévia não rodou" >&2
    [[ "$plan_rc" == "2" ]] && exit 2
    exit 3
  fi
  read_rc=0
  read_ledger "$RUN_DIR/before.txt" || read_rc=$?
  if [[ "$read_rc" != "0" ]]; then
    echo "não li o ledger do banco (o wrapper do PostgreSQL saiu com $read_rc); a prévia não rodou" >&2
    exit 2
  fi
  before_rc=0
  python3 "$LOGIC" check-before --plan "$RUN_DIR/plan.json" \
    --ledger-raw "$RUN_DIR/before.txt" >"$RUN_DIR/before.json" || before_rc=$?
  if [[ "$before_rc" != "0" ]]; then
    jq -r '.problems[]? // .error' "$RUN_DIR/before.json" >&2
    echo "BLOCKED: o banco não está onde o lote parte; a prévia não rodou" >&2
    exit 3
  fi
  preview_rc=0
  step_files=()
  for id in $(step_ids); do
    step_rc=0
    run_step "$id" previa || step_rc=$?
    step_files+=("$RUN_DIR/step-$id.json")
    if [[ "$step_rc" != "0" ]]; then
      preview_rc=1
      jq -r '.problems[]? // .error' "$RUN_DIR/step-$id.json" >&2
      tail -5 "$RUN_DIR/step-$id.err" >&2
    fi
  done
  if (( ${#step_files[@]} > 0 )); then
    jq -s '.' "${step_files[@]}" >"$RUN_DIR/steps.json"
  else
    echo '[]' >"$RUN_DIR/steps.json"
  fi
  # A prévia e o que o --apply pede: cada contagem da ação, como --esperado.
  jq -cn --arg sha "$SHA" --argjson rc "$preview_rc" --slurpfile before "$RUN_DIR/before.json" \
    --slurpfile plan "$RUN_DIR/plan.json" --slurpfile steps "$RUN_DIR/steps.json" \
    '{status: (if $rc == 0 then "preview" else "failed" end), sha: $sha,
      database: $before[0].ledger.database, from: $before[0].ledger.latest,
      to: $plan[0].to, steps: $steps[0], esperado: [$steps[0][].esperado[]?]}'
  exit "$preview_rc"
fi

# O diretório (físico) está neste checkout ou em outro worktree do mesmo repositório?
inside_repository() {
  local dir="$1" root here there
  root="$(cd "$ROOT_DIR" && pwd -P)"
  [[ "$dir/" == "$root/"* ]] && return 0
  here="$(cd "$ROOT_DIR" && cd "$(git rev-parse --git-common-dir)" && pwd -P)" || return 0
  there="$(cd "$dir" && git rev-parse --git-common-dir 2>/dev/null)" || return 1
  there="$(cd "$dir" && cd "$there" && pwd -P)" || return 0
  [[ "$here" == "$there" ]]
}

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
if inside_repository "$RECEIPT_DIR"; then
  echo "o receipt não pode ficar dentro do repositório (checkout ou worktree): $RECEIPT_DIR" >&2
  exit 2
fi
[[ -n "$BACKUP_RECEIPT" && -n "$UPGRADE_REHEARSAL" ]] || {
  echo "--apply exige as provas do lote: --backup-receipt (L-01, backup com ensaio de" \
    "restauração) e --upgrade-rehearsal (L-02, ensaio do upgrade)" >&2; exit 2; }

SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)"
[[ -z "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=all)" ]] || {
  echo "checkout sujo: as migrations do lote saem só de SHA limpo" >&2; exit 2; }
[[ "$(git -C "$ROOT_DIR" rev-parse origin/master 2>/dev/null || true)" == "$SHA" ]] || {
  echo "o checkout não é o origin/master (o SHA que a promoção sobe)" >&2; exit 2; }

# shellcheck source=scripts/lib/manaloom_dart_toolchain.sh
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

# Nomes únicos (carimbo e PID); cada arquivo nasce com O_EXCL e nunca é sobrescrito.
# Um só relógio para o started_at e o carimbo do nome.
read -r STARTED_AT RUN_STAMP <<<"$(date -u '+%Y-%m-%dT%H:%M:%SZ %Y%m%dT%H%M%SZ')"
RUN_ID="$RUN_STAMP-$$"
RECEIPT="$RECEIPT_DIR/lote-migrations-${SHA:0:12}-$RUN_ID.json"
LOG_NAME="lote-migrations-${SHA:0:12}-$RUN_ID.log"
LEDGER_AFTER="$RECEIPT_DIR/ledger-${SHA:0:12}-$RUN_ID.json"

# O receipt leva as contagens esperadas e o resultado de cada passo antes da primeira
# migration, quando já existem.
receipt() {
  local status="$1" step
  local extra=()
  shift
  if [[ -f "$RUN_DIR/expected.json" ]]; then
    extra+=(--expected "$RUN_DIR/expected.json")
  fi
  for step in "$RUN_DIR"/step-*.json; do
    if [[ -f "$step" ]]; then
      extra+=(--steps "$step")
    fi
  done
  python3 "$LOGIC" receipt --out "$RECEIPT" --status "$status" --sha "$SHA" \
    --started-at "$STARTED_AT" --plan "$RUN_DIR/plan.json" \
    ${extra[@]+"${extra[@]}"} "$@" >"$RUN_DIR/receipt.out" || {
    echo "CRITICAL: não gravei o receipt: $(jq -r '.error // "?"' "$RUN_DIR/receipt.out" \
      2>/dev/null || echo "?")" >&2
    return 1
  }
}

plan_rc=0
python3 "$LOGIC" plan --policy "$POLICY" >"$RUN_DIR/plan.json" || plan_rc=$?
if [[ "$plan_rc" == "2" ]]; then
  cat "$RUN_DIR/plan.json" >&2
  exit 2
fi
if [[ "$plan_rc" != "0" ]]; then
  receipt blocked || exit 2
  jq -r '.problems[]' "$RUN_DIR/plan.json" >&2
  echo "BLOCKED: o lote não bate com o código deste SHA; nada mudou ($RECEIPT)" >&2
  exit 3
fi
TO="$(jq -r '.to' "$RUN_DIR/plan.json")"
[[ "$TO" =~ ^[0-9]{3}$ ]] || { echo "plano sem a última migration" >&2; exit 2; }

# As contagens que a gravação de cada passo antes da primeira migration exige (as da
# prévia que o dono aprovou), antes de qualquer conexão.
expected_args=()
for value in ${ESPERADO[@]+"${ESPERADO[@]}"}; do
  expected_args+=(--esperado "$value")
done
expected_rc=0
python3 "$LOGIC" expected --plan "$RUN_DIR/plan.json" \
  ${expected_args[@]+"${expected_args[@]}"} >"$RUN_DIR/expected.json" || expected_rc=$?
if [[ "$expected_rc" != "0" ]]; then
  echo "contagens esperadas recusadas: $(jq -r '.error // "?"' "$RUN_DIR/expected.json")" >&2
  rm -f "$RUN_DIR/expected.json"
  exit 2
fi

# O L-01 e o L-02, antes de qualquer conexão.
proofs_rc=0
python3 "$LOGIC" proofs --backup-receipt "$BACKUP_RECEIPT" \
  --upgrade-rehearsal "$UPGRADE_REHEARSAL" >"$RUN_DIR/proofs.json" || proofs_rc=$?
if [[ "$proofs_rc" == "2" ]]; then
  echo "prova do lote ilegível: $(jq -r '.error // "?"' "$RUN_DIR/proofs.json")" >&2
  exit 2
fi
if [[ "$proofs_rc" != "0" ]]; then
  receipt blocked --proofs "$RUN_DIR/proofs.json" || exit 2
  jq -r '.problems[]' "$RUN_DIR/proofs.json" >&2
  echo "BLOCKED: sem as provas do L-01 e do L-02; nada mudou ($RECEIPT)" >&2
  exit 3
fi

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
    receipt blocked --proofs "$RUN_DIR/proofs.json" --before "$RUN_DIR/before.json" || exit 2
  else
    receipt blocked --proofs "$RUN_DIR/proofs.json" \
      --reason "ledger ilegível: $(jq -r '.error // "?"' "$RUN_DIR/before.json")" || exit 2
  fi
  jq -r '.problems[]? // .error' "$RUN_DIR/before.json" >&2
  echo "BLOCKED: o banco não está onde o lote parte; nada mudou ($RECEIPT)" >&2
  exit 3
fi

# O log nasce antes da primeira escrita (O_EXCL): se o nome existe, recusa sem escrever.
python3 "$LOGIC" create --out "$RECEIPT_DIR/$LOG_NAME" >/dev/null || {
  echo "recuso sobrescrever $RECEIPT_DIR/$LOG_NAME; nada mudou" >&2; exit 2; }

# Os passos antes da primeira migration (o dedupe da D-74), com o banco no from e o
# backend antigo no ar: a gravação com as contagens da prévia. Uma recusa do script
# (RAISE, transação desfeita) para o lote antes do migrate, sem nada gravado.
for id in $(step_ids); do
  echo "== $(date -u +%T) passo $id antes da primeira migration (log em $RECEIPT_DIR/$LOG_NAME)" >&2
  step_rc=0
  run_step "$id" gravacao || step_rc=$?
  {
    echo "== passo $id: $(jq -r '.script' "$RUN_DIR/step-$id.json" 2>/dev/null || echo "?")"
    cat "$RUN_DIR/step-$id.out" "$RUN_DIR/step-$id.err"
  } >>"$RECEIPT_DIR/$LOG_NAME"
  if [[ "$step_rc" == "0" ]]; then
    continue
  fi
  if [[ "$step_rc" == "3" ]]; then
    receipt blocked --proofs "$RUN_DIR/proofs.json" --before "$RUN_DIR/before.json" \
      --log "$LOG_NAME" || exit 2
    jq -r '.problems[]? // .error' "$RUN_DIR/step-$id.json" >&2
    tail -5 "$RUN_DIR/step-$id.err" >&2
    echo "BLOCKED: o passo $id recusou a gravação; nada mudou e as migrations não rodaram" \
      "($RECEIPT)" >&2
    exit 3
  fi
  receipt failed --proofs "$RUN_DIR/proofs.json" --before "$RUN_DIR/before.json" \
    --log "$LOG_NAME" --reason "o passo $id saiu com $step_rc antes do migrate" || true
  jq -r '.problems[]? // .error' "$RUN_DIR/step-$id.json" >&2 || true
  echo "CRITICAL: o passo $id falhou sem a prova de que nada gravou; as migrations não" \
    "rodaram; confira à mão antes de seguir ($RECEIPT)" >&2
  exit 1
done

echo "== $(date -u +%T) migrations $(jq -r '[.migrations[].version] | join(", ")' \
  "$RUN_DIR/plan.json") até a $TO (log em $RECEIPT_DIR/$LOG_NAME)" >&2
migrate_rc=0
(
  cd "$ROOT_DIR/server"
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" --write-approved \
    "$DART_BIN" run bin/migrate.dart --target "$TO"
) >>"$RECEIPT_DIR/$LOG_NAME" 2>&1 || migrate_rc=$?

after_read_rc=0
read_ledger "$RUN_DIR/after.txt" || after_read_rc=$?
if [[ "$after_read_rc" != "0" ]]; then
  receipt failed --proofs "$RUN_DIR/proofs.json" --before "$RUN_DIR/before.json" \
    --migrate-exit "$migrate_rc" --log "$LOG_NAME" \
    --reason "não li o ledger depois (o wrapper do PostgreSQL saiu com $after_read_rc)" || true
  echo "CRITICAL: o migrate.dart saiu com $migrate_rc e o ledger de depois não foi lido;" \
    "confira à mão antes de seguir ($RECEIPT)" >&2
  exit 1
fi
after_rc=0
python3 "$LOGIC" check-after --plan "$RUN_DIR/plan.json" --before-raw "$RUN_DIR/before.txt" \
  --after-raw "$RUN_DIR/after.txt" >"$RUN_DIR/after.json" || after_rc=$?
snapshot_args=()
if ! python3 "$LOGIC" snapshot --raw "$RUN_DIR/after.txt" --out "$LEDGER_AFTER" >/dev/null; then
  snapshot_args=(--reason "não gravei o ledger de depois em $LEDGER_AFTER; rode --read-ledger")
  LEDGER_AFTER=""
fi
if [[ "$migrate_rc" == "0" && "$after_rc" == "0" ]]; then
  receipt applied --proofs "$RUN_DIR/proofs.json" --before "$RUN_DIR/before.json" \
    --after "$RUN_DIR/after.json" --migrate-exit 0 --log "$LOG_NAME" \
    ${snapshot_args[@]+"${snapshot_args[@]}"} || exit 1
  [[ -n "$LEDGER_AFTER" ]] || echo "AVISO: ${snapshot_args[1]}" >&2
  jq -cn --arg receipt "$RECEIPT" --arg ledger "$LEDGER_AFTER" \
    --slurpfile before "$RUN_DIR/before.json" --slurpfile after "$RUN_DIR/after.json" \
    '{status:"applied", from:$before[0].ledger.latest, to:$after[0].ledger.latest,
      applied:$after[0].applied, database:$after[0].ledger.database, receipt:$receipt,
      schema_snapshot:(if $ledger == "" then null else $ledger end)}'
  exit 0
fi
receipt failed --proofs "$RUN_DIR/proofs.json" --before "$RUN_DIR/before.json" \
  --after "$RUN_DIR/after.json" --migrate-exit "$migrate_rc" --log "$LOG_NAME" \
  ${snapshot_args[@]+"${snapshot_args[@]}"} || true
jq -r '.problems[]? // .error' "$RUN_DIR/after.json" >&2
echo "FAIL: o migrate.dart saiu com $migrate_rc e o banco ficou na" \
  "$(jq -r '.ledger.latest // "?"' "$RUN_DIR/after.json"); o receipt diz onde parou ($RECEIPT)" >&2
exit 1

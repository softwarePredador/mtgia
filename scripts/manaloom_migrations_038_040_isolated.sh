#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_postgres_write_approval "harness PostgreSQL descartável das migrations 038-040"
require_live_mutation_approval "harness PostgreSQL descartável das migrations 038-040"

for tool in createdb dropdb psql dart shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatória ausente: $tool" >&2
    exit 2
  }
done

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-$(id -un)}"
DB_PASS="${DB_PASS:-}"
DB_ADMIN="${MANALOOM_S1_PG_ADMIN_DB:-postgres}"

case "$DB_HOST" in
  localhost|127.0.0.1|::1) ;;
  *) echo "BLOCKED: harness aceita somente PostgreSQL loopback" >&2; exit 2 ;;
esac

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$$"
PREFIX="manaloom_s1_migrations_${RUN_ID}"
FRESH_DB="${PREFIX}_fresh"
UPGRADE_DB="${PREFIX}_upgrade"
ROLLBACK_DB="${PREFIX}_rollback"
RUN_DIR="${TMPDIR:-/tmp}/manaloom_migrations_038_040_${RUN_ID}"
DUMP_FILE="$RUN_DIR/prior.dump"
mkdir -p "$RUN_DIR"

export PGPASSWORD="$DB_PASS"

PG_SERVER_MAJOR="$(
  psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_ADMIN" \
    -c "SELECT current_setting('server_version_num')::int / 10000"
)"
PG_VERSIONED_BIN="/opt/homebrew/opt/postgresql@${PG_SERVER_MAJOR}/bin"
PG_DUMP_BIN="${MANALOOM_PG_DUMP_BIN:-pg_dump}"
PG_RESTORE_BIN="${MANALOOM_PG_RESTORE_BIN:-pg_restore}"
if [[ -x "$PG_VERSIONED_BIN/pg_dump" && -x "$PG_VERSIONED_BIN/pg_restore" ]]; then
  PG_DUMP_BIN="$PG_VERSIONED_BIN/pg_dump"
  PG_RESTORE_BIN="$PG_VERSIONED_BIN/pg_restore"
fi
for tool in "$PG_DUMP_BIN" "$PG_RESTORE_BIN"; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta PostgreSQL versionada ausente: $tool" >&2
    exit 2
  }
done

cleanup() {
  for database in "$ROLLBACK_DB" "$UPGRADE_DB" "$FRESH_DB"; do
    dropdb --if-exists --force \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$database" \
      >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT INT TERM

create_database() {
  createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    --maintenance-db="$DB_ADMIN" "$1"
}

bootstrap_schema() {
  psql -X -v ON_ERROR_STOP=1 \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$1" \
    -f "$SERVER_DIR/database_setup.sql"
}

run_support() {
  local database="$1"
  local mode="$2"
  (
    cd "$SERVER_DIR"
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
      DB_PASS="$DB_PASS" DB_NAME="$database" \
      dart run bin/migration_038_040_isolated_support.dart "$mode"
  )
}

run_migrate() {
  local database="$1"
  (
    cd "$SERVER_DIR"
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
      DB_PASS="$DB_PASS" DB_NAME="$database" \
      MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
      MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
      dart run bin/migrate.dart
  )
}

create_database "$FRESH_DB"
bootstrap_schema "$FRESH_DB" >"$RUN_DIR/fresh-bootstrap.log" 2>&1
run_migrate "$FRESH_DB" >"$RUN_DIR/fresh-apply.log" 2>&1
run_support "$FRESH_DB" assert-post >"$RUN_DIR/fresh-postcheck.log" 2>&1
run_migrate "$FRESH_DB" >"$RUN_DIR/fresh-reapply.log" 2>&1
run_support "$FRESH_DB" assert-post >"$RUN_DIR/fresh-idempotency.log" 2>&1

create_database "$UPGRADE_DB"
bootstrap_schema "$UPGRADE_DB" >"$RUN_DIR/upgrade-bootstrap.log" 2>&1
run_support "$UPGRADE_DB" prepare-prior >"$RUN_DIR/upgrade-prior.log" 2>&1
"$PG_DUMP_BIN" -Fc -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  -d "$UPGRADE_DB" -f "$DUMP_FILE"
run_migrate "$UPGRADE_DB" >"$RUN_DIR/upgrade-apply.log" 2>&1
run_support "$UPGRADE_DB" assert-post >"$RUN_DIR/upgrade-postcheck.log" 2>&1
run_migrate "$UPGRADE_DB" >"$RUN_DIR/upgrade-reapply.log" 2>&1
run_support "$UPGRADE_DB" assert-post >"$RUN_DIR/upgrade-idempotency.log" 2>&1

create_database "$ROLLBACK_DB"
"$PG_RESTORE_BIN" --exit-on-error --no-owner \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$ROLLBACK_DB" \
  "$DUMP_FILE" >"$RUN_DIR/rollback-restore.log" 2>&1
run_support "$ROLLBACK_DB" assert-prior >"$RUN_DIR/rollback-postcheck.log" 2>&1
run_migrate "$ROLLBACK_DB" >"$RUN_DIR/rollback-reapply.log" 2>&1
run_support "$ROLLBACK_DB" assert-post >"$RUN_DIR/rollback-forward-check.log" 2>&1

SUMMARY="$RUN_DIR/summary.txt"
{
  printf 'result=pass\n'
  printf 'scope=migrations_038_039_040_isolated_loopback\n'
  printf 'fresh_apply=pass\n'
  printf 'fresh_reapply=pass\n'
  printf 'upgrade_from_prior=pass\n'
  printf 'upgrade_reapply=pass\n'
  printf 'rollback_restore_prior=pass\n'
  printf 'rollback_forward_reapply=pass\n'
  printf 'cleanup=trap_registered\n'
} >"$SUMMARY"

SUMMARY_SHA="$(shasum -a 256 "$SUMMARY" | awk '{print $1}')"
printf 'PASS: migrations 038-040 isolated harness\n'
printf 'summary=%s\n' "$SUMMARY"
printf 'summary_sha256=%s\n' "$SUMMARY_SHA"

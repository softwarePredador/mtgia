#!/usr/bin/env bash
# BT-COH-001: testa o script de convites do dono (server/bin/beta_invites.dart)
# contra um PostgreSQL 17 descartável em loopback, criado e apagado aqui.
#
# Uso: scripts/manaloom_beta_invites_cli_db_test.sh
#
# - O cluster nasce num diretório temporário, só em 127.0.0.1 e sem socket
#   Unix, recebe o server/database_setup.sql e todas as migrations, e é parado
#   e apagado no fim, com sucesso ou falha.
# - Roda server/test/beta_invites_cli_db_live_test.dart (o processo real do
#   script: simulação, bloqueios, lote, repetição, convite expirado e convite
#   usado) e server/test/beta_invite_db_live_test.dart (emissão e cadastro).
# - Nenhum e-mail sai: o teste entrega num webhook de teste em loopback.
# - Recusa rodar pelo wrapper da produção (MANALOOM_PG_WRAPPER_MODE).
#
# Saída: 0 quando os dois testes passam; 1 falha; 2 ambiente recusado.
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"
DB_NAME_LOCAL="manaloom_beta_invites_cli"
JWT_SECRET_LOCAL="local_quality_gate_jwt_secret_not_for_production_20260706"

if [[ -n "${MANALOOM_PG_WRAPPER_MODE:-}" ]]; then
  echo "BLOCKED: rodando pelo wrapper da produção; este teste só usa banco descartável" >&2
  exit 2
fi

PG_BIN="${MANALOOM_PG_BIN:-}"
if [[ -z "$PG_BIN" ]]; then
  if [[ -x /opt/homebrew/opt/postgresql@17/bin/initdb ]]; then
    PG_BIN=/opt/homebrew/opt/postgresql@17/bin
  elif command -v initdb >/dev/null 2>&1; then
    PG_BIN="$(dirname "$(command -v initdb)")"
  fi
fi
DART_BIN="${MANALOOM_DART_BIN:-$(command -v dart || true)}"
for tool in "$PG_BIN/initdb" "$PG_BIN/pg_ctl" "$PG_BIN/pg_isready" \
  "$PG_BIN/createdb" "$PG_BIN/psql" "$DART_BIN"; do
  if [[ ! -x "$tool" ]]; then
    echo "ferramenta obrigatória ausente: $tool" >&2
    exit 2
  fi
done

BASE="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_beta_invites_cli.XXXXXX")"
DATA="$BASE/data"
cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  if [[ -d "$DATA" ]]; then
    "$PG_BIN/pg_ctl" -D "$DATA" -m fast stop >/dev/null 2>&1 || true
  fi
  rm -rf "$BASE"
  if [[ -e "$BASE" ]]; then
    echo "cluster descartável NÃO foi apagado: $BASE" >&2
    status=1
  else
    echo "cluster descartável parado e apagado"
  fi
  exit "$status"
}
trap cleanup EXIT INT TERM

PORT="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"
export LC_ALL=C LANG=C
"$PG_BIN/initdb" -D "$DATA" -U postgres --auth=trust --no-locale \
  --encoding=UTF8 >"$BASE/initdb.log" 2>&1
"$PG_BIN/pg_ctl" -D "$DATA" -l "$BASE/postgres.log" \
  -o "-F -p $PORT -h 127.0.0.1 -c unix_socket_directories=''" start >/dev/null
for _ in $(seq 1 50); do
  "$PG_BIN/pg_isready" -h 127.0.0.1 -p "$PORT" -U postgres >/dev/null 2>&1 && break
  sleep 0.2
done
"$PG_BIN/createdb" -h 127.0.0.1 -p "$PORT" -U postgres "$DB_NAME_LOCAL"
"$PG_BIN/psql" -X -q -v ON_ERROR_STOP=1 -h 127.0.0.1 -p "$PORT" -U postgres \
  -d "$DB_NAME_LOCAL" -f "$SERVER_DIR/database_setup.sql" >"$BASE/bootstrap.log" 2>&1

# As migrations rodam compiladas, a partir do diretório temporário: nenhum
# .env do checkout entra, só o banco descartável.
(cd "$SERVER_DIR" && "$DART_BIN" compile kernel bin/migrate.dart \
  -o "$BASE/migrate.dill" >"$BASE/compile.log" 2>&1)
if ! (cd "$BASE" && env -i PATH="$PATH" HOME="${HOME:-/tmp}" \
  DB_HOST=127.0.0.1 DB_PORT="$PORT" DB_USER=postgres DB_PASS='' \
  DB_NAME="$DB_NAME_LOCAL" DB_SSL_MODE=disable ENVIRONMENT=development \
  MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
  MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
  "$DART_BIN" "$BASE/migrate.dill" >"$BASE/migrate.log" 2>&1); then
  tail -20 "$BASE/migrate.log" >&2
  exit 1
fi
echo "banco descartável pronto em 127.0.0.1:$PORT: $(
  "$PG_BIN/psql" -X -A -t -h 127.0.0.1 -p "$PORT" -U postgres -d "$DB_NAME_LOCAL" \
    -c "SELECT COUNT(*) || ' migrations, a última ' || MAX(version) FROM schema_migrations"
)"

cd "$SERVER_DIR"
DB_HOST=127.0.0.1 DB_PORT="$PORT" DB_USER=postgres DB_PASS='' \
  DB_NAME="$DB_NAME_LOCAL" DB_SSL_MODE=disable ENVIRONMENT=development \
  JWT_SECRET="$JWT_SECRET_LOCAL" \
  RUN_BETA_INVITE_CLI_DB_TESTS=1 RUN_BETA_INVITE_DB_TESTS=1 \
  "$DART_BIN" test -j 1 --reporter expanded \
    test/beta_invites_cli_db_live_test.dart \
    test/beta_invite_db_live_test.dart

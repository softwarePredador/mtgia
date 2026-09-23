#!/usr/bin/env bash
set -euo pipefail

# Auditoria reproduzível do schema (BT-DB-001), somente leitura.
#
# Sobe um PostgreSQL 17 local e descartável, só em loopback e, no macOS,
# dentro de sandbox-exec sem rede externa, com dois bancos:
#   base — criado do zero: server/database_setup.sql + server/bin/migrate.dart;
#   alvo — montado de um dump (--target-dump): só a estrutura
#          (pg_restore --schema-only) e só os dados de schema_migrations
#          (pg_restore --data-only -t schema_migrations). Nenhuma outra tabela
#          recebe dados, então nenhum dado pessoal entra no banco; o script
#          confere isso contando as linhas de cada tabela antes da auditoria.
# Roda server/bin/schema_audit.dart (transações READ ONLY) e grava
# schema-audit.json e schema-audit.md em --out-dir. No fim para o PostgreSQL
# e apaga o diretório temporário, com os bancos e tudo o que foi restaurado.
# O dump não é alterado.
#
# Uso:
#   scripts/manaloom_schema_audit.sh --target-dump CAMINHO.dump \
#     --out-dir DIRETORIO [--target-label NOME]
#
# Aprovação do PostgreSQL descartável: a mesma do gate tbls
# (git config manaloom.localGates.disposablePostgres=true ou
# MANALOOM_APPROVE_DISPOSABLE_POSTGRES=I_APPROVE_DISPOSABLE_LOCAL_POSTGRES).
# As dependências de server/ precisam estar resolvidas (dart pub get). O
# script chama o Dart sem `dart run`, para nunca disparar um pub get implícito
# no cache Pub compartilhado.

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APPROVAL_PHRASE="I_APPROVE_DISPOSABLE_LOCAL_POSTGRES"
USAGE="uso: $0 --target-dump CAMINHO --out-dir DIR [--target-label NOME]"

TARGET_DUMP=""
OUT_DIR=""
TARGET_LABEL="alvo-do-dump"
while (($# > 0)); do
  case "$1" in
    --target-dump) TARGET_DUMP="${2:-}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    --target-label) TARGET_LABEL="${2:-}"; shift 2 ;;
    *) echo "$USAGE" >&2; exit 2 ;;
  esac
done
if [[ -z "$TARGET_DUMP" || -z "$OUT_DIR" ]]; then
  echo "$USAGE" >&2
  exit 2
fi
if [[ ! -f "$TARGET_DUMP" || -L "$TARGET_DUMP" ]]; then
  echo "dump ausente ou link simbólico: $TARGET_DUMP" >&2
  exit 2
fi
mkdir -p "$OUT_DIR"
OUT_DIR="$(CDPATH='' cd -- "$OUT_DIR" && pwd)"

configured_approval="$(
  git -C "$ROOT_DIR" config --local --bool --get \
    manaloom.localGates.disposablePostgres 2>/dev/null || true
)"
if [[ "${MANALOOM_APPROVE_DISPOSABLE_POSTGRES:-}" != "$APPROVAL_PHRASE" &&
      "$configured_approval" != "true" ]]; then
  echo "BLOCKED: a auditoria cria só um PostgreSQL local descartável." >&2
  echo "Aprove com MANALOOM_APPROVE_DISPOSABLE_POSTGRES=$APPROVAL_PHRASE." >&2
  exit 2
fi

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"
if [[ ! -f "$ROOT_DIR/server/.dart_tool/package_config.json" ]]; then
  echo "server/ sem dependências resolvidas: rode dart pub get antes" >&2
  exit 2
fi

PG_BIN="${MANALOOM_PG17_BIN:-/opt/homebrew/opt/postgresql@17/bin}"
if [[ ! -x "$PG_BIN/pg_ctl" ]]; then
  PG_BIN="$(dirname "$(command -v pg_ctl)")"
fi
for tool in initdb pg_ctl pg_isready createdb psql pg_restore; do
  if [[ ! -x "$PG_BIN/$tool" ]]; then
    echo "ferramenta ausente: $PG_BIN/$tool" >&2
    exit 2
  fi
done
if ! "$PG_BIN/pg_restore" --version | grep -q ' 17\.'; then
  echo "pg_restore precisa ser da versão 17, a do dump" >&2
  exit 2
fi
export LC_ALL=C

SANDBOX=()
if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! command -v sandbox-exec >/dev/null 2>&1; then
    echo "BLOCKED: sandbox-exec é obrigatório no macOS" >&2
    exit 2
  fi
  SANDBOX=(sandbox-exec -p '(version 1)
(allow default)
(deny network*)
(allow network-outbound (remote ip "localhost:*"))
(allow network-inbound (local ip "localhost:*"))')
fi
isolated() {
  if ((${#SANDBOX[@]} > 0)); then
    "${SANDBOX[@]}" "$@"
  else
    "$@"
  fi
}

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_schema_audit.XXXXXX")"
DATA_DIR="$RUN_DIR/pgdata"
POSTGRES_STARTED=0
cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  if [[ "$POSTGRES_STARTED" == "1" ]]; then
    "$PG_BIN/pg_ctl" -D "$DATA_DIR" -m fast stop >/dev/null 2>&1 || status=1
  fi
  rm -rf "$RUN_DIR"
  if [[ -e "$RUN_DIR" ]]; then
    echo "não consegui apagar $RUN_DIR" >&2
    status=1
  else
    echo "descartado=$RUN_DIR"
  fi
  exit "$status"
}
trap cleanup EXIT INT TERM

PORT="$(python3 - <<'PY'
import socket

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"

"$PG_BIN/initdb" -D "$DATA_DIR" -U postgres --auth=trust --no-locale \
  --encoding=UTF8 >"$RUN_DIR/initdb.log" 2>&1
isolated "$PG_BIN/pg_ctl" -D "$DATA_DIR" -l "$RUN_DIR/postgres.log" \
  -o "-F -p $PORT -h 127.0.0.1 -c unix_socket_directories=''" start >/dev/null
POSTGRES_STARTED=1
for _attempt in $(seq 1 50); do
  if "$PG_BIN/pg_isready" -h 127.0.0.1 -p "$PORT" -U postgres >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done
"$PG_BIN/pg_isready" -h 127.0.0.1 -p "$PORT" -U postgres >/dev/null

psql_local() {
  isolated "$PG_BIN/psql" -X -q -v ON_ERROR_STOP=1 \
    -h 127.0.0.1 -p "$PORT" -U postgres "$@"
}

# Base criada do zero pelas migrations.
"$PG_BIN/createdb" -h 127.0.0.1 -p "$PORT" -U postgres base
psql_local -d base -f "$ROOT_DIR/server/database_setup.sql" \
  >"$RUN_DIR/base-setup.log" 2>&1
(
  cd "$ROOT_DIR/server"
  DB_HOST=127.0.0.1 DB_PORT="$PORT" DB_USER=postgres DB_PASS='' DB_NAME=base \
  ENVIRONMENT=development \
  MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
  MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
    isolated "$DART_BIN" bin/migrate.dart
) >"$RUN_DIR/base-migrate.log" 2>&1

# Alvo: só a estrutura e o ledger; nenhuma outra tabela recebe dados.
"$PG_BIN/createdb" -h 127.0.0.1 -p "$PORT" -U postgres alvo
RESTORE_FLAGS=(--no-owner --no-acl --no-tablespaces --no-publications
  --no-subscriptions --no-security-labels)
isolated "$PG_BIN/pg_restore" --schema-only "${RESTORE_FLAGS[@]}" \
  -h 127.0.0.1 -p "$PORT" -U postgres -d alvo "$TARGET_DUMP" \
  >"$RUN_DIR/alvo-estrutura.log" 2>&1
isolated "$PG_BIN/pg_restore" --data-only "${RESTORE_FLAGS[@]}" \
  -n public -t schema_migrations -h 127.0.0.1 -p "$PORT" -U postgres -d alvo \
  "$TARGET_DUMP" >"$RUN_DIR/alvo-ledger.log" 2>&1
printf 'pg_restore_log_linhas=estrutura:%s,ledger:%s\n' \
  "$(wc -l <"$RUN_DIR/alvo-estrutura.log" | tr -d ' ')" \
  "$(wc -l <"$RUN_DIR/alvo-ledger.log" | tr -d ' ')"

tables_with_rows="$(psql_local -d alvo -A -t -c "
  SELECT COALESCE(string_agg(n.nspname || '.' || c.relname, ','
                             ORDER BY n.nspname, c.relname), '')
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind IN ('r', 'p')
    AND n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_'
    AND (xpath('/row/c/text()', query_to_xml(
      format('SELECT count(*) AS c FROM %I.%I', n.nspname, c.relname),
      false, true, '')))[1]::text::bigint > 0
")"
if [[ "$tables_with_rows" != "public.schema_migrations" ]]; then
  echo "BLOCKED: só public.schema_migrations podia ter linhas no alvo; tem:" \
    "${tables_with_rows:-nenhuma}" >&2
  exit 1
fi
printf 'alvo_tabelas_com_linhas=%s\n' "$tables_with_rows"
printf 'dump_sha256=%s\n' "$(shasum -a 256 "$TARGET_DUMP" | awk '{print $1}')"

(
  cd "$ROOT_DIR/server"
  isolated "$DART_BIN" bin/schema_audit.dart \
    --baseline "postgres://postgres@127.0.0.1:$PORT/base" \
    --target "postgres://postgres@127.0.0.1:$PORT/alvo" \
    --baseline-label "base-fresca-das-migrations" \
    --target-label "$TARGET_LABEL" \
    --json "$OUT_DIR/schema-audit.json" \
    --markdown "$OUT_DIR/schema-audit.md"
)

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APPROVAL_PHRASE="I_APPROVE_DISPOSABLE_LOCAL_POSTGRES"
KEEP_ARTIFACTS="${MANALOOM_KEEP_LOCAL_GATE_ARTIFACTS:-0}"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

for tool in initdb pg_ctl pg_isready createdb psql tbls python3 "$DART_BIN"; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta local obrigatória ausente: $tool" >&2
    exit 2
  }
done

configured_approval="$(
  git -C "$ROOT_DIR" config --local --bool --get \
    manaloom.localGates.disposablePostgres 2>/dev/null || true
)"
if [[ "${MANALOOM_APPROVE_DISPOSABLE_POSTGRES:-}" != "$APPROVAL_PHRASE" &&
      "$configured_approval" != "true" ]]; then
  echo "BLOCKED: o gate cria somente um PostgreSQL local descartável em /tmp." >&2
  echo "Instale os hooks com scripts/manaloom_install_local_hooks.sh --install" >&2
  echo "ou aprove uma execução com MANALOOM_APPROVE_DISPOSABLE_POSTGRES=$APPROVAL_PHRASE." >&2
  exit 2
fi

if [[ ! -f "$ROOT_DIR/project_logic_manifest.json" ]]; then
  echo "manifesto ausente; gere-o antes do gate tbls" >&2
  exit 2
fi

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_tbls_local.XXXXXX")"
DATA_DIR="$RUN_DIR/pgdata"
SOCKET_DIR="$RUN_DIR/socket"
DOC_DIR="$RUN_DIR/docs"
SCHEMA_JSON="$RUN_DIR/schema.json"
POSTGRES_STARTED=0
mkdir -p "$SOCKET_DIR"

cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  if [[ "$POSTGRES_STARTED" == "1" ]]; then
    pg_ctl -D "$DATA_DIR" -m fast stop >/dev/null 2>&1 || status=1
  fi
  if [[ "$KEEP_ARTIFACTS" == "1" ]]; then
    printf 'tbls_local_artifacts=%s\n' "$RUN_DIR"
  else
    rm -rf "$RUN_DIR"
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

initdb \
  -D "$DATA_DIR" \
  -U postgres \
  --auth=trust \
  --no-locale \
  --encoding=UTF8 >"$RUN_DIR/initdb.log" 2>&1
pg_ctl \
  -D "$DATA_DIR" \
  -l "$RUN_DIR/postgres.log" \
  -o "-F -p $PORT -h 127.0.0.1 -k $SOCKET_DIR" \
  start >/dev/null
POSTGRES_STARTED=1

ready=0
for _attempt in $(seq 1 40); do
  if pg_isready -h 127.0.0.1 -p "$PORT" -U postgres >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.1
done
if [[ "$ready" != "1" ]]; then
  echo "PostgreSQL descartável não ficou pronto" >&2
  exit 1
fi

createdb -h 127.0.0.1 -p "$PORT" -U postgres manaloom_tbls
psql -X -v ON_ERROR_STOP=1 \
  -h 127.0.0.1 -p "$PORT" -U postgres -d manaloom_tbls \
  -f "$ROOT_DIR/server/database_setup.sql" \
  >"$RUN_DIR/bootstrap.log" 2>&1

(
  cd "$ROOT_DIR/server"
  DB_HOST=127.0.0.1 \
  DB_PORT="$PORT" \
  DB_USER=postgres \
  DB_PASS='' \
  DB_NAME=manaloom_tbls \
  ENVIRONMENT=development \
  MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
  MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
    "$DART_BIN" run bin/migrate.dart
) >"$RUN_DIR/migrate.log" 2>&1

DSN="postgres://postgres@127.0.0.1:$PORT/manaloom_tbls?sslmode=disable"
tbls out "$DSN" \
  --config "$ROOT_DIR/.tbls.yml" \
  --sort \
  --format json \
  --out "$SCHEMA_JSON" >"$RUN_DIR/tbls-out.log" 2>&1
tbls doc "$DSN" "$DOC_DIR" \
  --config "$ROOT_DIR/.tbls.yml" \
  --er-format mermaid \
  --sort \
  --force >"$RUN_DIR/tbls-doc.log" 2>&1
tbls lint "$DSN" "$DOC_DIR" \
  --config "$ROOT_DIR/.tbls.yml" >"$RUN_DIR/tbls-lint.log" 2>&1

grep -Fq '```mermaid' "$DOC_DIR/README.md"
grep -Fq 'erDiagram' "$DOC_DIR/README.md"

migration_count="$(
  psql -X -A -t \
    -h 127.0.0.1 -p "$PORT" -U postgres -d manaloom_tbls \
    -c 'SELECT COUNT(*) FROM schema_migrations'
)"

python3 - \
  "$ROOT_DIR/project_logic_manifest.json" \
  "$SCHEMA_JSON" \
  "$migration_count" <<'PY'
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
schema = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
migration_count = int(sys.argv[3])
database = manifest["database"]

live_tables = {
    table["name"].split(".", 1)[-1]: table
    for table in schema["tables"]
    if table["type"] == "BASE TABLE"
}
live_views = {
    table["name"].split(".", 1)[-1]
    for table in schema["tables"]
    if table["type"] == "VIEW"
}
manifest_tables = {table["name"]: table for table in database["tables"]}
manifest_views = set(database["views"])

failures = []
if set(live_tables) != set(manifest_tables):
    failures.append(
        "table inventory drift: "
        f"live_only={sorted(set(live_tables) - set(manifest_tables))} "
        f"manifest_only={sorted(set(manifest_tables) - set(live_tables))}"
    )
if live_views != manifest_views:
    failures.append(
        "view inventory drift: "
        f"live_only={sorted(live_views - manifest_views)} "
        f"manifest_only={sorted(manifest_views - live_views)}"
    )

for name in sorted(set(live_tables) & set(manifest_tables)):
    live_columns = {column["name"] for column in live_tables[name]["columns"]}
    manifest_columns = {
        column["name"] for column in manifest_tables[name]["columns"]
    }
    if live_columns != manifest_columns:
        failures.append(
            f"column drift in {name}: "
            f"live_only={sorted(live_columns - manifest_columns)} "
            f"manifest_only={sorted(manifest_columns - live_columns)}"
        )

live_relations = {
    (
        relation["table"].split(".", 1)[-1],
        tuple(relation["columns"]),
        relation["parent_table"].split(".", 1)[-1],
        tuple(relation["parent_columns"]),
    )
    for relation in schema["relations"]
}
manifest_relations = {
    (
        relation["from_table"],
        (relation["from_column"],),
        relation["to_table"],
        (relation["to_column"],),
    )
    for relation in database["relations"]
}
if live_relations != manifest_relations:
    failures.append(
        "foreign-key drift: "
        f"live_only={sorted(live_relations - manifest_relations)} "
        f"manifest_only={sorted(manifest_relations - live_relations)}"
    )

if migration_count != database["migration_count"]:
    failures.append(
        f"migration drift: live={migration_count} "
        f"manifest={database['migration_count']}"
    )

if failures:
    raise SystemExit("\n".join(failures))

print(
    "PASS: tbls local schema matches manifest "
    f"({len(live_tables)} tables, {len(live_views)} views, "
    f"{len(live_relations)} foreign keys, {migration_count} migrations)."
)
PY

printf 'PASS: PostgreSQL/tbls local descartável, sem conexão externa.\n'

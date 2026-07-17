#!/usr/bin/env bash
set -euo pipefail

BACKUP="${MANALOOM_RESTORE_DRILL_BACKUP:-}"
IDENTITY="${MANALOOM_RESTORE_DRILL_AGE_IDENTITY:-}"
MANIFEST="${MANALOOM_RESTORE_DRILL_MANIFEST:-}"
EVIDENCE_DIR="${MANALOOM_RESTORE_DRILL_EVIDENCE_DIR:-}"
readonly APPROVED_POSTGRES_IMAGE="postgres:17.10-alpine3.23@sha256:8189a1f6e40904781fc9e2612687877791d21679866db58b1de996b31fc312e4"
IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-$APPROVED_POSTGRES_IMAGE}"
MIN_TABLES="${MANALOOM_RESTORE_MIN_TABLES:-80}"
EXECUTE=0

usage() {
  cat <<'EOF'
Uso: manaloom_full_restore_drill.sh --backup FILE [opcoes]

O padrao e dry-run. A restauracao local exige --execute e
MANALOOM_RESTORE_DRILL_EXECUTE=1. Nenhuma conexao remota e usada.

Opcoes:
  --backup FILE
  --identity AGE_PRIVATE_KEY_FILE   obrigatorio para backup .age
  --manifest FILE                  manifesto gerado pelo backup off-site
  --evidence-dir DIR
  --image POSTGRES_IMAGE
  --min-tables N
  --execute
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup) BACKUP="${2:-}"; shift 2 ;;
    --identity) IDENTITY="${2:-}"; shift 2 ;;
    --manifest) MANIFEST="${2:-}"; shift 2 ;;
    --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
    --image) IMAGE="${2:-}"; shift 2 ;;
    --min-tables) MIN_TABLES="${2:-}"; shift 2 ;;
    --execute) EXECUTE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$BACKUP" ]]; then
  echo "backup obrigatorio" >&2
  exit 2
fi
if [[ ! "$MIN_TABLES" =~ ^[1-9][0-9]*$ ]]; then
  echo "min-tables deve ser inteiro positivo" >&2
  exit 2
fi
if [[ "$IMAGE" != "$APPROVED_POSTGRES_IMAGE" ]]; then
  echo "imagem do restore deve usar o digest PostgreSQL 17 aprovado" >&2
  exit 2
fi

if [[ "$EXECUTE" == "0" ]]; then
  ENCRYPTED=false
  [[ "$BACKUP" == *.age ]] && ENCRYPTED=true
  printf '{"status":"dry_run","backup":"%s","encrypted":%s,"decryption_identity_required":%s,"manifest_required":%s,"mode":"full","runner":"isolated_local_docker","image":"%s","min_tables":%s,"writes_performed":false}\n' \
    "$BACKUP" "$ENCRYPTED" "$ENCRYPTED" "$ENCRYPTED" "$IMAGE" "$MIN_TABLES"
  exit 0
fi
if [[ "${MANALOOM_RESTORE_DRILL_EXECUTE:-0}" != "1" ]]; then
  echo "execucao recusada: defina MANALOOM_RESTORE_DRILL_EXECUTE=1 junto com --execute" >&2
  exit 2
fi
if [[ ! -f "$BACKUP" ]]; then
  echo "backup ausente: $BACKUP" >&2
  exit 2
fi

for tool in docker jq shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done
docker info >/dev/null

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
CONTAINER="manaloom-full-restore-$STAMP-$$"
DB_NAME="manaloom_restore_check"
BACKUP_ABS="$(CDPATH='' cd -- "$(dirname -- "$BACKUP")" && pwd)/$(basename "$BACKUP")"
RESTORE_BACKUP_ABS="$BACKUP_ABS"
STAGING_DIR=""
EVIDENCE_DIR="${EVIDENCE_DIR:-/tmp/manaloom-full-restore-$STAMP}"
mkdir -p "$EVIDENCE_DIR"
chmod 700 "$EVIDENCE_DIR"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ARCHIVE_SHA256="$(shasum -a 256 "$BACKUP_ABS" | awk '{print $1}')"
ARCHIVE_BYTES="$(wc -c < "$BACKUP_ABS" | tr -d ' ')"
ENCRYPTED=false
ENCRYPTION_CHAIN_VERIFIED=false

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  if [[ -n "$STAGING_DIR" ]]; then
    rm -rf "$STAGING_DIR"
  fi
}
trap cleanup EXIT

if [[ "$BACKUP_ABS" == *.age ]]; then
  ENCRYPTED=true
  for artifact in "$IDENTITY" "$MANIFEST"; do
    if [[ -z "$artifact" || ! -f "$artifact" ]]; then
      echo "backup .age exige --identity e --manifest validos" >&2
      exit 2
    fi
  done
  command -v age >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: age" >&2
    exit 2
  }
  EXPECTED_ARCHIVE_SHA256="$(jq -er '.encrypted.sha256 | select(type == "string" and length == 64)' "$MANIFEST")"
  EXPECTED_SOURCE_SHA256="$(jq -er '.source.sha256 | select(type == "string" and length == 64)' "$MANIFEST")"
  if [[ "$ARCHIVE_SHA256" != "$EXPECTED_ARCHIVE_SHA256" ]]; then
    echo "arquivo .age diverge do manifesto off-site" >&2
    exit 1
  fi
  STAGING_DIR="$(mktemp -d /tmp/manaloom-full-restore-decrypt.XXXXXX)"
  chmod 700 "$STAGING_DIR"
  RESTORE_BACKUP_ABS="$STAGING_DIR/backup.dump"
  age --decrypt --identity "$IDENTITY" --output "$RESTORE_BACKUP_ABS" "$BACKUP_ABS"
  chmod 600 "$RESTORE_BACKUP_ABS"
  if [[ "$(shasum -a 256 "$RESTORE_BACKUP_ABS" | awk '{print $1}')" != "$EXPECTED_SOURCE_SHA256" ]]; then
    echo "dump descriptografado diverge do SHA-256 de origem" >&2
    exit 1
  fi
  ENCRYPTION_CHAIN_VERIFIED=true
elif [[ -n "$IDENTITY" || -n "$MANIFEST" ]]; then
  echo "--identity/--manifest so podem ser usados com backup .age" >&2
  exit 2
fi

RESTORED_DUMP_SHA256="$(shasum -a 256 "$RESTORE_BACKUP_ABS" | awk '{print $1}')"
RESTORED_DUMP_BYTES="$(wc -c < "$RESTORE_BACKUP_ABS" | tr -d ' ')"

docker run -d \
  --name "$CONTAINER" \
  --network none \
  -e POSTGRES_PASSWORD=restore_check \
  -v "$RESTORE_BACKUP_ABS:/evidence/backup.dump:ro" \
  "$IMAGE" > "$EVIDENCE_DIR/container-id.txt"

ready=0
for _ in $(seq 1 60); do
  if docker exec "$CONTAINER" pg_isready -U postgres >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [[ "$ready" != "1" ]]; then
  echo "Postgres isolado nao ficou pronto" >&2
  exit 1
fi

docker exec "$CONTAINER" createdb -U postgres "$DB_NAME"
docker exec "$CONTAINER" pg_restore \
  -U postgres \
  -d "$DB_NAME" \
  --exit-on-error \
  --no-owner \
  --no-privileges \
  /evidence/backup.dump \
  > "$EVIDENCE_DIR/pg_restore.stdout.log" \
  2> "$EVIDENCE_DIR/pg_restore.stderr.log"

TABLE_COUNT="$(docker exec "$CONTAINER" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" | tr -d '[:space:]')"
if [[ ! "$TABLE_COUNT" =~ ^[0-9]+$ || "$TABLE_COUNT" -lt "$MIN_TABLES" ]]; then
  echo "restore full incompleto: table_count=${TABLE_COUNT:-invalid} min=$MIN_TABLES" >&2
  exit 1
fi

FOREIGN_KEY_COUNT="$(docker exec "$CONTAINER" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c \
  "SELECT COUNT(*) FROM pg_constraint WHERE contype = 'f';" | tr -d '[:space:]')"
DATABASE_BYTES="$(docker exec "$CONTAINER" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c \
  "SELECT pg_database_size(current_database());" | tr -d '[:space:]')"
docker exec "$CONTAINER" psql -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1 -c \
  'BEGIN; SET CONSTRAINTS ALL IMMEDIATE; COMMIT;' \
  > "$EVIDENCE_DIR/constraints.log"

ROW_COUNTS='{}'
for table in users cards decks deck_cards; do
  exists="$(docker exec "$CONTAINER" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c \
    "SELECT to_regclass('public.$table') IS NOT NULL;" | tr -d '[:space:]')"
  if [[ "$exists" == "t" ]]; then
    count="$(docker exec "$CONTAINER" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c \
      "SELECT COUNT(*) FROM public.$table;" | tr -d '[:space:]')"
    ROW_COUNTS="$(jq --arg table "$table" --argjson count "$count" '. + {($table): $count}' <<<"$ROW_COUNTS")"
  fi
done

COMPLETED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
jq -n \
  --arg status passed \
  --arg mode full \
  --arg runner isolated_local_docker \
  --arg image "$IMAGE" \
  --arg backup_file "$(basename "$BACKUP_ABS")" \
  --arg archive_sha256 "$ARCHIVE_SHA256" \
  --arg restored_dump_sha256 "$RESTORED_DUMP_SHA256" \
  --arg started_at "$STARTED_AT" \
  --arg completed_at "$COMPLETED_AT" \
  --argjson archive_bytes "$ARCHIVE_BYTES" \
  --argjson restored_dump_bytes "$RESTORED_DUMP_BYTES" \
  --argjson encrypted "$ENCRYPTED" \
  --argjson encryption_chain_verified "$ENCRYPTION_CHAIN_VERIFIED" \
  --argjson table_count "$TABLE_COUNT" \
  --argjson foreign_key_count "$FOREIGN_KEY_COUNT" \
  --argjson database_bytes "$DATABASE_BYTES" \
  --argjson row_counts "$ROW_COUNTS" \
  '{
    status: $status,
    mode: $mode,
    runner: $runner,
    image: $image,
    backup: {
      file: $backup_file,
      sha256: $archive_sha256,
      bytes: $archive_bytes,
      encrypted: $encrypted
    },
    restored_dump: {sha256: $restored_dump_sha256, bytes: $restored_dump_bytes},
    encryption_chain_verified: $encryption_chain_verified,
    started_at: $started_at,
    completed_at: $completed_at,
    table_count: $table_count,
    foreign_key_count: $foreign_key_count,
    database_bytes: $database_bytes,
    critical_row_counts: $row_counts,
    constraints_immediate: true,
    remote_writes: false
  }' | tee "$EVIDENCE_DIR/restore-result.json"
chmod 600 "$EVIDENCE_DIR"/*

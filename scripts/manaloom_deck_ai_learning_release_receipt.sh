#!/usr/bin/env bash
set -euo pipefail

# Canonical producer for the v2 release-read-only receipt. This command opens
# only the pinned SSH/PostgreSQL read-only tunnel through the canonical wrapper;
# it never accepts a live API URL or a mutation approval token.

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
POLICY_FILE="$ROOT_DIR/server/config/deck_ai_learning_gate_policy.json"
VALIDATOR="$ROOT_DIR/scripts/manaloom_deck_ai_learning_receipt_validator.py"
KNOWLEDGE_DB="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
EVIDENCE_ROOT="${MANALOOM_DECK_AI_DURABLE_EVIDENCE_ROOT:-}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

usage() {
  cat <<'EOF'
Uso:
  MANALOOM_NEW_SERVER_ENV=/caminho/seguro/server.env \
  MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256=SHA256:... \
  ./scripts/manaloom_deck_ai_learning_release_receipt.sh \
    --evidence-root /caminho/duravel/fora-de-tmp

O produtor abre somente o tunnel PostgreSQL read-only canonico, executa o
auditor PG/Hermes/SQLite e o preflight das migrations 038-058, e emite um
receipt v2 ligado ao checkout limpo. Nao faz deploy, DDL, DML ou chamada de API.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --evidence-root)
      if (( $# < 2 )); then
        echo "BLOCKED: --evidence-root exige caminho" >&2
        exit 2
      fi
      EVIDENCE_ROOT="$2"
      shift 2
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "BLOCKED: argumento desconhecido: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$EVIDENCE_ROOT" || "$EVIDENCE_ROOT" != /* ]]; then
  echo "BLOCKED: evidence root absoluto e duravel e obrigatorio" >&2
  exit 2
fi
if [[ -z "${MANALOOM_NEW_SERVER_ENV:-}" || ! -r "$MANALOOM_NEW_SERVER_ENV" ]]; then
  echo "BLOCKED: MANALOOM_NEW_SERVER_ENV deve apontar para config legivel" >&2
  exit 2
fi
if [[ ! "${MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256:-}" =~ ^SHA256:[A-Za-z0-9+/]{43}$ ]]; then
  echo "BLOCKED: MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256 invalido ou ausente" >&2
  exit 2
fi
if [[ ! -f "$KNOWLEDGE_DB" || ! -r "$KNOWLEDGE_DB" ]]; then
  echo "BLOCKED: cache Hermes canonico ausente" >&2
  exit 2
fi

python3 "$VALIDATOR" check-durable-path \
  --path "$EVIDENCE_ROOT" \
  --policy "$POLICY_FILE" \
  --repo "$ROOT_DIR" >/dev/null

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$EVIDENCE_ROOT/${STAMP}_$$"
if [[ -e "$RUN_DIR" ]]; then
  echo "BLOCKED: evidence run ja existe: $RUN_DIR" >&2
  exit 2
fi
mkdir -p "$RUN_DIR"

SOURCE_START="$RUN_DIR/source-start.json"
SOURCE_END="$RUN_DIR/source-end.json"
PG_AUDIT_PREFIX="$RUN_DIR/pg-hermes-sqlite-audit"
PG_AUDIT_JSON="$PG_AUDIT_PREFIX.json"
PG_AUDIT_LOG="$RUN_DIR/pg-hermes-sqlite-audit.log"
MIGRATION_STATUS="$RUN_DIR/migration-status.json"
READ_ONLY_PREFLIGHT="$RUN_DIR/read-only-preflight.json"
RECEIPT="$RUN_DIR/deck-ai-learning-release-receipt-v2.json"

python3 "$VALIDATOR" snapshot-source \
  --repo "$ROOT_DIR" \
  --policy "$POLICY_FILE" \
  --out "$SOURCE_START"
python3 "$VALIDATOR" verify-source-stable \
  --start "$SOURCE_START" \
  --end "$SOURCE_START" \
  --require-clean >/dev/null

# Mutation approvals are deliberately removed from the producer process. The
# selected wrapper mode also forces default_transaction_read_only=on.
unset MANALOOM_CONFIRM_LIVE_MUTATIONS MANALOOM_CONFIRM_POSTGRES_WRITES \
  MANALOOM_PG_WRITE_APPROVED MANALOOM_REPO
export MANALOOM_KNOWLEDGE_DB="$KNOWLEDGE_DB"
MANALOOM_PG_HERMES_SQLITE_CONTRACT_AUDIT_OUT_PREFIX="$PG_AUDIT_PREFIX" \
  "$ROOT_DIR/scripts/manaloom_pg_hermes_sqlite_contract_audit.sh" \
  >"$PG_AUDIT_LOG" 2>&1

PREFLIGHT_SQL="SELECT jsonb_build_object(
  'generated_at', clock_timestamp(),
  'transaction_read_only', current_setting('transaction_read_only'),
  'database', current_database(),
  'user', current_user,
  'pg_wrapper_mode', 'read-only',
  'expected_ssh_host_key_sha256', :'expected_ssh_host_key_sha256',
  'write_authorization_used', false
)::text;"
printf '%s\n' "$PREFLIGHT_SQL" | \
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
    psql -X -v ON_ERROR_STOP=1 -qAt \
      -v "expected_ssh_host_key_sha256=$MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256" \
  >"$READ_ONLY_PREFLIGHT"

MIGRATION_SQL="WITH required(version) AS (
  SELECT lpad(value::text, 3, '0')
  FROM generate_series(38, 58) AS value
), applied AS (
  SELECT version FROM public.schema_migrations
)
SELECT jsonb_build_object(
  'generated_at', clock_timestamp(),
  'transaction_read_only', current_setting('transaction_read_only'),
  'database', current_database(),
  'required_range', '038-058',
  'required_versions', (SELECT jsonb_agg(version ORDER BY version) FROM required),
  'applied_versions', (SELECT jsonb_agg(version ORDER BY version) FROM applied),
  'latest_applied', (SELECT max(version) FROM applied),
  'pending_versions', COALESCE(
    (
      SELECT jsonb_agg(required.version ORDER BY required.version)
      FROM required
      LEFT JOIN applied USING (version)
      WHERE applied.version IS NULL
    ),
    '[]'::jsonb
  )
)::text;"
"$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
  psql -X -v ON_ERROR_STOP=1 -qAt -c "$MIGRATION_SQL" \
  >"$MIGRATION_STATUS"

python3 "$VALIDATOR" snapshot-source \
  --repo "$ROOT_DIR" \
  --policy "$POLICY_FILE" \
  --out "$SOURCE_END"
python3 "$VALIDATOR" verify-source-stable \
  --start "$SOURCE_START" \
  --end "$SOURCE_END" \
  --require-clean >/dev/null

python3 "$VALIDATOR" assemble-release \
  --repo "$ROOT_DIR" \
  --policy "$POLICY_FILE" \
  --credential-file "$MANALOOM_NEW_SERVER_ENV" \
  --evidence-root "$RUN_DIR" \
  --out "$RECEIPT" \
  --source-start "$SOURCE_START" \
  --source-end "$SOURCE_END" \
  --pg-audit-json "$PG_AUDIT_JSON" \
  --pg-audit-log "$PG_AUDIT_LOG" \
  --migration-status "$MIGRATION_STATUS" \
  --read-only-preflight "$READ_ONLY_PREFLIGHT" \
  --knowledge-db "$KNOWLEDGE_DB" \
  --started-at "$STARTED_AT"

printf '{"status":"PASS","profile":"release-read-only","receipt":"%s"}\n' \
  "$RECEIPT"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"

# Approval must come from the process invoking this deploy, never from the
# persistent server environment loaded below.
require_live_mutation_approval "deploy do backend ManaLoom"
readonly LIVE_MUTATION_APPROVED=1

if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
load_manaloom_env_keys "$ENV_FILE" \
  DATABASE_URL DB_HOST DB_NAME DB_PASS DB_PORT DB_SSL_MODE DB_USER ENVIRONMENT \
  EASYPANEL_API_TOKEN EASYPANEL_APP_NAME \
  EASYPANEL_BASE_URL EASYPANEL_PROJECT_NAME EASYPANEL_SERVER_IP \
  EASYPANEL_SSH_KEY EASYPANEL_SSH_USER MANALOOM_ALLOWED_ORIGINS \
  MANALOOM_API_BASE_URL MANALOOM_BACKEND_IMAGE_REPO \
  MANALOOM_BACKEND_SERVICE MANALOOM_DEPLOY_AI_DRAIN_TIMEOUT_SECONDS \
  MANALOOM_DEPLOY_READINESS_ATTEMPTS MANALOOM_EASYPANEL_INSECURE_TLS \
  MANALOOM_EASYPANEL_SSH_HOST MANALOOM_EASYPANEL_SSH_KEY \
  MANALOOM_EXPECTED_BATTLE_ENGINE MANALOOM_EXPECTED_DB_HOST \
  MANALOOM_EXPECTED_DB_NAME MANALOOM_EXPECTED_DB_PORT \
  MANALOOM_EXPECTED_FORGE_URL MANALOOM_EXPECTED_NATIVE_URL \
  MANALOOM_EXPECTED_XMAGE_URL MANALOOM_REMOTE_BUILD_ROOT \
  MANALOOM_TRUSTED_PROXY_HOPS MANALOOM_TRUSTED_PROXY_PEERS JWT_SECRET \
  SENTRY_DSN

SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
SERVICE="${MANALOOM_BACKEND_SERVICE:-evolution_cartinhas}"
IMAGE_REPO="${MANALOOM_BACKEND_IMAGE_REPO:-localhost:5000/manaloom/cartinhas}"
EASYPANEL_PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
EASYPANEL_SERVICE="${EASYPANEL_APP_NAME:-cartinhas}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
EXPECTED_DB_HOST="${MANALOOM_EXPECTED_DB_HOST:-evolution_manaloom-postgres}"
EXPECTED_DB_PORT="${MANALOOM_EXPECTED_DB_PORT:-5432}"
EXPECTED_DB_NAME="${MANALOOM_EXPECTED_DB_NAME:-halder}"
EXPECTED_BATTLE_ENGINE="${MANALOOM_EXPECTED_BATTLE_ENGINE:-auto}"
EXPECTED_XMAGE_URL="${MANALOOM_EXPECTED_XMAGE_URL:-http://xmage-sidecar:8080}"
EXPECTED_FORGE_URL="${MANALOOM_EXPECTED_FORGE_URL:-http://forge-sidecar:8080}"
EXPECTED_NATIVE_URL="${MANALOOM_EXPECTED_NATIVE_URL:-http://${EASYPANEL_PROJECT}_manaloom-ops:8080}"
API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
REQUIRED_WEB_ORIGIN="https://evolution-manaloom-web-public.2ta7qx.easypanel.host"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool git
require_tool curl
require_tool jq
require_tool python3
require_tool shasum
require_tool ssh
require_tool psql
require_tool pg_isready

SSH_KEY="$(python3 - "$ROOT_DIR" "$SSH_KEY" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
candidate = Path(sys.argv[2]).expanduser()
if not candidate.is_absolute():
    candidate = root / candidate
print(candidate.resolve())
PY
)"
if [[ ! -f "$SSH_KEY" ]]; then
  echo "chave SSH do deploy nao e legivel" >&2
  exit 2
fi

# Destinos operacionais são parte do contrato de release, não preferências
# vindas do mesmo .env que carrega credenciais.
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
validate_manaloom_release_api_base_url "$API_BASE_URL"
validate_manaloom_exact_coordinate project "$EASYPANEL_PROJECT" \
  "$MANALOOM_PRODUCTION_EASYPANEL_PROJECT"
validate_manaloom_exact_coordinate backend_service "$SERVICE" \
  evolution_cartinhas
validate_manaloom_exact_coordinate easypanel_service "$EASYPANEL_SERVICE" \
  cartinhas
validate_manaloom_exact_coordinate backend_image_repo "$IMAGE_REPO" \
  localhost:5000/manaloom/cartinhas
validate_manaloom_exact_coordinate remote_build_root "$REMOTE_BUILD_ROOT" \
  "$MANALOOM_PRODUCTION_REMOTE_BUILD_ROOT"
MANALOOM_ALLOWED_ORIGINS="${MANALOOM_ALLOWED_ORIGINS:-$REQUIRED_WEB_ORIGIN}"
ENVIRONMENT="${ENVIRONMENT:-production}"
MANALOOM_TRUSTED_PROXY_HOPS="${MANALOOM_TRUSTED_PROXY_HOPS:-$MANALOOM_PRODUCTION_TRUSTED_PROXY_HOPS}"
MANALOOM_TRUSTED_PROXY_PEERS="${MANALOOM_TRUSTED_PROXY_PEERS:-$MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS}"
validate_manaloom_exact_coordinate trusted_proxy_hops \
  "$MANALOOM_TRUSTED_PROXY_HOPS" \
  "$MANALOOM_PRODUCTION_TRUSTED_PROXY_HOPS"
validate_manaloom_exact_coordinate trusted_proxy_peers \
  "$MANALOOM_TRUSTED_PROXY_PEERS" \
  "$MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS"
validate_manaloom_exact_coordinate environment "$ENVIRONMENT" production
validate_manaloom_easypanel_base_url "${EASYPANEL_BASE_URL:-}"
MANALOOM_EXPECTED_SENTRY_DSN_SHA256="${MANALOOM_EXPECTED_SENTRY_DSN_SHA256:-$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256}"
validate_manaloom_exact_coordinate sentry_dsn_sha256 \
  "$MANALOOM_EXPECTED_SENTRY_DSN_SHA256" \
  "$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256"
if [[ -z "${SENTRY_DSN:-}" ]]; then
  SENTRY_DSN="$(read_manaloom_keychain_secret \
    "$MANALOOM_SENTRY_DSN_KEYCHAIN_SERVICE" || true)"
fi
resolve_manaloom_release_sentry_dsn "$SENTRY_DSN" 1
initialize_manaloom_secure_ssh "$SSH_HOST"

# Prefer the release-owned Keychain secret. This intentionally rotates the
# production JWT signing key after the historical account credential incident,
# invalidating every token issued with the previous key without persisting the
# replacement in the checkout or deploy logs.
if [[ -z "${JWT_SECRET:-}" ]]; then
  JWT_SECRET="$(read_manaloom_keychain_secret \
    "$MANALOOM_JWT_SECRET_KEYCHAIN_SERVICE" \
    "$MANALOOM_JWT_SECRET_KEYCHAIN_ACCOUNT" || true)"
fi

# Reuse the already deployed JWT secret if the operator intentionally keeps
# secrets out of the local checkout. The value is neither printed nor written
# to disk, and the production auth preflight validates it before any mutation.
if [[ -z "${JWT_SECRET:-}" ]]; then
  JWT_SECRET="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk '
    /^JWT_SECRET=/ {count++; value=substr(\$0,index(\$0,\"=\")+1)}
    END {if (count != 1 || length(value) == 0) exit 2; printf \"%s\", value}'
")" || {
    echo "deploy recusado: JWT_SECRET nao foi fornecido e nao pode ser herdado da spec atual" >&2
    exit 2
  }
fi
DEPLOY_MUTATION_STARTED=0
DEPLOY_COMMITTED=0
SOURCE_MUTATED=0
PREVIOUS_SOURCE_IMAGE=""
ROLLBACK_SOURCE_IMAGE=""
PREVIOUS_SPEC_IMAGE=""
PREVIOUS_RUNNING_IMAGE=""
PREVIOUS_UPDATE_STATE=""
cleanup_release_runtime() {
  local status="${1:-$?}"
  trap - EXIT
  if [[ "$status" != "0" && "$DEPLOY_MUTATION_STARTED" == "1" &&
        "$DEPLOY_COMMITTED" != "1" ]] &&
     declare -F rollback_backend_deploy >/dev/null 2>&1; then
    rollback_backend_deploy || status=1
  fi
  cleanup_manaloom_secure_ssh
  exit "$status"
}
trap 'cleanup_release_runtime $?' EXIT
require_tool dart

require_clean_worktree() {
  if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
    echo "deploy recusado: worktree deve estar limpo para o gate e o git archive usarem o mesmo SHA" >&2
    exit 2
  fi
}

require_auth_runtime_contract() {
  (
    cd "$ROOT_DIR/server"
    ENVIRONMENT="$ENVIRONMENT" \
      JWT_SECRET="$JWT_SECRET" \
      MANALOOM_TRUSTED_PROXY_HOPS="$MANALOOM_TRUSTED_PROXY_HOPS" \
      MANALOOM_TRUSTED_PROXY_PEERS="$MANALOOM_TRUSTED_PROXY_PEERS" \
      dart run bin/auth_runtime_preflight.dart
  )
}

require_trusted_proxy_topology() {
  local topology proxy_ip backend_ip proxy_subnet expected_proxy_ip
  topology="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
proxy_cid=\$(docker ps --filter label=com.docker.swarm.service.name=easypanel-traefik -q | head -1)
backend_cid=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
test -n \"\$proxy_cid\" && test -n \"\$backend_cid\"
proxy_ip=\$(docker inspect \"\$proxy_cid\" --format '{{.NetworkSettings.Networks.easypanel.IPAddress}}')
backend_ip=\$(docker inspect \"\$backend_cid\" --format '{{.NetworkSettings.Networks.easypanel.IPAddress}}')
proxy_subnet=\$(docker network inspect '$MANALOOM_PRODUCTION_TRUSTED_PROXY_NETWORK' --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
printf '%s|%s|%s' \"\$proxy_ip\" \"\$backend_ip\" \"\$proxy_subnet\"
")"
  IFS='|' read -r proxy_ip backend_ip proxy_subnet <<<"$topology"
  expected_proxy_ip="${MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS%/32}"
  if [[ "$proxy_ip" != "$expected_proxy_ip" ||
        "$proxy_subnet" != "$MANALOOM_PRODUCTION_TRUSTED_PROXY_SUBNET" ]] ||
     ! python3 - "$backend_ip" "$proxy_subnet" <<'PY'
import ipaddress
import sys

try:
    valid = ipaddress.ip_address(sys.argv[1]) in ipaddress.ip_network(sys.argv[2])
except ValueError:
    valid = False
raise SystemExit(0 if valid else 1)
PY
  then
    echo "deploy recusado: topologia Traefik/backend diverge do peer de proxy aprovado" >&2
    exit 2
  fi
}

require_migration_038_contract() {
  local contract_status
  contract_status="$(
    "$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
      psql -X -v ON_ERROR_STOP=1 -qAt <<'SQL'
BEGIN TRANSACTION READ ONLY;
WITH checks(check_name, ok) AS (
  VALUES
    (
      'transaction_read_only',
      current_setting('transaction_read_only') = 'on'
    ),
    (
      'schema_migration',
      EXISTS (
        SELECT 1
        FROM public.schema_migrations
        WHERE version = '038'
          AND name = 'add_privacy_and_post_game_sync_contracts'
      )
    ),
    (
      'pgcrypto',
      EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto')
    ),
    (
      'users_deleted_at',
      EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'deleted_at'
          AND data_type = 'timestamp with time zone'
      )
    ),
    (
      'post_game_note_columns',
      (
        SELECT COUNT(DISTINCT column_name)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'post_game_notes'
          AND (
            (column_name = 'play_session_id' AND data_type = 'text')
            OR (
              column_name IN (
                'session_started_at',
                'session_ended_at',
                'deck_version_at',
                'deleted_at'
              )
              AND data_type = 'timestamp with time zone'
            )
            OR (column_name = 'deck_snapshot_hash' AND data_type = 'text')
            OR (
              column_name = 'revision'
              AND data_type = 'bigint'
              AND is_nullable = 'NO'
              AND column_default IN ('1', '1::bigint')
            )
          )
      ) = 7
    ),
    (
      'post_game_note_constraints',
      (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE conrelid = 'public.post_game_notes'::regclass
          AND contype = 'c'
          AND convalidated
          AND conname IN (
            'chk_post_game_notes_revision',
            'chk_post_game_notes_session_order'
          )
      ) = 2
    ),
    (
      'migration_indexes',
      (
        SELECT COUNT(*)
        FROM pg_index
        WHERE indexrelid IN (
          'public.idx_users_active_identity'::regclass,
          'public.idx_post_game_notes_user_sync'::regclass,
          'public.idx_post_game_notes_tombstones'::regclass,
          'public.uq_post_game_notes_play_session'::regclass,
          'public.uq_privacy_keyring_active'::regclass
        )
          AND indisvalid
          AND indisready
      ) = 5
      AND (
        SELECT indisunique
        FROM pg_index
        WHERE indexrelid = 'public.uq_post_game_notes_play_session'::regclass
      )
      AND (
        SELECT indisunique
        FROM pg_index
        WHERE indexrelid = 'public.uq_privacy_keyring_active'::regclass
      )
    ),
    (
      'migration_tables',
      (
        SELECT COUNT(*)
        FROM pg_class
        WHERE oid IN (
          'public.post_game_sync_state'::regclass,
          'public.account_deletion_receipts'::regclass,
          'public.privacy_keyring'::regclass,
          'public.privacy_deleted_deck_tombstones'::regclass
        )
          AND relkind IN ('r', 'p')
      ) = 4
    ),
    (
      'post_game_sync_state',
      (
        SELECT COUNT(*)
        FROM public.post_game_sync_state
        WHERE id = 1 AND watermark IS NOT NULL
      ) = 1
    ),
    (
      'privacy_keyring',
      (
        SELECT COUNT(*)
        FROM public.privacy_keyring
        WHERE is_active
      ) = 1
      AND (
        SELECT COUNT(*)
        FROM public.privacy_keyring
        WHERE is_active AND octet_length(hmac_key) >= 32
      ) = 1
    ),
    (
      'guard_functions',
      to_regprocedure('public.manaloom_require_active_user()') IS NOT NULL
      AND to_regprocedure(
        'public.manaloom_guard_deck_learning_event()'
      ) IS NOT NULL
      AND to_regprocedure(
        'public.manaloom_guard_battle_simulation()'
      ) IS NOT NULL
    ),
    (
      'active_user_triggers',
      (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE contype = 'f'
          AND confrelid = 'public.users'::regclass
          AND array_length(conkey, 1) = 1
      ) > 0
      AND NOT EXISTS (
        SELECT 1
        FROM pg_constraint constraint_row
        WHERE constraint_row.contype = 'f'
          AND constraint_row.confrelid = 'public.users'::regclass
          AND array_length(constraint_row.conkey, 1) = 1
          AND NOT EXISTS (
            SELECT 1
            FROM pg_trigger trigger_row
            WHERE trigger_row.tgrelid = constraint_row.conrelid
              AND trigger_row.tgname =
                'manaloom_active_user_' || constraint_row.oid::text
              AND trigger_row.tgfoid = to_regprocedure(
                'public.manaloom_require_active_user()'
              )
              AND trigger_row.tgenabled IN ('O', 'A')
              AND NOT trigger_row.tgisinternal
          )
      )
    ),
    (
      'deck_learning_trigger',
      to_regclass('public.deck_learning_events') IS NULL
      OR EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgrelid = 'public.deck_learning_events'::regclass
          AND tgname = 'manaloom_guard_deck_learning_event'
          AND tgfoid = to_regprocedure(
            'public.manaloom_guard_deck_learning_event()'
          )
          AND tgenabled IN ('O', 'A')
          AND NOT tgisinternal
      )
    ),
    (
      'battle_simulation_trigger',
      to_regclass('public.battle_simulations') IS NULL
      OR EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgrelid = 'public.battle_simulations'::regclass
          AND tgname = 'manaloom_guard_battle_simulation'
          AND tgfoid = to_regprocedure(
            'public.manaloom_guard_battle_simulation()'
          )
          AND tgenabled IN ('O', 'A')
          AND NOT tgisinternal
      )
    ),
    (
      'trade_item_binder_fk',
      EXISTS (
        SELECT 1
        FROM pg_constraint constraint_row
        JOIN pg_attribute source_column
          ON source_column.attrelid = constraint_row.conrelid
         AND source_column.attnum = constraint_row.conkey[1]
        JOIN pg_attribute target_column
          ON target_column.attrelid = constraint_row.confrelid
         AND target_column.attnum = constraint_row.confkey[1]
        WHERE constraint_row.conname = 'trade_items_binder_item_id_fkey'
          AND constraint_row.contype = 'f'
          AND constraint_row.conrelid = 'public.trade_items'::regclass
          AND constraint_row.confrelid = 'public.user_binder_items'::regclass
          AND array_length(constraint_row.conkey, 1) = 1
          AND array_length(constraint_row.confkey, 1) = 1
          AND constraint_row.confdeltype = 'n'
          AND constraint_row.convalidated
          AND source_column.attname = 'binder_item_id'
          AND NOT source_column.attnotnull
          AND target_column.attname = 'id'
      )
    )
), missing AS (
  SELECT check_name
  FROM checks
  WHERE NOT ok
)
SELECT CASE
  WHEN COUNT(*) = 0 THEN 'migration_038_ready'
  ELSE 'migration_038_incomplete:' || string_agg(check_name, ',' ORDER BY check_name)
END
FROM missing;
ROLLBACK;
SQL
  )"

  if [[ "$contract_status" != "migration_038_ready" ]]; then
    echo "deploy recusado: contrato read-only da migration 038 incompleto: $contract_status" >&2
    exit 2
  fi
}

require_migration_039_contract() {
  local contract_status
  contract_status="$(
    "$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
      psql -X -v ON_ERROR_STOP=1 -qAt <<'SQL'
BEGIN TRANSACTION READ ONLY;
WITH checks(check_name, ok) AS (
  VALUES
    (
      'transaction_read_only',
      current_setting('transaction_read_only') = 'on'
    ),
    (
      'schema_migration',
      EXISTS (
        SELECT 1
        FROM public.schema_migrations
        WHERE version = '039'
          AND name = 'persist_deck_validation_review_state'
      )
    ),
    (
      'deck_validation_columns',
      (
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'decks'
          AND (
            (
              column_name = 'validation_state'
              AND data_type = 'text'
              AND is_nullable = 'NO'
            )
            OR (
              column_name = 'validation_reasons'
              AND data_type = 'jsonb'
              AND is_nullable = 'NO'
            )
            OR (
              column_name = 'validation_updated_at'
              AND data_type = 'timestamp with time zone'
            )
          )
      ) = 3
    ),
    (
      'deck_validation_constraints',
      (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE conrelid = 'public.decks'::regclass
          AND contype = 'c'
          AND convalidated
          AND conname IN (
            'chk_decks_validation_state',
            'chk_decks_validation_reasons_array'
          )
      ) = 2
    ),
    (
      'deck_validation_index',
      EXISTS (
        SELECT 1
        FROM pg_index
        WHERE indexrelid =
              'public.idx_decks_user_validation_state'::regclass
          AND indisvalid
          AND indisready
      )
    ),
    (
      'deck_validation_functions',
      to_regprocedure(
        'public.manaloom_mark_deck_cards_changed()'
      ) IS NOT NULL
      AND to_regprocedure(
        'public.manaloom_mark_deck_format_changed()'
      ) IS NOT NULL
      AND position(
        'array[old.deck_id, new.deck_id]'
        IN lower(
          pg_get_functiondef(
            to_regprocedure('public.manaloom_mark_deck_cards_changed()')
          )
        )
      ) > 0
    ),
    (
      'deck_validation_triggers',
      (
        SELECT COUNT(*)
        FROM pg_trigger
        WHERE (
            (
              tgrelid = 'public.deck_cards'::regclass
              AND tgname = 'manaloom_deck_cards_require_review'
              AND tgfoid = to_regprocedure(
                'public.manaloom_mark_deck_cards_changed()'
              )
              AND lower(pg_get_triggerdef(oid)) LIKE '%update of deck_id%'
            )
            OR (
              tgrelid = 'public.decks'::regclass
              AND tgname = 'manaloom_deck_format_require_review'
              AND tgfoid = to_regprocedure(
                'public.manaloom_mark_deck_format_changed()'
              )
            )
          )
          AND tgenabled IN ('O', 'A')
          AND NOT tgisinternal
      ) = 2
    ),
    (
      'deck_validation_rows',
      NOT EXISTS (
        SELECT 1
        FROM public.decks
        WHERE validation_state NOT IN ('unknown', 'draft', 'validated')
          OR validation_state IS NULL
          OR validation_reasons IS NULL
          OR jsonb_typeof(validation_reasons) <> 'array'
      )
    )
), missing AS (
  SELECT check_name
  FROM checks
  WHERE NOT ok
)
SELECT CASE
  WHEN COUNT(*) = 0 THEN 'migration_039_ready'
  ELSE 'migration_039_incomplete:' || string_agg(check_name, ',' ORDER BY check_name)
END
FROM missing;
ROLLBACK;
SQL
  )"

  if [[ "$contract_status" != "migration_039_ready" ]]; then
    echo "deploy recusado: contrato read-only da migration 039 incompleto: $contract_status" >&2
    exit 2
  fi
}

require_migration_040_contract() {
  local contract_status
  contract_status="$(
    "$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
      psql -X -v ON_ERROR_STOP=1 -qAt <<'SQL'
BEGIN TRANSACTION READ ONLY;
WITH checks(check_name, ok) AS (
  VALUES
    (
      'transaction_read_only',
      current_setting('transaction_read_only') = 'on'
    ),
    (
      'schema_migration',
      EXISTS (
        SELECT 1
        FROM public.schema_migrations
        WHERE version = '040'
          AND name = 'align_cards_reserved_runtime_schema'
      )
    ),
    (
      'cards_is_reserved_column',
      EXISTS (
        SELECT 1
        FROM pg_attribute attribute_row
        JOIN pg_class relation_row
          ON relation_row.oid = attribute_row.attrelid
        JOIN pg_namespace namespace_row
          ON namespace_row.oid = relation_row.relnamespace
        LEFT JOIN pg_attrdef default_row
          ON default_row.adrelid = attribute_row.attrelid
         AND default_row.adnum = attribute_row.attnum
        WHERE namespace_row.nspname = 'public'
          AND relation_row.relname = 'cards'
          AND attribute_row.attname = 'is_reserved'
          AND NOT attribute_row.attisdropped
          AND attribute_row.attnotnull
          AND format_type(
            attribute_row.atttypid,
            attribute_row.atttypmod
          ) = 'boolean'
          AND lower(
            COALESCE(
              pg_get_expr(default_row.adbin, default_row.adrelid),
              ''
            )
          ) = 'false'
      )
    ),
    (
      'cards_is_reserved_rows',
      NOT EXISTS (
        SELECT 1
        FROM public.cards
        WHERE is_reserved IS NULL
      )
    )
), missing AS (
  SELECT check_name
  FROM checks
  WHERE NOT ok
)
SELECT CASE
  WHEN COUNT(*) = 0 THEN 'migration_040_ready'
  ELSE 'migration_040_incomplete:' || string_agg(check_name, ',' ORDER BY check_name)
END
FROM missing;
ROLLBACK;
SQL
  )"

  if [[ "$contract_status" != "migration_040_ready" ]]; then
    echo "deploy recusado: contrato read-only da migration 040 incompleto: $contract_status" >&2
    exit 2
  fi
}

for key in SSH_HOST SSH_KEY EASYPANEL_BASE_URL EASYPANEL_API_TOKEN DB_HOST DB_PORT DB_NAME DB_USER DB_PASS DB_SSL_MODE DATABASE_URL MANALOOM_ALLOWED_ORIGINS ENVIRONMENT JWT_SECRET MANALOOM_TRUSTED_PROXY_HOPS MANALOOM_TRUSTED_PROXY_PEERS SENTRY_DSN; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done

ALLOWED_ORIGINS_CANONICAL="$(
  MANALOOM_ALLOWED_ORIGINS="$MANALOOM_ALLOWED_ORIGINS" \
    python3 "$ROOT_DIR/scripts/manaloom_validate_production_origins.py" \
      --required-origin "$REQUIRED_WEB_ORIGIN"
)"
ALLOWED_ORIGINS_SHA256="$(printf '%s' "$ALLOWED_ORIGINS_CANONICAL" | shasum -a 256 | awk '{print $1}')"

if [[ "$DB_HOST" != "$EXPECTED_DB_HOST" ||
      "$DB_PORT" != "$EXPECTED_DB_PORT" ||
      "$DB_NAME" != "$EXPECTED_DB_NAME" ]]; then
  echo "server/.env nao aponta para o PostgreSQL interno esperado" >&2
  exit 2
fi
if [[ "$DATABASE_URL" != *"@$EXPECTED_DB_HOST:$EXPECTED_DB_PORT/$EXPECTED_DB_NAME"* ]]; then
  echo "DATABASE_URL nao aponta para o PostgreSQL interno esperado" >&2
  exit 2
fi

curl_args=(-fsS)
if [[ "${MANALOOM_EASYPANEL_INSECURE_TLS:-0}" != "0" ]]; then
  echo "deploy recusado: TLS inseguro do EasyPanel nao e permitido" >&2
  exit 2
fi

trpc_post() {
  local procedure="$1"
  local payload="$2"
  curl "${curl_args[@]}" \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$payload" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$procedure"
}

rollback_backend_deploy() {
  local source_status=1 runtime_status=1 configured_status=1 health_status=1
  local services_json configured_image readiness

  echo "deploy backend falhou; restaurando spec e origem anteriores" >&2
  if [[ "$SOURCE_MUTATED" == "1" && -n "$ROLLBACK_SOURCE_IMAGE" ]]; then
    trpc_post services.app.updateSourceImage "$(jq -cn \
      --arg project "$EASYPANEL_PROJECT" \
      --arg service "$EASYPANEL_SERVICE" \
      --arg image "$ROLLBACK_SOURCE_IMAGE" \
      '{projectName:$project,serviceName:$service,image:$image}')" \
      >/dev/null && source_status=0
  else
    source_status=0
  fi

  if [[ -n "$PREVIOUS_SPEC_IMAGE" ]]; then
    if ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
restored=0
for attempt in \$(seq 1 60); do
  replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
  spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
  running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
  update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
  if [ \"\$replicas\" = '1/1' ] && [ \"\$spec\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$running\" = '$PREVIOUS_SPEC_IMAGE' ]; then
    restored=1
    break
  fi
  case \"\$update\" in
    rollback_started) sleep 2 ;;
    *) break ;;
  esac
done
if [ \"\$restored\" != 1 ]; then
  docker service update --detach=true --rollback '$SERVICE' >/dev/null
fi
for attempt in \$(seq 1 60); do
  replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
  spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
  running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
  update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
  if [ \"\$replicas\" = '1/1' ] && [ \"\$spec\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$running\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     { [ -z \"\$update\" ] || [ \"\$update\" = completed ] || [ \"\$update\" = rollback_completed ]; }; then
    exit 0
  fi
  case \"\$update\" in paused|rollback_paused) break ;; esac
  sleep 2
done
docker service inspect '$SERVICE' --format 'image={{.Spec.TaskTemplate.ContainerSpec.Image}} update={{if .UpdateStatus}}{{.UpdateStatus.State}} {{.UpdateStatus.Message}}{{end}}' >&2
docker service ps '$SERVICE' --no-trunc >&2
exit 1
"; then
      runtime_status=0
    fi
  fi

  if [[ "$SOURCE_MUTATED" == "1" ]]; then
    if services_json="$(trpc_post projects.listProjectsAndServices null)" &&
       configured_image="$(jq -er \
         --arg project "$EASYPANEL_PROJECT" \
         --arg service "$EASYPANEL_SERVICE" \
         '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
         <<<"$services_json")" &&
       [[ "$configured_image" == "$ROLLBACK_SOURCE_IMAGE" ]]; then
      configured_status=0
    fi
  else
    configured_status=0
  fi

  for _ in $(seq 1 30); do
    if readiness="$(curl -fsS "$API_BASE_URL/health/ready" 2>/dev/null)" &&
       jq -e '.status == "ready" and .environment == "production"' \
         >/dev/null <<<"$readiness"; then
      health_status=0
      break
    fi
    sleep 2
  done

  if [[ "$source_status" == "0" && "$runtime_status" == "0" &&
        "$configured_status" == "0" && "$health_status" == "0" ]]; then
    echo "rollback backend comprovado: spec, origem e readiness restaurados" >&2
    return 0
  fi
  echo "CRITICAL: rollback backend nao foi comprovado (source=$source_status runtime=$runtime_status configured=$configured_status health=$health_status)" >&2
  return 1
}

cd "$ROOT_DIR"
require_clean_worktree
require_trusted_proxy_topology
require_auth_runtime_contract
"$ROOT_DIR/scripts/manaloom_battle_product_gate.sh"
require_clean_worktree
require_migration_038_contract
require_migration_039_contract
require_migration_040_contract

drain_timeout_seconds="${MANALOOM_DEPLOY_AI_DRAIN_TIMEOUT_SECONDS:-300}"
if ! [[ "$drain_timeout_seconds" =~ ^[0-9]+$ ]]; then
  echo "MANALOOM_DEPLOY_AI_DRAIN_TIMEOUT_SECONDS deve ser inteiro" >&2
  exit 2
fi
drain_started_at="$(date +%s)"
while true; do
  active_ai_jobs="$(
    "$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
      psql -X -v ON_ERROR_STOP=1 -At -c \
      "SELECT
         (SELECT COUNT(*) FROM ai_generate_jobs
          WHERE status IN ('pending', 'processing')) +
         (SELECT COUNT(*) FROM ai_optimize_jobs
          WHERE status IN ('pending', 'processing'));"
  )"
  if [[ "$active_ai_jobs" == "0" ]]; then
    break
  fi
  now="$(date +%s)"
  if (( now - drain_started_at >= drain_timeout_seconds )); then
    echo "deploy recusado: $active_ai_jobs job(s) de IA ainda ativos apos ${drain_timeout_seconds}s" >&2
    exit 2
  fi
  echo "aguardando $active_ai_jobs job(s) de IA antes do deploy" >&2
  sleep 5
done

git fetch origin master --quiet
sha="$(git rev-parse HEAD)"
short_sha="$(git rev-parse --short=12 HEAD)"
remote_dir="$REMOTE_BUILD_ROOT/cartinhas-$short_sha"
deploy_timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/master 2>/dev/null || true)" ]; then
  echo "HEAD local nao esta alinhado com origin/master; faca push antes do deploy." >&2
  exit 2
fi

if [[ "$LIVE_MUTATION_APPROVED" != "1" ]]; then
  echo "deploy recusado: aprovacao live do processo chamador nao foi preservada" >&2
  exit 2
fi

# Bootstrap one server-side operations credential without ever printing or
# persisting it in the repository/local environment.
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
ops_configured=\$(docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk '/^MANALOOM_OPS_API_KEY=/{if (length(substr(\$0, index(\$0, \"=\") + 1)) >= 32) found=1} END{print found+0}')
if [ \"\$ops_configured\" != 1 ]; then
  command -v openssl >/dev/null 2>&1
  ops_key=\$(openssl rand -hex 32)
  docker service update --detach=true --env-add MANALOOM_OPS_API_KEY=\"\$ops_key\" '$SERVICE' >/dev/null
  for attempt in \$(seq 1 45); do
    replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -n 1)
    update_state=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
    if [ \"\$replicas\" = '1/1' ] && { [ -z \"\$update_state\" ] || [ \"\$update_state\" = completed ]; }; then
      exit 0
    fi
    sleep 2
  done
  exit 1
fi
"

runtime_spec_contract="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk -F= '
    /^DB_HOST=/{host=\$2}
    /^DB_PORT=/{port=\$2}
    /^DB_NAME=/{name=\$2}
    /^BATTLE_ENGINE=/{engine=\$2}
    /^XMAGE_SIDECAR_URL=/{xmage=\$2}
    /^FORGE_SIDECAR_URL=/{forge=\$2}
    /^NATIVE_BATTLE_SIDECAR_URL=/{native=\$2}
    /^ENVIRONMENT=/{environment=\$2}
    /^OPENAI_PROFILE=/{profile=\$2}
    /^OPENAI_API_KEY=/{openai=(length(substr(\$0,index(\$0,\"=\")+1))>0 ? 1 : 0)}
    /^MANALOOM_OPS_API_KEY=/{ops=(length(substr(\$0,index(\$0,\"=\")+1))>=32 ? 1 : 0)}
    /^JWT_SECRET=/ {
      value=substr(\$0,index(\$0,\"=\")+1)
      normalized=tolower(value)
      jwt_secret_configured=(length(value)>=32 && normalized !~ /(change_this|changeme|placeholder|not_for_production|not-for-production|local_test|local-test|password)/) ? 1 : 0
    }
    /^MANALOOM_TRUSTED_PROXY_HOPS=/ {
      value=substr(\$0,index(\$0,\"=\")+1)
      trusted_proxy_configured=(value ~ /^[1-5]$/) ? 1 : 0
    }
    /^MANALOOM_TRUSTED_PROXY_PEERS=/ {
      value=substr(\$0,index(\$0,\"=\")+1)
      trusted_proxy_peers_configured=(length(value)>0 && value !~ /(^|,)(0\.0\.0\.0\/0|::\/0)(,|$)/) ? 1 : 0
    }
    END{print host \"|\" port \"|\" name \"|\" engine \"|\" xmage \"|\" forge \"|\" native \"|\" environment \"|\" profile \"|\" openai \"|\" ops \"|\" jwt_secret_configured \"|\" trusted_proxy_configured \"|\" trusted_proxy_peers_configured}'
")"
IFS='|' read -r spec_db_host spec_db_port spec_db_name spec_battle_engine spec_xmage_url spec_forge_url spec_native_url spec_environment spec_openai_profile spec_openai_configured spec_ops_configured spec_jwt_secret_configured spec_trusted_proxy_configured spec_trusted_proxy_peers_configured <<<"$runtime_spec_contract"
if [[ "$spec_db_host|$spec_db_port|$spec_db_name|$spec_battle_engine|$spec_xmage_url|$spec_forge_url|$spec_native_url" != "$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME|$EXPECTED_BATTLE_ENGINE|$EXPECTED_XMAGE_URL|$EXPECTED_FORGE_URL|$EXPECTED_NATIVE_URL" ]]; then
  echo "deploy recusado: contrato PostgreSQL/battle da spec do backend esta divergente" >&2
  exit 2
fi
if [[ "$spec_environment" != "production" ||
      ( -n "$spec_openai_profile" && "$spec_openai_profile" != "prod" ) ||
      "$spec_openai_configured" != "1" ||
      "$spec_ops_configured" != "1" ||
      "$spec_jwt_secret_configured" != "1" ]]; then
  echo "deploy recusado: runtime de autenticacao/IA/operacoes nao esta fail-closed para producao" >&2
  exit 2
fi

git archive HEAD server tools/manaloom_lints | ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

# Build and push first, then capture the immutable RepoDigest produced by the
# remote registry. The mutable SHA/latest tags are never used as a deploy
# source after this point.
# shellcheck disable=SC2087
image_digest_ref="$(
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
cd '$remote_dir'
docker build \
  -f server/Dockerfile \
  -t '$IMAGE_REPO:$short_sha' \
  -t '$IMAGE_REPO:latest' \
  . >&2
docker push '$IMAGE_REPO:$short_sha' >&2
docker push '$IMAGE_REPO:latest' >&2
image_digest_ref="\$(
  docker image inspect '$IMAGE_REPO:$short_sha' \
    --format '{{range .RepoDigests}}{{println .}}{{end}}' |
    awk -v expected_repo='$IMAGE_REPO' \
      'index(\$0, expected_repo "@sha256:") == 1 {print; exit}'
)"
image_digest="\${image_digest_ref#'$IMAGE_REPO@sha256:'}"
if [[ "\$image_digest_ref" != '$IMAGE_REPO@sha256:'"\$image_digest" ||
      ! "\$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo 'push remoto nao produziu RepoDigest SHA-256 valido para o backend' >&2
  exit 2
fi
printf '%s\n' "\$image_digest_ref"
REMOTE
)"
image_digest="${image_digest_ref#"$IMAGE_REPO@sha256:"}"
if [[ "$image_digest_ref" != "$IMAGE_REPO@sha256:$image_digest" ||
      ! "$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "push remoto retornou RepoDigest invalido para o backend: $image_digest_ref" >&2
  exit 2
fi
readonly image_digest_ref

services_before="$(trpc_post projects.listProjectsAndServices null)"
PREVIOUS_SOURCE_IMAGE="$(jq -er \
  --arg project "$EASYPANEL_PROJECT" \
  --arg service "$EASYPANEL_SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$services_before")"
previous_runtime_state="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$update\"
")"
IFS='|' read -r previous_replicas PREVIOUS_SPEC_IMAGE PREVIOUS_RUNNING_IMAGE \
  PREVIOUS_UPDATE_STATE \
  <<<"$previous_runtime_state"
if [[ "$previous_replicas" != "1/1" ||
      "$PREVIOUS_RUNNING_IMAGE" != "$PREVIOUS_SPEC_IMAGE" ||
      ( -n "$PREVIOUS_UPDATE_STATE" &&
        "$PREVIOUS_UPDATE_STATE" != "completed" &&
        "$PREVIOUS_UPDATE_STATE" != "rollback_completed" ) ||
      ! "$PREVIOUS_SPEC_IMAGE" =~ @sha256:[0-9a-f]{64}$ ]]; then
  echo "deploy recusado: baseline backend nao e rollback-safe: $previous_runtime_state" >&2
  exit 2
fi
ROLLBACK_SOURCE_IMAGE="$PREVIOUS_SPEC_IMAGE"
if [[ "$PREVIOUS_SOURCE_IMAGE" != "$ROLLBACK_SOURCE_IMAGE" ]]; then
  echo "origem EasyPanel anterior sera normalizada para o digest imutavel da spec durante eventual rollback" >&2
fi

# Local deploy values are embedded; remote values are escaped. Swarm must keep
# the full repo@sha256 reference in both its spec and running task.
DEPLOY_MUTATION_STARTED=1
# shellcheck disable=SC2087
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
docker service update \
  --update-order stop-first \
  --update-failure-action rollback \
  --update-monitor 30s \
  --rollback-order stop-first \
  --rollback-failure-action pause \
  --rollback-monitor 30s \
  --detach=true \
  --image '$image_digest_ref' \
  --env-add GIT_SHA='$sha' \
  --env-add SENTRY_RELEASE='$sha' \
  --env-add DEPLOY_TIMESTAMP='$deploy_timestamp' \
  --env-add MANALOOM_ALLOWED_ORIGINS='$ALLOWED_ORIGINS_CANONICAL' \
  --env-add MANALOOM_TRUSTED_PROXY_HOPS='$MANALOOM_TRUSTED_PROXY_HOPS' \
  --env-add MANALOOM_TRUSTED_PROXY_PEERS='$MANALOOM_TRUSTED_PROXY_PEERS' \
  --env-add SENTRY_DSN='$SENTRY_DSN' \
  --env-add SENTRY_ENVIRONMENT=production \
  --env-add SENTRY_RELEASE='manaloom-backend@$short_sha' \
  '$SERVICE'

for attempt in \$(seq 1 45); do
  replicas="\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -n 1)"
  spec_image="\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')"
  running_image="\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -n 1)"
  update_state="\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')"
  if [ "\$replicas" = "1/1" ] && \
     [ "\$spec_image" = '$image_digest_ref' ] && \
     [ "\$running_image" = '$image_digest_ref' ] && \
     { [ -z "\$update_state" ] || [ "\$update_state" = "completed" ]; }; then
    docker service ls --filter name='$SERVICE' --format '{{.Name}} {{.Image}} {{.Replicas}}'
    exit 0
  fi
  case "\$update_state" in
    paused|rollback_started|rollback_paused)
      break
      ;;
  esac
  sleep 2
done

docker service inspect '$SERVICE' --format 'image={{.Spec.TaskTemplate.ContainerSpec.Image}} update={{if .UpdateStatus}}{{.UpdateStatus.State}} {{.UpdateStatus.Message}}{{end}}'
docker service ps '$SERVICE' --no-trunc
exit 1
REMOTE

spec_allowed_origins_sha256="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk -F= '
    /^MANALOOM_ALLOWED_ORIGINS=/{count++; value=substr(\$0,index(\$0,\"=\")+1)}
    END{if(count==1) printf \"%s\",value; else printf \"__invalid_count_%d__\",count}' |
  sha256sum | awk '{print \$1}'
")"
if [[ "$spec_allowed_origins_sha256" != "$ALLOWED_ORIGINS_SHA256" ]]; then
  echo "deploy convergiu sem a allowlist CORS exata na spec do servico" >&2
  exit 2
fi
spec_proxy_contract="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk '
    /^MANALOOM_TRUSTED_PROXY_HOPS=/{hops_count++; hops=substr(\$0,index(\$0,\"=\")+1)}
    /^MANALOOM_TRUSTED_PROXY_PEERS=/{peers_count++; peers=substr(\$0,index(\$0,\"=\")+1)}
    END{printf \"%d|%s|%d|%s\",hops_count,hops,peers_count,peers}'
")"
if [[ "$spec_proxy_contract" != "1|$MANALOOM_PRODUCTION_TRUSTED_PROXY_HOPS|1|$MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS" ]]; then
  echo "deploy convergiu sem o contrato exato do proxy confiavel na spec" >&2
  exit 2
fi
spec_sentry_dsn_sha256="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk '
    /^SENTRY_DSN=/{count++; value=substr(\$0,index(\$0,\"=\")+1)}
    END{if(count==1) printf \"%s\",value; else printf \"__invalid_count_%d__\",count}' |
  sha256sum | awk '{print \$1}'
")"
spec_sentry_metadata="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk '
    /^SENTRY_ENVIRONMENT=/{environment_count++; environment=substr(\$0,index(\$0,\"=\")+1)}
    /^SENTRY_RELEASE=/{release_count++; release=substr(\$0,index(\$0,\"=\")+1)}
    END{printf \"%d|%s|%d|%s\",environment_count,environment,release_count,release}'
")"
if [[ "$spec_sentry_dsn_sha256" != "$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256" ||
      "$spec_sentry_metadata" != "1|production|1|manaloom-backend@$short_sha" ]]; then
  echo "deploy convergiu sem o projeto/release Sentry exato na spec" >&2
  exit 2
fi

source_payload="$(jq -cn \
  --arg project "$EASYPANEL_PROJECT" \
  --arg service "$EASYPANEL_SERVICE" \
  --arg image "$image_digest_ref" \
  '{projectName:$project,serviceName:$service,image:$image}')"
SOURCE_MUTATED=1
trpc_post services.app.updateSourceImage "$source_payload" >/dev/null

runtime_contract="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker inspect \"\$container\" --format '{{range .Config.Env}}{{println .}}{{end}}' |
  awk -F= '
    /^GIT_SHA=/{sha=\$2}
    /^DB_HOST=/{host=\$2}
    /^DB_PORT=/{port=\$2}
    /^DB_NAME=/{name=\$2}
    /^BATTLE_ENGINE=/{engine=\$2}
    /^XMAGE_SIDECAR_URL=/{xmage=\$2}
    /^FORGE_SIDECAR_URL=/{forge=\$2}
    /^NATIVE_BATTLE_SIDECAR_URL=/{native=\$2}
    /^ENVIRONMENT=/{environment=\$2}
    /^OPENAI_PROFILE=/{profile=\$2}
    /^OPENAI_API_KEY=/{openai=(length(substr(\$0,index(\$0,\"=\")+1))>0 ? 1 : 0)}
    /^MANALOOM_OPS_API_KEY=/{ops=(length(substr(\$0,index(\$0,\"=\")+1))>=32 ? 1 : 0)}
    /^JWT_SECRET=/ {
      value=substr(\$0,index(\$0,\"=\")+1)
      normalized=tolower(value)
      jwt=(length(value)>=32 && normalized !~ /(change_this|changeme|placeholder|not_for_production|not-for-production|local_test|local-test|password)/) ? 1 : 0
    }
    /^MANALOOM_TRUSTED_PROXY_HOPS=/{proxy_hops_count++; proxy_hops=substr(\$0,index(\$0,\"=\")+1)}
    /^MANALOOM_TRUSTED_PROXY_PEERS=/{proxy_peers_count++; proxy_peers=substr(\$0,index(\$0,\"=\")+1)}
    END{print sha \"|\" host \"|\" port \"|\" name \"|\" engine \"|\" xmage \"|\" forge \"|\" native \"|\" environment \"|\" profile \"|\" openai \"|\" ops \"|\" jwt \"|\" proxy_hops_count \"|\" proxy_hops \"|\" proxy_peers_count \"|\" proxy_peers}'
")"
IFS='|' read -r runtime_sha runtime_db_host runtime_db_port runtime_db_name runtime_battle_engine runtime_xmage_url runtime_forge_url runtime_native_url runtime_environment runtime_openai_profile runtime_openai_configured runtime_ops_configured runtime_jwt_configured runtime_proxy_hops_count runtime_proxy_hops runtime_proxy_peers_count runtime_proxy_peers <<<"$runtime_contract"
runtime_allowed_origins_sha256="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker inspect \"\$container\" --format '{{range .Config.Env}}{{println .}}{{end}}' |
  awk -F= '
    /^MANALOOM_ALLOWED_ORIGINS=/{count++; value=substr(\$0,index(\$0,\"=\")+1)}
    END{if(count==1) printf \"%s\",value; else printf \"__invalid_count_%d__\",count}' |
  sha256sum | awk '{print \$1}'
")"
runtime_sentry_dsn_sha256="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker inspect \"\$container\" --format '{{range .Config.Env}}{{println .}}{{end}}' |
  awk '
    /^SENTRY_DSN=/{count++; value=substr(\$0,index(\$0,\"=\")+1)}
    END{if(count==1) printf \"%s\",value; else printf \"__invalid_count_%d__\",count}' |
  sha256sum | awk '{print \$1}'
")"
runtime_sentry_metadata="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker inspect \"\$container\" --format '{{range .Config.Env}}{{println .}}{{end}}' |
  awk '
    /^SENTRY_ENVIRONMENT=/{environment_count++; environment=substr(\$0,index(\$0,\"=\")+1)}
    /^SENTRY_RELEASE=/{release_count++; release=substr(\$0,index(\$0,\"=\")+1)}
    END{printf \"%d|%s|%d|%s\",environment_count,environment,release_count,release}'
")"
if [[ "$runtime_sha|$runtime_db_host|$runtime_db_port|$runtime_db_name|$runtime_battle_engine|$runtime_xmage_url|$runtime_forge_url|$runtime_native_url" != "$sha|$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME|$EXPECTED_BATTLE_ENGINE|$EXPECTED_XMAGE_URL|$EXPECTED_FORGE_URL|$EXPECTED_NATIVE_URL" ||
      "$runtime_environment" != "production" ||
      ( -n "$runtime_openai_profile" && "$runtime_openai_profile" != "prod" ) ||
      "$runtime_openai_configured" != "1" ||
      "$runtime_ops_configured" != "1" ||
      "$runtime_jwt_configured" != "1" ||
      "$runtime_proxy_hops_count" != "1" ||
      "$runtime_proxy_hops" != "$MANALOOM_PRODUCTION_TRUSTED_PROXY_HOPS" ||
      "$runtime_proxy_peers_count" != "1" ||
      "$runtime_proxy_peers" != "$MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS" ||
      "$runtime_allowed_origins_sha256" != "$ALLOWED_ORIGINS_SHA256" ||
      "$runtime_sentry_dsn_sha256" != "$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256" ||
      "$runtime_sentry_metadata" != "1|production|1|manaloom-backend@$short_sha" ]]; then
  echo "deploy convergiu com SHA ou contrato PostgreSQL/battle/IA/auth/CORS/Sentry divergente" >&2
  exit 2
fi

readiness_payload=""
readiness_attempts="${MANALOOM_DEPLOY_READINESS_ATTEMPTS:-8}"
if ! [[ "$readiness_attempts" =~ ^[1-9][0-9]*$ ]]; then
  echo "MANALOOM_DEPLOY_READINESS_ATTEMPTS deve ser inteiro positivo" >&2
  exit 2
fi
for attempt in $(seq 1 "$readiness_attempts"); do
  if readiness_payload="$(curl -fsS "$API_BASE_URL/health/ready" 2>/dev/null)" &&
     jq -e '
       .status == "ready" and
       .environment == "production" and
       .checks.ai_runtime.status == "healthy" and
       .checks.ai_runtime.provider_configured == true and
       .checks.ai_runtime.mock_fallbacks_allowed == false and
       .checks.battle_runtime.status == "healthy" and
       .checks.battle_runtime.mode == "auto" and
       .checks.battle_runtime.engines.xmage.status == "healthy" and
       .checks.battle_runtime.engines.forge.status == "healthy" and
       .checks.battle_runtime.engines.native.status == "healthy"
     ' >/dev/null <<<"$readiness_payload"; then
    break
  fi
  readiness_payload=""
  if [[ "$attempt" -lt "$readiness_attempts" ]]; then
    echo "readiness ainda indisponivel apos deploy; tentativa $attempt/$readiness_attempts" >&2
    sleep "$((attempt * 2))"
  fi
done
if [[ -z "$readiness_payload" ]]; then
  echo "deploy convergiu, mas o readiness de IA/Battle recusou o runtime" >&2
  exit 2
fi

runtime_image_contract="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
spec_image=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running_image=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -n 1)
printf '%s|%s' \"\$spec_image\" \"\$running_image\"
")"
IFS='|' read -r runtime_spec_image runtime_running_image <<<"$runtime_image_contract"
if [[ "$runtime_spec_image" != "$image_digest_ref" ||
      "$runtime_running_image" != "$image_digest_ref" ]]; then
  echo "deploy convergiu sem o digest exato na spec/tarefa: $runtime_image_contract" >&2
  exit 2
fi

services_payload="$(trpc_post projects.listProjectsAndServices null)"
configured_image="$(jq -er \
  --arg project "$EASYPANEL_PROJECT" \
  --arg service "$EASYPANEL_SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$services_payload")"
if [[ "$configured_image" != "$image_digest_ref" ]]; then
  echo "deploy convergiu sem o digest exato na origem EasyPanel: $configured_image" >&2
  exit 2
fi

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "rm -rf '$remote_dir'"

DEPLOY_COMMITTED=1
jq -cn \
  --arg service "$SERVICE" \
  --arg image "$IMAGE_REPO:$short_sha" \
  --arg image_digest_ref "$image_digest_ref" \
  --arg git_sha "$sha" \
  --arg remote_dir_removed "$remote_dir" \
  '{
    status: "deployed",
    service: $service,
    image: $image,
    image_digest_ref: $image_digest_ref,
    git_sha: $git_sha,
    cors_allowlist: "verified",
    remote_dir_removed: $remote_dir_removed
  }'

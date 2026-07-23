#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_postgres_write_approval "E2E de contrato da API em PostgreSQL descartável"
require_live_mutation_approval "E2E de contrato da API em PostgreSQL descartável"

for tool in createdb curl dart dart_frog dropdb psql python3 shasum; do
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
ISOLATED_ENVIRONMENT="${MANALOOM_ISOLATED_SERVER_ENVIRONMENT:-development}"

case "$ISOLATED_ENVIRONMENT" in
  development|test|staging|production) ;;
  *) echo "ambiente isolado inválido: $ISOLATED_ENVIRONMENT" >&2; exit 2 ;;
esac

case "$DB_HOST" in
  localhost|127.0.0.1|::1) ;;
  *) echo "BLOCKED: harness aceita somente PostgreSQL loopback" >&2; exit 2 ;;
esac

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$$"
OPS_KEY="manaloom-isolated-ops-${RUN_ID}-key-material"
DATABASE="manaloom_s1_api_${RUN_ID}"
RUN_DIR="${TMPDIR:-/tmp}/manaloom_server_contract_e2e_${RUN_ID}"
SERVER_LOG="$RUN_DIR/server.log"
EMAIL_FIXTURE_LOG="$RUN_DIR/email-delivery-evidence.jsonl"
TEST_LOG="$RUN_DIR/tests.log"
SUMMARY="$RUN_DIR/summary.txt"
mkdir -p "$RUN_DIR"
touch "$EMAIL_FIXTURE_LOG"

PORT="$(python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
)"
EMAIL_FIXTURE_PORT="$(python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
)"
SERVER_PID=""
EMAIL_FIXTURE_PID=""
export PGPASSWORD="$DB_PASS"

cleanup() {
  rm -f "$RUN_DIR/AtomicCards.json"
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$EMAIL_FIXTURE_PID" ]]; then
    kill "$EMAIL_FIXTURE_PID" >/dev/null 2>&1 || true
    wait "$EMAIL_FIXTURE_PID" >/dev/null 2>&1 || true
  fi
  dropdb --if-exists --force \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DATABASE" \
    >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

MANALOOM_EMAIL_FIXTURE_PORT="$EMAIL_FIXTURE_PORT" \
  MANALOOM_EMAIL_FIXTURE_LOG="$EMAIL_FIXTURE_LOG" \
  python3 "$ROOT_DIR/scripts/testing/manaloom_email_webhook_fixture.py" \
  >"$RUN_DIR/email-fixture.log" 2>&1 &
EMAIL_FIXTURE_PID=$!
for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:$EMAIL_FIXTURE_PORT/health" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$EMAIL_FIXTURE_PID" >/dev/null 2>&1; then
    echo "fixture de email encerrou antes do healthcheck" >&2
    exit 1
  fi
  sleep 0.1
done

createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  --maintenance-db="$DB_ADMIN" "$DATABASE"
psql -X -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
  -f "$SERVER_DIR/database_setup.sql" >"$RUN_DIR/bootstrap.log" 2>&1

(
  cd "$SERVER_DIR"
  DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$DB_PASS" DB_NAME="$DATABASE" \
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    dart run bin/migrate.dart
) >"$RUN_DIR/migrate.log" 2>&1

FULL_CARD_COUNT=0
if [[ "${MANALOOM_ISOLATED_FULL_CARD_CATALOG:-0}" == "1" ]]; then
  ATOMIC_CARDS="$RUN_DIR/AtomicCards.json"
  curl -fsSL --retry 3 --retry-delay 2 \
    https://mtgjson.com/api/v5/AtomicCards.json \
    -o "$ATOMIC_CARDS"
  (
    cd "$SERVER_DIR"
    DATABASE_URL= DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
      DB_PASS="$DB_PASS" DB_NAME="$DATABASE" \
      python3 bin/sync_cards_full_fast.py \
        --atomic-cards "$ATOMIC_CARDS" \
        --batch-size 10000
  ) >"$RUN_DIR/full-card-catalog.json" 2>"$RUN_DIR/full-card-catalog.log"
  rm -f "$ATOMIC_CARDS"
  FULL_CARD_COUNT="$(
    psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
      -d "$DATABASE" -c 'SELECT COUNT(*) FROM cards'
  )"
  if [[ ! "$FULL_CARD_COUNT" =~ ^[0-9]+$ || "$FULL_CARD_COUNT" -lt 30000 ]]; then
    echo "catálogo MTGJSON isolado incompleto: $FULL_CARD_COUNT" >&2
    exit 1
  fi
fi

# Deterministic product fixture used by card, deck, community and trade flows.
# It exists only in the disposable database and is removed with that database.
psql -X -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
  -c "
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, set_code, rarity, price_usd, cmc
    ) VALUES
    (
      '00000000-0000-4000-8000-000000000001'::uuid,
      '00000000-0000-4000-8000-000000000002'::uuid,
      'Sol Ring', '{1}', 'Artifact',
      '{T}: Add {C}{C}.', ARRAY[]::text[], ARRAY[]::text[],
      'TST', 'uncommon', 1.50, 1
    ),
    (
      '00000000-0000-4000-8000-000000000007'::uuid,
      '00000000-0000-4000-8000-000000000002'::uuid,
      'Sol Ring', '{1}', 'Artifact',
      '{T}: Add {C}{C}.', ARRAY[]::text[], ARRAY[]::text[],
      'T2S', 'rare', 2.50, 1
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, 'commander', 'legal' FROM cards WHERE name = 'Sol Ring'
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, set_code, rarity, price_usd, cmc
    ) VALUES (
      '00000000-0000-4000-8000-000000000003'::uuid,
      '00000000-0000-4000-8000-000000000004'::uuid,
      'Plains', NULL, 'Basic Land — Plains',
      '({T}: Add {W}.)', ARRAY[]::text[], ARRAY['W']::text[],
      'TST', 'common', 0.10, 0
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, format, 'legal'
    FROM cards
    CROSS JOIN (VALUES ('standard'), ('modern')) AS formats(format)
    WHERE name = 'Plains'
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, set_code, rarity, price_usd, cmc
    ) VALUES (
      '00000000-0000-4000-8000-000000000005'::uuid,
      '00000000-0000-4000-8000-000000000006'::uuid,
      'Island', NULL, 'Basic Land — Island',
      '({T}: Add {U}.)', ARRAY[]::text[], ARRAY['U']::text[],
      'TST', 'common', 0.10, 0
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, format, 'legal'
    FROM cards
    CROSS JOIN (VALUES ('standard'), ('modern')) AS formats(format)
    WHERE name = 'Island'
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
  " >"$RUN_DIR/fixture.log" 2>&1

(
  cd "$SERVER_DIR"
  dart_frog build
) >"$RUN_DIR/build.log" 2>&1

(
  cd "$SERVER_DIR"
  DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$DB_PASS" DB_NAME="$DATABASE" \
    JWT_SECRET="manaloom-isolated-contract-${RUN_ID}-not-production" \
    MANALOOM_PASSWORD_RESET_TEST_RESPONSE="I_UNDERSTAND_RESET_TOKENS_ARE_TEST_ONLY" \
    MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE="I_UNDERSTAND_VERIFICATION_TOKENS_ARE_TEST_ONLY" \
    PASSWORD_RESET_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver" \
    PASSWORD_RESET_WEBHOOK_TOKEN="isolated-fixture" \
    PASSWORD_RESET_APP_URL="http://127.0.0.1:$PORT/app/#/reset-password" \
    EMAIL_VERIFICATION_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver" \
    EMAIL_VERIFICATION_WEBHOOK_TOKEN="isolated-fixture" \
    EMAIL_VERIFICATION_APP_URL="http://127.0.0.1:$PORT/app/#/verify-email" \
    MANALOOM_OPS_API_KEY="$OPS_KEY" \
    MANALOOM_REQUIRE_LEGAL_ACCEPTANCE="${MANALOOM_REQUIRE_LEGAL_ACCEPTANCE:-false}" \
    MANALOOM_REQUIRE_VERIFIED_EMAIL="${MANALOOM_REQUIRE_VERIFIED_EMAIL:-false}" \
    ENVIRONMENT="$ISOLATED_ENVIRONMENT" PORT="$PORT" \
    exec dart build/bin/server.dart
) >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

ready=0
for _ in $(seq 1 80); do
  if curl -fsS "http://127.0.0.1:$PORT/health/live" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "servidor encerrou antes do healthcheck" >&2
    tail -80 "$SERVER_LOG" >&2 || true
    exit 1
  fi
  sleep 0.25
done
if [[ "$ready" != 1 ]]; then
  echo "timeout aguardando /health/live" >&2
  tail -80 "$SERVER_LOG" >&2 || true
  exit 1
fi

# Optional browser-QA mode. It keeps the same disposable PostgreSQL/API/email
# fixture alive until the caller interrupts this process; the existing trap
# still owns and proves cleanup. No production coordinate is ever accepted.
if [[ "${MANALOOM_HOLD_FOR_BROWSER_QA:-0}" == "1" ]]; then
  BROWSER_READY="$RUN_DIR/browser-ready.env"
  {
    printf 'scope=browser_qa_isolated_loopback\n'
    printf 'api_base_url=http://127.0.0.1:%s\n' "$PORT"
    printf 'database=%s\n' "$DATABASE"
    printf 'run_dir=%s\n' "$RUN_DIR"
    printf 'cleanup=trap_registered\n'
  } >"$BROWSER_READY"
  printf 'READY: isolated browser QA fixture\n'
  printf 'ready_manifest=%s\n' "$BROWSER_READY"
  printf 'api_base_url=http://127.0.0.1:%s\n' "$PORT"
  printf 'database=%s\n' "$DATABASE"
  while kill -0 "$SERVER_PID" >/dev/null 2>&1; do
    sleep 1
  done
  echo "servidor browser QA encerrou inesperadamente" >&2
  exit 1
fi

if (($# > 0)); then
  tests=("$@")
else
  tests=("test/error_contract_test.dart")
fi
(
  cd "$SERVER_DIR"
  DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$DB_PASS" DB_NAME="$DATABASE" \
    RUN_INTEGRATION_TESTS=1 \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_TEST_OPS_API_KEY="$OPS_KEY" \
    TEST_API_BASE_URL="http://127.0.0.1:$PORT" \
    dart test "${tests[@]}"
) 2>&1 | tee "$TEST_LOG"

migration_count="$(
  psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COUNT(*) FROM schema_migrations'
)"
email_delivery_count="$(
  (wc -l <"$EMAIL_FIXTURE_LOG" 2>/dev/null || printf '0') | tr -d '[:space:]'
)"
email_delivery_templates="$(
  python3 - "$EMAIL_FIXTURE_LOG" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
templates = set()
if path.exists():
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            templates.add(json.loads(line)["template"])
print(",".join(sorted(templates)))
PY
)"
if [[ -n "${MANALOOM_EXPECT_EMAIL_TEMPLATES:-}" ]]; then
  IFS=',' read -r -a expected_templates <<<"$MANALOOM_EXPECT_EMAIL_TEMPLATES"
  for template in "${expected_templates[@]}"; do
    if [[ ",$email_delivery_templates," != *",$template,"* ]]; then
      echo "template de email esperado não foi entregue: $template" >&2
      exit 1
    fi
  done
fi
{
  printf 'result=pass\n'
  printf 'scope=server_contract_e2e_isolated_loopback\n'
  printf 'tests=%s\n' "${tests[*]}"
  printf 'migration_count=%s\n' "$migration_count"
  printf 'card_catalog_count=%s\n' "$FULL_CARD_COUNT"
  printf 'server_environment=%s\n' "$ISOLATED_ENVIRONMENT"
  printf 'openai_profile=%s\n' "${OPENAI_PROFILE:-default}"
  printf 'full_card_catalog_enabled=%s\n' "${MANALOOM_ISOLATED_FULL_CARD_CATALOG:-0}"
  printf 'latest_migration=051\n'
  printf 'email_delivery_count=%s\n' "$email_delivery_count"
  printf 'email_delivery_templates=%s\n' "$email_delivery_templates"
  printf 'email_delivery_log=sanitized_without_links_or_tokens\n'
  printf 'database_cleanup=trap_registered\n'
  printf 'server_cleanup=trap_registered\n'
} >"$SUMMARY"

SUMMARY_SHA="$(shasum -a 256 "$SUMMARY" | awk '{print $1}')"
printf 'PASS: isolated server contract E2E\n'
printf 'summary=%s\n' "$SUMMARY"
printf 'summary_sha256=%s\n' "$SUMMARY_SHA"

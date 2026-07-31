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
if [[ -z "${INTERACTIVE_BATTLE_ENABLED+x}" ]]; then
  INTERACTIVE_BATTLE_ENABLED=false
fi

case "$ISOLATED_ENVIRONMENT" in
  development|test|staging|production) ;;
  *) echo "ambiente isolado inválido: $ISOLATED_ENVIRONMENT" >&2; exit 2 ;;
esac
case "$INTERACTIVE_BATTLE_ENABLED" in
  true|false) ;;
  *) echo "INTERACTIVE_BATTLE_ENABLED deve ser true ou false" >&2; exit 2 ;;
esac

case "$DB_HOST" in
  localhost|127.0.0.1|::1) ;;
  *) echo "BLOCKED: harness aceita somente PostgreSQL loopback" >&2; exit 2 ;;
esac

EGRESS_POLICY="deny_non_loopback"
EGRESS_GUARD_KIND=""
EGRESS_SANDBOX_PROFILE=""
EGRESS_GUARD=()
case "$(uname -s)" in
  Darwin)
    command -v sandbox-exec >/dev/null 2>&1 || {
      echo "BLOCKED: sandbox-exec é obrigatório para o harness sem egress" >&2
      exit 2
    }
    EGRESS_GUARD_KIND="macos_sandbox_exec_loopback_only"
    EGRESS_SANDBOX_PROFILE='(version 1)
(allow default)
(deny network*)
(allow network-outbound (remote ip "localhost:*"))
(allow network-inbound (local ip "localhost:*"))'
    EGRESS_GUARD=(sandbox-exec -p "$EGRESS_SANDBOX_PROFILE")
    ;;
  *)
    echo "BLOCKED: não há guard de egress loopback-only suportado neste sistema" >&2
    exit 2
    ;;
esac

run_no_egress() {
  "${EGRESS_GUARD[@]}" "$@"
}

if run_no_egress python3 -c \
  'import socket; socket.socket(socket.AF_INET, socket.SOCK_DGRAM).connect(("1.1.1.1", 53))' \
  >/dev/null 2>&1; then
  echo "BLOCKED: o guard de egress permitiu conexão não-loopback" >&2
  exit 2
fi
EGRESS_GUARD_SELF_TEST="pass"

if [[ "${MANALOOM_ISOLATED_FULL_CARD_CATALOG:-0}" == "1" ]]; then
  echo "BLOCKED: catálogo remoto é incompatível com o harness sem egress" >&2
  exit 2
fi

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$$"
OPS_KEY="manaloom-isolated-ops-${RUN_ID}-key-material"
ISOLATED_JWT_SECRET="manaloom-isolated-contract-${RUN_ID}-not-production"
ISOLATED_OPTIMIZATION_SIGNING_SECRET="$(
  run_no_egress python3 -c \
    'import secrets; print("manaloom-isolated-optimization-" + secrets.token_hex(32))'
)"
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
  run_no_egress dropdb --if-exists --force \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DATABASE" \
    >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

run_no_egress env \
  MANALOOM_EMAIL_FIXTURE_PORT="$EMAIL_FIXTURE_PORT" \
  MANALOOM_EMAIL_FIXTURE_LOG="$EMAIL_FIXTURE_LOG" \
  python3 "$ROOT_DIR/scripts/testing/manaloom_email_webhook_fixture.py" \
  >"$RUN_DIR/email-fixture.log" 2>&1 &
EMAIL_FIXTURE_PID=$!
for _ in $(seq 1 40); do
  if run_no_egress curl -fsS \
    "http://127.0.0.1:$EMAIL_FIXTURE_PORT/health" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$EMAIL_FIXTURE_PID" >/dev/null 2>&1; then
    echo "fixture de email encerrou antes do healthcheck" >&2
    exit 1
  fi
  sleep 0.1
done

run_no_egress createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  --maintenance-db="$DB_ADMIN" "$DATABASE"
run_no_egress psql -X -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
  -f "$SERVER_DIR/database_setup.sql" >"$RUN_DIR/bootstrap.log" 2>&1

(
  cd "$SERVER_DIR"
  run_no_egress env \
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$DB_PASS" DB_NAME="$DATABASE" \
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    dart run bin/migrate.dart
) >"$RUN_DIR/migrate.log" 2>&1

FULL_CARD_COUNT=0

# Deterministic product fixture used by card, deck, community and trade flows.
# It exists only in the disposable database and is removed with that database.
run_no_egress psql -X -v ON_ERROR_STOP=1 \
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
    CROSS JOIN (VALUES ('standard'), ('modern'), ('commander')) AS formats(format)
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
    CROSS JOIN (VALUES ('standard'), ('modern'), ('commander')) AS formats(format)
    WHERE name = 'Island'
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, power, toughness, set_code, rarity,
      price_usd, collector_number, foil, layout, cmc
    ) VALUES
    (
      '10000000-0000-4000-8000-000000000001'::uuid,
      '10000000-0000-4000-8000-000000000010'::uuid,
      'Talrand, Sky Summoner', '{2}{U}{U}',
      'Legendary Creature — Merfolk Wizard',
      'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
      ARRAY['U']::text[], ARRAY['U']::text[], '2', '2',
      'M13', 'rare', 0.50, '72', FALSE, 'normal', 4
    ),
    (
      '10000000-0000-4000-8000-000000000002'::uuid,
      '10000000-0000-4000-8000-000000000010'::uuid,
      'Talrand, Sky Summoner', '{2}{U}{U}',
      'Legendary Creature — Merfolk Wizard',
      'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
      ARRAY['U']::text[], ARRAY['U']::text[], '2', '2',
      'CMM', 'rare', 0.75, '125', TRUE, 'normal', 4
    ),
    (
      '10000000-0000-4000-8000-000000000003'::uuid,
      '10000000-0000-4000-8000-000000000011'::uuid,
      'Lightning Bolt', '{R}', 'Instant',
      'Lightning Bolt deals 3 damage to any target.',
      ARRAY['R']::text[], ARRAY['R']::text[], NULL, NULL,
      'M11', 'common', 1.00, '149', FALSE, 'normal', 1
    ),
    (
      '10000000-0000-4000-8000-000000000004'::uuid,
      '10000000-0000-4000-8000-000000000012'::uuid,
      'Wastes', NULL, 'Basic Land — Wastes',
      '{T}: Add {C}.',
      ARRAY[]::text[], ARRAY[]::text[], NULL, NULL,
      'OGW', 'common', 0.25, '184', FALSE, 'normal', 0
    ),
    (
      '10000000-0000-4000-8000-000000000005'::uuid,
      '10000000-0000-4000-8000-000000000013'::uuid,
      'Lorehold, the Historian', '{3}{R}{W}',
      'Legendary Creature — Elder Dragon',
      'Flying, haste. Lorehold, the Historian can be your commander.',
      ARRAY['R','W']::text[], ARRAY['R','W']::text[], '4', '4',
      'SOS', 'mythic', 3.00, '201', FALSE, 'normal', 5
    ),
    (
      '10000000-0000-4000-8000-000000000006'::uuid,
      '10000000-0000-4000-8000-000000000013'::uuid,
      'Lorehold, the Historian', '{3}{R}{W}',
      'Legendary Creature — Elder Dragon',
      'Flying, haste. Lorehold, the Historian can be your commander.',
      ARRAY['R','W']::text[], ARRAY['R','W']::text[], '4', '4',
      'PSOS', 'mythic', 5.00, '201p', TRUE, 'normal', 5
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, 'commander', 'legal'
    FROM cards
    WHERE name IN (
      'Talrand, Sky Summoner',
      'Lightning Bolt',
      'Wastes',
      'Lorehold, the Historian'
    )
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
  " >"$RUN_DIR/fixture.log" 2>&1

CARD_CATALOG_COUNT="$(
  run_no_egress psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COUNT(*) FROM cards'
)"

(
  cd "$SERVER_DIR"
  run_no_egress dart_frog build
) >"$RUN_DIR/build.log" 2>&1

(
  cd "$SERVER_DIR"
  exec "${EGRESS_GUARD[@]}" env \
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$DB_PASS" DB_NAME="$DATABASE" \
    JWT_SECRET="$ISOLATED_JWT_SECRET" \
    OPTIMIZATION_APPLY_SIGNING_SECRET="$ISOLATED_OPTIMIZATION_SIGNING_SECRET" \
    OPENAI_API_KEY= \
    OPENAI_BASE_URL= \
    OPENAI_PROFILE="isolated_no_provider" \
    OPTIMIZE_COMPLETE_DISABLE_OPENAI=1 \
    MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED= \
    HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= \
    NO_PROXY="localhost,127.0.0.1,::1" \
    AI_GENERATE_INTERNAL_BASE_URL="http://127.0.0.1:$PORT" \
    AI_OPTIMIZE_INTERNAL_BASE_URL="http://127.0.0.1:$PORT" \
    MANALOOM_PASSWORD_RESET_TEST_RESPONSE="I_UNDERSTAND_RESET_TOKENS_ARE_TEST_ONLY" \
    MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE="I_UNDERSTAND_VERIFICATION_TOKENS_ARE_TEST_ONLY" \
    PASSWORD_RESET_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver" \
    PASSWORD_RESET_WEBHOOK_TOKEN="isolated-fixture" \
    PASSWORD_RESET_APP_URL="http://127.0.0.1:$PORT/app/#/reset-password" \
    EMAIL_VERIFICATION_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver" \
    EMAIL_VERIFICATION_WEBHOOK_TOKEN="isolated-fixture" \
    EMAIL_VERIFICATION_APP_URL="http://127.0.0.1:$PORT/app/#/verify-email" \
    MANALOOM_OPS_API_KEY="$OPS_KEY" \
    MANALOOM_ALLOW_DEV_ORIGINS="${MANALOOM_ALLOW_DEV_ORIGINS:-false}" \
    MANALOOM_REQUIRE_LEGAL_ACCEPTANCE="${MANALOOM_REQUIRE_LEGAL_ACCEPTANCE:-false}" \
    MANALOOM_REQUIRE_VERIFIED_EMAIL="${MANALOOM_REQUIRE_VERIFIED_EMAIL:-false}" \
    BATTLE_JOB_WORKER_ENABLED=false \
    INTERACTIVE_BATTLE_ENABLED="${INTERACTIVE_BATTLE_ENABLED:-false}" \
    XMAGE_SIDECAR_URL="${XMAGE_SIDECAR_URL:-}" \
    XMAGE_INTERACTIVE_SIDECAR_URL="${XMAGE_INTERACTIVE_SIDECAR_URL:-}" \
    FORGE_SIDECAR_URL= \
    NATIVE_BATTLE_SIDECAR_URL= \
    XMAGE_EXPECTED_COMMIT="${XMAGE_EXPECTED_COMMIT:-}" \
    XMAGE_EXPECTED_PATCH_COMMIT="${XMAGE_EXPECTED_PATCH_COMMIT:-}" \
    XMAGE_EXPECTED_VERSION="${XMAGE_EXPECTED_VERSION:-}" \
    BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY="${BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY:-false}" \
    ENVIRONMENT="$ISOLATED_ENVIRONMENT" PORT="$PORT" \
    dart build/bin/server.dart
) >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

ready=0
for _ in $(seq 1 80); do
  if run_no_egress curl -fsS \
    "http://127.0.0.1:$PORT/health/live" >/dev/null 2>&1; then
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
    printf 'egress_policy=%s\n' "$EGRESS_POLICY"
    printf 'egress_guard=%s\n' "$EGRESS_GUARD_KIND"
    printf 'egress_guard_self_test=%s\n' "$EGRESS_GUARD_SELF_TEST"
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
  run_no_egress env \
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$DB_PASS" DB_NAME="$DATABASE" \
    OPTIMIZATION_APPLY_SIGNING_SECRET="$ISOLATED_OPTIMIZATION_SIGNING_SECRET" \
    OPENAI_API_KEY= \
    OPTIMIZE_COMPLETE_DISABLE_OPENAI=1 \
    MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED= \
    HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= \
    NO_PROXY="localhost,127.0.0.1,::1" \
    RUN_INTEGRATION_TESTS=1 \
    MANALOOM_ISOLATED_CONTRACT_E2E=1 \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_TEST_OPS_API_KEY="$OPS_KEY" \
    TEST_API_BASE_URL="http://127.0.0.1:$PORT" \
    dart test -j 1 "${tests[@]}"
) 2>&1 | tee "$TEST_LOG"

migration_count="$(
  run_no_egress psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COUNT(*) FROM schema_migrations'
)"
latest_migration="$(
  run_no_egress psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COALESCE(MAX(version), '\''none'\'') FROM schema_migrations'
)"
email_delivery_count="$(
  (wc -l <"$EMAIL_FIXTURE_LOG" 2>/dev/null || printf '0') | tr -d '[:space:]'
)"
email_delivery_templates="$(
  run_no_egress python3 - "$EMAIL_FIXTURE_LOG" <<'PY'
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
battle_sidecars_enabled=0
if [[ "$INTERACTIVE_BATTLE_ENABLED" == "true" ]]; then
  battle_sidecars_enabled=1
fi
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
  printf 'card_catalog_count=%s\n' "$CARD_CATALOG_COUNT"
  printf 'server_environment=%s\n' "$ISOLATED_ENVIRONMENT"
  printf 'egress_policy=%s\n' "$EGRESS_POLICY"
  printf 'egress_guard=%s\n' "$EGRESS_GUARD_KIND"
  printf 'egress_guard_self_test=%s\n' "$EGRESS_GUARD_SELF_TEST"
  printf 'openai_profile=isolated_no_provider\n'
  printf 'openai_provider_enabled=0\n'
  printf 'edhrec_collection_enabled=0\n'
  printf 'battle_sidecars_enabled=%s\n' "$battle_sidecars_enabled"
  printf 'optimization_apply_signing=isolated_ephemeral\n'
  printf 'full_card_catalog_enabled=%s\n' "${MANALOOM_ISOLATED_FULL_CARD_CATALOG:-0}"
  printf 'latest_migration=%s\n' "$latest_migration"
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

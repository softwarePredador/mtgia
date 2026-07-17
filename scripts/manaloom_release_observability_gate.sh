#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MTGIA_ENV_FILE:-$ROOT_DIR/server/.env}"
DEVICE="${MANALOOM_RELEASE_DEVICE:-}"
API_BASE_URL="${MANALOOM_API_BASE_URL:-}"
API_BASE_URL_EXPLICIT="$([[ -n "${MANALOOM_API_BASE_URL:-}" ]] && printf 1 || printf 0)"
EVIDENCE_DIR="${MANALOOM_OBSERVABILITY_EVIDENCE_DIR:-}"
REQUIRE_FCM_DELIVERY="${MANALOOM_REQUIRE_FCM_DELIVERY_PROOF:-1}"
FCM_DELIVERY_LOG="${MANALOOM_FCM_DELIVERY_PROOF_LOG:-}"
RELEASE_MANIFEST="${MANALOOM_RELEASE_MANIFEST:-}"
EXECUTE=0

usage() {
  cat <<'EOF'
Uso: manaloom_release_observability_gate.sh [opcoes]

Por padrao apenas descreve o gate. A execucao exige --execute e
MANALOOM_RELEASE_OBSERVABILITY_EXECUTE=1. Como o smoke registra um usuario e
token FCM no ambiente informado, tambem exige
MANALOOM_OBSERVABILITY_ALLOW_STATEFUL_API=1.

Opcoes:
  --device ID
  --api-base-url URL
  --env-file FILE
  --evidence-dir DIR
  --fcm-delivery-log FILE
  --release-manifest FILE
  --no-require-fcm-delivery
  --execute
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="${2:-}"; shift 2 ;;
    --api-base-url) API_BASE_URL="${2:-}"; API_BASE_URL_EXPLICIT=1; shift 2 ;;
    --env-file) ENV_FILE="${2:-}"; shift 2 ;;
    --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
    --fcm-delivery-log) FCM_DELIVERY_LOG="${2:-}"; shift 2 ;;
    --release-manifest) RELEASE_MANIFEST="${2:-}"; shift 2 ;;
    --no-require-fcm-delivery) REQUIRE_FCM_DELIVERY=0; shift ;;
    --execute) EXECUTE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$REQUIRE_FCM_DELIVERY" in
  0|1) ;;
  *) echo "MANALOOM_REQUIRE_FCM_DELIVERY_PROOF deve ser 0 ou 1" >&2; exit 2 ;;
esac

if [[ "$EXECUTE" == "0" ]]; then
  API_BASE_URL="${API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
  printf '{"status":"dry_run","device":"%s","api_base_url":"%s","release_manifest":"%s","release_identity_required":true,"sentry_ingestion_required":true,"fcm_registration_required":true,"fcm_delivery_required":%s,"stateful_api_write_on_execute":true,"writes_performed":false}\n' \
    "$DEVICE" "$API_BASE_URL" "$RELEASE_MANIFEST" "$([[ "$REQUIRE_FCM_DELIVERY" == "1" ]] && printf true || printf false)"
  exit 0
fi
if [[ "${MANALOOM_RELEASE_OBSERVABILITY_EXECUTE:-0}" != "1" ]]; then
  echo "execucao recusada: defina MANALOOM_RELEASE_OBSERVABILITY_EXECUTE=1 junto com --execute" >&2
  exit 2
fi
if [[ "${MANALOOM_OBSERVABILITY_ALLOW_STATEFUL_API:-0}" != "1" ]]; then
  echo "execucao recusada: o smoke FCM grava usuario/token de QA; defina MANALOOM_OBSERVABILITY_ALLOW_STATEFUL_API=1" >&2
  exit 2
fi
if [[ -z "$DEVICE" ]]; then
  echo "device fisico obrigatorio" >&2
  exit 2
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi
if [[ -z "$RELEASE_MANIFEST" || ! -f "$RELEASE_MANIFEST" ]]; then
  echo "manifesto do release obrigatorio: informe --release-manifest" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a
if [[ "$API_BASE_URL_EXPLICIT" == "0" ]]; then
  API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
fi
: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN ausente}"
: "${SENTRY_MOBILE_DSN:?SENTRY_MOBILE_DSN ausente}"
: "${SENTRY_ORG_SLUG:?SENTRY_ORG_SLUG ausente}"
: "${SENTRY_MOBILE_PROJECT_SLUG:?SENTRY_MOBILE_PROJECT_SLUG ausente}"

for tool in adb flutter git jq shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done

RELEASE_GIT_SHA="$(jq -er '.git_sha | select(type == "string" and length == 40)' "$RELEASE_MANIFEST")"
RELEASE_VERSION="$(jq -er '.version | select(type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+\\+[1-9][0-9]*$"))' "$RELEASE_MANIFEST")"
jq -e '.platform == "android" and .permissions_gate == "passed" and .sentry_configured == true' \
  "$RELEASE_MANIFEST" >/dev/null || {
  echo "manifesto Android nao esta apto ao gate de observabilidade" >&2
  exit 1
}
SOURCE_IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="$RELEASE_GIT_SHA" \
  MANALOOM_RELEASE_REQUIRE_CLEAN=1 \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
SOURCE_VERSION="$(jq -r '.version' <<<"$SOURCE_IDENTITY_JSON")"
if [[ "$SOURCE_VERSION" != "$RELEASE_VERSION" ]]; then
  echo "versao do pubspec no source diverge do manifesto: source=$SOURCE_VERSION manifest=$RELEASE_VERSION" >&2
  exit 1
fi
if [[ "$(adb -s "$DEVICE" get-state 2>/dev/null || true)" != "device" ]]; then
  echo "Android fisico indisponivel: $DEVICE" >&2
  exit 2
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-/tmp/manaloom-observability-$STAMP}"
mkdir -p "$EVIDENCE_DIR"
chmod 700 "$EVIDENCE_DIR"
SENTRY_LOG="$EVIDENCE_DIR/sentry-mobile.log"
FCM_LOG="$EVIDENCE_DIR/fcm-registration.log"

MTGIA_ENV_FILE="$ENV_FILE" \
API_BASE_URL="$API_BASE_URL" \
MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS="${MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS:-600}" \
  "$ROOT_DIR/scripts/validate_sentry_mobile_ingestion.sh" \
    -d "$DEVICE" \
    --no-version-check \
    --reporter expanded | tee "$SENTRY_LOG"

if grep -Eq 'not_configured|not_proven|TOOLCHAIN_BLOCKED' "$SENTRY_LOG"; then
  echo "Sentry nao foi provado" >&2
  exit 1
fi
SENTRY_EVENT_ID="$(sed -n 's/^SENTRY_MOBILE_EVENT_ID=//p' "$SENTRY_LOG" | tail -1)"
SENTRY_SMOKE_TAG="$(sed -n 's/^SENTRY_MOBILE_SMOKE_TAG=//p' "$SENTRY_LOG" | tail -1)"
if [[ -z "$SENTRY_EVENT_ID" || -z "$SENTRY_SMOKE_TAG" ]]; then
  echo "Sentry sem event_id/smoke_tag verificavel" >&2
  exit 1
fi

(
  cd "$ROOT_DIR/app"
  flutter test integration_test/fcm_staging_smoke_test.dart \
    -d "$DEVICE" \
    --dart-define="API_BASE_URL=$API_BASE_URL" \
    --no-version-check \
    --reporter expanded
) | tee "$FCM_LOG"

if grep -Fq 'FCM_SMOKE_RESULT=not_proven' "$FCM_LOG" ||
   ! grep -Fq 'FCM_SMOKE_RESULT=token_registered token_present=true' "$FCM_LOG"; then
  echo "FCM registration nao foi provado" >&2
  exit 1
fi

FCM_DELIVERY_SHA256=""
if [[ "$REQUIRE_FCM_DELIVERY" == "1" ]]; then
  if [[ -z "$FCM_DELIVERY_LOG" || ! -f "$FCM_DELIVERY_LOG" ]]; then
    echo "prova de entrega FCM obrigatoria; informe --fcm-delivery-log" >&2
    exit 1
  fi
  grep -Fq 'FCM_FOREGROUND_DELIVERY_PASS' "$FCM_DELIVERY_LOG"
  grep -Fq 'FCM_BACKGROUND_TAP_DELIVERY_PASS' "$FCM_DELIVERY_LOG"
  FCM_DELIVERY_SHA256="$(shasum -a 256 "$FCM_DELIVERY_LOG" | awk '{print $1}')"
fi

# Re-check after both Flutter integration runs so generated tooling cannot
# silently leave tracked source changes behind the evidence file.
FINAL_SOURCE_IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="$RELEASE_GIT_SHA" \
  MANALOOM_RELEASE_REQUIRE_CLEAN=1 \
  MANALOOM_RELEASE_FETCH_ORIGIN=0 \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
jq -e --arg sha "$RELEASE_GIT_SHA" --arg version "$RELEASE_VERSION" \
  '.git_sha == $sha and .version == $version' \
  <<<"$FINAL_SOURCE_IDENTITY_JSON" >/dev/null

jq -n \
  --arg status passed \
  --arg device "$DEVICE" \
  --arg api_base_url "$API_BASE_URL" \
  --arg git_sha "$RELEASE_GIT_SHA" \
  --arg version "$RELEASE_VERSION" \
  --arg sentry_event_id "$SENTRY_EVENT_ID" \
  --arg sentry_smoke_tag "$SENTRY_SMOKE_TAG" \
  --arg fcm_delivery_log_sha256 "$FCM_DELIVERY_SHA256" \
  --argjson fcm_delivery_required "$([[ "$REQUIRE_FCM_DELIVERY" == "1" ]] && printf true || printf false)" \
  '{
    status: $status,
    device: $device,
    api_base_url: $api_base_url,
    git_sha: $git_sha,
    version: $version,
    source_identity: "clean_head_origin_master_confirmed",
    runtime_test_scope: "integration_test_build_from_exact_clean_source",
    artifact_installation: "not_proven",
    sentry: {ingestion: "confirmed", event_id: $sentry_event_id, smoke_tag: $sentry_smoke_tag},
    fcm: {
      registration: "confirmed",
      delivery_required: $fcm_delivery_required,
      delivery_log_sha256: (if ($fcm_delivery_log_sha256 | length) > 0 then $fcm_delivery_log_sha256 else null end)
    }
  }' | tee "$EVIDENCE_DIR/observability-result.json"
chmod 600 "$EVIDENCE_DIR"/*

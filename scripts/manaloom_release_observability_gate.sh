#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MTGIA_ENV_FILE:-$ROOT_DIR/server/.env}"
CALLER_EXPECTED_SENTRY_DSN_SHA256="${MANALOOM_EXPECTED_SENTRY_DSN_SHA256:-}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
DEVICE="${MANALOOM_RELEASE_DEVICE:-}"
API_BASE_URL="${MANALOOM_API_BASE_URL:-}"
API_BASE_URL_EXPLICIT="$([[ -n "${MANALOOM_API_BASE_URL:-}" ]] && printf 1 || printf 0)"
EVIDENCE_DIR="${MANALOOM_OBSERVABILITY_EVIDENCE_DIR:-}"
REQUIRE_FCM_DELIVERY="${MANALOOM_REQUIRE_FCM_DELIVERY_PROOF:-1}"
FCM_DELIVERY_LOG="${MANALOOM_FCM_DELIVERY_PROOF_LOG:-}"
RELEASE_MANIFEST="${MANALOOM_RELEASE_MANIFEST:-}"
APK_PATH="${MANALOOM_RELEASE_APK:-}"
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
  --apk FILE
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
    --apk) APK_PATH="${2:-}"; shift 2 ;;
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
  jq -n \
    --arg device "$DEVICE" \
    --arg api_base_url "$API_BASE_URL" \
    --arg release_manifest "$RELEASE_MANIFEST" \
    --arg apk "$APK_PATH" \
    --argjson fcm_delivery_required "$([[ "$REQUIRE_FCM_DELIVERY" == "1" ]] && printf true || printf false)" \
    '{
      status: "dry_run",
      device: $device,
      api_base_url: $api_base_url,
      release_manifest: $release_manifest,
      apk: $apk,
      release_identity_required: true,
      exact_signed_apk_installation_required: true,
      physical_device_required: true,
      device_reinstall_acknowledgement_required: true,
      sentry_ingestion_required: true,
      fcm_registration_required: true,
      fcm_delivery_required: $fcm_delivery_required,
      stateful_api_write_on_execute: true,
      writes_performed: false
    }'
  exit 0
fi
require_live_mutation_approval "gate de observabilidade da release ManaLoom"
readonly LIVE_MUTATION_APPROVED=1
: "$LIVE_MUTATION_APPROVED"
if [[ "${MANALOOM_RELEASE_OBSERVABILITY_EXECUTE:-0}" != "1" ]]; then
  echo "execucao recusada: defina MANALOOM_RELEASE_OBSERVABILITY_EXECUTE=1 junto com --execute" >&2
  exit 2
fi
if [[ "${MANALOOM_OBSERVABILITY_ALLOW_STATEFUL_API:-0}" != "1" ]]; then
  echo "execucao recusada: o smoke FCM grava usuario/token de QA; defina MANALOOM_OBSERVABILITY_ALLOW_STATEFUL_API=1" >&2
  exit 2
fi
if [[ "${MANALOOM_OBSERVABILITY_ALLOW_DEVICE_REINSTALL:-0}" != "1" ]]; then
  echo "execucao recusada: a prova reinstala o APK no device; defina MANALOOM_OBSERVABILITY_ALLOW_DEVICE_REINSTALL=1" >&2
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
if [[ -z "$APK_PATH" || ! -f "$APK_PATH" ]]; then
  echo "APK assinado obrigatorio: informe --apk" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
load_manaloom_env_keys "$ENV_FILE" \
  API_BASE_URL MANALOOM_API_BASE_URL SENTRY_AUTH_TOKEN SENTRY_DSN \
  SENTRY_ENVIRONMENT SENTRY_MOBILE_DSN SENTRY_MOBILE_PROJECT_SLUG \
  SENTRY_ORG_SLUG SENTRY_TRACES_SAMPLE_RATE
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
MANALOOM_EXPECTED_SENTRY_DSN_SHA256="${CALLER_EXPECTED_SENTRY_DSN_SHA256:-$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256}"
readonly MANALOOM_EXPECTED_SENTRY_DSN_SHA256
export MANALOOM_EXPECTED_SENTRY_DSN_SHA256
validate_manaloom_exact_coordinate sentry_dsn_sha256 \
  "$MANALOOM_EXPECTED_SENTRY_DSN_SHA256" \
  "$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256"
if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]]; then
  SENTRY_AUTH_TOKEN="$(read_manaloom_keychain_secret \
    "$MANALOOM_SENTRY_AUTH_TOKEN_KEYCHAIN_SERVICE" || true)"
fi
if [[ -z "${SENTRY_MOBILE_DSN:-}" ]]; then
  SENTRY_MOBILE_DSN="${SENTRY_DSN:-}"
fi
if [[ -z "${SENTRY_MOBILE_DSN:-}" ]]; then
  SENTRY_MOBILE_DSN="$(read_manaloom_keychain_secret \
    "$MANALOOM_SENTRY_DSN_KEYCHAIN_SERVICE" || true)"
fi
SENTRY_ORG_SLUG="${SENTRY_ORG_SLUG:-$MANALOOM_PRODUCTION_SENTRY_ORG_SLUG}"
SENTRY_MOBILE_PROJECT_SLUG="${SENTRY_MOBILE_PROJECT_SLUG:-$MANALOOM_PRODUCTION_SENTRY_PROJECT_SLUG}"
if [[ "$API_BASE_URL_EXPLICIT" == "0" ]]; then
  API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
fi
: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN ausente}"
: "${SENTRY_MOBILE_DSN:?SENTRY_MOBILE_DSN ausente}"
: "${SENTRY_ORG_SLUG:?SENTRY_ORG_SLUG ausente}"
: "${SENTRY_MOBILE_PROJECT_SLUG:?SENTRY_MOBILE_PROJECT_SLUG ausente}"

for tool in adb curl git jq python3 shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done

# shellcheck source=scripts/lib/manaloom_flutter_release_sdk.sh
source "$ROOT_DIR/scripts/lib/manaloom_flutter_release_sdk.sh"
resolve_manaloom_release_flutter
validate_manaloom_release_api_base_url "$API_BASE_URL"
resolve_manaloom_release_sentry_dsn "$SENTRY_MOBILE_DSN" 1

RELEASE_GIT_SHA="$(jq -er '.git_sha | select(type == "string" and length == 40)' "$RELEASE_MANIFEST")"
RELEASE_SHORT_SHA="$(jq -er '.short_sha | select(type == "string" and test("^[0-9a-f]{12}$"))' "$RELEASE_MANIFEST")"
RELEASE_VERSION="$(jq -er '.version | select(type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+\\+[1-9][0-9]*$"))' "$RELEASE_MANIFEST")"
EXPECTED_SENTRY_RELEASE="manaloom-android@$RELEASE_SHORT_SHA"
EXPECTED_APK_SHA256="$(jq -er '.artifacts.apk.sha256 | select(type == "string" and test("^[0-9a-f]{64}$"))' "$RELEASE_MANIFEST")"
EXPECTED_IDENTITY_SHA256="$(jq -er '.artifacts.embedded_release_identity.sha256 | select(type == "string" and test("^[0-9a-f]{64}$"))' "$RELEASE_MANIFEST")"
EXPECTED_CERTIFICATE_SHA256="$(jq -er '.signing.certificate_sha256 | select(type == "string" and test("^[0-9a-f]{64}$"))' "$RELEASE_MANIFEST")"
APPROVED_CERTIFICATE_SHA256="$MANALOOM_APPROVED_ANDROID_CERT_SHA256"
if [[ "$EXPECTED_CERTIFICATE_SHA256" != "$APPROVED_CERTIFICATE_SHA256" ]]; then
  echo "certificado Android do manifesto diverge do fingerprint aprovado" >&2
  exit 1
fi
validate_manaloom_android_release_certificate "$EXPECTED_CERTIFICATE_SHA256"
EXPECTED_VERSION_NAME="${RELEASE_VERSION%%+*}"
EXPECTED_VERSION_CODE="${RELEASE_VERSION##*+}"
ACTUAL_APK_SHA256="$(shasum -a 256 "$APK_PATH" | awk '{print $1}')"
if [[ "$ACTUAL_APK_SHA256" != "$EXPECTED_APK_SHA256" ]]; then
  echo "APK informado diverge do hash registrado no manifesto" >&2
  exit 1
fi
"$ROOT_DIR/scripts/manaloom_verify_android_release_artifacts.sh" \
  --apk "$APK_PATH" \
  --expected-package com.mtgia.mtg_app \
  --expected-version "$RELEASE_VERSION" \
  --expected-cert-sha256 "$APPROVED_CERTIFICATE_SHA256" >/dev/null
jq -e \
  --arg sentry_release "$EXPECTED_SENTRY_RELEASE" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  '.platform == "android" and .permissions_gate == "passed" and
   .sentry_configured == true and .sentry_release == $sentry_release and
   .api_base_url == $api_base_url and .sentry_dsn_sha256 == $sentry_dsn_sha256' \
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
if [[ "$(adb -s "$DEVICE" shell getprop ro.kernel.qemu 2>/dev/null | tr -d '\r')" == "1" ||
      "$(adb -s "$DEVICE" shell getprop ro.boot.qemu 2>/dev/null | tr -d '\r')" == "1" ]]; then
  echo "device recusado: a prova final exige Android fisico, nao emulador" >&2
  exit 2
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-/tmp/manaloom-observability-$STAMP}"
mkdir -p "$EVIDENCE_DIR"
chmod 700 "$EVIDENCE_DIR"
FCM_LOG="$EVIDENCE_DIR/fcm-registration.log"
DEVICE_FINGERPRINT="$(printf '%s' "$DEVICE" | shasum -a 256 | awk '{print substr($1,1,12)}')"
INTEGRATION_SESSION_ID="manaloom-source-$RELEASE_SHORT_SHA-$STAMP-$DEVICE_FINGERPRINT"

(
  cd "$ROOT_DIR/app"
  "$MANALOOM_FLUTTER_BIN_RESOLVED" pub get --enforce-lockfile
)
git -C "$ROOT_DIR" diff --exit-code -- \
  pubspec.lock server/pubspec.lock app/pubspec.lock

(
  cd "$ROOT_DIR/app"
  "$MANALOOM_FLUTTER_BIN_RESOLVED" test integration_test/fcm_staging_smoke_test.dart \
    -d "$DEVICE" \
    --dart-define="API_BASE_URL=$API_BASE_URL" \
    --dart-define="MANALOOM_OBSERVABILITY_SESSION_ID=$INTEGRATION_SESSION_ID" \
    --no-version-check \
    --no-pub \
    --reporter expanded
) | tee "$FCM_LOG"

if grep -Fq 'FCM_SMOKE_RESULT=not_proven' "$FCM_LOG" ||
   ! grep -Fq "FCM_SMOKE_RESULT=token_registered token_present=true install_session_id=$INTEGRATION_SESSION_ID" "$FCM_LOG"; then
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
  grep -Fq "FCM_OBSERVABILITY_SESSION_ID=$INTEGRATION_SESSION_ID" "$FCM_DELIVERY_LOG"
  grep -Fq "FCM_RELEASE_GIT_SHA=$RELEASE_GIT_SHA" "$FCM_DELIVERY_LOG"
  grep -Fq 'FCM_PACKAGE_NAME=com.mtgia.mtg_app' "$FCM_DELIVERY_LOG"
  grep -Fq "FCM_APK_SHA256=$EXPECTED_APK_SHA256" "$FCM_DELIVERY_LOG"
  FCM_DELIVERY_SHA256="$(shasum -a 256 "$FCM_DELIVERY_LOG" | awk '{print $1}')"
fi

APK_INSTALL_LOG="$EVIDENCE_DIR/apk-install.log"
APK_LAUNCH_LOG="$EVIDENCE_DIR/apk-launch.log"
APK_RUNTIME_LOG="$EVIDENCE_DIR/apk-runtime.log"
SENTRY_RESPONSE="$EVIDENCE_DIR/sentry-exact-artifact-event.json"
PACKAGE_NAME="com.mtgia.mtg_app"
adb -s "$DEVICE" uninstall "$PACKAGE_NAME" >/dev/null 2>&1 || true
adb -s "$DEVICE" install "$APK_PATH" | tee "$APK_INSTALL_LOG"
grep -Fq 'Success' "$APK_INSTALL_LOG"
PACKAGE_DUMP="$(adb -s "$DEVICE" shell dumpsys package "$PACKAGE_NAME")"
grep -Eq "versionName=$EXPECTED_VERSION_NAME([[:space:]]|$)" <<<"$PACKAGE_DUMP"
grep -Eq "versionCode=$EXPECTED_VERSION_CODE([[:space:]]|$)" <<<"$PACKAGE_DUMP"
INSTALLED_APK_REMOTE="$(adb -s "$DEVICE" shell pm path "$PACKAGE_NAME" | sed -n 's/^package://p' | tr -d '\r' | head -1)"
if [[ -z "$INSTALLED_APK_REMOTE" ]]; then
  echo "nao foi possivel localizar o APK instalado" >&2
  exit 1
fi
INSTALLED_APK_COPY="$EVIDENCE_DIR/installed-base.apk"
adb -s "$DEVICE" pull "$INSTALLED_APK_REMOTE" "$INSTALLED_APK_COPY" >/dev/null
INSTALLED_APK_SHA256="$(shasum -a 256 "$INSTALLED_APK_COPY" | awk '{print $1}')"
rm -f "$INSTALLED_APK_COPY"
if [[ "$INSTALLED_APK_SHA256" != "$EXPECTED_APK_SHA256" ]]; then
  echo "APK instalado no device diverge do artefato assinado" >&2
  exit 1
fi
adb -s "$DEVICE" shell am force-stop "$PACKAGE_NAME"
adb -s "$DEVICE" logcat -c
adb -s "$DEVICE" shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 | tee "$APK_LAUNCH_LOG"
APP_PID=""
for _attempt in $(seq 1 20); do
  APP_PID="$(adb -s "$DEVICE" shell pidof "$PACKAGE_NAME" 2>/dev/null | tr -d '\r' | awk '{print $1}')"
  [[ -n "$APP_PID" ]] && break
  sleep 0.5
done
if [[ -z "$APP_PID" ]]; then
  echo "cold launch do APK assinado nao permaneceu ativo" >&2
  exit 1
fi

PROOF_LINE=""
for _attempt in $(seq 1 30); do
  adb -s "$DEVICE" logcat --pid="$APP_PID" -d -v brief >"$APK_RUNTIME_LOG"
  PROOF_LINE="$(grep 'MANALOOM_RELEASE_STARTUP_PROOF status=captured' "$APK_RUNTIME_LOG" | tail -1 || true)"
  [[ -n "$PROOF_LINE" ]] && break
  sleep 2
done
if [[ -z "$PROOF_LINE" ]]; then
  echo "APK assinado nao emitiu prova de startup Sentry/FCM" >&2
  exit 1
fi
SENTRY_EVENT_ID="$(sed -E 's/.* event_id=([0-9a-f]{32}).*/\1/' <<<"$PROOF_LINE")"
ARTIFACT_INSTALL_SESSION_ID="$(sed -E 's/.* install_session_id=([^ ]+).*/\1/' <<<"$PROOF_LINE")"
if [[ ! "$SENTRY_EVENT_ID" =~ ^[0-9a-f]{32}$ ||
      ! "$ARTIFACT_INSTALL_SESSION_ID" =~ ^[A-Za-z0-9_-]{20,64}$ ]]; then
  echo "prova do APK assinado possui event/session id invalido" >&2
  exit 1
fi
for expected_fragment in \
  "git_sha=$RELEASE_GIT_SHA" \
  "release_identity_sha256=$EXPECTED_IDENTITY_SHA256" \
  'fcm_initialized=true' \
  'fcm_token_present=true'; do
  if [[ "$PROOF_LINE" != *"$expected_fragment"* ]]; then
    echo "prova do APK assinado diverge: $expected_fragment" >&2
    exit 1
  fi
done

SENTRY_EVENT_URL="https://sentry.io/api/0/projects/${SENTRY_ORG_SLUG}/${SENTRY_MOBILE_PROJECT_SLUG}/events/${SENTRY_EVENT_ID}/"
SENTRY_EXACT_CONFIRMED=0
for _attempt in $(seq 1 12); do
  HTTP_CODE="$(curl -sS \
    -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
    "$SENTRY_EVENT_URL" \
    -o "$SENTRY_RESPONSE" \
    -w '%{http_code}' || true)"
  if [[ "$HTTP_CODE" == "200" ]] && python3 - \
    "$SENTRY_EVENT_ID" "$EXPECTED_SENTRY_RELEASE" "$RELEASE_GIT_SHA" \
    "$EXPECTED_IDENTITY_SHA256" "$ARTIFACT_INSTALL_SESSION_ID" \
    "$SENTRY_RESPONSE" <<'PY'
import json
import sys

event_id, expected_release, git_sha, identity_sha256, session_id, path = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)
tags = {
    str(item.get("key")): str(item.get("value"))
    for item in payload.get("tags", [])
    if isinstance(item, dict)
}
release_value = payload.get("release") or tags.get("release") or ""
if isinstance(release_value, dict):
    release_value = release_value.get("version") or ""
release = str(release_value)
valid = (
    event_id in json.dumps(payload, sort_keys=True)
    and release == expected_release
    and tags.get("proof_type") == "release_startup"
    and tags.get("git_sha") == git_sha
    and tags.get("release_identity_sha256") == identity_sha256
    and tags.get("install_session_id") == session_id
    and tags.get("package_name") == "com.mtgia.mtg_app"
    and tags.get("fcm_initialized") == "true"
    and tags.get("fcm_token_present") == "true"
)
raise SystemExit(0 if valid else 1)
PY
  then
    SENTRY_EXACT_CONFIRMED=1
    break
  fi
  sleep 5
done
if [[ "$SENTRY_EXACT_CONFIRMED" != "1" ]]; then
  echo "evento Sentry do APK assinado nao foi confirmado pela API" >&2
  exit 1
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
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  --arg git_sha "$RELEASE_GIT_SHA" \
  --arg version "$RELEASE_VERSION" \
  --arg sentry_event_id "$SENTRY_EVENT_ID" \
  --arg sentry_release "$EXPECTED_SENTRY_RELEASE" \
  --arg install_session_id "$ARTIFACT_INSTALL_SESSION_ID" \
  --arg integration_session_id "$INTEGRATION_SESSION_ID" \
  --arg apk_sha256 "$EXPECTED_APK_SHA256" \
  --arg installed_apk_sha256 "$INSTALLED_APK_SHA256" \
  --arg certificate_sha256 "$EXPECTED_CERTIFICATE_SHA256" \
  --arg package_name "$PACKAGE_NAME" \
  --arg version_name "$EXPECTED_VERSION_NAME" \
  --arg version_code "$EXPECTED_VERSION_CODE" \
  --arg fcm_delivery_log_sha256 "$FCM_DELIVERY_SHA256" \
  --argjson fcm_delivery_required "$([[ "$REQUIRE_FCM_DELIVERY" == "1" ]] && printf true || printf false)" \
  '{
    status: $status,
    device: $device,
    api_base_url: $api_base_url,
    sentry_dsn_sha256: $sentry_dsn_sha256,
    git_sha: $git_sha,
    version: $version,
    source_identity: "clean_head_origin_master_confirmed",
    runtime_test_scope: "exact_signed_apk_startup_sentry_and_fcm_token_plus_exact_source_fcm_registration_and_delivery",
    artifact_installation: "confirmed",
    artifact: {
      apk_sha256: $apk_sha256,
      installed_apk_sha256: $installed_apk_sha256,
      certificate_sha256: $certificate_sha256,
      package_name: $package_name,
      version_name: $version_name,
      version_code: $version_code,
      device_kind: "physical",
      cold_launch: "confirmed"
    },
    install_session_id: $install_session_id,
    sentry: {
      ingestion: "confirmed",
      event_id: $sentry_event_id,
      proof_type: "release_startup",
      release: $sentry_release,
      install_session_id: $install_session_id,
      scope: "exact_signed_apk"
    },
    fcm: {
      artifact_token_availability: "confirmed",
      artifact_install_session_id: $install_session_id,
      artifact_scope: "exact_signed_apk",
      registration: "confirmed",
      registration_install_session_id: $integration_session_id,
      registration_scope: "integration_test_build_from_exact_clean_source",
      delivery_required: $fcm_delivery_required,
      delivery_scope: "integration_test_build_from_exact_clean_source",
      delivery_log_sha256: (if ($fcm_delivery_log_sha256 | length) > 0 then $fcm_delivery_log_sha256 else null end)
    }
  }' | tee "$EVIDENCE_DIR/observability-result.json"
chmod 600 "$EVIDENCE_DIR"/*

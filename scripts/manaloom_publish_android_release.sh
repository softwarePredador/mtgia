#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
CALLER_EXPECTED_SENTRY_DSN_SHA256="${MANALOOM_EXPECTED_SENTRY_DSN_SHA256:-}"

# Approval must come from the process invoking this release, never from the
# persistent server environment loaded below.
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "ManaLoom Android release publication"
readonly LIVE_MUTATION_APPROVED=1

if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
load_manaloom_env_keys "$ENV_FILE" \
  EASYPANEL_API_TOKEN EASYPANEL_BASE_URL EASYPANEL_PROJECT_NAME \
  EASYPANEL_SERVER_IP EASYPANEL_SSH_KEY EASYPANEL_SSH_USER \
  MANALOOM_API_BASE_URL MANALOOM_EASYPANEL_SSH_HOST \
  MANALOOM_EASYPANEL_SSH_KEY MANALOOM_RELEASE_IMAGE_REPO \
  MANALOOM_RELEASE_SERVICE MANALOOM_WEB_PUBLIC_HOST \
  SENTRY_DSN SENTRY_MOBILE_DSN

# Release trust anchors must come from the invoking process. A persistent
# server .env is deployment input, not an independent approval source.
MANALOOM_EXPECTED_SENTRY_DSN_SHA256="$CALLER_EXPECTED_SENTRY_DSN_SHA256"
readonly MANALOOM_EXPECTED_SENTRY_DSN_SHA256
export MANALOOM_EXPECTED_SENTRY_DSN_SHA256

API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SENTRY_RELEASE_DSN="${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}"
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
validate_manaloom_release_api_base_url "$API_BASE_URL"
resolve_manaloom_release_sentry_dsn "$SENTRY_RELEASE_DSN" 1
# The constants are used to authenticate the toolchain identity embedded in
# the signed APK/AAB; publication does not need to execute Flutter itself.
# shellcheck source=scripts/lib/manaloom_flutter_release_sdk.sh
source "$ROOT_DIR/scripts/lib/manaloom_flutter_release_sdk.sh"

EXPECTED_ANDROID_CERT_SHA256="$MANALOOM_APPROVED_ANDROID_CERT_SHA256"
readonly EXPECTED_ANDROID_CERT_SHA256

IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="${MANALOOM_RELEASE_SOURCE_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}" \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
SOURCE_SHA="$(jq -r '.git_sha' <<<"$IDENTITY_JSON")"
SHORT_SHA="$(jq -r '.short_sha' <<<"$IDENTITY_JSON")"
IDENTITY_VERSION="$(jq -r '.version' <<<"$IDENTITY_JSON")"
VERSION="${MANALOOM_RELEASE_VERSION:-$IDENTITY_VERSION}"
if [[ "$VERSION" != "$IDENTITY_VERSION" ]]; then
  echo "versao solicitada diverge da identidade do source: requested=$VERSION source=$IDENTITY_VERSION" >&2
  exit 2
fi
RELEASE_DIR="${MANALOOM_RELEASE_DIR:-$HOME/.manaloom/releases/$VERSION/$SHORT_SHA}"
APK="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.apk"
AAB="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.aab"
RELEASE_MANIFEST="$RELEASE_DIR/release-manifest.json"
RELEASE_IDENTITY="$RELEASE_DIR/release-identity.json"
SBOM="$RELEASE_DIR/sbom.cdx.json"
OSV_SCAN="$RELEASE_DIR/osv-scan.json"
EMBEDDED_IDENTITY="$RELEASE_DIR/embedded-release-identity.json"
PROVENANCE="$RELEASE_DIR/provenance.intoto.json"
ANDROID_VERIFICATION="$RELEASE_DIR/android-verification.json"
OBSERVABILITY_EVIDENCE="${MANALOOM_RELEASE_OBSERVABILITY_EVIDENCE:-}"
PUBLIC_HOST="${MANALOOM_WEB_PUBLIC_HOST:-evolution-manaloom-web-public.2ta7qx.easypanel.host}"
PUBLIC_URL="https://$PUBLIC_HOST/downloads/manaloom-android.apk"
PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
SERVICE="${MANALOOM_RELEASE_SERVICE:-manaloom-releases}"
SWARM_SERVICE="${PROJECT}_${SERVICE}"
IMAGE_REPO="${MANALOOM_RELEASE_IMAGE_REPO:-localhost:5000/manaloom/mobile-releases}"
IMAGE="$IMAGE_REPO:${VERSION//+/-}-$SHORT_SHA"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
REMOTE_RELEASE="/opt/manaloom/releases/mobile/$VERSION/$SHORT_SHA"
REMOTE_BUILD="/opt/manaloom/deploy/mobile-releases-$SHORT_SHA"

validate_manaloom_exact_coordinate public_host "$PUBLIC_HOST" \
  "$MANALOOM_PRODUCTION_PUBLIC_HOST"
validate_manaloom_exact_coordinate project "$PROJECT" \
  "$MANALOOM_PRODUCTION_EASYPANEL_PROJECT"
validate_manaloom_exact_coordinate release_service "$SERVICE" \
  manaloom-releases
validate_manaloom_exact_coordinate release_image_repo "$IMAGE_REPO" \
  localhost:5000/manaloom/mobile-releases

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

for tool in curl git jarsigner jq keytool scp shasum ssh tar unzip; do
  require_tool "$tool"
done
for key in SSH_HOST SSH_KEY EASYPANEL_BASE_URL EASYPANEL_API_TOKEN; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done
resolve_manaloom_android_build_tools

for artifact in "$APK" "$AAB" "$RELEASE_MANIFEST" "$RELEASE_IDENTITY" "$SBOM" "$OSV_SCAN" "$EMBEDDED_IDENTITY" "$PROVENANCE" "$ANDROID_VERIFICATION" "$RELEASE_DIR/SHA256SUMS" "$ROOT_DIR/app/release-host/Dockerfile" "$ROOT_DIR/app/release-host/nginx.conf" "$ROOT_DIR/app/release-host/traefik.yaml"; do
  if [[ ! -f "$artifact" ]]; then
    echo "artefato obrigatorio ausente: $artifact" >&2
    exit 2
  fi
done
if [[ -z "$OBSERVABILITY_EVIDENCE" || ! -f "$OBSERVABILITY_EVIDENCE" ]]; then
  echo "publicacao recusada: MANALOOM_RELEASE_OBSERVABILITY_EVIDENCE ausente" >&2
  exit 2
fi

(
  cd "$RELEASE_DIR"
  shasum -a 256 -c SHA256SUMS >/dev/null
)
jq -e --arg sha "$SOURCE_SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version and .platform == "android" and .permissions_gate == "passed" and .sentry_configured == true' \
  "$RELEASE_MANIFEST" >/dev/null
jq -e --arg sha "$SOURCE_SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version' "$RELEASE_IDENTITY" >/dev/null
jq -e --arg sha "$SOURCE_SHA" \
  '.predicate.buildDefinition.externalParameters.git_sha == $sha' "$PROVENANCE" >/dev/null
APK_HASH="$(shasum -a 256 "$APK" | awk '{print $1}')"
AAB_HASH="$(shasum -a 256 "$AAB" | awk '{print $1}')"
SBOM_HASH="$(shasum -a 256 "$SBOM" | awk '{print $1}')"
OSV_SCAN_HASH="$(shasum -a 256 "$OSV_SCAN" | awk '{print $1}')"
EMBEDDED_IDENTITY_HASH="$(shasum -a 256 "$EMBEDDED_IDENTITY" | awk '{print $1}')"
PROVENANCE_HASH="$(shasum -a 256 "$PROVENANCE" | awk '{print $1}')"
OBSERVABILITY_HASH="$(shasum -a 256 "$OBSERVABILITY_EVIDENCE" | awk '{print $1}')"
CERTIFICATE_SHA256="$(jq -r '.signing.certificate_sha256' "$RELEASE_MANIFEST")"
EXPECTED_SENTRY_RELEASE="manaloom-android@$SHORT_SHA"

# Re-verify both Android artifacts at the publication boundary. The manifest
# and build-time report are evidence, but neither is trusted as a substitute
# for parsing the exact bytes that will be published.
APK_VERIFICATION_JSON="$(
  "$ROOT_DIR/scripts/manaloom_verify_android_release_artifacts.sh" \
    --apk "$APK" \
    --expected-package com.mtgia.mtg_app \
    --expected-version "$VERSION" \
    --expected-cert-sha256 "$EXPECTED_ANDROID_CERT_SHA256"
)"
ACTUAL_APK_CERT_SHA256="$(jq -er '.certificate_sha256' <<<"$APK_VERIFICATION_JSON")"
AAB_VERIFY_OUTPUT="$(jarsigner -verify "$AAB" 2>&1)"
grep -Fq 'jar verified' <<<"$AAB_VERIFY_OUTPUT" || {
  echo "AAB nao passou na verificacao criptografica do jarsigner" >&2
  exit 1
}
ACTUAL_AAB_CERT_SHA256="$(
  keytool -printcert -jarfile "$AAB" 2>/dev/null |
    awk -F': ' '/SHA256:/{print tolower($2); exit}' |
    tr -d ':[:space:]'
)"
if [[ "$ACTUAL_APK_CERT_SHA256" != "$EXPECTED_ANDROID_CERT_SHA256" ||
      "$ACTUAL_AAB_CERT_SHA256" != "$EXPECTED_ANDROID_CERT_SHA256" ||
      "$CERTIFICATE_SHA256" != "$EXPECTED_ANDROID_CERT_SHA256" ]]; then
  echo "certificado Android diverge do fingerprint aprovado no ponto de publicacao" >&2
  exit 1
fi
validate_manaloom_android_release_certificate "$ACTUAL_APK_CERT_SHA256"

APK_EMBEDDED_IDENTITY="$(unzip -p "$APK" assets/flutter_assets/assets/release/release-identity.json)"
AAB_EMBEDDED_IDENTITY="$(unzip -p "$AAB" base/assets/flutter_assets/assets/release/release-identity.json)"
SIDECAR_EMBEDDED_IDENTITY="$(jq -cS . "$EMBEDDED_IDENTITY")"
if [[ "$(jq -cS . <<<"$APK_EMBEDDED_IDENTITY")" != "$SIDECAR_EMBEDDED_IDENTITY" ||
      "$(jq -cS . <<<"$AAB_EMBEDDED_IDENTITY")" != "$SIDECAR_EMBEDDED_IDENTITY" ]]; then
  echo "identidade assinada diverge entre APK, AAB e sidecar" >&2
  exit 1
fi
GRADLE_LOCK_SHA256="$(shasum -a 256 "$ROOT_DIR/app/android/app/gradle.lockfile" | awk '{print $1}')"
GRADLE_DISTRIBUTION_SHA256="$(
  awk -F= '/^distributionSha256Sum=/{print $2; exit}' \
    "$ROOT_DIR/app/android/gradle/wrapper/gradle-wrapper.properties"
)"
jq -e \
  --arg git_sha "$SOURCE_SHA" \
  --arg version "$VERSION" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  --arg flutter_version "$MANALOOM_RELEASE_FLUTTER_VERSION" \
  --arg flutter_revision "$MANALOOM_RELEASE_FLUTTER_REVISION" \
  --arg engine_revision "$MANALOOM_RELEASE_FLUTTER_ENGINE_REVISION" \
  --arg dart_version "$MANALOOM_RELEASE_DART_VERSION" \
  --arg gradle_distribution_sha256 "$GRADLE_DISTRIBUTION_SHA256" \
  --arg gradle_lock_sha256 "$GRADLE_LOCK_SHA256" \
  --arg java_version "$MANALOOM_RELEASE_JAVA_VERSION" \
  --arg java_vendor "$MANALOOM_RELEASE_JAVA_VENDOR" \
  --arg android_build_tools_version "$MANALOOM_ANDROID_BUILD_TOOLS_VERSION" \
  --arg apksigner_sha256 "$MANALOOM_ANDROID_APKSIGNER_SHA256" \
  --arg aapt_sha256 "$MANALOOM_ANDROID_AAPT_SHA256" \
  '.status == "release" and .release_identity_embedded == true and
   .git_sha == $git_sha and .version == $version and
   .api_base_url == $api_base_url and .sentry_dsn_sha256 == $sentry_dsn_sha256 and
   .toolchain.flutter_version == $flutter_version and
   .toolchain.flutter_revision == $flutter_revision and
   .toolchain.engine_revision == $engine_revision and
   .toolchain.dart_version == $dart_version and
   .toolchain.gradle_distribution_sha256 == $gradle_distribution_sha256 and
   .toolchain.gradle_lock_sha256 == $gradle_lock_sha256 and
   .toolchain.java_version == $java_version and
   .toolchain.java_vendor == $java_vendor and
   .toolchain.android_build_tools_version == $android_build_tools_version and
   .toolchain.apksigner_sha256 == $apksigner_sha256 and
   .toolchain.aapt_sha256 == $aapt_sha256' \
  "$EMBEDDED_IDENTITY" >/dev/null || {
  echo "identidade embarcada nao autentica source, runtime ou toolchain desta release" >&2
  exit 1
}

jq -e --arg aab_sha256 "$AAB_HASH" '
  ([.metadata.component.properties[] |
    select(.name == "manaloom:gradle-aab-dependency-parity") |
    .value] == ["exact-bidirectional-match"]) and
  ([.metadata.component.properties[] |
    select(.name == "manaloom:android-release-artifact-sha256") |
    .value] == [$aab_sha256]) and
  ([.metadata.component.properties[] |
    select(.name == "manaloom:android-release-artifact-dependency-count") |
    .value][0] | tonumber) as $aab_count |
  ([.components[] |
    select(.scope == "required") |
    select(any(.properties[];
      .name == "manaloom:dependency-lock" and
      .value == "gradle.lockfile"))] | length) as $release_count |
  $release_count > 0 and $release_count == $aab_count
' "$SBOM" >/dev/null || {
  echo "publicacao recusada: SBOM nao prova paridade exata entre Gradle lock e AAB" >&2
  exit 1
}
jq -e --arg sbom_sha256 "$SBOM_HASH" \
  '.schema_version == 2 and .status == "passed" and
   .sbom_sha256 == $sbom_sha256 and .vulnerability_count == 0 and
   .blocking_vulnerability_count == 0 and
   .release_vulnerability_count == 0 and
   .total_vulnerability_count ==
     (.blocking_vulnerability_count + .excluded_vulnerability_count) and
   .observed_vulnerability_count ==
     (.release_vulnerability_count + .non_release_vulnerability_count) and
   .non_release_vulnerability_count == (.non_release_vulnerabilities | length)' \
  "$OSV_SCAN" >/dev/null || {
  echo "publicacao recusada: OSV scan ausente, divergente ou com vulnerabilidades" >&2
  exit 1
}
jq -e \
  --arg sha "$SOURCE_SHA" \
  --arg version "$VERSION" \
  --arg version_name "${VERSION%%+*}" \
  --arg version_code "${VERSION##*+}" \
  --arg apk_sha256 "$APK_HASH" \
  --arg certificate_sha256 "$CERTIFICATE_SHA256" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  --arg sentry_release "$EXPECTED_SENTRY_RELEASE" \
  '.status == "passed" and .git_sha == $sha and .version == $version and
   .artifact_installation == "confirmed" and
   .artifact.apk_sha256 == $apk_sha256 and
   .artifact.installed_apk_sha256 == $apk_sha256 and
   .artifact.certificate_sha256 == $certificate_sha256 and
   .artifact.package_name == "com.mtgia.mtg_app" and
   .artifact.version_name == $version_name and
   .artifact.version_code == $version_code and
   .artifact.device_kind == "physical" and
   .artifact.cold_launch == "confirmed" and
   .api_base_url == $api_base_url and
   .sentry_dsn_sha256 == $sentry_dsn_sha256 and
   .runtime_test_scope == "exact_signed_apk_startup_sentry_and_fcm_token_plus_exact_source_fcm_registration_and_delivery" and
   (.install_session_id | type == "string" and length > 20) and
   .sentry.ingestion == "confirmed" and
   .sentry.release == $sentry_release and
   .sentry.install_session_id == .install_session_id and
   .sentry.proof_type == "release_startup" and
   .sentry.scope == "exact_signed_apk" and
   .fcm.artifact_token_availability == "confirmed" and
   .fcm.artifact_install_session_id == .install_session_id and
   .fcm.artifact_scope == "exact_signed_apk" and
   .fcm.registration == "confirmed" and
   (.fcm.registration_install_session_id | type == "string" and length > 20) and
   .fcm.registration_scope == "integration_test_build_from_exact_clean_source" and
   .fcm.delivery_scope == "integration_test_build_from_exact_clean_source" and
   (.fcm.delivery_required == false or (.fcm.delivery_log_sha256 | type == "string" and length == 64))' \
  "$OBSERVABILITY_EVIDENCE" >/dev/null || {
  echo "publicacao recusada: observabilidade Sentry/FCM not_proven para este release" >&2
  exit 1
}

jq -e \
  --arg apk_sha256 "$APK_HASH" \
  --arg aab_sha256 "$AAB_HASH" \
  --arg sbom_sha256 "$SBOM_HASH" \
  --arg osv_scan_sha256 "$OSV_SCAN_HASH" \
  --arg embedded_identity_sha256 "$EMBEDDED_IDENTITY_HASH" \
  --arg certificate_sha256 "$CERTIFICATE_SHA256" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  '.artifacts.apk.sha256 == $apk_sha256 and
   .artifacts.aab.sha256 == $aab_sha256 and
   .artifacts.sbom.sha256 == $sbom_sha256 and
   .artifacts.vulnerability_scan.sha256 == $osv_scan_sha256 and
   .artifacts.vulnerability_scan.status == "passed" and
   .artifacts.embedded_release_identity.sha256 == $embedded_identity_sha256 and
   .signing.certificate_sha256 == $certificate_sha256 and
   .api_base_url == $api_base_url and
   .sentry_dsn_sha256 == $sentry_dsn_sha256' \
  "$RELEASE_MANIFEST" >/dev/null
jq -e \
  --arg apk "$(basename "$APK")" --arg apk_sha256 "$APK_HASH" \
  --arg aab "$(basename "$AAB")" --arg aab_sha256 "$AAB_HASH" \
  --arg sbom_sha256 "$SBOM_HASH" --arg osv_scan_sha256 "$OSV_SCAN_HASH" \
  --arg embedded_identity_sha256 "$EMBEDDED_IDENTITY_HASH" \
  'any(.subject[]; .name == $apk and .digest.sha256 == $apk_sha256) and
   any(.subject[]; .name == $aab and .digest.sha256 == $aab_sha256) and
   any(.subject[]; .name == "sbom.cdx.json" and .digest.sha256 == $sbom_sha256) and
   any(.subject[]; .name == "osv-scan.json" and .digest.sha256 == $osv_scan_sha256) and
   any(.subject[]; .name == "embedded-release-identity.json" and .digest.sha256 == $embedded_identity_sha256)' \
  "$PROVENANCE" >/dev/null
jq -e --arg version_name "${VERSION%%+*}" --arg version_code "${VERSION##*+}" --arg certificate_sha256 "$CERTIFICATE_SHA256" \
  '.status == "passed" and .version_name == $version_name and .version_code == $version_code and .certificate_sha256 == $certificate_sha256' \
  "$ANDROID_VERIFICATION" >/dev/null
jq -e --argjson actual "$APK_VERIFICATION_JSON" \
  '.status == $actual.status and .package == $actual.package and
   .version_name == $actual.version_name and .version_code == $actual.version_code and
   .certificate_sha256 == $actual.certificate_sha256 and .permissions == $actual.permissions' \
  "$ANDROID_VERIFICATION" >/dev/null

trpc_post() {
  local procedure="$1"
  local payload="$2"
  curl -fsS \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$payload" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$procedure"
}

BUILD_DIR="$(mktemp -d /tmp/manaloom-mobile-publish.XXXXXX)"
DEPLOY_MUTATION_STARTED=0
DEPLOY_COMMITTED=0
SOURCE_MUTATED=0
PREVIOUS_SOURCE_IMAGE=""
ROLLBACK_SOURCE_IMAGE=""
PREVIOUS_SPEC_IMAGE=""
PREVIOUS_RUNNING_IMAGE=""
PREVIOUS_UPDATE_STATE=""
PREVIOUS_PUBLIC_APK_HASH=""

rollback_android_release_host() {
  local runtime_status=1 configured_status=1 health_status=1
  local services_json configured_image rollback_state public_hash

  echo "publicacao Android falhou; restaurando origem e digest anteriores" >&2
  if [[ "$SOURCE_MUTATED" == "1" && -n "$ROLLBACK_SOURCE_IMAGE" ]]; then
    trpc_post services.app.updateSourceImage "$(jq -cn \
      --arg project "$PROJECT" \
      --arg service "$SERVICE" \
      --arg image "$ROLLBACK_SOURCE_IMAGE" \
      '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null || true
    trpc_post services.app.deployService "$(jq -cn \
      --arg project "$PROJECT" \
      --arg service "$SERVICE" \
      '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null || true
  fi

  if [[ -n "$PREVIOUS_SPEC_IMAGE" ]]; then
    for _ in $(seq 1 30); do
      rollback_state="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
        "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); spec=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); running=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1); printf '%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\"" 2>/dev/null || true)"
      if [[ "$rollback_state" == "1/1|$PREVIOUS_SPEC_IMAGE|$PREVIOUS_SPEC_IMAGE" ]]; then
        runtime_status=0
        break
      fi
      sleep 2
    done
    if [[ "$runtime_status" != "0" ]] &&
       ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
docker service update \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --rollback-order stop-first \\
  --detach=true \\
  --image '$PREVIOUS_SPEC_IMAGE' \\
  '$SWARM_SERVICE' >/dev/null
for attempt in \$(seq 1 60); do
  replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1)
  spec=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
  running=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
  update=\$(docker service inspect '$SWARM_SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
  if [ \"\$replicas\" = '1/1' ] && [ \"\$spec\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$running\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     { [ -z \"\$update\" ] || [ \"\$update\" = completed ] || [ \"\$update\" = rollback_completed ]; }; then
    exit 0
  fi
  case \"\$update\" in paused|rollback_paused) break ;; esac
  sleep 2
done
docker service ps '$SWARM_SERVICE' --no-trunc >&2
exit 1
"; then
      runtime_status=0
    fi
  fi

  if [[ "$SOURCE_MUTATED" == "1" ]]; then
    if services_json="$(trpc_post projects.listProjectsAndServices null)" &&
       configured_image="$(jq -er \
         --arg project "$PROJECT" \
         --arg service "$SERVICE" \
         '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
         <<<"$services_json")" &&
       [[ "$configured_image" == "$ROLLBACK_SOURCE_IMAGE" ]]; then
      configured_status=0
    fi
  else
    configured_status=0
  fi

  for _ in $(seq 1 30); do
    if public_hash="$(curl -fsS "$PUBLIC_URL" 2>/dev/null | \
         shasum -a 256 | awk '{print $1}')" &&
       [[ "$public_hash" == "$PREVIOUS_PUBLIC_APK_HASH" ]]; then
      health_status=0
      break
    fi
    sleep 2
  done

  if [[ "$runtime_status" == "0" && "$configured_status" == "0" &&
        "$health_status" == "0" ]]; then
    echo "rollback Android comprovado: origem, digest e APK publico restaurados" >&2
    return 0
  fi
  echo "CRITICAL: rollback Android nao foi comprovado (runtime=$runtime_status configured=$configured_status health=$health_status)" >&2
  return 1
}

cleanup() {
  local status="${1:-$?}"
  trap - EXIT
  if [[ "$status" != "0" && "$DEPLOY_MUTATION_STARTED" == "1" &&
        "$DEPLOY_COMMITTED" != "1" ]]; then
    rollback_android_release_host || status=1
  fi
  rm -rf "$BUILD_DIR"
  if [[ "$LIVE_MUTATION_APPROVED" == "1" &&
        -n "${MANALOOM_SECURE_SSH_KNOWN_HOSTS:-}" ]]; then
    ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "rm -rf '$REMOTE_BUILD'" >/dev/null 2>&1 || true
  fi
  cleanup_manaloom_secure_ssh
  exit "$status"
}
trap 'cleanup $?' EXIT

validate_manaloom_easypanel_base_url "$EASYPANEL_BASE_URL"
initialize_manaloom_secure_ssh "$SSH_HOST"

mkdir -p "$BUILD_DIR/public/downloads"
cp "$ROOT_DIR/app/release-host/Dockerfile" "$BUILD_DIR/Dockerfile"
cp "$ROOT_DIR/app/release-host/nginx.conf" "$BUILD_DIR/nginx.conf"
cp "$APK" "$BUILD_DIR/public/downloads/manaloom-android.apk"
jq -n \
  --arg version "$VERSION" \
  --arg git_sha "$SOURCE_SHA" \
  --arg artifact manaloom-android.apk \
  --arg sha256 "$APK_HASH" \
  --arg aab_sha256 "$AAB_HASH" \
  --arg sbom_sha256 "$SBOM_HASH" \
  --arg osv_scan_sha256 "$OSV_SCAN_HASH" \
  --arg embedded_identity_sha256 "$EMBEDDED_IDENTITY_HASH" \
  --arg provenance_sha256 "$PROVENANCE_HASH" \
  --arg observability_sha256 "$OBSERVABILITY_HASH" \
  --arg certificate_sha256 "$CERTIFICATE_SHA256" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  '{
    schema_version: 1,
    version: $version,
    git_sha: $git_sha,
    platform: "android",
    artifact: $artifact,
    sha256: $sha256,
    aab_sha256: $aab_sha256,
    sbom_sha256: $sbom_sha256,
    osv_scan_sha256: $osv_scan_sha256,
    embedded_identity_sha256: $embedded_identity_sha256,
    provenance_sha256: $provenance_sha256,
    observability_sha256: $observability_sha256,
    certificate_sha256: $certificate_sha256,
    api_base_url: $api_base_url,
    sentry_dsn_sha256: $sentry_dsn_sha256
  }' \
  > "$BUILD_DIR/public/downloads/release.json"
printf '%s  %s\n' "$APK_HASH" manaloom-android.apk > "$BUILD_DIR/public/downloads/SHA256SUMS"
chmod 644 "$BUILD_DIR/public/downloads/manaloom-android.apk" \
  "$BUILD_DIR/public/downloads/release.json" \
  "$BUILD_DIR/public/downloads/SHA256SUMS"
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$BUILD_DIR"
fi

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "rm -rf '$REMOTE_BUILD' && install -d -m 700 '$REMOTE_BUILD' '$REMOTE_RELEASE'"
scp -q -i "$SSH_KEY" "$APK" "$SSH_HOST:$REMOTE_RELEASE/$(basename "$APK")"
scp -q -i "$SSH_KEY" "$AAB" "$SSH_HOST:$REMOTE_RELEASE/$(basename "$AAB")"
for evidence in SHA256SUMS android-verification.json embedded-release-identity.json osv-scan.json provenance.intoto.json release-identity.json release-manifest.json sbom.cdx.json; do
  scp -q -i "$SSH_KEY" "$RELEASE_DIR/$evidence" "$SSH_HOST:$REMOTE_RELEASE/$evidence"
done
scp -q -i "$SSH_KEY" "$OBSERVABILITY_EVIDENCE" "$SSH_HOST:$REMOTE_RELEASE/observability-result.json"
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "chmod 600 '$REMOTE_RELEASE'/*"

COPYFILE_DISABLE=1 tar --no-mac-metadata -C "$BUILD_DIR" -czf - . | \
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "tar -xzf - -C '$REMOTE_BUILD'"
# Capture the registry RepoDigest after the pushes, and use only that immutable
# reference for EasyPanel and Docker Swarm convergence.
# shellcheck disable=SC2087
IMAGE_DIGEST_REF="$(
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
cd '$REMOTE_BUILD'
docker build -t '$IMAGE' -t '$IMAGE_REPO:latest' . >&2
docker push '$IMAGE' >&2
docker push '$IMAGE_REPO:latest' >&2
image_digest_ref="\$(
  docker image inspect '$IMAGE' \
    --format '{{range .RepoDigests}}{{println .}}{{end}}' |
    awk -v expected_repo='$IMAGE_REPO' \
      'index(\$0, expected_repo "@sha256:") == 1 {print; exit}'
)"
image_digest="\${image_digest_ref#'$IMAGE_REPO@sha256:'}"
if [[ "\$image_digest_ref" != '$IMAGE_REPO@sha256:'"\$image_digest" ||
      ! "\$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo 'push remoto nao produziu RepoDigest SHA-256 valido para Android release host' >&2
  exit 2
fi
printf '%s\n' "\$image_digest_ref"
REMOTE
)"
image_digest="${IMAGE_DIGEST_REF#"$IMAGE_REPO@sha256:"}"
if [[ "$IMAGE_DIGEST_REF" != "$IMAGE_REPO@sha256:$image_digest" ||
      ! "$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "push remoto retornou RepoDigest invalido para Android release host: $IMAGE_DIGEST_REF" >&2
  exit 2
fi
readonly IMAGE_DIGEST_REF

SERVICES_JSON="$(trpc_post projects.listProjectsAndServices null)"
if ! jq -e --arg project "$PROJECT" --arg service "$SERVICE" \
  '.json.services[]? | select(.projectName == $project and .name == $service and .type == "app")' \
  >/dev/null <<<"$SERVICES_JSON"; then
  echo "publicacao recusada: release host precisa existir para permitir rollback" >&2
  exit 2
fi
PREVIOUS_SOURCE_IMAGE="$(jq -er \
  --arg project "$PROJECT" \
  --arg service "$SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$SERVICES_JSON")"
PREVIOUS_RUNTIME_STATE="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); spec=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); running=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1); update=\$(docker service inspect '$SWARM_SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}' 2>/dev/null || true); printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$update\"")"
IFS='|' read -r previous_replicas PREVIOUS_SPEC_IMAGE PREVIOUS_RUNNING_IMAGE \
  PREVIOUS_UPDATE_STATE \
  <<<"$PREVIOUS_RUNTIME_STATE"
if [[ "$previous_replicas" != "1/1" ||
      "$PREVIOUS_RUNNING_IMAGE" != "$PREVIOUS_SPEC_IMAGE" ||
      ( -n "$PREVIOUS_UPDATE_STATE" &&
        "$PREVIOUS_UPDATE_STATE" != "completed" &&
        "$PREVIOUS_UPDATE_STATE" != "rollback_completed" ) ||
      ! "$PREVIOUS_SPEC_IMAGE" =~ @sha256:[0-9a-f]{64}$ ]]; then
  echo "publicacao recusada: baseline Android nao e rollback-safe: $PREVIOUS_RUNTIME_STATE" >&2
  exit 2
fi
ROLLBACK_SOURCE_IMAGE="$PREVIOUS_SPEC_IMAGE"
if [[ "$PREVIOUS_SOURCE_IMAGE" != "$ROLLBACK_SOURCE_IMAGE" ]]; then
  echo "origem EasyPanel anterior sera normalizada para o digest imutavel da spec durante eventual rollback" >&2
fi
PREVIOUS_PUBLIC_APK_HASH="$(curl -fsS "$PUBLIC_URL" | \
  shasum -a 256 | awk '{print $1}')"

DEPLOY_MUTATION_STARTED=1
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
docker service update \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --rollback-order stop-first \\
  --detach=true \\
  '$SWARM_SERVICE' >/dev/null
"
SOURCE_MUTATED=1
trpc_post services.app.updateSourceImage "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" --arg image "$IMAGE_DIGEST_REF" '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null
trpc_post services.app.updateDeploy "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" '{projectName:$project,serviceName:$service,deploy:{command:null,replicas:1,zeroDowntime:false}}')" >/dev/null
trpc_post services.app.deployService "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null

scp -q -i "$SSH_KEY" "$ROOT_DIR/app/release-host/traefik.yaml" "$SSH_HOST:/etc/easypanel/traefik/config/evolution-manaloom-releases-path.yaml.tmp"
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "mv /etc/easypanel/traefik/config/evolution-manaloom-releases-path.yaml.tmp /etc/easypanel/traefik/config/evolution-manaloom-releases-path.yaml"

for _ in $(seq 1 60); do
  RUNTIME_STATE="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); spec_image=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); running_image=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1); update_state=\$(docker service inspect '$SWARM_SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}' 2>/dev/null || true); printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec_image\" \"\$running_image\" \"\$update_state\"")"
  if [[ "$RUNTIME_STATE" == "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|completed" ||
        "$RUNTIME_STATE" == "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|" ]]; then
    break
  fi
  IFS='|' read -r _ _ _ update_state <<<"$RUNTIME_STATE"
  case "$update_state" in paused|rollback_paused|rollback_completed) break ;; esac
  sleep 2
done
if [[ "$RUNTIME_STATE" != "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|completed" &&
      "$RUNTIME_STATE" != "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|" ]]; then
  echo "servico de releases nao convergiu: $RUNTIME_STATE" >&2
  exit 1
fi

SERVICES_JSON="$(trpc_post projects.listProjectsAndServices null)"
CONFIGURED_IMAGE="$(jq -er \
  --arg project "$PROJECT" \
  --arg service "$SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$SERVICES_JSON")"
if [[ "$CONFIGURED_IMAGE" != "$IMAGE_DIGEST_REF" ]]; then
  echo "release host convergiu sem o digest exato na origem EasyPanel: $CONFIGURED_IMAGE" >&2
  exit 2
fi

for _ in $(seq 1 30); do
  HTTP_CODE="$(curl -sS -o /tmp/manaloom-public-release.apk -w '%{http_code}' "$PUBLIC_URL")"
  if [[ "$HTTP_CODE" == "200" ]]; then
    break
  fi
  sleep 2
done
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "download publico nao respondeu 200: $HTTP_CODE" >&2
  exit 1
fi

PUBLIC_HASH="$(shasum -a 256 /tmp/manaloom-public-release.apk | awk '{print $1}')"
rm -f /tmp/manaloom-public-release.apk
if [[ "$PUBLIC_HASH" != "$APK_HASH" ]]; then
  echo "download publico diverge do APK assinado" >&2
  exit 1
fi

REMOTE_AAB_HASH="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "sha256sum '$REMOTE_RELEASE/$(basename "$AAB")' | awk '{print \$1}'")"
if [[ "$REMOTE_AAB_HASH" != "$AAB_HASH" ]]; then
  echo "backup privado do AAB diverge do artefato local" >&2
  exit 1
fi
REMOTE_MANIFEST_HASH="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "sha256sum '$REMOTE_RELEASE/release-manifest.json' | awk '{print \$1}'")"
LOCAL_MANIFEST_HASH="$(shasum -a 256 "$RELEASE_MANIFEST" | awk '{print $1}')"
if [[ "$REMOTE_MANIFEST_HASH" != "$LOCAL_MANIFEST_HASH" ]]; then
  echo "manifesto privado remoto diverge do artefato local" >&2
  exit 1
fi
REMOTE_OBSERVABILITY_HASH="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "sha256sum '$REMOTE_RELEASE/observability-result.json' | awk '{print \$1}'")"
if [[ "$REMOTE_OBSERVABILITY_HASH" != "$OBSERVABILITY_HASH" ]]; then
  echo "evidencia remota de observabilidade diverge do arquivo local" >&2
  exit 1
fi

DEPLOY_COMMITTED=1
printf '{"status":"published","version":"%s","git_sha":"%s","image":"%s","image_digest_ref":"%s","download_url":"%s","apk_sha256":"%s","aab_sha256":"%s","sbom_sha256":"%s","osv_scan_sha256":"%s","provenance_sha256":"%s","observability_sha256":"%s","private_aab_backup":true,"private_release_evidence":true}\n' \
  "$VERSION" "$SOURCE_SHA" "$IMAGE" "$IMAGE_DIGEST_REF" "$PUBLIC_URL" "$APK_HASH" "$AAB_HASH" "$SBOM_HASH" "$OSV_SCAN_HASH" "$PROVENANCE_HASH" "$OBSERVABILITY_HASH"

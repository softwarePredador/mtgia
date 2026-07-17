#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

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

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

for tool in curl git jq scp shasum ssh tar; do
  require_tool "$tool"
done

for artifact in "$APK" "$AAB" "$RELEASE_MANIFEST" "$RELEASE_IDENTITY" "$SBOM" "$PROVENANCE" "$ANDROID_VERIFICATION" "$RELEASE_DIR/SHA256SUMS" "$ROOT_DIR/app/release-host/Dockerfile" "$ROOT_DIR/app/release-host/nginx.conf" "$ROOT_DIR/app/release-host/traefik.yaml"; do
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
jq -e --arg sha "$SOURCE_SHA" --arg version "$VERSION" \
  '.status == "passed" and .git_sha == $sha and .version == $version and
   .sentry.ingestion == "confirmed" and .fcm.registration == "confirmed" and
   (.fcm.delivery_required == false or (.fcm.delivery_log_sha256 | type == "string" and length == 64))' \
  "$OBSERVABILITY_EVIDENCE" >/dev/null || {
  echo "publicacao recusada: observabilidade Sentry/FCM not_proven para este release" >&2
  exit 1
}

APK_HASH="$(shasum -a 256 "$APK" | awk '{print $1}')"
AAB_HASH="$(shasum -a 256 "$AAB" | awk '{print $1}')"
SBOM_HASH="$(shasum -a 256 "$SBOM" | awk '{print $1}')"
PROVENANCE_HASH="$(shasum -a 256 "$PROVENANCE" | awk '{print $1}')"
OBSERVABILITY_HASH="$(shasum -a 256 "$OBSERVABILITY_EVIDENCE" | awk '{print $1}')"
CERTIFICATE_SHA256="$(jq -r '.signing.certificate_sha256' "$RELEASE_MANIFEST")"
jq -e \
  --arg apk_sha256 "$APK_HASH" \
  --arg aab_sha256 "$AAB_HASH" \
  --arg sbom_sha256 "$SBOM_HASH" \
  --arg certificate_sha256 "$CERTIFICATE_SHA256" \
  '.artifacts.apk.sha256 == $apk_sha256 and
   .artifacts.aab.sha256 == $aab_sha256 and
   .artifacts.sbom.sha256 == $sbom_sha256 and
   .signing.certificate_sha256 == $certificate_sha256' \
  "$RELEASE_MANIFEST" >/dev/null
jq -e \
  --arg apk "$(basename "$APK")" --arg apk_sha256 "$APK_HASH" \
  --arg aab "$(basename "$AAB")" --arg aab_sha256 "$AAB_HASH" \
  'any(.subject[]; .name == $apk and .digest.sha256 == $apk_sha256) and
   any(.subject[]; .name == $aab and .digest.sha256 == $aab_sha256)' \
  "$PROVENANCE" >/dev/null
jq -e --arg version_name "${VERSION%%+*}" --arg version_code "${VERSION##*+}" --arg certificate_sha256 "$CERTIFICATE_SHA256" \
  '.status == "passed" and .version_name == $version_name and .version_code == $version_code and .certificate_sha256 == $certificate_sha256' \
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
cleanup() {
  rm -rf "$BUILD_DIR"
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "rm -rf '$REMOTE_BUILD'" >/dev/null 2>&1 || true
}
trap cleanup EXIT

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
  --arg provenance_sha256 "$PROVENANCE_HASH" \
  --arg observability_sha256 "$OBSERVABILITY_HASH" \
  --arg certificate_sha256 "$CERTIFICATE_SHA256" \
  '{
    schema_version: 1,
    version: $version,
    git_sha: $git_sha,
    platform: "android",
    artifact: $artifact,
    sha256: $sha256,
    aab_sha256: $aab_sha256,
    sbom_sha256: $sbom_sha256,
    provenance_sha256: $provenance_sha256,
    observability_sha256: $observability_sha256,
    certificate_sha256: $certificate_sha256
  }' \
  > "$BUILD_DIR/public/downloads/release.json"
printf '%s  %s\n' "$APK_HASH" manaloom-android.apk > "$BUILD_DIR/public/downloads/SHA256SUMS"
chmod 644 "$BUILD_DIR/public/downloads/manaloom-android.apk" \
  "$BUILD_DIR/public/downloads/release.json" \
  "$BUILD_DIR/public/downloads/SHA256SUMS"
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$BUILD_DIR"
fi

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  "rm -rf '$REMOTE_BUILD' && install -d -m 700 '$REMOTE_BUILD' '$REMOTE_RELEASE'"
scp -q -i "$SSH_KEY" "$APK" "$SSH_HOST:$REMOTE_RELEASE/$(basename "$APK")"
scp -q -i "$SSH_KEY" "$AAB" "$SSH_HOST:$REMOTE_RELEASE/$(basename "$AAB")"
for evidence in SHA256SUMS android-verification.json provenance.intoto.json release-identity.json release-manifest.json sbom.cdx.json; do
  scp -q -i "$SSH_KEY" "$RELEASE_DIR/$evidence" "$SSH_HOST:$REMOTE_RELEASE/$evidence"
done
scp -q -i "$SSH_KEY" "$OBSERVABILITY_EVIDENCE" "$SSH_HOST:$REMOTE_RELEASE/observability-result.json"
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "chmod 600 '$REMOTE_RELEASE'/*"

COPYFILE_DISABLE=1 tar --no-mac-metadata -C "$BUILD_DIR" -czf - . | \
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "tar -xzf - -C '$REMOTE_BUILD'"
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "cd '$REMOTE_BUILD' && docker build -t '$IMAGE' -t '$IMAGE_REPO:latest' . && docker push '$IMAGE' && docker push '$IMAGE_REPO:latest'"

SERVICES_JSON="$(trpc_post projects.listProjectsAndServices null)"
if jq -e --arg project "$PROJECT" --arg service "$SERVICE" \
  '.json.services[]? | select(.projectName == $project and .name == $service and .type == "app")' \
  >/dev/null <<<"$SERVICES_JSON"; then
  trpc_post services.app.updateSourceImage "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" --arg image "$IMAGE" '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null
  trpc_post services.app.updateDeploy "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" '{projectName:$project,serviceName:$service,deploy:{command:null,replicas:1,zeroDowntime:false}}')" >/dev/null
  trpc_post services.app.deployService "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null
else
  trpc_post services.app.createService "$(jq -cn \
    --arg project "$PROJECT" --arg service "$SERVICE" --arg image "$IMAGE" \
    '{projectName:$project,serviceName:$service,source:{type:"image",image:$image},env:"",deploy:{command:null,replicas:1,zeroDowntime:false},resources:{cpuLimit:0.5,cpuReservation:0.05,memoryLimit:128,memoryReservation:32}}')" >/dev/null
fi

scp -q -i "$SSH_KEY" "$ROOT_DIR/app/release-host/traefik.yaml" "$SSH_HOST:/etc/easypanel/traefik/config/evolution-manaloom-releases-path.yaml.tmp"
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "mv /etc/easypanel/traefik/config/evolution-manaloom-releases-path.yaml.tmp /etc/easypanel/traefik/config/evolution-manaloom-releases-path.yaml"

for _ in $(seq 1 60); do
  RUNTIME_STATE="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); image=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); printf '%s|%s' \"\$replicas\" \"\${image%%@*}\"")"
  if [[ "$RUNTIME_STATE" == "1/1|$IMAGE" ]]; then
    break
  fi
  sleep 2
done
if [[ "$RUNTIME_STATE" != "1/1|$IMAGE" ]]; then
  echo "servico de releases nao convergiu: $RUNTIME_STATE" >&2
  exit 1
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

printf '{"status":"published","version":"%s","git_sha":"%s","image":"%s","download_url":"%s","apk_sha256":"%s","aab_sha256":"%s","sbom_sha256":"%s","provenance_sha256":"%s","observability_sha256":"%s","private_aab_backup":true,"private_release_evidence":true}\n' \
  "$VERSION" "$SOURCE_SHA" "$IMAGE" "$PUBLIC_URL" "$APK_HASH" "$AAB_HASH" "$SBOM_HASH" "$PROVENANCE_HASH" "$OBSERVABILITY_HASH"

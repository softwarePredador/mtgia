#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
BUILD_ONLY="${MANALOOM_RELEASE_BUILD_ONLY:-0}"

if [[ "$BUILD_ONLY" != "0" && "$BUILD_ONLY" != "1" ]]; then
  echo "MANALOOM_RELEASE_BUILD_ONLY deve ser 0 ou 1" >&2
  exit 2
fi
if [[ ! -f "$ENV_FILE" && "$BUILD_ONLY" == "0" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
PUBLIC_HOST="${MANALOOM_WEB_PUBLIC_HOST:-evolution-manaloom-web-public.2ta7qx.easypanel.host}"
PUBLIC_BASE_URL="https://$PUBLIC_HOST"
PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
SERVICE="${MANALOOM_FLUTTER_WEB_SERVICE:-manaloom-app}"
SWARM_SERVICE="${PROJECT}_${SERVICE}"
IMAGE_REPO="${MANALOOM_FLUTTER_WEB_IMAGE_REPO:-localhost:5000/manaloom/app-web}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
TRAEFIK_FILE="/etc/easypanel/traefik/config/evolution-manaloom-app-path.yaml"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

for tool in flutter git jq python3 shasum; do
  require_tool "$tool"
done

if [[ "$BUILD_ONLY" == "0" ]]; then
  for tool in curl ssh tar; do
    require_tool "$tool"
  done
  for key in SSH_HOST SSH_KEY EASYPANEL_BASE_URL EASYPANEL_API_TOKEN; do
    if [[ -z "${!key:-}" ]]; then
      echo "variavel obrigatoria ausente: $key" >&2
      exit 2
    fi
  done
fi

trpc_post() {
  local procedure="$1"
  local payload="$2"
  curl -fsS \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$payload" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$procedure"
}

cleanup() {
  if [[ -n "${WEB_RELEASE_TMP:-}" && -d "$WEB_RELEASE_TMP" ]]; then
    rm -rf "$WEB_RELEASE_TMP"
  fi
  if [[ -n "${WORKTREE_DIR:-}" && -d "$WORKTREE_DIR" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
  fi
  if [[ "$BUILD_ONLY" == "0" && -n "${REMOTE_DIR:-}" ]]; then
    ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "rm -rf '$REMOTE_DIR'" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# The shared identity helper preserves the legacy failure contract:
# "HEAD local nao esta alinhado com origin/master" now fails earlier with the
# exact source/head/origin values and also rejects a dirty release checkout.
IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="${MANALOOM_RELEASE_SOURCE_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}" \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
SHA="$(jq -r '.git_sha' <<<"$IDENTITY_JSON")"
SHORT_SHA="$(jq -r '.short_sha' <<<"$IDENTITY_JSON")"
VERSION="$(jq -r '.version' <<<"$IDENTITY_JSON")"
SOURCE_COMMITTED_AT="$(jq -r '.source_committed_at' <<<"$IDENTITY_JSON")"
IMAGE="$IMAGE_REPO:$SHORT_SHA"
RELEASE_DIR="${MANALOOM_RELEASE_DIR:-$HOME/.manaloom/releases/$VERSION/$SHORT_SHA}"
WORKTREE_DIR="$(mktemp -d /tmp/manaloom-app-web-source.XXXXXX)"
REMOTE_DIR="$REMOTE_BUILD_ROOT/app-web-$SHORT_SHA"

git -C "$ROOT_DIR" worktree add --detach "$WORKTREE_DIR" "$SHA" >/dev/null

build_args=(
  web
  --release
  --base-href /app/
  --dart-define="API_BASE_URL=$API_BASE_URL"
  --dart-define="PUBLIC_API_BASE_URL=$API_BASE_URL"
  --dart-define="SENTRY_ENVIRONMENT=production"
  --dart-define="SENTRY_RELEASE=manaloom-web@$SHORT_SHA"
  --no-version-check
)
SENTRY_RELEASE_DSN="${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}"
REQUIRE_SENTRY="${MANALOOM_RELEASE_REQUIRE_SENTRY:-$([[ "$BUILD_ONLY" == "0" ]] && printf 1 || printf 0)}"
if [[ "$REQUIRE_SENTRY" != "0" && "$REQUIRE_SENTRY" != "1" ]]; then
  echo "MANALOOM_RELEASE_REQUIRE_SENTRY deve ser 0 ou 1" >&2
  exit 2
fi
# A local build-only candidate may be produced without credentials. Any web
# deployment is publication and therefore remains fail-closed without a DSN.
if [[ "$BUILD_ONLY" == "0" && -z "$SENTRY_RELEASE_DSN" ]] ||
   [[ "$REQUIRE_SENTRY" == "1" && -z "$SENTRY_RELEASE_DSN" ]]; then
  echo "deploy web recusado: SENTRY_MOBILE_DSN/SENTRY_DSN ausente" >&2
  exit 2
fi
if [[ -n "$SENTRY_RELEASE_DSN" ]]; then
  build_args+=(--dart-define="SENTRY_DSN=$SENTRY_RELEASE_DSN")
fi

(
  cd "$WORKTREE_DIR/app"
  flutter pub get
  flutter build "${build_args[@]}"
)

grep -Fq '<base href="/app/">' "$WORKTREE_DIR/app/build/web/index.html"
BUILT_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 "$WORKTREE_DIR/scripts/manaloom_generate_release_sbom.py" \
  --app-dir "$WORKTREE_DIR/app" \
  --git-sha "$SHA" \
  --source-committed-at "$SOURCE_COMMITTED_AT" \
  --output "$WORKTREE_DIR/app/build/web/sbom.cdx.json" >/dev/null

INDEX_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/index.html" | awk '{print $1}')"
BOOTSTRAP_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/flutter_bootstrap.js" | awk '{print $1}')"
MAIN_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/main.dart.js" | awk '{print $1}')"
SERVICE_WORKER_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/flutter_service_worker.js" | awk '{print $1}')"
SBOM_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/sbom.cdx.json" | awk '{print $1}')"
LOTUS_INDEX_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/assets/assets/lotus/index.html" | awk '{print $1}')"
LOTUS_APP_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/assets/assets/lotus/js/app.min.js" | awk '{print $1}')"
LOTUS_STYLES_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/assets/assets/lotus/css/styles.min.css" | awk '{print $1}')"
jq -n \
  --arg version "$VERSION" \
  --arg git_sha "$SHA" \
  --arg short_sha "$SHORT_SHA" \
  --arg built_at "$BUILT_AT" \
  --arg source_committed_at "$SOURCE_COMMITTED_AT" \
  --arg sentry_release "manaloom-web@$SHORT_SHA" \
  --arg index_sha256 "$INDEX_SHA256" \
  --arg bootstrap_sha256 "$BOOTSTRAP_SHA256" \
  --arg main_sha256 "$MAIN_SHA256" \
  --arg service_worker_sha256 "$SERVICE_WORKER_SHA256" \
  --arg sbom_sha256 "$SBOM_SHA256" \
  --arg lotus_index_sha256 "$LOTUS_INDEX_SHA256" \
  --arg lotus_app_sha256 "$LOTUS_APP_SHA256" \
  --arg lotus_styles_sha256 "$LOTUS_STYLES_SHA256" \
  --argjson sentry_configured "$([[ -n "$SENTRY_RELEASE_DSN" ]] && printf true || printf false)" \
  '{
    schema_version: 1,
    product: "manaloom",
    platform: "web",
    version: $version,
    git_sha: $git_sha,
    short_sha: $short_sha,
    built_at: $built_at,
    source_committed_at: $source_committed_at,
    sentry_release: $sentry_release,
    sentry_configured: $sentry_configured,
    artifacts: {
      "index.html": $index_sha256,
      "flutter_bootstrap.js": $bootstrap_sha256,
      "main.dart.js": $main_sha256,
      "flutter_service_worker.js": $service_worker_sha256,
      "sbom.cdx.json": $sbom_sha256,
      "assets/assets/lotus/index.html": $lotus_index_sha256,
      "assets/assets/lotus/js/app.min.js": $lotus_app_sha256,
      "assets/assets/lotus/css/styles.min.css": $lotus_styles_sha256
    }
  }' > "$WORKTREE_DIR/app/build/web/release.json"
jq -e --arg sha "$SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version and .platform == "web"' \
  "$WORKTREE_DIR/app/build/web/release.json" >/dev/null

if [[ "$BUILD_ONLY" == "1" ]]; then
  WEB_RELEASE_DIR="$RELEASE_DIR/web"
  WEB_RELEASE_TMP="$RELEASE_DIR/.web.$$.tmp"
  rm -rf "$WEB_RELEASE_TMP"
  mkdir -p "$WEB_RELEASE_TMP"
  cp -R "$WORKTREE_DIR/app/build/web/." "$WEB_RELEASE_TMP/"
  printf '%s\n' "$IDENTITY_JSON" > "$WEB_RELEASE_TMP/release-identity.json"
  (
    cd "$WEB_RELEASE_TMP"
    shasum -a 256 \
      index.html \
      flutter_bootstrap.js \
      main.dart.js \
      flutter_service_worker.js \
      assets/assets/lotus/index.html \
      assets/assets/lotus/js/app.min.js \
      assets/assets/lotus/css/styles.min.css \
      release-identity.json \
      release.json \
      sbom.cdx.json > SHA256SUMS
  )
  rm -rf "$WEB_RELEASE_DIR"
  mv "$WEB_RELEASE_TMP" "$WEB_RELEASE_DIR"
  printf '{"status":"built","platform":"web","version":"%s","git_sha":"%s","release_dir":"%s","manifest":"%s"}\n' \
    "$VERSION" "$SHA" "$WEB_RELEASE_DIR" "$WEB_RELEASE_DIR/release.json"
  exit 0
fi
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$WORKTREE_DIR/app/Dockerfile.web" "$WORKTREE_DIR/app/web/nginx.conf" "$WORKTREE_DIR/app/build/web"
fi

COPYFILE_DISABLE=1 tar --no-mac-metadata -C "$WORKTREE_DIR/app" -czf - Dockerfile.web web/nginx.conf build/web | \
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
    "rm -rf '$REMOTE_DIR' && mkdir -p '$REMOTE_DIR' && tar -xzf - -C '$REMOTE_DIR'"

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "cd '$REMOTE_DIR' && docker build -f Dockerfile.web -t '$IMAGE' -t '$IMAGE_REPO:latest' . && docker push '$IMAGE' && docker push '$IMAGE_REPO:latest'"

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
    '{projectName:$project,serviceName:$service,source:{type:"image",image:$image},env:"",deploy:{command:null,replicas:1,zeroDowntime:false},resources:{cpuLimit:1,cpuReservation:0.1,memoryLimit:256,memoryReservation:64}}')" >/dev/null
fi

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "cat > '$TRAEFIK_FILE.tmp' <<'YAML'
http:
  routers:
    http-evolution-manaloom-app-path:
      middlewares:
        - redirect-to-https
        - bad-gateway-error-page
      priority: 220
      rule: Host(\`$PUBLIC_HOST\`) && (Path(\`/app\`) || PathPrefix(\`/app/\`))
      service: evolution-manaloom-app-path
      entryPoints:
        - http
    https-evolution-manaloom-app-path:
      middlewares:
        - bad-gateway-error-page
      priority: 220
      rule: Host(\`$PUBLIC_HOST\`) && (Path(\`/app\`) || PathPrefix(\`/app/\`))
      service: evolution-manaloom-app-path
      tls:
        certResolver: letsencrypt
        domains:
          - main: $PUBLIC_HOST
      entryPoints:
        - https
  services:
    evolution-manaloom-app-path:
      loadBalancer:
        passHostHeader: true
        servers:
          - url: http://$SWARM_SERVICE:80/
YAML
mv '$TRAEFIK_FILE.tmp' '$TRAEFIK_FILE'"

for _ in $(seq 1 60); do
  RUNTIME_STATE="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); image=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); printf '%s|%s' \"\$replicas\" \"\${image%%@*}\"")"
  if [[ "$RUNTIME_STATE" == "1/1|$IMAGE" ]]; then
    break
  fi
  sleep 2
done
if [[ "$RUNTIME_STATE" != "1/1|$IMAGE" ]]; then
  echo "servico Flutter Web nao convergiu: $RUNTIME_STATE" >&2
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "docker service ps '$SWARM_SERVICE' --no-trunc" >&2
  exit 1
fi

for _ in $(seq 1 30); do
  APP_CODE="$(curl -sS -o /tmp/manaloom_app_web_index.html -w '%{http_code}' "$PUBLIC_BASE_URL/app/")"
  if [[ "$APP_CODE" == "200" ]] && grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_index.html; then
    break
  fi
  sleep 2
done

[[ "$APP_CODE" == "200" ]]
grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_index.html
BOOTSTRAP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_BASE_URL/app/flutter_bootstrap.js")"
RELEASE_HEADERS="$(mktemp /tmp/manaloom_app_release_headers.XXXXXX)"
RELEASE_CODE="$(curl -sS -D "$RELEASE_HEADERS" -o /tmp/manaloom_app_release.json -w '%{http_code}' "$PUBLIC_BASE_URL/app/release.json")"
DEEP_LINK_CODE="$(curl -sS -o /tmp/manaloom_app_web_deep.html -w '%{http_code}' "$PUBLIC_BASE_URL/app/decks")"
ROOT_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_BASE_URL/")"
[[ "$BOOTSTRAP_CODE" == "200" ]]
[[ "$RELEASE_CODE" == "200" ]]
[[ "$DEEP_LINK_CODE" == "200" ]]
[[ "$ROOT_CODE" == "200" ]]
grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_deep.html
jq -e --arg sha "$SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version and .platform == "web"' \
  /tmp/manaloom_app_release.json >/dev/null
grep -Eqi '^cache-control:[[:space:]]*no-cache, no-store, must-revalidate' "$RELEASE_HEADERS"
APP_HEADERS="$(mktemp /tmp/manaloom_app_headers.XXXXXX)"
curl -fsS -D "$APP_HEADERS" -o /dev/null "$PUBLIC_BASE_URL/app/"
grep -Eqi '^content-security-policy:' "$APP_HEADERS"
BOOTSTRAP_HEADERS="$(mktemp /tmp/manaloom_bootstrap_headers.XXXXXX)"
curl -fsS -D "$BOOTSTRAP_HEADERS" -o /dev/null "$PUBLIC_BASE_URL/app/flutter_bootstrap.js"
grep -Eqi '^cache-control:[[:space:]]*no-cache, must-revalidate' "$BOOTSTRAP_HEADERS"

rm -f /tmp/manaloom_app_web_index.html /tmp/manaloom_app_web_deep.html \
  /tmp/manaloom_app_release.json "$RELEASE_HEADERS" "$APP_HEADERS" "$BOOTSTRAP_HEADERS"

printf '{"status":"deployed","service":"%s","image":"%s","version":"%s","git_sha":"%s","app_url":"%s/app/","root_code":%s,"app_code":%s,"bootstrap_code":%s,"release_code":%s,"deep_link_code":%s}\n' \
  "$SWARM_SERVICE" "$IMAGE" "$VERSION" "$SHA" "$PUBLIC_BASE_URL" "$ROOT_CODE" "$APP_CODE" "$BOOTSTRAP_CODE" "$RELEASE_CODE" "$DEEP_LINK_CODE"

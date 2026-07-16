#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
PUBLIC_HOST="${MANALOOM_WEB_PUBLIC_HOST:-evolution-manaloom-web-public.2ta7qx.easypanel.host}"
PUBLIC_BASE_URL="https://$PUBLIC_HOST"
PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
SERVICE="${MANALOOM_FLUTTER_WEB_SERVICE:-manaloom-app}"
SWARM_SERVICE="${PROJECT}_${SERVICE}"
NETWORK="${MANALOOM_EASYPANEL_NETWORK:-easypanel-$PROJECT}"
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

for tool in curl flutter git jq ssh tar; do
  require_tool "$tool"
done

for key in SSH_HOST SSH_KEY EASYPANEL_BASE_URL EASYPANEL_API_TOKEN; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done

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
  if [[ -n "${WORKTREE_DIR:-}" && -d "$WORKTREE_DIR" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
  fi
  if [[ -n "${REMOTE_DIR:-}" ]]; then
    ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "rm -rf '$REMOTE_DIR'" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

git -C "$ROOT_DIR" fetch origin master --quiet
SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)"
ORIGIN_SHA="$(git -C "$ROOT_DIR" rev-parse origin/master)"
if [[ "$SHA" != "$ORIGIN_SHA" ]]; then
  echo "HEAD local nao esta alinhado com origin/master; faca push antes do deploy." >&2
  exit 2
fi

SHORT_SHA="$(git -C "$ROOT_DIR" rev-parse --short=12 "$SHA")"
IMAGE="$IMAGE_REPO:$SHORT_SHA"
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
if [[ -n "${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}" ]]; then
  build_args+=(--dart-define="SENTRY_DSN=${SENTRY_MOBILE_DSN:-$SENTRY_DSN}")
fi

(
  cd "$WORKTREE_DIR/app"
  flutter pub get
  flutter build "${build_args[@]}"
)

grep -Fq '<base href="/app/">' "$WORKTREE_DIR/app/build/web/index.html"

tar -C "$WORKTREE_DIR/app" -czf - Dockerfile.web web/nginx.conf build/web | \
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

for attempt in $(seq 1 60); do
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

for attempt in $(seq 1 30); do
  APP_CODE="$(curl -sS -o /tmp/manaloom_app_web_index.html -w '%{http_code}' "$PUBLIC_BASE_URL/app/")"
  if [[ "$APP_CODE" == "200" ]] && grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_index.html; then
    break
  fi
  sleep 2
done

[[ "$APP_CODE" == "200" ]]
grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_index.html
BOOTSTRAP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_BASE_URL/app/flutter_bootstrap.js")"
DEEP_LINK_CODE="$(curl -sS -o /tmp/manaloom_app_web_deep.html -w '%{http_code}' "$PUBLIC_BASE_URL/app/decks")"
ROOT_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_BASE_URL/")"
[[ "$BOOTSTRAP_CODE" == "200" ]]
[[ "$DEEP_LINK_CODE" == "200" ]]
[[ "$ROOT_CODE" == "200" ]]
grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_deep.html

rm -f /tmp/manaloom_app_web_index.html /tmp/manaloom_app_web_deep.html

printf '{"status":"deployed","service":"%s","image":"%s","git_sha":"%s","app_url":"%s/app/","root_code":%s,"app_code":%s,"bootstrap_code":%s,"deep_link_code":%s}\n' \
  "$SWARM_SERVICE" "$IMAGE" "$SHA" "$PUBLIC_BASE_URL" "$ROOT_CODE" "$APP_CODE" "$BOOTSTRAP_CODE" "$DEEP_LINK_CODE"

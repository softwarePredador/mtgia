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

SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
SERVICE="${MANALOOM_PUBLIC_WEB_SWARM_SERVICE:-evolution_manaloom-web-public}"
IMAGE_REPO="${MANALOOM_PUBLIC_WEB_IMAGE_REPO:-localhost:5000/manaloom/web-public}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
PUBLIC_BASE_URL="${MANALOOM_WEB_PUBLIC_URL:-https://evolution-manaloom-web-public.2ta7qx.easypanel.host}"
API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SITE_URL="${NEXT_PUBLIC_SITE_URL:-$PUBLIC_BASE_URL}"
REMOTE_DIR=""
HEADERS_FILE=""

cleanup() {
  if [[ -n "$HEADERS_FILE" ]]; then
    rm -f "$HEADERS_FILE"
  fi
  if [[ -n "$REMOTE_DIR" ]]; then
    ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
      "rm -rf '$REMOTE_DIR'" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

for tool in curl git ssh tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  fi
done

for key in SSH_HOST SSH_KEY; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done

git -C "$ROOT_DIR" fetch origin master --quiet
SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)"
ORIGIN_SHA="$(git -C "$ROOT_DIR" rev-parse origin/master)"
if [[ "$SHA" != "$ORIGIN_SHA" ]]; then
  echo "HEAD local nao esta alinhado com origin/master; faca push antes do deploy." >&2
  exit 2
fi

SHORT_SHA="$(git -C "$ROOT_DIR" rev-parse --short=12 "$SHA")"
IMAGE="$IMAGE_REPO:$SHORT_SHA"
REMOTE_DIR="$REMOTE_BUILD_ROOT/web-public-$SHORT_SHA"
DEPLOY_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" \
  "$SSH_HOST" "docker service inspect '$SERVICE' >/dev/null"

git -C "$ROOT_DIR" archive "$SHA" web-public | \
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" \
    "$SSH_HOST" "rm -rf '$REMOTE_DIR' && mkdir -p '$REMOTE_DIR' && tar -x -C '$REMOTE_DIR'"

api_arg="$(printf '%q' "$API_BASE_URL")"
site_arg="$(printf '%q' "$SITE_URL")"
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
cd '$REMOTE_DIR/web-public'
docker build \
  --build-arg NEXT_PUBLIC_MANALOOM_API_BASE_URL=$api_arg \
  --build-arg NEXT_PUBLIC_SITE_URL=$site_arg \
  -t '$IMAGE' \
  -t '$IMAGE_REPO:latest' \
  .
docker push '$IMAGE'
docker push '$IMAGE_REPO:latest'
docker service update \
  --update-order stop-first \
  --rollback-order stop-first \
  --detach=true \
  --image '$IMAGE' \
  --env-add GIT_SHA='$SHA' \
  --env-add DEPLOY_TIMESTAMP='$DEPLOY_TIMESTAMP' \
  '$SERVICE'
"

runtime_state=""
for _ in $(seq 1 60); do
  runtime_state="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
printf '%s|%s|%s|%s' \"\$replicas\" \"\${spec%%@*}\" \"\${running%%@*}\" \"\$update\"
")"
  IFS='|' read -r replicas spec_image running_image update_state <<<"$runtime_state"
  if [[ "$replicas" == "1/1" && "$spec_image" == "$IMAGE" &&
        "$running_image" == "$IMAGE" &&
        ( -z "$update_state" || "$update_state" == "completed" ) ]]; then
    break
  fi
  case "$update_state" in
    paused|rollback_started|rollback_paused) break ;;
  esac
  sleep 2
done

IFS='|' read -r replicas spec_image running_image update_state <<<"$runtime_state"
if [[ "$replicas" != "1/1" || "$spec_image" != "$IMAGE" ||
      "$running_image" != "$IMAGE" ||
      ( -n "$update_state" && "$update_state" != "completed" ) ]]; then
  echo "servico publico nao convergiu: $runtime_state" >&2
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "docker service ps '$SERVICE' --no-trunc" >&2
  exit 1
fi

for route in / /pricing /marketplace /blog /legal/privacy /legal/terms /legal/disclaimer /robots.txt /sitemap.xml; do
  status="$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' "$PUBLIC_BASE_URL$route")"
  if [[ "$status" != "200" ]]; then
    echo "smoke publico falhou em $route: HTTP $status" >&2
    exit 1
  fi
done

HEADERS_FILE="$(mktemp /tmp/manaloom_public_web_headers.XXXXXX)"
curl -fsS --max-time 20 -D "$HEADERS_FILE" -o /dev/null "$PUBLIC_BASE_URL/"
grep -Eqi '^x-content-type-options:[[:space:]]*nosniff' "$HEADERS_FILE"
grep -Eqi '^x-frame-options:[[:space:]]*SAMEORIGIN' "$HEADERS_FILE"
grep -Eqi '^referrer-policy:' "$HEADERS_FILE"
grep -Eqi '^permissions-policy:' "$HEADERS_FILE"
grep -Eqi '^strict-transport-security:' "$HEADERS_FILE"
if grep -Eqi '^x-powered-by:' "$HEADERS_FILE"; then
  echo "site publico ainda expoe X-Powered-By" >&2
  exit 1
fi

printf '{"status":"deployed","service":"%s","image":"%s","git_sha":"%s","public_url":"%s"}\n' \
  "$SERVICE" "$IMAGE" "$SHA" "$PUBLIC_BASE_URL"

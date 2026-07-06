#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
SERVICE="${MANALOOM_BACKEND_SERVICE:-evolution_cartinhas}"
IMAGE_REPO="${MANALOOM_BACKEND_IMAGE_REPO:-localhost:5000/manaloom/cartinhas}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool git
require_tool ssh

cd "$ROOT_DIR"

sha="$(git rev-parse HEAD)"
short_sha="$(git rev-parse --short=12 HEAD)"
remote_dir="$REMOTE_BUILD_ROOT/cartinhas-$short_sha"
deploy_timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/master 2>/dev/null || true)" ]; then
  echo "HEAD local nao esta alinhado com origin/master; faca push antes do deploy." >&2
  exit 2
fi

git archive HEAD:server | ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
cd '$remote_dir'
docker build -t '$IMAGE_REPO:$short_sha' -t '$IMAGE_REPO:latest' .
docker push '$IMAGE_REPO:$short_sha'
docker push '$IMAGE_REPO:latest'
docker service update \
  --update-order stop-first \
  --image '$IMAGE_REPO:latest' \
  --env-add GIT_SHA='$sha' \
  --env-add SENTRY_RELEASE='$sha' \
  --env-add DEPLOY_TIMESTAMP='$deploy_timestamp' \
  '$SERVICE'

for attempt in \$(seq 1 45); do
  replicas="\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -n 1)"
  if [ "\$replicas" = "1/1" ]; then
    docker service ls --filter name='$SERVICE' --format '{{.Name}} {{.Image}} {{.Replicas}}'
    exit 0
  fi
  sleep 2
done

docker service ps '$SERVICE' --no-trunc
exit 1
REMOTE

printf '{"status":"deployed","service":"%s","image":"%s:latest","git_sha":"%s","remote_dir":"%s"}\n' \
  "$SERVICE" "$IMAGE_REPO" "$sha" "$remote_dir"

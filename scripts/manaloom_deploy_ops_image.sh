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

SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
SERVICE="${MANALOOM_OPS_SERVICE:-evolution_manaloom-ops}"
IMAGE_REPO="${MANALOOM_OPS_IMAGE_REPO:-localhost:5000/manaloom/ops}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
EXPECTED_DB_HOST="${MANALOOM_EXPECTED_DB_HOST:-evolution_manaloom-postgres}"
EXPECTED_DB_PORT="${MANALOOM_EXPECTED_DB_PORT:-5432}"
EXPECTED_DB_NAME="${MANALOOM_EXPECTED_DB_NAME:-halder}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool git
require_tool ssh

for key in SSH_HOST SSH_KEY DB_HOST DB_PORT DB_NAME; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done

if [[ "$DB_HOST" != "$EXPECTED_DB_HOST" ||
      "$DB_PORT" != "$EXPECTED_DB_PORT" ||
      "$DB_NAME" != "$EXPECTED_DB_NAME" ]]; then
  echo "server/.env nao aponta para o PostgreSQL interno esperado" >&2
  exit 2
fi

cd "$ROOT_DIR"
git fetch origin master --quiet
sha="$(git rev-parse HEAD)"
short_sha="$(git rev-parse --short=12 HEAD)"
remote_dir="$REMOTE_BUILD_ROOT/manaloom-ops-$short_sha"
deploy_timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ "$sha" != "$(git rev-parse origin/master 2>/dev/null || true)" ]]; then
  echo "HEAD must match origin/master before ops deploy" >&2
  exit 2
fi

runtime_contract="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk -F= '/^DB_HOST=/{host=\$2} /^DB_PORT=/{port=\$2} /^DB_NAME=/{name=\$2} END{print host \"|\" port \"|\" name}'
")"
if [[ "$runtime_contract" != "$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME" ]]; then
  echo "deploy recusado: manaloom-ops nao aponta para o PostgreSQL interno esperado" >&2
  exit 2
fi

runtime_volume="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{if eq .Target \"/data/manaloom-ops\"}}{{println .Type \"|\" .Source \"|\" .Target}}{{end}}{{end}}'")"
if [[ "$runtime_volume" != "volume | evolution_manaloom-ops-data | /data/manaloom-ops" ]]; then
  echo "deploy recusado: volume persistente de manaloom-ops divergente" >&2
  exit 2
fi

git archive HEAD server docs/hermes-analysis/manaloom-knowledge |
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
    "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
cd '$remote_dir'
docker build \
  -f server/Dockerfile.manaloom-ops \
  -t '$IMAGE_REPO:$short_sha' \
  -t '$IMAGE_REPO:latest' \
  .
docker push '$IMAGE_REPO:$short_sha'
docker push '$IMAGE_REPO:latest'
docker service update \
  --update-order stop-first \
  --image '$IMAGE_REPO:$short_sha' \
  --env-add GIT_SHA='$sha' \
  --env-add DEPLOY_TIMESTAMP='$deploy_timestamp' \
  '$SERVICE'

for attempt in \$(seq 1 60); do
  replicas="\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -n 1)"
  if [[ "\$replicas" == "1/1" ]]; then
    container="\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)"
    docker exec "\$container" grep -Fq \
      "oracle_hash = COALESCE(NULLIF(EXCLUDED.oracle_hash, ''), card_battle_rules.oracle_hash)" \
      /app/docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py
    docker exec "\$container" grep -Fq \
      "def backfill_trusted_oracle_hashes" \
      /app/docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py
    docker service ls --filter name='$SERVICE' --format '{{.Name}} {{.Image}} {{.Replicas}}'
    exit 0
  fi
  sleep 2
done

docker service ps '$SERVICE' --no-trunc
exit 1
REMOTE

deployed_contract="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker inspect \"\$container\" --format '{{range .Config.Env}}{{println .}}{{end}}' |
  awk -F= '/^GIT_SHA=/{sha=\$2} /^DB_HOST=/{host=\$2} /^DB_PORT=/{port=\$2} /^DB_NAME=/{name=\$2} END{print sha \"|\" host \"|\" port \"|\" name}'
")"
if [[ "$deployed_contract" != "$sha|$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME" ]]; then
  echo "deploy convergiu com SHA ou alvo PostgreSQL divergente" >&2
  exit 2
fi

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "rm -rf '$remote_dir'"

printf '{"status":"deployed","service":"%s","image":"%s:%s","git_sha":"%s","remote_dir_removed":"%s"}\n' \
  "$SERVICE" "$IMAGE_REPO" "$short_sha" "$sha" "$remote_dir"

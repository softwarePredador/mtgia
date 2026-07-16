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
SERVICE="${MANALOOM_BACKEND_SERVICE:-evolution_cartinhas}"
IMAGE_REPO="${MANALOOM_BACKEND_IMAGE_REPO:-localhost:5000/manaloom/cartinhas}"
EASYPANEL_PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
EASYPANEL_SERVICE="${EASYPANEL_APP_NAME:-cartinhas}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
EXPECTED_DB_HOST="${MANALOOM_EXPECTED_DB_HOST:-evolution_manaloom-postgres}"
EXPECTED_DB_PORT="${MANALOOM_EXPECTED_DB_PORT:-5432}"
EXPECTED_DB_NAME="${MANALOOM_EXPECTED_DB_NAME:-halder}"
EXPECTED_BATTLE_ENGINE="${MANALOOM_EXPECTED_BATTLE_ENGINE:-auto}"
EXPECTED_XMAGE_URL="${MANALOOM_EXPECTED_XMAGE_URL:-http://xmage-sidecar:8080}"
EXPECTED_FORGE_URL="${MANALOOM_EXPECTED_FORGE_URL:-http://forge-sidecar:8080}"
EXPECTED_NATIVE_URL="${MANALOOM_EXPECTED_NATIVE_URL:-http://${EASYPANEL_PROJECT}_manaloom-ops:8080}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool git
require_tool curl
require_tool jq
require_tool ssh

require_clean_worktree() {
  if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
    echo "deploy recusado: worktree deve estar limpo para o gate e o git archive usarem o mesmo SHA" >&2
    exit 2
  fi
}

for key in SSH_HOST SSH_KEY EASYPANEL_BASE_URL EASYPANEL_API_TOKEN DB_HOST DB_PORT DB_NAME DB_USER DB_PASS DB_SSL_MODE DATABASE_URL; do
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
if [[ "$DATABASE_URL" != *"@$EXPECTED_DB_HOST:$EXPECTED_DB_PORT/$EXPECTED_DB_NAME"* ]]; then
  echo "DATABASE_URL nao aponta para o PostgreSQL interno esperado" >&2
  exit 2
fi

curl_args=(-fsS)
if [[ "${MANALOOM_EASYPANEL_INSECURE_TLS:-0}" == "1" ]]; then
  curl_args+=(-k)
fi

trpc_post() {
  local procedure="$1"
  local payload="$2"
  curl "${curl_args[@]}" \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$payload" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$procedure"
}

cd "$ROOT_DIR"
require_clean_worktree
"$ROOT_DIR/scripts/manaloom_battle_product_gate.sh"
require_clean_worktree

git fetch origin master --quiet
sha="$(git rev-parse HEAD)"
short_sha="$(git rev-parse --short=12 HEAD)"
remote_dir="$REMOTE_BUILD_ROOT/cartinhas-$short_sha"
deploy_timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/master 2>/dev/null || true)" ]; then
  echo "HEAD local nao esta alinhado com origin/master; faca push antes do deploy." >&2
  exit 2
fi

runtime_db_target="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" "
docker service inspect '$SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' |
  awk -F= '/^DB_HOST=/{host=\$2} /^DB_PORT=/{port=\$2} /^DB_NAME=/{name=\$2} /^BATTLE_ENGINE=/{engine=\$2} /^XMAGE_SIDECAR_URL=/{xmage=\$2} /^FORGE_SIDECAR_URL=/{forge=\$2} /^NATIVE_BATTLE_SIDECAR_URL=/{native=\$2} END{print host \"|\" port \"|\" name \"|\" engine \"|\" xmage \"|\" forge \"|\" native}'
")"
if [[ "$runtime_db_target" != "$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME|$EXPECTED_BATTLE_ENGINE|$EXPECTED_XMAGE_URL|$EXPECTED_FORGE_URL|$EXPECTED_NATIVE_URL" ]]; then
  echo "deploy recusado: contrato PostgreSQL/battle da spec do backend esta divergente" >&2
  exit 2
fi

git archive HEAD server tools/manaloom_lints | ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

# Local deploy values are embedded; remote values are escaped.
# shellcheck disable=SC2087
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
cd '$remote_dir'
docker build \
  -f server/Dockerfile \
  -t '$IMAGE_REPO:$short_sha' \
  -t '$IMAGE_REPO:latest' \
  .
docker push '$IMAGE_REPO:$short_sha'
docker push '$IMAGE_REPO:latest'
docker service update \
  --update-order stop-first \
  --rollback-order stop-first \
  --detach=true \
  --image '$IMAGE_REPO:$short_sha' \
  --env-add GIT_SHA='$sha' \
  --env-add SENTRY_RELEASE='$sha' \
  --env-add DEPLOY_TIMESTAMP='$deploy_timestamp' \
  '$SERVICE'

for attempt in \$(seq 1 45); do
  replicas="\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -n 1)"
  spec_image="\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')"
  running_image="\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -n 1)"
  update_state="\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')"
  spec_image="\${spec_image%%@*}"
  running_image="\${running_image%%@*}"
  if [ "\$replicas" = "1/1" ] && \
     [ "\$spec_image" = '$IMAGE_REPO:$short_sha' ] && \
     [ "\$running_image" = '$IMAGE_REPO:$short_sha' ] && \
     { [ -z "\$update_state" ] || [ "\$update_state" = "completed" ]; }; then
    docker service ls --filter name='$SERVICE' --format '{{.Name}} {{.Image}} {{.Replicas}}'
    exit 0
  fi
  case "\$update_state" in
    paused|rollback_started|rollback_paused)
      break
      ;;
  esac
  sleep 2
done

docker service inspect '$SERVICE' --format 'image={{.Spec.TaskTemplate.ContainerSpec.Image}} update={{if .UpdateStatus}}{{.UpdateStatus.State}} {{.UpdateStatus.Message}}{{end}}'
docker service ps '$SERVICE' --no-trunc
exit 1
REMOTE

source_payload="$(jq -cn \
  --arg project "$EASYPANEL_PROJECT" \
  --arg service "$EASYPANEL_SERVICE" \
  --arg image "$IMAGE_REPO:$short_sha" \
  '{projectName:$project,serviceName:$service,image:$image}')"
trpc_post services.app.updateSourceImage "$source_payload" >/dev/null

runtime_contract="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" "
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker inspect \"\$container\" --format '{{range .Config.Env}}{{println .}}{{end}}' |
  awk -F= '/^GIT_SHA=/{sha=\$2} /^DB_HOST=/{host=\$2} /^DB_PORT=/{port=\$2} /^DB_NAME=/{name=\$2} /^BATTLE_ENGINE=/{engine=\$2} /^XMAGE_SIDECAR_URL=/{xmage=\$2} /^FORGE_SIDECAR_URL=/{forge=\$2} /^NATIVE_BATTLE_SIDECAR_URL=/{native=\$2} END{print sha \"|\" host \"|\" port \"|\" name \"|\" engine \"|\" xmage \"|\" forge \"|\" native}'
")"
if [[ "$runtime_contract" != "$sha|$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME|$EXPECTED_BATTLE_ENGINE|$EXPECTED_XMAGE_URL|$EXPECTED_FORGE_URL|$EXPECTED_NATIVE_URL" ]]; then
  echo "deploy convergiu com SHA ou contrato PostgreSQL/battle divergente" >&2
  exit 2
fi

runtime_image="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  "docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'")"
if [[ "${runtime_image%%@*}" != "$IMAGE_REPO:$short_sha" ]]; then
  echo "deploy convergiu com imagem mutavel ou SHA divergente: $runtime_image" >&2
  exit 2
fi

services_payload="$(trpc_post projects.listProjectsAndServices null)"
configured_image="$(jq -er \
  --arg project "$EASYPANEL_PROJECT" \
  --arg service "$EASYPANEL_SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$services_payload")"
if [[ "$configured_image" != "$IMAGE_REPO:$short_sha" ]]; then
  echo "deploy convergiu com origem EasyPanel mutavel ou SHA divergente: $configured_image" >&2
  exit 2
fi

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  "rm -rf '$remote_dir'"

printf '{"status":"deployed","service":"%s","image":"%s:%s","git_sha":"%s","remote_dir_removed":"%s"}\n' \
  "$SERVICE" "$IMAGE_REPO" "$short_sha" "$sha" "$remote_dir"

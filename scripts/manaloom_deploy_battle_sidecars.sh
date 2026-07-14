#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required tool missing: $1" >&2
    exit 2
  }
}

for tool in base64 curl git jq ssh; do
  require_tool "$tool"
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "env file not found: $ENV_FILE" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
BACKEND_SERVICE="${EASYPANEL_APP_NAME:-cartinhas}"
XMAGE_SERVICE="${MANALOOM_XMAGE_SERVICE:-xmage-sidecar}"
FORGE_SERVICE="${MANALOOM_FORGE_SERVICE:-forge-sidecar}"

required=(
  EASYPANEL_BASE_URL
  EASYPANEL_API_TOKEN
  EASYPANEL_SERVER_IP
  EASYPANEL_SSH_USER
  EASYPANEL_SSH_KEY
  DB_HOST
  DB_PORT
  DB_NAME
  DB_USER
  DB_PASS
  DB_SSL_MODE
  DATABASE_URL
)
for key in "${required[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "missing required environment key: $key" >&2
    exit 2
  fi
done

cd "$ROOT_DIR"
git fetch origin master --quiet
sha="$(git rev-parse HEAD)"
origin_sha="$(git rev-parse origin/master)"
if [[ "$sha" != "$origin_sha" ]]; then
  echo "HEAD must match origin/master before sidecar deploy" >&2
  exit 2
fi

short_sha="$(git rev-parse --short=12 HEAD)"
remote_dir="$REMOTE_BUILD_ROOT/battle-sidecars-$short_sha"
ssh_target="$EASYPANEL_SSH_USER@$EASYPANEL_SERVER_IP"
ssh_args=(-i "$EASYPANEL_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new)
xmage_image="localhost:5000/manaloom/xmage-sidecar:$short_sha"
forge_image="localhost:5000/manaloom/forge-sidecar:$short_sha"

git archive HEAD -- services/xmage-sidecar services/forge-sidecar |
  ssh "${ssh_args[@]}" "$ssh_target" \
    "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
cd '$remote_dir'
DOCKER_BUILDKIT=1 docker build \
  --label org.opencontainers.image.revision='$sha' \
  -f services/xmage-sidecar/Dockerfile \
  -t '$xmage_image' \
  -t 'localhost:5000/manaloom/xmage-sidecar:latest' .
docker push '$xmage_image'
docker push 'localhost:5000/manaloom/xmage-sidecar:latest'
DOCKER_BUILDKIT=1 docker build \
  --label org.opencontainers.image.revision='$sha' \
  -f services/forge-sidecar/Dockerfile \
  -t '$forge_image' \
  -t 'localhost:5000/manaloom/forge-sidecar:latest' .
docker push '$forge_image'
docker push 'localhost:5000/manaloom/forge-sidecar:latest'
"

curl_args=(-fsS)
if [[ "${MANALOOM_EASYPANEL_INSECURE_TLS:-0}" == "1" ]]; then
  curl_args+=(-k)
fi

trpc_post() {
  local procedure="$1"
  local payload="$2"
  local body
  body="$(jq -cn --argjson input "$payload" '{json:$input}')"
  curl "${curl_args[@]}" \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$body" \
    "$EASYPANEL_BASE_URL/api/trpc/$procedure"
}

services_json="$(trpc_post projects.listProjectsAndServices null)"
jq -e '.json.services' >/dev/null <<<"$services_json"

service_exists() {
  local service_name="$1"
  jq -e \
    --arg project "$PROJECT" \
    --arg service "$service_name" \
    '.json.services[]? | select(.projectName == $project and .name == $service and .type == "app")' \
    >/dev/null <<<"$services_json"
}

upsert_sidecar() {
  local service_name="$1"
  local image="$2"
  local env_text="$3"
  local memory_limit="$4"
  local payload

  if service_exists "$service_name"; then
    payload="$(jq -cn \
      --arg project "$PROJECT" --arg service "$service_name" --arg image "$image" \
      '{projectName:$project,serviceName:$service,image:$image}')"
    trpc_post services.app.updateSourceImage "$payload" >/dev/null

    payload="$(jq -cn \
      --arg project "$PROJECT" --arg service "$service_name" --arg env "$env_text" \
      '{projectName:$project,serviceName:$service,env:$env}')"
    trpc_post services.app.updateEnv "$payload" >/dev/null

    payload="$(jq -cn \
      --arg project "$PROJECT" --arg service "$service_name" --argjson memory "$memory_limit" \
      '{projectName:$project,serviceName:$service,resources:{cpuLimit:2,cpuReservation:0.25,memoryLimit:$memory,memoryReservation:512}}')"
    trpc_post services.app.updateResources "$payload" >/dev/null

    payload="$(jq -cn \
      --arg project "$PROJECT" --arg service "$service_name" \
      '{projectName:$project,serviceName:$service,deploy:{command:null,replicas:1,zeroDowntime:false}}')"
    trpc_post services.app.updateDeploy "$payload" >/dev/null
    trpc_post services.app.deployService "$(jq -cn --arg project "$PROJECT" --arg service "$service_name" '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null
  else
    payload="$(jq -cn \
      --arg project "$PROJECT" --arg service "$service_name" --arg image "$image" --arg env "$env_text" --argjson memory "$memory_limit" \
      '{projectName:$project,serviceName:$service,source:{type:"image",image:$image},env:$env,deploy:{command:null,replicas:1,zeroDowntime:false},resources:{cpuLimit:2,cpuReservation:0.25,memoryLimit:$memory,memoryReservation:512}}')"
    trpc_post services.app.createService "$payload" >/dev/null
  fi
}

upsert_sidecar "$XMAGE_SERVICE" "$xmage_image" $'PORT=8080\nXMAGE_SERVER_JAVA_OPTS=-Xms256m -Xmx2g\nXMAGE_SIDECAR_JAVA_OPTS=-Xms128m -Xmx512m\n' 3072
upsert_sidecar "$FORGE_SERVICE" "$forge_image" $'PORT=8080\nFORGE_JAVA_COMMAND=xvfb-run -a java -Xms128m -Xmx1536m\n' 2560

wait_for_service() {
  local swarm_service="$1"
  ssh "${ssh_args[@]}" "$ssh_target" "
for attempt in \$(seq 1 180); do
  replicas=\$(docker service ls --filter name='$swarm_service' --format '{{.Replicas}}' | head -1)
  if [[ \"\$replicas\" == '1/1' ]]; then exit 0; fi
  sleep 2
done
docker service ps '$swarm_service' --no-trunc
exit 1
"
}

wait_for_service "${PROJECT}_${XMAGE_SERVICE}"
wait_for_service "${PROJECT}_${FORGE_SERVICE}"

wait_for_sidecar_health() {
  local swarm_service="$1"
  local service_alias="$2"
  local expected_fragment="${3:-}"

  ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
network_id=\$(docker service inspect '$swarm_service' | jq -r \
  --arg alias '$service_alias' \
  '.[0].Spec.TaskTemplate.Networks[] | select((.Aliases // []) | index(\$alias)) | .Target' | head -1)
if [[ -z \"\$network_id\" ]]; then
  echo 'project network alias not found for $swarm_service: $service_alias' >&2
  exit 1
fi
network_name=\$(docker network inspect \"\$network_id\" --format '{{.Name}}')
docker run --rm --network \"\$network_name\" --entrypoint sh curlimages/curl:8.10.1 -c '
  for attempt in \$(seq 1 180); do
    if response=\$(curl -fsS --connect-timeout 2 --max-time 5 http://$service_alias:8080/health); then
      if [ -z '$expected_fragment' ] || printf '%s' "\$response" | grep -Fq '$expected_fragment'; then
        printf '%s\n' "\$response"
        exit 0
      fi
    fi
    sleep 2
  done
  exit 1
'
"
}

wait_for_sidecar_health "${PROJECT}_${XMAGE_SERVICE}" "$XMAGE_SERVICE" catalog_ready
wait_for_sidecar_health "${PROJECT}_${FORGE_SERVICE}" "$FORGE_SERVICE"

services_json="$(trpc_post projects.listProjectsAndServices null)"
backend_env="$(jq -er --arg project "$PROJECT" --arg service "$BACKEND_SERVICE" '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .env' <<<"$services_json")"

upsert_env() {
  local current="$1"
  local key="$2"
  local value="$3"
  local output=""
  local found=0
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$key="* ]]; then
      output+="$key=$value"$'\n'
      found=1
    elif [[ -n "$line" ]]; then
      output+="$line"$'\n'
    fi
  done <<<"$current"
  if [[ "$found" == "0" ]]; then
    output+="$key=$value"$'\n'
  fi
  printf '%s' "$output"
}

backend_env="$(upsert_env "$backend_env" BATTLE_ENGINE auto)"
backend_env="$(upsert_env "$backend_env" XMAGE_SIDECAR_URL "http://$XMAGE_SERVICE:8080")"
backend_env="$(upsert_env "$backend_env" FORGE_SIDECAR_URL "http://$FORGE_SERVICE:8080")"
backend_env="$(upsert_env "$backend_env" DB_HOST "$DB_HOST")"
backend_env="$(upsert_env "$backend_env" DB_PORT "$DB_PORT")"
backend_env="$(upsert_env "$backend_env" DB_NAME "$DB_NAME")"
backend_env="$(upsert_env "$backend_env" DB_USER "$DB_USER")"
backend_env="$(upsert_env "$backend_env" DB_PASS "$DB_PASS")"
backend_env="$(upsert_env "$backend_env" DATABASE_URL "$DATABASE_URL")"
backend_env="$(upsert_env "$backend_env" DB_SSL_MODE "$DB_SSL_MODE")"

trpc_post services.app.updateEnv "$(jq -cn --arg project "$PROJECT" --arg service "$BACKEND_SERVICE" --arg env "$backend_env" '{projectName:$project,serviceName:$service,env:$env}')" >/dev/null

encode_base64() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

db_host_b64="$(encode_base64 "$DB_HOST")"
db_port_b64="$(encode_base64 "$DB_PORT")"
db_name_b64="$(encode_base64 "$DB_NAME")"
db_user_b64="$(encode_base64 "$DB_USER")"
db_pass_b64="$(encode_base64 "$DB_PASS")"
database_url_b64="$(encode_base64 "$DATABASE_URL")"
db_ssl_mode_b64="$(encode_base64 "$DB_SSL_MODE")"
backend_swarm_service="${PROJECT}_${BACKEND_SERVICE}"

ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
decode() { printf '%s' \"\$1\" | base64 -d; }
db_host=\$(decode '$db_host_b64')
db_port=\$(decode '$db_port_b64')
db_name=\$(decode '$db_name_b64')
db_user=\$(decode '$db_user_b64')
db_pass=\$(decode '$db_pass_b64')
database_url=\$(decode '$database_url_b64')
db_ssl_mode=\$(decode '$db_ssl_mode_b64')
update_args=(
  docker service update
  --update-order stop-first
  --env-add 'BATTLE_ENGINE=auto'
  --env-add 'XMAGE_SIDECAR_URL=http://$XMAGE_SERVICE:8080'
  --env-add 'FORGE_SIDECAR_URL=http://$FORGE_SERVICE:8080'
  --env-add \"DB_HOST=\$db_host\"
  --env-add \"DB_PORT=\$db_port\"
  --env-add \"DB_NAME=\$db_name\"
  --env-add \"DB_USER=\$db_user\"
  --env-add \"DB_PASS=\$db_pass\"
  --env-add \"DATABASE_URL=\$database_url\"
  --env-add \"DB_SSL_MODE=\$db_ssl_mode\"
)
\"\${update_args[@]}\" '$backend_swarm_service' >/dev/null
"
wait_for_service "$backend_swarm_service"

ssh "${ssh_args[@]}" "$ssh_target" "rm -rf '$remote_dir'"

printf '{"status":"deployed","git_sha":"%s","xmage_service":"%s","forge_service":"%s","backend_service":"%s"}\n' \
  "$sha" "$XMAGE_SERVICE" "$FORGE_SERVICE" "$BACKEND_SERVICE"

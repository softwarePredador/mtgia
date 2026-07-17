#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "deploy dos battle sidecars"
require_postgres_write_approval "deploy dos battle sidecars com runtime PostgreSQL"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required tool missing: $1" >&2
    exit 2
  }
}

for tool in base64 curl git jq python3 shasum ssh; do
  require_tool "$tool"
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "env file not found: $ENV_FILE" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
load_manaloom_env_keys "$ENV_FILE" \
  DATABASE_URL DB_HOST DB_NAME DB_PASS DB_PORT DB_SSL_MODE DB_USER \
  EASYPANEL_API_TOKEN EASYPANEL_APP_NAME EASYPANEL_BASE_URL \
  EASYPANEL_PROJECT_NAME EASYPANEL_SERVER_IP EASYPANEL_SSH_KEY \
  EASYPANEL_SSH_USER MANALOOM_EASYPANEL_INSECURE_TLS \
  MANALOOM_EASYPANEL_SSH_HOST MANALOOM_EASYPANEL_SSH_KEY \
  MANALOOM_FORGE_MEMORY_LIMIT_MB MANALOOM_FORGE_SERVICE \
  MANALOOM_NATIVE_BATTLE_SERVICE MANALOOM_NATIVE_BATTLE_SERVICE_DNS \
  MANALOOM_PROJECT_NETWORK MANALOOM_REMOTE_BUILD_ROOT \
  MANALOOM_XMAGE_MEMORY_LIMIT_MB MANALOOM_XMAGE_SERVICE

REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
BACKEND_SERVICE="${EASYPANEL_APP_NAME:-cartinhas}"
XMAGE_SERVICE="${MANALOOM_XMAGE_SERVICE:-xmage-sidecar}"
FORGE_SERVICE="${MANALOOM_FORGE_SERVICE:-forge-sidecar}"
NATIVE_SERVICE="${MANALOOM_NATIVE_BATTLE_SERVICE:-manaloom-ops}"
NATIVE_SERVICE_DNS="${MANALOOM_NATIVE_BATTLE_SERVICE_DNS:-${PROJECT}_${NATIVE_SERVICE}}"
PROJECT_NETWORK="${MANALOOM_PROJECT_NETWORK:-easypanel-$PROJECT}"
XMAGE_MEMORY_LIMIT_MB="${MANALOOM_XMAGE_MEMORY_LIMIT_MB:-4096}"
FORGE_MEMORY_LIMIT_MB="${MANALOOM_FORGE_MEMORY_LIMIT_MB:-2560}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
HEALTH_PROBE_IMAGE="curlimages/curl:8.10.1@sha256:d9b4541e214bcd85196d6e92e2753ac6d0ea699f0af5741f8c6cccbfcf00ef4b"

required=(
  EASYPANEL_BASE_URL
  EASYPANEL_API_TOKEN
  SSH_HOST
  SSH_KEY
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

if [[ ! -f "$SSH_KEY" ]]; then
  echo "SSH key not found: $SSH_KEY" >&2
  exit 2
fi

validate_manaloom_exact_coordinate \
  "destino SSH" "$SSH_HOST" "${MANALOOM_EXPECTED_SSH_TARGET:-}"
validate_manaloom_easypanel_base_url "$EASYPANEL_BASE_URL"
EASYPANEL_BASE_URL="$MANALOOM_EASYPANEL_BASE_URL_RESOLVED"
validate_manaloom_exact_coordinate \
  "projeto EasyPanel" "$PROJECT" "$MANALOOM_PRODUCTION_EASYPANEL_PROJECT"
validate_manaloom_exact_coordinate \
  "backend EasyPanel" "$BACKEND_SERVICE" "cartinhas"
validate_manaloom_exact_coordinate "servico XMage" "$XMAGE_SERVICE" "xmage-sidecar"
validate_manaloom_exact_coordinate "servico Forge" "$FORGE_SERVICE" "forge-sidecar"
validate_manaloom_exact_coordinate "servico nativo" "$NATIVE_SERVICE" "manaloom-ops"
validate_manaloom_exact_coordinate \
  "DNS do servico nativo" "$NATIVE_SERVICE_DNS" "evolution_manaloom-ops"
validate_manaloom_exact_coordinate \
  "rede EasyPanel" "$PROJECT_NETWORK" "easypanel-evolution"
validate_manaloom_exact_coordinate \
  "raiz remota de build" "$REMOTE_BUILD_ROOT" "$MANALOOM_PRODUCTION_REMOTE_BUILD_ROOT"
validate_manaloom_exact_coordinate "host PostgreSQL" "$DB_HOST" "evolution_manaloom-postgres"
validate_manaloom_exact_coordinate "porta PostgreSQL" "$DB_PORT" "5432"
validate_manaloom_exact_coordinate "database PostgreSQL" "$DB_NAME" "halder"
validate_manaloom_exact_coordinate "usuario PostgreSQL" "$DB_USER" "postgres"
validate_manaloom_exact_coordinate "TLS PostgreSQL interno" "$DB_SSL_MODE" "disable"

if [[ "${MANALOOM_EASYPANEL_INSECURE_TLS:-0}" != "0" ]]; then
  echo "TLS inseguro para EasyPanel e proibido" >&2
  exit 2
fi
if [[ ! "$XMAGE_MEMORY_LIMIT_MB" =~ ^[0-9]+$ ||
      ! "$FORGE_MEMORY_LIMIT_MB" =~ ^[0-9]+$ ||
      "$XMAGE_MEMORY_LIMIT_MB" -lt 512 || "$XMAGE_MEMORY_LIMIT_MB" -gt 16384 ||
      "$FORGE_MEMORY_LIMIT_MB" -lt 512 || "$FORGE_MEMORY_LIMIT_MB" -gt 16384 ]]; then
  echo "limites de memoria dos sidecars sao invalidos" >&2
  exit 2
fi
if ! python3 - "$DATABASE_URL" "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" <<'PY'
import sys
from urllib.parse import parse_qsl, urlsplit

url = urlsplit(sys.argv[1])
expected_port = int(sys.argv[3])
valid = (
    url.scheme in {"postgres", "postgresql"}
    and url.hostname == sys.argv[2]
    and (url.port or 5432) == expected_port
    and url.path == f"/{sys.argv[4]}"
    and url.username == sys.argv[5]
    and url.password is not None
    and parse_qsl(url.query, keep_blank_values=True) == [("sslmode", "disable")]
    and not url.fragment
)
raise SystemExit(0 if valid else 1)
PY
then
  echo "DATABASE_URL diverge das coordenadas PostgreSQL aprovadas" >&2
  exit 2
fi

REMOTE_DIR_CLEANUP_REQUIRED=0
REMOTE_CLEANUP_PROOF=""
DEPLOY_MUTATION_STARTED=0
DEPLOY_COMMITTED=0
XMAGE_MUTATION_STARTED=0
FORGE_MUTATION_STARTED=0
XMAGE_PREVIOUS_SOURCE_IMAGE=""
XMAGE_ROLLBACK_SOURCE_IMAGE=""
XMAGE_PREVIOUS_SPEC_IMAGE=""
XMAGE_PREVIOUS_RUNNING_IMAGE=""
XMAGE_PREVIOUS_UPDATE_STATE=""
FORGE_PREVIOUS_SOURCE_IMAGE=""
FORGE_ROLLBACK_SOURCE_IMAGE=""
FORGE_PREVIOUS_SPEC_IMAGE=""
FORGE_PREVIOUS_RUNNING_IMAGE=""
FORGE_PREVIOUS_UPDATE_STATE=""

cleanup_remote_build_dir() {
  local proof expected
  if [[ "$REMOTE_DIR_CLEANUP_REQUIRED" != "1" || -z "${remote_dir:-}" ]]; then
    return 0
  fi
  expected="removed:$remote_dir"
  if ! proof="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "rm -rf '$remote_dir'; test ! -e '$remote_dir'; printf '%s' '$expected'")"; then
    echo "cleanup remoto do build dos sidecars falhou" >&2
    return 1
  fi
  if [[ "$proof" != "$expected" ]]; then
    echo "cleanup remoto dos sidecars nao produziu prova exata" >&2
    return 1
  fi
  REMOTE_DIR_CLEANUP_REQUIRED=0
  REMOTE_CLEANUP_PROOF="$proof"
}

cleanup_on_exit() {
  local original_status=$?
  local cleanup_status=0
  local rollback_status=0
  trap - EXIT
  set +e
  if [[ "$original_status" != "0" && "$DEPLOY_MUTATION_STARTED" == "1" &&
        "$DEPLOY_COMMITTED" != "1" ]] &&
     declare -F rollback_battle_sidecars >/dev/null 2>&1; then
    rollback_battle_sidecars || rollback_status=$?
  fi
  cleanup_remote_build_dir || cleanup_status=$?
  cleanup_manaloom_secure_ssh
  if (( rollback_status != 0 || cleanup_status != 0 )); then
    exit 1
  fi
  exit "$original_status"
}

initialize_manaloom_secure_ssh "$SSH_HOST"
trap cleanup_on_exit EXIT

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/manaloom_battle_product_gate.sh"
git fetch origin master --quiet
sha="$(git rev-parse HEAD)"
origin_sha="$(git rev-parse origin/master)"
if [[ "$sha" != "$origin_sha" ]]; then
  echo "HEAD must match origin/master before sidecar deploy" >&2
  exit 2
fi

short_sha="$(git rev-parse --short=12 HEAD)"
remote_dir="$REMOTE_BUILD_ROOT/battle-sidecars-$short_sha"
ssh_target="$SSH_HOST"
ssh_args=(-i "$SSH_KEY" -o BatchMode=yes)
XMAGE_IMAGE_REPO="localhost:5000/manaloom/xmage-sidecar"
FORGE_IMAGE_REPO="localhost:5000/manaloom/forge-sidecar"
xmage_tag="$XMAGE_IMAGE_REPO:$short_sha"
forge_tag="$FORGE_IMAGE_REPO:$short_sha"
XMAGE_IMAGE_DIGEST_REF=""
FORGE_IMAGE_DIGEST_REF=""

curl_args=(-fsS --proto '=https' --tlsv1.2)

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

wait_for_service() {
  local swarm_service="$1"
  local expected_image="${2:-}"
  # shellcheck disable=SC2029
  ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
expected_image='$expected_image'
for attempt in \$(seq 1 180); do
  replicas=\$(docker service ls --filter name='$swarm_service' --format '{{.Replicas}}' | head -1)
  spec_image=\$(docker service inspect '$swarm_service' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
  running_image=\$(docker service ps '$swarm_service' --filter desired-state=running --format '{{.Image}}' | head -1)
  update_state=\$(docker service inspect '$swarm_service' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
  image_ready=0
  if [[ -z \"\$expected_image\" || (\"\$spec_image\" == \"\$expected_image\" && \"\$running_image\" == \"\$expected_image\") ]]; then
    image_ready=1
  fi
  if [[ \"\$replicas\" == '1/1' && \"\$image_ready\" == '1' &&
        ( -z \"\$update_state\" || \"\$update_state\" == 'completed' ||
          \"\$update_state\" == 'rollback_completed' ) ]]; then
    exit 0
  fi
  if [[ \"\$update_state\" == 'paused' || \"\$update_state\" == 'rollback_started' || \"\$update_state\" == 'rollback_paused' ]]; then
    break
  fi
  sleep 2
done
docker service inspect '$swarm_service' --format 'image={{.Spec.TaskTemplate.ContainerSpec.Image}} update={{if .UpdateStatus}}{{.UpdateStatus.State}} {{.UpdateStatus.Message}}{{end}}'
docker service ps '$swarm_service' --no-trunc
exit 1
"
}

wait_for_sidecar_health() {
  local swarm_service="$1"
  local service_alias="$2"
  local expected_fragment="${3:-}"

  # shellcheck disable=SC2140
  ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
docker service inspect '$swarm_service' >/dev/null
docker network inspect '$PROJECT_NETWORK' >/dev/null
network_name='$PROJECT_NETWORK'
docker run --rm --network \"\$network_name\" --entrypoint sh '$HEALTH_PROBE_IMAGE' -c '
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

for required_service in "$XMAGE_SERVICE" "$FORGE_SERVICE"; do
  if ! service_exists "$required_service"; then
    echo "deploy recusado: sidecar EasyPanel existente e obrigatorio: $required_service" >&2
    exit 2
  fi
done

sidecar_runtime_state() {
  local swarm_service="$1"
  # shellcheck disable=SC2029
  ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
replicas=\$(docker service ls --filter name='$swarm_service' --format '{{.Replicas}}' | head -1)
spec=\$(docker service inspect '$swarm_service' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$swarm_service' --filter desired-state=running --format '{{.Image}}' | head -1)
update=\$(docker service inspect '$swarm_service' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$update\"
"
}

validate_sidecar_baseline() {
  local label="$1"
  local image_repo="$2"
  local runtime_state="$3"
  local replicas="$4"
  local spec_image="$5"
  local running_image="$6"
  local update_state="$7"
  local digest
  digest="${spec_image#"$image_repo@sha256:"}"
  if [[ "$replicas" != "1/1" || "$running_image" != "$spec_image" ||
        ( -n "$update_state" && "$update_state" != "completed" &&
          "$update_state" != "rollback_completed" ) ||
        "$spec_image" != "$image_repo@sha256:$digest" ||
        ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
    echo "deploy recusado: baseline $label nao e rollback-safe: $runtime_state" >&2
    exit 2
  fi
}

XMAGE_PREVIOUS_SOURCE_IMAGE="$(jq -er \
  --arg project "$PROJECT" --arg service "$XMAGE_SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$services_json")"
FORGE_PREVIOUS_SOURCE_IMAGE="$(jq -er \
  --arg project "$PROJECT" --arg service "$FORGE_SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$services_json")"
XMAGE_PREVIOUS_RUNTIME_STATE="$(sidecar_runtime_state "${PROJECT}_${XMAGE_SERVICE}")"
FORGE_PREVIOUS_RUNTIME_STATE="$(sidecar_runtime_state "${PROJECT}_${FORGE_SERVICE}")"
IFS='|' read -r xmage_previous_replicas XMAGE_PREVIOUS_SPEC_IMAGE \
  XMAGE_PREVIOUS_RUNNING_IMAGE XMAGE_PREVIOUS_UPDATE_STATE \
  <<<"$XMAGE_PREVIOUS_RUNTIME_STATE"
IFS='|' read -r forge_previous_replicas FORGE_PREVIOUS_SPEC_IMAGE \
  FORGE_PREVIOUS_RUNNING_IMAGE FORGE_PREVIOUS_UPDATE_STATE \
  <<<"$FORGE_PREVIOUS_RUNTIME_STATE"
validate_sidecar_baseline \
  "$XMAGE_SERVICE" "$XMAGE_IMAGE_REPO" "$XMAGE_PREVIOUS_RUNTIME_STATE" \
  "$xmage_previous_replicas" "$XMAGE_PREVIOUS_SPEC_IMAGE" \
  "$XMAGE_PREVIOUS_RUNNING_IMAGE" "$XMAGE_PREVIOUS_UPDATE_STATE"
validate_sidecar_baseline \
  "$FORGE_SERVICE" "$FORGE_IMAGE_REPO" "$FORGE_PREVIOUS_RUNTIME_STATE" \
  "$forge_previous_replicas" "$FORGE_PREVIOUS_SPEC_IMAGE" \
  "$FORGE_PREVIOUS_RUNNING_IMAGE" "$FORGE_PREVIOUS_UPDATE_STATE"
wait_for_sidecar_health \
  "${PROJECT}_${XMAGE_SERVICE}" "$XMAGE_SERVICE" catalog_ready >/dev/null
wait_for_sidecar_health \
  "${PROJECT}_${FORGE_SERVICE}" "$FORGE_SERVICE" >/dev/null
XMAGE_ROLLBACK_SOURCE_IMAGE="$XMAGE_PREVIOUS_SPEC_IMAGE"
FORGE_ROLLBACK_SOURCE_IMAGE="$FORGE_PREVIOUS_SPEC_IMAGE"
if [[ "$XMAGE_PREVIOUS_SOURCE_IMAGE" != "$XMAGE_ROLLBACK_SOURCE_IMAGE" ]]; then
  echo "origem XMage anterior sera normalizada para o digest imutavel durante eventual rollback" >&2
fi
if [[ "$FORGE_PREVIOUS_SOURCE_IMAGE" != "$FORGE_ROLLBACK_SOURCE_IMAGE" ]]; then
  echo "origem Forge anterior sera normalizada para o digest imutavel durante eventual rollback" >&2
fi

REMOTE_DIR_CLEANUP_REQUIRED=1
# shellcheck disable=SC2029
git archive HEAD -- services/xmage-sidecar services/forge-sidecar |
  ssh "${ssh_args[@]}" "$ssh_target" \
    "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

# Tags are publication handles only. Deployment starts only after both registry
# RepoDigests have been resolved and validated locally.
# shellcheck disable=SC2029,SC2087
digest_pair="$(ssh "${ssh_args[@]}" "$ssh_target" <<REMOTE
set -euo pipefail
cd '$remote_dir'
DOCKER_BUILDKIT=1 docker build \
  --label org.opencontainers.image.revision='$sha' \
  -f services/xmage-sidecar/Dockerfile \
  -t '$xmage_tag' \
  -t '$XMAGE_IMAGE_REPO:latest' . >&2
docker push '$xmage_tag' >&2
docker push '$XMAGE_IMAGE_REPO:latest' >&2
DOCKER_BUILDKIT=1 docker build \
  --label org.opencontainers.image.revision='$sha' \
  -f services/forge-sidecar/Dockerfile \
  -t '$forge_tag' \
  -t '$FORGE_IMAGE_REPO:latest' . >&2
docker push '$forge_tag' >&2
docker push '$FORGE_IMAGE_REPO:latest' >&2

xmage_digest_ref=''
forge_digest_ref=''
for attempt in \$(seq 1 15); do
  xmage_digest_ref="\$(
    docker image inspect '$xmage_tag' \
      --format '{{range .RepoDigests}}{{println .}}{{end}}' |
      awk -v expected_repo='$XMAGE_IMAGE_REPO' \
        'index(\$0, expected_repo "@sha256:") == 1 {print; exit}'
  )"
  forge_digest_ref="\$(
    docker image inspect '$forge_tag' \
      --format '{{range .RepoDigests}}{{println .}}{{end}}' |
      awk -v expected_repo='$FORGE_IMAGE_REPO' \
        'index(\$0, expected_repo "@sha256:") == 1 {print; exit}'
  )"
  xmage_digest="\${xmage_digest_ref#'$XMAGE_IMAGE_REPO@sha256:'}"
  forge_digest="\${forge_digest_ref#'$FORGE_IMAGE_REPO@sha256:'}"
  if [[ "\$xmage_digest_ref" == '$XMAGE_IMAGE_REPO@sha256:'"\$xmage_digest" &&
        "\$forge_digest_ref" == '$FORGE_IMAGE_REPO@sha256:'"\$forge_digest" &&
        "\$xmage_digest" =~ ^[0-9a-f]{64}$ &&
        "\$forge_digest" =~ ^[0-9a-f]{64}$ ]]; then
    printf '%s|%s\n' "\$xmage_digest_ref" "\$forge_digest_ref"
    exit 0
  fi
  sleep 1
done
echo 'push remoto nao produziu RepoDigests SHA-256 validos para os sidecars' >&2
exit 2
REMOTE
)"
IFS='|' read -r XMAGE_IMAGE_DIGEST_REF FORGE_IMAGE_DIGEST_REF <<<"$digest_pair"
xmage_digest="${XMAGE_IMAGE_DIGEST_REF#"$XMAGE_IMAGE_REPO@sha256:"}"
forge_digest="${FORGE_IMAGE_DIGEST_REF#"$FORGE_IMAGE_REPO@sha256:"}"
if [[ "$XMAGE_IMAGE_DIGEST_REF" != "$XMAGE_IMAGE_REPO@sha256:$xmage_digest" ||
      "$FORGE_IMAGE_DIGEST_REF" != "$FORGE_IMAGE_REPO@sha256:$forge_digest" ||
      ! "$xmage_digest" =~ ^[0-9a-f]{64}$ ||
      ! "$forge_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "push remoto retornou RepoDigests invalidos: $digest_pair" >&2
  exit 2
fi
readonly XMAGE_IMAGE_DIGEST_REF FORGE_IMAGE_DIGEST_REF

configured_sidecar_image() {
  local service_name="$1"
  local current_services
  current_services="$(trpc_post projects.listProjectsAndServices null)"
  jq -er \
    --arg project "$PROJECT" --arg service "$service_name" \
    '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
    <<<"$current_services"
}

deploy_sidecar_digest() {
  local service_name="$1"
  local image_digest_ref="$2"
  local env_text="$3"
  local memory_limit="$4"
  local swarm_service="${PROJECT}_${service_name}"
  local payload

  DEPLOY_MUTATION_STARTED=1
  case "$service_name" in
    "$XMAGE_SERVICE") XMAGE_MUTATION_STARTED=1 ;;
    "$FORGE_SERVICE") FORGE_MUTATION_STARTED=1 ;;
    *) echo "sidecar nao aprovado para mutacao: $service_name" >&2; return 2 ;;
  esac

  payload="$(jq -cn \
    --arg project "$PROJECT" --arg service "$service_name" \
    --arg image "$image_digest_ref" \
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
  trpc_post services.app.deployService "$(jq -cn \
    --arg project "$PROJECT" --arg service "$service_name" \
    '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null
  wait_for_service "$swarm_service" "$image_digest_ref"

  # EasyPanel owns the desired source; this explicit update also fixes the
  # effective Swarm rollout/rollback policy and proves the exact task digest.
  # shellcheck disable=SC2029
  ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
docker service update \\
  --update-order stop-first \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-order stop-first \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --detach=true \\
  --image '$image_digest_ref' \\
  '$swarm_service' >/dev/null
"
  wait_for_service "$swarm_service" "$image_digest_ref"
}

prove_sidecar_release() {
  local service_name="$1"
  local image_digest_ref="$2"
  local service_alias="$3"
  local expected_fragment="${4:-}"
  local swarm_service="${PROJECT}_${service_name}"
  local configured_image runtime_state health_payload

  wait_for_service "$swarm_service" "$image_digest_ref"
  health_payload="$(wait_for_sidecar_health \
    "$swarm_service" "$service_alias" "$expected_fragment")"
  if [[ -z "$health_payload" ]]; then
    echo "sidecar $service_name retornou health vazio" >&2
    return 1
  fi
  configured_image="$(configured_sidecar_image "$service_name")"
  runtime_state="$(sidecar_runtime_state "$swarm_service")"
  IFS='|' read -r proof_replicas proof_spec_image proof_running_image \
    proof_update_state <<<"$runtime_state"
  if [[ "$configured_image" != "$image_digest_ref" ||
        "$proof_replicas" != "1/1" ||
        "$proof_spec_image" != "$image_digest_ref" ||
        "$proof_running_image" != "$image_digest_ref" ||
        ( -n "$proof_update_state" && "$proof_update_state" != "completed" &&
          "$proof_update_state" != "rollback_completed" ) ]]; then
    echo "sidecar $service_name sem prova origem=spec=tarefa=digest: configured=$configured_image runtime=$runtime_state" >&2
    return 1
  fi
  printf '%s|%s|%s|health=ok\n' \
    "$configured_image" "$proof_spec_image" "$proof_running_image"
}

rollback_one_sidecar() {
  local service_name="$1"
  local previous_digest_ref="$2"
  local rollback_source_image="$3"
  local service_alias="$4"
  local expected_fragment="${5:-}"
  local swarm_service="${PROJECT}_${service_name}"
  local source_status=1 runtime_status=1 configured_status=1 health_status=1
  local configured_image

  if trpc_post services.app.updateSourceImage "$(jq -cn \
       --arg project "$PROJECT" --arg service "$service_name" \
       --arg image "$rollback_source_image" \
       '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null &&
     trpc_post services.app.deployService "$(jq -cn \
       --arg project "$PROJECT" --arg service "$service_name" \
       '{projectName:$project,serviceName:$service,forceRebuild:false}')" \
       >/dev/null; then
    source_status=0
  fi
  # shellcheck disable=SC2029
  if ssh "${ssh_args[@]}" "$ssh_target" "
set -euo pipefail
docker service update \\
  --update-order stop-first \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-order stop-first \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --detach=true \\
  --image '$previous_digest_ref' \\
  '$swarm_service' >/dev/null
" && wait_for_service "$swarm_service" "$previous_digest_ref"; then
    runtime_status=0
  fi
  if wait_for_sidecar_health \
    "$swarm_service" "$service_alias" "$expected_fragment" >/dev/null; then
    health_status=0
  fi
  if [[ "$health_status" == "0" ]]; then
    runtime_status=1
    configured_status=1
    if wait_for_service "$swarm_service" "$previous_digest_ref"; then
      runtime_status=0
    fi
    if configured_image="$(configured_sidecar_image "$service_name")" &&
       [[ "$configured_image" == "$rollback_source_image" ]]; then
      configured_status=0
    fi
  fi
  if [[ "$source_status" == "0" && "$runtime_status" == "0" &&
        "$configured_status" == "0" && "$health_status" == "0" ]]; then
    echo "rollback $service_name comprovado: origem, spec, tarefa e health no digest anterior" >&2
    return 0
  fi
  echo "CRITICAL: rollback $service_name nao comprovado (source=$source_status runtime=$runtime_status configured=$configured_status health=$health_status)" >&2
  return 1
}

rollback_battle_sidecars() {
  local rollback_status=0
  echo "deploy dos battle sidecars falhou; restaurando digests anteriores" >&2
  if [[ "$FORGE_MUTATION_STARTED" == "1" ]]; then
    rollback_one_sidecar \
      "$FORGE_SERVICE" "$FORGE_PREVIOUS_SPEC_IMAGE" \
      "$FORGE_ROLLBACK_SOURCE_IMAGE" "$FORGE_SERVICE" || rollback_status=1
  fi
  if [[ "$XMAGE_MUTATION_STARTED" == "1" ]]; then
    rollback_one_sidecar \
      "$XMAGE_SERVICE" "$XMAGE_PREVIOUS_SPEC_IMAGE" \
      "$XMAGE_ROLLBACK_SOURCE_IMAGE" "$XMAGE_SERVICE" catalog_ready || rollback_status=1
  fi
  return "$rollback_status"
}

deploy_sidecar_digest \
  "$XMAGE_SERVICE" "$XMAGE_IMAGE_DIGEST_REF" \
  $'PORT=8080\nXMAGE_SERVER_JAVA_OPTS=-Xms256m -Xmx2g\nXMAGE_SIDECAR_JAVA_OPTS=-Xms128m -Xmx512m\n' \
  "$XMAGE_MEMORY_LIMIT_MB"
prove_sidecar_release \
  "$XMAGE_SERVICE" "$XMAGE_IMAGE_DIGEST_REF" "$XMAGE_SERVICE" catalog_ready \
  >/dev/null
deploy_sidecar_digest \
  "$FORGE_SERVICE" "$FORGE_IMAGE_DIGEST_REF" \
  $'PORT=8080\nFORGE_JAVA_COMMAND=xvfb-run -a java -Xms128m -Xmx1536m\n' \
  "$FORGE_MEMORY_LIMIT_MB"
prove_sidecar_release \
  "$FORGE_SERVICE" "$FORGE_IMAGE_DIGEST_REF" "$FORGE_SERVICE" >/dev/null
wait_for_sidecar_health \
  "${PROJECT}_${NATIVE_SERVICE}" \
  "$NATIVE_SERVICE_DNS" \
  native_reviewed_rules_execution >/dev/null

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
backend_env="$(upsert_env "$backend_env" NATIVE_BATTLE_SIDECAR_URL "http://$NATIVE_SERVICE_DNS:8080")"
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

# shellcheck disable=SC2029
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
  --rollback-order stop-first
  --env-add 'BATTLE_ENGINE=auto'
  --env-add 'XMAGE_SIDECAR_URL=http://$XMAGE_SERVICE:8080'
  --env-add 'FORGE_SIDECAR_URL=http://$FORGE_SERVICE:8080'
  --env-add 'NATIVE_BATTLE_SIDECAR_URL=http://$NATIVE_SERVICE_DNS:8080'
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

xmage_release_proof="$(prove_sidecar_release \
  "$XMAGE_SERVICE" "$XMAGE_IMAGE_DIGEST_REF" "$XMAGE_SERVICE" catalog_ready)"
forge_release_proof="$(prove_sidecar_release \
  "$FORGE_SERVICE" "$FORGE_IMAGE_DIGEST_REF" "$FORGE_SERVICE")"
wait_for_sidecar_health \
  "${PROJECT}_${NATIVE_SERVICE}" \
  "$NATIVE_SERVICE_DNS" \
  native_reviewed_rules_execution >/dev/null
DEPLOY_COMMITTED=1

cleanup_remote_build_dir

printf '{"status":"deployed","git_sha":"%s","xmage_service":"%s","xmage_image_digest_ref":"%s","xmage_release_proof":"%s","forge_service":"%s","forge_image_digest_ref":"%s","forge_release_proof":"%s","native_service":"%s","backend_service":"%s","remote_cleanup_proof":"%s"}\n' \
  "$sha" "$XMAGE_SERVICE" "$XMAGE_IMAGE_DIGEST_REF" "$xmage_release_proof" \
  "$FORGE_SERVICE" "$FORGE_IMAGE_DIGEST_REF" "$forge_release_proof" \
  "$NATIVE_SERVICE" "$BACKEND_SERVICE" "$REMOTE_CLEANUP_PROOF"

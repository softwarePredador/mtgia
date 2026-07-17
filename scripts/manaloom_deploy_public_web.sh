#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"

# Approval must be supplied by the invoking process before any persistent
# environment or remote tooling is consulted.
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "deploy do site publico ManaLoom"
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
  MANALOOM_EASYPANEL_SSH_KEY MANALOOM_PUBLIC_WEB_IMAGE_REPO \
  MANALOOM_PUBLIC_WEB_EASYPANEL_SERVICE \
  MANALOOM_PUBLIC_WEB_SWARM_SERVICE MANALOOM_REMOTE_BUILD_ROOT \
  MANALOOM_WEB_PUBLIC_URL NEXT_PUBLIC_SITE_URL

SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
SERVICE="${MANALOOM_PUBLIC_WEB_SWARM_SERVICE:-evolution_manaloom-web-public}"
EASYPANEL_PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
EASYPANEL_SERVICE="${MANALOOM_PUBLIC_WEB_EASYPANEL_SERVICE:-manaloom-web-public}"
IMAGE_REPO="${MANALOOM_PUBLIC_WEB_IMAGE_REPO:-localhost:5000/manaloom/web-public}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
PUBLIC_BASE_URL="${MANALOOM_WEB_PUBLIC_URL:-https://evolution-manaloom-web-public.2ta7qx.easypanel.host}"
API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SITE_URL="${NEXT_PUBLIC_SITE_URL:-$PUBLIC_BASE_URL}"
REMOTE_DIR=""
HEADERS_FILE=""
DEPLOY_MUTATION_STARTED=0
DEPLOY_COMMITTED=0
SOURCE_MUTATED=0
EASYPANEL_SOURCE_MANAGED=0
PREVIOUS_SOURCE_IMAGE=""
ROLLBACK_SOURCE_IMAGE=""
PREVIOUS_SPEC_IMAGE=""
PREVIOUS_RUNNING_IMAGE=""
PREVIOUS_UPDATE_STATE=""
PREVIOUS_RELEASE_MARKER=""

trpc_post() {
  local procedure="$1"
  local payload="$2"
  curl -fsS \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$payload" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$procedure"
}

public_web_release_marker() {
  local root_html asset_path marker_hash health_state
  root_html="$(curl -fsS --max-time 20 "$PUBLIC_BASE_URL/")"
  asset_path=""
  if [[ "$root_html" =~ (/_next/static/chunks/webpack-[^\"]+\.js) ]]; then
    asset_path="${BASH_REMATCH[1]}"
  fi
  if [[ -n "$asset_path" ]]; then
    marker_hash="$(
      curl -fsS --max-time 20 "$PUBLIC_BASE_URL$asset_path" |
        shasum -a 256 | awk '{print $1}'
    )"
  else
    asset_path="root"
    marker_hash="$(printf '%s' "$root_html" | shasum -a 256 | awk '{print $1}')"
  fi
  health_state="legacy"
  if [[ "$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' \
        "$PUBLIC_BASE_URL/healthz" 2>/dev/null || true)" == "200" ]]; then
    health_state="healthz"
  fi
  printf '%s|%s|%s' "$health_state" "$asset_path" "$marker_hash"
}

rollback_public_web() {
  local source_status=1 runtime_status=1 configured_status=1 health_status=1
  local services_json configured_image status

  echo "deploy web-public falhou; restaurando origem e digest anteriores" >&2
  if [[ "$EASYPANEL_SOURCE_MANAGED" == "1" &&
        "$SOURCE_MUTATED" == "1" && -n "$ROLLBACK_SOURCE_IMAGE" ]]; then
    trpc_post services.app.updateSourceImage "$(jq -cn \
      --arg project "$EASYPANEL_PROJECT" \
      --arg service "$EASYPANEL_SERVICE" \
      --arg image "$ROLLBACK_SOURCE_IMAGE" \
      '{projectName:$project,serviceName:$service,image:$image}')" \
      >/dev/null && source_status=0
  else
    source_status=0
  fi

  if [[ -n "$PREVIOUS_SPEC_IMAGE" ]]; then
    if ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
docker service update \\
  --update-order stop-first \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-order stop-first \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --detach=true \\
  --image '$PREVIOUS_SPEC_IMAGE' \\
  '$SERVICE' >/dev/null
for attempt in \$(seq 1 60); do
  replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
  spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
  running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
  update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
  if [ \"\$replicas\" = '1/1' ] && [ \"\$spec\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$running\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     { [ -z \"\$update\" ] || [ \"\$update\" = completed ] || [ \"\$update\" = rollback_completed ]; }; then
    exit 0
  fi
  case \"\$update\" in paused|rollback_paused) break ;; esac
  sleep 2
done
docker service ps '$SERVICE' --no-trunc >&2
exit 1
"; then
      runtime_status=0
    fi
  fi

  if [[ "$EASYPANEL_SOURCE_MANAGED" == "1" &&
        "$SOURCE_MUTATED" == "1" ]]; then
    if services_json="$(trpc_post projects.listProjectsAndServices null)" &&
       configured_image="$(jq -er \
         --arg project "$EASYPANEL_PROJECT" \
         --arg service "$EASYPANEL_SERVICE" \
         '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
         <<<"$services_json")" &&
       [[ "$configured_image" == "$ROLLBACK_SOURCE_IMAGE" ]]; then
      configured_status=0
    fi
  else
    configured_status=0
  fi

  for _ in $(seq 1 30); do
    status="$(public_web_release_marker 2>/dev/null || true)"
    if [[ "$status" == "$PREVIOUS_RELEASE_MARKER" ]]; then
      health_status=0
      break
    fi
    sleep 2
  done

  if [[ "$source_status" == "0" && "$runtime_status" == "0" &&
        "$configured_status" == "0" && "$health_status" == "0" ]]; then
    echo "rollback web-public comprovado: origem, digest e marcador externo restaurados" >&2
    return 0
  fi
  echo "CRITICAL: rollback web-public nao foi comprovado (source=$source_status runtime=$runtime_status configured=$configured_status health=$health_status)" >&2
  return 1
}

cleanup() {
  local status="${1:-$?}"
  trap - EXIT
  if [[ "$status" != "0" && "$DEPLOY_MUTATION_STARTED" == "1" &&
        "$DEPLOY_COMMITTED" != "1" ]]; then
    rollback_public_web || status=1
  fi
  if [[ -n "$HEADERS_FILE" ]]; then
    rm -f "$HEADERS_FILE"
  fi
  if [[ "$LIVE_MUTATION_APPROVED" == "1" && -n "$REMOTE_DIR" &&
        -n "${MANALOOM_SECURE_SSH_KNOWN_HOSTS:-}" ]]; then
    ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
      "rm -rf '$REMOTE_DIR'" >/dev/null 2>&1 || true
  fi
  if declare -F cleanup_manaloom_secure_ssh >/dev/null 2>&1; then
    cleanup_manaloom_secure_ssh
  fi
  exit "$status"
}
trap 'cleanup $?' EXIT

for tool in curl git jq ssh tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  fi
done

# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
validate_manaloom_release_api_base_url "$API_BASE_URL"
validate_manaloom_exact_coordinate public_base_url "$PUBLIC_BASE_URL" \
  "https://$MANALOOM_PRODUCTION_PUBLIC_HOST"
validate_manaloom_exact_coordinate site_url "$SITE_URL" \
  "https://$MANALOOM_PRODUCTION_PUBLIC_HOST"
validate_manaloom_exact_coordinate public_web_service "$SERVICE" \
  evolution_manaloom-web-public
validate_manaloom_exact_coordinate project "$EASYPANEL_PROJECT" \
  "$MANALOOM_PRODUCTION_EASYPANEL_PROJECT"
validate_manaloom_exact_coordinate public_web_easypanel_service \
  "$EASYPANEL_SERVICE" manaloom-web-public
validate_manaloom_exact_coordinate public_web_image_repo "$IMAGE_REPO" \
  localhost:5000/manaloom/web-public
validate_manaloom_exact_coordinate remote_build_root "$REMOTE_BUILD_ROOT" \
  "$MANALOOM_PRODUCTION_REMOTE_BUILD_ROOT"
validate_manaloom_easypanel_base_url "${EASYPANEL_BASE_URL:-}"
initialize_manaloom_secure_ssh "$SSH_HOST"

for key in SSH_HOST SSH_KEY EASYPANEL_BASE_URL EASYPANEL_API_TOKEN; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done

IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="${MANALOOM_RELEASE_SOURCE_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}" \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
SHA="$(jq -r '.git_sha' <<<"$IDENTITY_JSON")"
SHORT_SHA="$(jq -r '.short_sha' <<<"$IDENTITY_JSON")"
IMAGE="$IMAGE_REPO:$SHORT_SHA"
REMOTE_DIR="$REMOTE_BUILD_ROOT/web-public-$SHORT_SHA"
DEPLOY_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

ssh -o BatchMode=yes -i "$SSH_KEY" \
  "$SSH_HOST" "docker service inspect '$SERVICE' >/dev/null"

SERVICES_BEFORE="$(trpc_post projects.listProjectsAndServices null)"
easypanel_service_count="$(jq -er \
  --arg project "$EASYPANEL_PROJECT" \
  --arg service "$EASYPANEL_SERVICE" \
  '[.json.services[] | select(.projectName == $project and .name == $service and .type == "app")] | length' \
  <<<"$SERVICES_BEFORE")"
case "$easypanel_service_count" in
  0)
    EASYPANEL_SOURCE_MANAGED=0
    echo "web-public usa contrato Swarm direto; origem EasyPanel nao se aplica" >&2
    ;;
  1)
    EASYPANEL_SOURCE_MANAGED=1
    PREVIOUS_SOURCE_IMAGE="$(jq -er \
      --arg project "$EASYPANEL_PROJECT" \
      --arg service "$EASYPANEL_SERVICE" \
      '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
      <<<"$SERVICES_BEFORE")"
    ;;
  *)
    echo "deploy recusado: inventario EasyPanel duplicou web-public" >&2
    exit 2
    ;;
esac
PREVIOUS_RUNTIME_STATE="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$update\"
")"
IFS='|' read -r previous_replicas PREVIOUS_SPEC_IMAGE PREVIOUS_RUNNING_IMAGE \
  PREVIOUS_UPDATE_STATE \
  <<<"$PREVIOUS_RUNTIME_STATE"
if [[ "$previous_replicas" != "1/1" ||
      "$PREVIOUS_RUNNING_IMAGE" != "$PREVIOUS_SPEC_IMAGE" ||
      ( -n "$PREVIOUS_UPDATE_STATE" &&
        "$PREVIOUS_UPDATE_STATE" != "completed" &&
        "$PREVIOUS_UPDATE_STATE" != "rollback_completed" ) ||
      ! "$PREVIOUS_SPEC_IMAGE" =~ @sha256:[0-9a-f]{64}$ ]]; then
  echo "deploy recusado: baseline web-public nao e rollback-safe: $PREVIOUS_RUNTIME_STATE" >&2
  exit 2
fi
ROLLBACK_SOURCE_IMAGE="$PREVIOUS_SPEC_IMAGE"
if [[ "$EASYPANEL_SOURCE_MANAGED" == "1" &&
      "$PREVIOUS_SOURCE_IMAGE" != "$ROLLBACK_SOURCE_IMAGE" ]]; then
  echo "origem EasyPanel anterior sera normalizada para o digest imutavel da spec durante eventual rollback" >&2
fi
PREVIOUS_RELEASE_MARKER="$(public_web_release_marker)"

git -C "$ROOT_DIR" archive "$SHA" web-public | \
  ssh -o BatchMode=yes -i "$SSH_KEY" \
    "$SSH_HOST" "rm -rf '$REMOTE_DIR' && mkdir -p '$REMOTE_DIR' && tar -x -C '$REMOTE_DIR'"

api_arg="$(printf '%q' "$API_BASE_URL")"
site_arg="$(printf '%q' "$SITE_URL")"
# shellcheck disable=SC2087
IMAGE_DIGEST_OUTPUT="$(
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
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
image_digest_ref="\$(
  docker image inspect '$IMAGE' \
    --format '{{range .RepoDigests}}{{println .}}{{end}}' |
    awk -v expected_repo='$IMAGE_REPO' \
      'index(\$0, expected_repo "@sha256:") == 1 {print; exit}'
)"
image_digest="\${image_digest_ref#'$IMAGE_REPO@sha256:'}"
if [[ "\$image_digest_ref" != '$IMAGE_REPO@sha256:'"\$image_digest" ||
      ! "\$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo 'push remoto nao produziu RepoDigest SHA-256 valido para web-public' >&2
  exit 2
fi
printf '%s\n' "\$image_digest_ref"
REMOTE
)"
IMAGE_DIGEST_REF="$(
  extract_manaloom_repo_digest_ref "$IMAGE_REPO" <<<"$IMAGE_DIGEST_OUTPUT"
)"
unset IMAGE_DIGEST_OUTPUT
image_digest="${IMAGE_DIGEST_REF#"$IMAGE_REPO@sha256:"}"
if [[ "$IMAGE_DIGEST_REF" != "$IMAGE_REPO@sha256:$image_digest" ||
      ! "$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "push remoto retornou RepoDigest invalido para web-public: $IMAGE_DIGEST_REF" >&2
  exit 2
fi
readonly IMAGE_DIGEST_REF

DEPLOY_MUTATION_STARTED=1
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
docker service update \\
  --update-order stop-first \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-order stop-first \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --detach=true \\
  --image '$IMAGE_DIGEST_REF' \\
  --env-add GIT_SHA='$SHA' \\
  --env-add DEPLOY_TIMESTAMP='$DEPLOY_TIMESTAMP' \\
  '$SERVICE'
"

runtime_state=""
for _ in $(seq 1 60); do
  runtime_state="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$update\"
")"
  IFS='|' read -r replicas spec_image running_image update_state <<<"$runtime_state"
  if [[ "$replicas" == "1/1" && "$spec_image" == "$IMAGE_DIGEST_REF" &&
        "$running_image" == "$IMAGE_DIGEST_REF" &&
        ( -z "$update_state" || "$update_state" == "completed" ) ]]; then
    break
  fi
  case "$update_state" in
    paused|rollback_started|rollback_paused) break ;;
  esac
  sleep 2
done

IFS='|' read -r replicas spec_image running_image update_state <<<"$runtime_state"
if [[ "$replicas" != "1/1" || "$spec_image" != "$IMAGE_DIGEST_REF" ||
      "$running_image" != "$IMAGE_DIGEST_REF" ||
      ( -n "$update_state" && "$update_state" != "completed" ) ]]; then
  echo "servico publico nao convergiu: $runtime_state" >&2
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "docker service ps '$SERVICE' --no-trunc" >&2
  exit 1
fi

if [[ "$EASYPANEL_SOURCE_MANAGED" == "1" ]]; then
  SOURCE_MUTATED=1
  trpc_post services.app.updateSourceImage "$(jq -cn \
    --arg project "$EASYPANEL_PROJECT" \
    --arg service "$EASYPANEL_SERVICE" \
    --arg image "$IMAGE_DIGEST_REF" \
    '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null
  SERVICES_AFTER="$(trpc_post projects.listProjectsAndServices null)"
  CONFIGURED_IMAGE="$(jq -er \
    --arg project "$EASYPANEL_PROJECT" \
    --arg service "$EASYPANEL_SERVICE" \
    '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
    <<<"$SERVICES_AFTER")"
  if [[ "$CONFIGURED_IMAGE" != "$IMAGE_DIGEST_REF" ]]; then
    echo "web-public convergiu sem o digest exato na origem EasyPanel: $CONFIGURED_IMAGE" >&2
    exit 2
  fi
fi

HEALTH_BODY="$(curl -fsS --max-time 20 "$PUBLIC_BASE_URL/healthz")"
[[ "$HEALTH_BODY" == "ok" ]]
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

DEPLOY_COMMITTED=1

printf '{"status":"deployed","service":"%s","image":"%s","image_digest_ref":"%s","git_sha":"%s","public_url":"%s","source_management":"%s","healthz":"ok"}\n' \
  "$SERVICE" "$IMAGE" "$IMAGE_DIGEST_REF" "$SHA" "$PUBLIC_BASE_URL" \
  "$([[ "$EASYPANEL_SOURCE_MANAGED" == "1" ]] && printf easypanel || printf swarm)"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "deploy da imagem manaloom-ops"
require_postgres_write_approval "deploy da imagem manaloom-ops com runtime PostgreSQL"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool python3
require_tool jq
require_tool shasum

if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
# shellcheck source=scripts/lib/manaloom_release_capabilities_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh"
load_manaloom_env_keys "$ENV_FILE" \
  DB_HOST DB_NAME DB_PORT \
  EASYPANEL_SERVER_IP EASYPANEL_SSH_KEY EASYPANEL_SSH_USER \
  MANALOOM_EASYPANEL_SSH_HOST MANALOOM_EASYPANEL_SSH_KEY \
  MANALOOM_EXPECTED_DB_HOST MANALOOM_EXPECTED_DB_NAME \
  MANALOOM_EXPECTED_DB_PORT MANALOOM_OPS_IMAGE_REPO \
  MANALOOM_OPS_SERVICE MANALOOM_REMOTE_BUILD_ROOT

SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
SERVICE="${MANALOOM_OPS_SERVICE:-evolution_manaloom-ops}"
IMAGE_REPO="${MANALOOM_OPS_IMAGE_REPO:-localhost:5000/manaloom/ops}"
REMOTE_BUILD_ROOT="${MANALOOM_REMOTE_BUILD_ROOT:-/opt/manaloom/deploy}"
EXPECTED_DB_HOST="${MANALOOM_EXPECTED_DB_HOST:-evolution_manaloom-postgres}"
EXPECTED_DB_PORT="${MANALOOM_EXPECTED_DB_PORT:-5432}"
EXPECTED_DB_NAME="${MANALOOM_EXPECTED_DB_NAME:-halder}"

require_tool git
require_tool ssh

require_clean_worktree() {
  if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
    echo "deploy recusado: worktree deve estar limpo para o gate e o git archive usarem o mesmo SHA" >&2
    exit 2
  fi
}

for key in SSH_HOST SSH_KEY DB_HOST DB_PORT DB_NAME; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done

SSH_KEY="$(resolve_manaloom_path "$ROOT_DIR" "$SSH_KEY")"
if [[ ! -f "$SSH_KEY" ]]; then
  echo "chave SSH ausente: $SSH_KEY" >&2
  exit 2
fi

validate_manaloom_exact_coordinate \
  "destino SSH" "$SSH_HOST" "${MANALOOM_EXPECTED_SSH_TARGET:-}"
validate_manaloom_exact_coordinate \
  "servico manaloom-ops" "$SERVICE" "evolution_manaloom-ops"
validate_manaloom_exact_coordinate \
  "repositorio da imagem manaloom-ops" "$IMAGE_REPO" "localhost:5000/manaloom/ops"
validate_manaloom_exact_coordinate \
  "raiz remota de build" "$REMOTE_BUILD_ROOT" "$MANALOOM_PRODUCTION_REMOTE_BUILD_ROOT"
validate_manaloom_exact_coordinate \
  "host PostgreSQL esperado" "$EXPECTED_DB_HOST" "evolution_manaloom-postgres"
validate_manaloom_exact_coordinate \
  "porta PostgreSQL esperada" "$EXPECTED_DB_PORT" "5432"
validate_manaloom_exact_coordinate \
  "database PostgreSQL esperada" "$EXPECTED_DB_NAME" "halder"

if [[ "$DB_HOST" != "$EXPECTED_DB_HOST" ||
      "$DB_PORT" != "$EXPECTED_DB_PORT" ||
      "$DB_NAME" != "$EXPECTED_DB_NAME" ]]; then
  echo "server/.env nao aponta para o PostgreSQL interno esperado" >&2
  exit 2
fi

REMOTE_DIR_CLEANUP_REQUIRED=0
REMOTE_CLEANUP_PROOF=""
DEPLOY_MUTATION_STARTED=0
DEPLOY_COMMITTED=0
PREVIOUS_SPEC_IMAGE=""
PREVIOUS_RUNNING_IMAGE=""
PREVIOUS_UPDATE_STATE=""
PREVIOUS_HEALTH_CONTRACT=""

cleanup_remote_build_dir() {
  local proof expected
  if [[ "$REMOTE_DIR_CLEANUP_REQUIRED" != "1" || -z "${remote_dir:-}" ]]; then
    return 0
  fi
  expected="removed:$remote_dir"
  if ! proof="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "rm -rf '$remote_dir'; test ! -e '$remote_dir'; printf '%s' '$expected'")"; then
    echo "cleanup remoto do build manaloom-ops falhou" >&2
    return 1
  fi
  if [[ "$proof" != "$expected" ]]; then
    echo "cleanup remoto do build manaloom-ops nao produziu prova exata" >&2
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
     declare -F rollback_ops_deploy >/dev/null 2>&1; then
    rollback_ops_deploy || rollback_status=$?
  fi
  cleanup_remote_build_dir || cleanup_status=$?
  cleanup_manaloom_secure_ssh
  if (( rollback_status != 0 || cleanup_status != 0 )); then
    exit 1
  fi
  exit "$original_status"
}

rollback_ops_deploy() {
  local rollback_result

  if [[ -z "$PREVIOUS_SPEC_IMAGE" ]]; then
    echo "CRITICAL: rollback manaloom-ops sem digest anterior capturado" >&2
    return 1
  fi

  echo "deploy manaloom-ops falhou; restaurando digest anterior" >&2
  if ! rollback_result="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
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
  container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
  health=''
  if [ -n \"\$container\" ]; then
    health=\$(docker exec \"\$container\" python3 -c \
      \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5)); print(d['status']+'|'+d['engine_contract']+'|'+str(d.get('release_capabilities',{}).get('configuration_status','legacy')))\" \
      2>/dev/null || true)
  fi
  if [ \"\$replicas\" = '1/1' ] && [ \"\$spec\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$running\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$health\" = '$PREVIOUS_HEALTH_CONTRACT' ] && \\
     { [ -z \"\$update\" ] || [ \"\$update\" = completed ] || [ \"\$update\" = rollback_completed ]; }; then
    printf '%s|%s|%s|health=%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$health\"
    exit 0
  fi
  case \"\$update\" in paused|rollback_paused) break ;; esac
  sleep 2
done
docker service inspect '$SERVICE' --format 'image={{.Spec.TaskTemplate.ContainerSpec.Image}} update={{if .UpdateStatus}}{{.UpdateStatus.State}} {{.UpdateStatus.Message}}{{end}}' >&2
docker service ps '$SERVICE' --no-trunc >&2
exit 1
")"; then
    echo "CRITICAL: rollback manaloom-ops nao comprovou spec, tarefa e health no digest anterior" >&2
    return 1
  fi
  echo "rollback manaloom-ops comprovado: $rollback_result" >&2
}

initialize_manaloom_secure_ssh "$SSH_HOST"
trap cleanup_on_exit EXIT

cd "$ROOT_DIR"
require_clean_worktree
"$ROOT_DIR/scripts/manaloom_battle_product_gate.sh"
require_clean_worktree
git fetch origin master --quiet
sha="$(git rev-parse HEAD)"
short_sha="$(git rev-parse --short=12 HEAD)"
remote_dir="$REMOTE_BUILD_ROOT/manaloom-ops-$short_sha"
deploy_timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ "$sha" != "$(git rev-parse origin/master 2>/dev/null || true)" ]]; then
  echo "HEAD must match origin/master before ops deploy" >&2
  exit 2
fi

# The candidate image and the runtime health must carry the exact policy blob
# committed in this SHA. The current Free Beta contract accepts only the
# canonical 28-key all-OFF matrix; a dirty or permissive working-tree file
# cannot enable an ops job.
manaloom_load_release_capabilities_from_git "$ROOT_DIR" "$sha"
readonly RELEASE_CAPABILITIES_DIGEST_SHA256="$MANALOOM_RELEASE_CAPABILITIES_DIGEST_SHA256"

runtime_contract="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
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

previous_runtime_state="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
replicas=\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -1)
spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
update=\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$update\"
")"
IFS='|' read -r previous_replicas PREVIOUS_SPEC_IMAGE PREVIOUS_RUNNING_IMAGE \
  PREVIOUS_UPDATE_STATE <<<"$previous_runtime_state"
previous_digest="${PREVIOUS_SPEC_IMAGE#"$IMAGE_REPO@sha256:"}"
if [[ "$previous_replicas" != "1/1" ||
      "$PREVIOUS_RUNNING_IMAGE" != "$PREVIOUS_SPEC_IMAGE" ||
      ( -n "$PREVIOUS_UPDATE_STATE" &&
        "$PREVIOUS_UPDATE_STATE" != "completed" &&
        "$PREVIOUS_UPDATE_STATE" != "rollback_completed" ) ||
      "$PREVIOUS_SPEC_IMAGE" != "$IMAGE_REPO@sha256:$previous_digest" ||
      ! "$previous_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "deploy recusado: baseline manaloom-ops nao e rollback-safe: $previous_runtime_state" >&2
  exit 2
fi
previous_health_proof="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker exec \"\$container\" python3 -c \
  \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5)); print(d['status']+'|'+d['engine_contract']+'|'+str(d.get('release_capabilities',{}).get('configuration_status','legacy')))\"
")"
if [[ "$previous_health_proof" != "ok|native_reviewed_rules_execution|legacy" &&
      "$previous_health_proof" != "ok|disabled_by_release_capability|valid" ]]; then
  echo "deploy recusado: baseline manaloom-ops sem health rollback-safe: $previous_health_proof" >&2
  exit 2
fi
PREVIOUS_HEALTH_CONTRACT="$previous_health_proof"

REMOTE_DIR_CLEANUP_REQUIRED=1
git archive HEAD server docs/hermes-analysis/manaloom-knowledge scripts/lib tools/manaloom_lints |
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

# Build/push uses mutable publication tags only long enough to obtain the
# registry's immutable RepoDigest. No tag is promoted to the Swarm service.
# shellcheck disable=SC2087
IMAGE_DIGEST_OUTPUT="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
cd '$remote_dir'
docker build \
  -f server/Dockerfile.manaloom-ops \
  -t '$IMAGE_REPO:$short_sha' \
  -t '$IMAGE_REPO:latest' \
  . >&2
docker push '$IMAGE_REPO:$short_sha' >&2
docker push '$IMAGE_REPO:latest' >&2
for attempt in \$(seq 1 15); do
  image_digest_ref="\$(
    docker image inspect '$IMAGE_REPO:$short_sha' \
      --format '{{range .RepoDigests}}{{println .}}{{end}}' |
      awk -v expected_repo='$IMAGE_REPO' \
        'index(\$0, expected_repo "@sha256:") == 1 {print; exit}'
  )"
  image_digest="\${image_digest_ref#'$IMAGE_REPO@sha256:'}"
  if [[ "\$image_digest_ref" == '$IMAGE_REPO@sha256:'"\$image_digest" &&
        "\$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
    printf '%s\n' "\$image_digest_ref"
    exit 0
  fi
  sleep 1
done
echo 'push remoto nao produziu RepoDigest SHA-256 valido para manaloom-ops' >&2
exit 2
REMOTE
)"
IMAGE_DIGEST_REF="$(
  printf '%s\n' "$IMAGE_DIGEST_OUTPUT" |
    extract_manaloom_repo_digest_ref "$IMAGE_REPO"
)"
unset IMAGE_DIGEST_OUTPUT
image_digest="${IMAGE_DIGEST_REF#"$IMAGE_REPO@sha256:"}"
if [[ "$IMAGE_DIGEST_REF" != "$IMAGE_REPO@sha256:$image_digest" ||
      ! "$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "push remoto retornou RepoDigest invalido para manaloom-ops: $IMAGE_DIGEST_REF" >&2
  exit 2
fi
readonly IMAGE_DIGEST_REF

# Local deploy values are embedded; remote values are escaped. From this point
# the full repo@sha256 value is the only accepted release identity.
DEPLOY_MUTATION_STARTED=1
# shellcheck disable=SC2087
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
set -euo pipefail
docker service update \
  --update-order stop-first \
  --update-failure-action rollback \
  --update-monitor 30s \
  --rollback-order stop-first \
  --rollback-failure-action pause \
  --rollback-monitor 30s \
  --detach=true \
  --image '$IMAGE_DIGEST_REF' \
  --env-add GIT_SHA='$sha' \
  --env-add DEPLOY_TIMESTAMP='$deploy_timestamp' \
  --env-add MANALOOM_RELEASE_CAPABILITIES_FILE=/app/server/config/release_capabilities.json \
  --env-add MANALOOM_BOOT_PULL_PENDING_EVENTS=0 \
  --env-add MANALOOM_RUN_PREFLIGHT_ON_BOOT=0 \
  --env-add MTGIA_SYNC_GIT_PULL=0 \
  --env-add HERMES_AUTO_SYNC_APPLY=0 \
  --env-add HERMES_AUTO_PROMOTE_APPLY=0 \
  --env-add MANALOOM_IMPORT_APPLY=0 \
  --env-add MANALOOM_ENABLE_LEARNING_WRITES=0 \
  --env-add MANALOOM_ENABLE_LEARNED_DECK_WRITES=0 \
  --env-add MANALOOM_LEARNING_WRITES=0 \
  --env-add MANALOOM_BATTLE_RULES_APPLY_PG=0 \
  --env-add MANALOOM_SYNC_CARD_LEGALITIES_APPLY=0 \
  --env-add MANALOOM_NATIVE_BATTLE_HTTP_ENABLED=0 \
  --env-add MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT=0 \
  --env-add MANALOOM_NATIVE_BATTLE_HOST=0.0.0.0 \
  --env-add MANALOOM_NATIVE_BATTLE_PORT=8080 \
  --env-add MANALOOM_LOREHOLD_CANONICAL_OVERRIDE=0 \
  '$SERVICE'

for attempt in \$(seq 1 60); do
  replicas="\$(docker service ls --filter name='$SERVICE' --format '{{.Replicas}}' | head -n 1)"
  spec_image="\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')"
  running_image="\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -n 1)"
  update_state="\$(docker service inspect '$SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')"
  if [[ "\$replicas" == "1/1" && "\$spec_image" == '$IMAGE_DIGEST_REF' &&
        "\$running_image" == '$IMAGE_DIGEST_REF' &&
        ( -z "\$update_state" || "\$update_state" == completed ) ]]; then
    container="\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)"
    if docker exec "\$container" python3 -c \
        "import hashlib,json,urllib.request; policy_path='/app/server/config/release_capabilities.json'; raw=open(policy_path,'rb').read(); assert hashlib.sha256(raw).hexdigest()=='$RELEASE_CAPABILITIES_DIGEST_SHA256'; policy=json.loads(raw); assert len(policy['capabilities'])==29; assert all(row['release_capability']=='off' and row['allowed'] is False for row in policy['capabilities'].values()); data=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5)); assert data['status']=='ok'; assert data['engine_contract']=='disabled_by_release_capability'; assert data['git_sha']=='$sha'; assert data['operational_mode']=='safe_housekeeping_only'; assert data['enabled_jobs']==['hermes_cron_governor_report']; caps=data['release_capabilities']; assert caps['configuration_status']=='valid'; assert caps['policy_digest_sha256']=='$RELEASE_CAPABILITIES_DIGEST_SHA256'; assert caps['battle_batch']=='off'; assert caps['learning_writes']=='off'" \
        >/dev/null 2>&1 && \
      docker exec "\$container" python3 -c \
        "import json; jobs=json.load(open('/data/manaloom-ops/cron/jobs.json')); assert [row['name'] for row in jobs]==['hermes_cron_governor_report']; assert all(row['enabled'] is True for row in jobs)" \
        >/dev/null 2>&1; then
      docker exec "\$container" python3 -c \
        "import json, urllib.request; data=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=5)); print(json.dumps(data, sort_keys=True))"
      docker service ls --filter name='$SERVICE' --format '{{.Name}} {{.Image}} {{.Replicas}}'
      exit 0
    fi
  fi
  case "\$update_state" in
    paused|rollback_started|rollback_paused) break ;;
  esac
  sleep 2
done

docker service inspect '$SERVICE' --format 'image={{.Spec.TaskTemplate.ContainerSpec.Image}} update={{if .UpdateStatus}}{{.UpdateStatus.State}} {{.UpdateStatus.Message}}{{end}}'
docker service ps '$SERVICE' --no-trunc
exit 1
REMOTE

deployed_contract="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
docker inspect \"\$container\" --format '{{range .Config.Env}}{{println .}}{{end}}' |
  awk -F= '
    /^GIT_SHA=/{sha=\$2}
    /^DB_HOST=/{host=\$2}
    /^DB_PORT=/{port=\$2}
    /^DB_NAME=/{name=\$2}
    /^MANALOOM_RELEASE_CAPABILITIES_FILE=/{policy=\$2}
    /^MANALOOM_NATIVE_BATTLE_HTTP_ENABLED=/{http=\$2}
    /^MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT=/{sync=\$2}
    /^MANALOOM_BOOT_PULL_PENDING_EVENTS=/{pull=\$2}
    /^MANALOOM_RUN_PREFLIGHT_ON_BOOT=/{preflight=\$2}
    /^HERMES_AUTO_SYNC_APPLY=/{autosync=\$2}
    /^HERMES_AUTO_PROMOTE_APPLY=/{promote=\$2}
    /^MANALOOM_IMPORT_APPLY=/{import_apply=\$2}
    /^MANALOOM_ENABLE_LEARNING_WRITES=/{learning_enable=\$2}
    /^MANALOOM_ENABLE_LEARNED_DECK_WRITES=/{learned_enable=\$2}
    /^MANALOOM_LEARNING_WRITES=/{learning=\$2}
    /^MANALOOM_BATTLE_RULES_APPLY_PG=/{battle_pg=\$2}
    /^MANALOOM_SYNC_CARD_LEGALITIES_APPLY=/{legalities=\$2}
    /^MTGIA_SYNC_GIT_PULL=/{git_pull=\$2}
    /^MANALOOM_LOREHOLD_CANONICAL_OVERRIDE=/{override=\$2}
    END{print sha \"|\" host \"|\" port \"|\" name \"|\" policy \"|\" http \"|\" sync \"|\" pull \"|\" preflight \"|\" autosync \"|\" promote \"|\" import_apply \"|\" learning_enable \"|\" learned_enable \"|\" learning \"|\" battle_pg \"|\" legalities \"|\" git_pull \"|\" override}'
")"
if [[ "$deployed_contract" != "$sha|$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME|/app/server/config/release_capabilities.json|0|0|0|0|0|0|0|0|0|0|0|0|0|0" ]]; then
  echo "deploy convergiu com SHA ou alvo PostgreSQL divergente" >&2
  exit 2
fi

release_proof="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
health=\$(docker exec \"\$container\" python3 -c \
  \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5)); c=d['release_capabilities']; print(d['status']+'|'+d['engine_contract']+'|'+d['git_sha']+'|'+c['configuration_status']+'|'+c['policy_digest_sha256']+'|'+c['battle_batch']+'|'+c['learning_writes'])\")
spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
printf '%s|%s|%s' \"\$spec\" \"\$running\" \"\$health\"
")"
if [[ "$release_proof" != "$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|ok|disabled_by_release_capability|$sha|valid|$RELEASE_CAPABILITIES_DIGEST_SHA256|off|off" ]]; then
  echo "deploy manaloom-ops sem prova exata de spec=tarefa=digest e health: $release_proof" >&2
  exit 2
fi

DEPLOY_COMMITTED=1

cleanup_remote_build_dir

printf '{"status":"deployed","service":"%s","image_digest_ref":"%s","git_sha":"%s","release_capabilities_digest_sha256":"%s","release_proof":"%s","remote_cleanup_proof":"%s"}\n' \
  "$SERVICE" "$IMAGE_DIGEST_REF" "$sha" \
  "$RELEASE_CAPABILITIES_DIGEST_SHA256" "$release_proof" \
  "$REMOTE_CLEANUP_PROOF"

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

if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
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
  health=0
  if [ -n \"\$container\" ] && docker exec \"\$container\" python3 -c \
    \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5)); assert d['status']=='ok'; assert d['engine_contract']=='native_reviewed_rules_execution'\" \
    >/dev/null 2>&1; then
    health=1
  fi
  if [ \"\$replicas\" = '1/1' ] && [ \"\$spec\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$running\" = '$PREVIOUS_SPEC_IMAGE' ] && [ \"\$health\" = 1 ] && \\
     { [ -z \"\$update\" ] || [ \"\$update\" = completed ] || [ \"\$update\" = rollback_completed ]; }; then
    printf '%s|%s|%s|health=ok' \"\$replicas\" \"\$spec\" \"\$running\"
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
  \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5)); print(d['status']+'|'+d['engine_contract'])\"
")"
if [[ "$previous_health_proof" != "ok|native_reviewed_rules_execution" ]]; then
  echo "deploy recusado: baseline manaloom-ops sem health rollback-safe: $previous_health_proof" >&2
  exit 2
fi

REMOTE_DIR_CLEANUP_REQUIRED=1
git archive HEAD server docs/hermes-analysis/manaloom-knowledge scripts/lib tools/manaloom_lints |
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -x -C '$remote_dir'"

# Build/push uses mutable publication tags only long enough to obtain the
# registry's immutable RepoDigest. No tag is promoted to the Swarm service.
# shellcheck disable=SC2087
IMAGE_DIGEST_REF="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE
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
  --env-add MANALOOM_NATIVE_BATTLE_HTTP_ENABLED=1 \
  --env-add MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT=1 \
  --env-add MANALOOM_NATIVE_BATTLE_HOST=0.0.0.0 \
  --env-add MANALOOM_NATIVE_BATTLE_PORT=8080 \
  --env-add MANALOOM_CANONICAL_PG_DECK_ID=8938b746-1a9e-46ce-b0d9-c2ec932ddddd \
  --env-add MANALOOM_TARGET_PG_DECK_ID=8938b746-1a9e-46ce-b0d9-c2ec932ddddd \
  --env-add MANALOOM_LOREHOLD_CANONICAL_OVERRIDE=0 \
  --env-add MANALOOM_BATTLE_GATE_SUMMARY=/data/manaloom-ops/artifacts/battle-strategy-audit/latest/summary.json \
  --env-add MANALOOM_BATTLE_STRATEGY_BASE_DIR=/data/manaloom-ops \
  --env-add MANALOOM_BATTLE_STRATEGY_ARTIFACT_ROOT=/data/manaloom-ops/artifacts/battle-strategy-audit \
  --env-add 'MANALOOM_BATTLE_STRATEGY_AUDIT_CRON=5 0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23 * * *' \
  --env-add MANALOOM_BATTLE_STRATEGY_SEEDS=16 \
  --env-add 'MANALOOM_BATTLE_STRATEGY_NIGHTLY_CRON=5 6 * * *' \
  --env-add MANALOOM_BATTLE_STRATEGY_NIGHTLY_SEEDS=64 \
  --env-add MANALOOM_CANONICAL_KNOWN_CARDS_JSON=/data/manaloom-ops/known_cards_canonical_snapshot.runtime.json \
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
    if docker exec "\$container" test -s \
        /data/manaloom-ops/known_cards_canonical_snapshot.runtime.json && \
      docker exec "\$container" python3 -c \
        "import json, urllib.request; data=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=5)); assert data['status']=='ok'; assert data['engine_contract']=='native_reviewed_rules_execution'; assert data['git_sha']=='$sha'; assert data['verified_rule_count']>0" \
        >/dev/null 2>&1; then
      docker exec "\$container" grep -Fq \
        "oracle_hash = COALESCE(NULLIF(EXCLUDED.oracle_hash, ''), card_battle_rules.oracle_hash)" \
        /app/docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py
      docker exec "\$container" grep -Fq \
        "def backfill_trusted_oracle_hashes" \
        /app/docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py
      docker exec "\$container" test -x /app/server/bin/manaloom_battle_strategy_audit.sh
      docker exec "\$container" test -r /app/scripts/lib/manaloom_mutation_guard.sh
      docker exec "\$container" /app/server/bin/manaloom_battle_strategy_audit.sh \
        --dry-run --seeds 1 >/dev/null
      docker exec "\$container" python3 -c \
        "import json; jobs=json.load(open('/data/manaloom-ops/cron/jobs.json')); names={row['name'] for row in jobs}; assert {'manaloom_battle_strategy_audit','manaloom_battle_strategy_nightly'} <= names"
      docker exec "\$container" mkdir -p \
        /data/manaloom-ops/artifacts/target-deck-identity
      docker exec "\$container" python3 \
        /app/docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py \
        --sqlite-db /data/manaloom-ops/knowledge.db \
        --pg-deck-id 8938b746-1a9e-46ce-b0d9-c2ec932ddddd \
        --protected-pg-deck-id 8938b746-1a9e-46ce-b0d9-c2ec932ddddd \
        --target-deck-id 6 \
        --apply \
        --report /data/manaloom-ops/artifacts/target-deck-identity/deploy_sync_$short_sha.json \
        >/dev/null
      docker exec "\$container" python3 \
        /app/docs/hermes-analysis/manaloom-knowledge/scripts/battle_target_deck_identity_guard.py \
        --sqlite-db /data/manaloom-ops/knowledge.db \
        --target-deck-id 6 \
        --expected-pg-deck-id 8938b746-1a9e-46ce-b0d9-c2ec932ddddd \
        --output /data/manaloom-ops/artifacts/target-deck-identity/deploy_guard_$short_sha.json \
        >/dev/null
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
  awk -F= '/^GIT_SHA=/{sha=\$2} /^DB_HOST=/{host=\$2} /^DB_PORT=/{port=\$2} /^DB_NAME=/{name=\$2} /^MANALOOM_NATIVE_BATTLE_HTTP_ENABLED=/{http=\$2} /^MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT=/{sync=\$2} /^MANALOOM_LOREHOLD_CANONICAL_OVERRIDE=/{override=\$2} /^MANALOOM_CANONICAL_PG_DECK_ID=/{canonical=\$2} /^MANALOOM_TARGET_PG_DECK_ID=/{target=\$2} END{print sha \"|\" host \"|\" port \"|\" name \"|\" http \"|\" sync \"|\" override \"|\" canonical \"|\" target}'
")"
if [[ "$deployed_contract" != "$sha|$EXPECTED_DB_HOST|$EXPECTED_DB_PORT|$EXPECTED_DB_NAME|1|1|0|8938b746-1a9e-46ce-b0d9-c2ec932ddddd|8938b746-1a9e-46ce-b0d9-c2ec932ddddd" ]]; then
  echo "deploy convergiu com SHA ou alvo PostgreSQL divergente" >&2
  exit 2
fi

release_proof="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
container=\$(docker ps --filter label=com.docker.swarm.service.name='$SERVICE' -q | head -1)
health=\$(docker exec \"\$container\" python3 -c \
  \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5)); print(d['status']+'|'+d['engine_contract']+'|'+d['git_sha'])\")
spec=\$(docker service inspect '$SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
running=\$(docker service ps '$SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
printf '%s|%s|%s' \"\$spec\" \"\$running\" \"\$health\"
")"
if [[ "$release_proof" != "$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|ok|native_reviewed_rules_execution|$sha" ]]; then
  echo "deploy manaloom-ops sem prova exata de spec=tarefa=digest e health: $release_proof" >&2
  exit 2
fi

DEPLOY_COMMITTED=1

cleanup_remote_build_dir

printf '{"status":"deployed","service":"%s","image_digest_ref":"%s","git_sha":"%s","release_proof":"%s","remote_cleanup_proof":"%s"}\n' \
  "$SERVICE" "$IMAGE_DIGEST_REF" "$sha" "$release_proof" "$REMOTE_CLEANUP_PROOF"

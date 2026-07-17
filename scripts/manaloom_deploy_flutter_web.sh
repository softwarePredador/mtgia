#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
BUILD_ONLY="${MANALOOM_RELEASE_BUILD_ONLY:-0}"

# Approval must come from the process invoking this release, never from the
# persistent server environment loaded below.
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"

if [[ "$BUILD_ONLY" != "0" && "$BUILD_ONLY" != "1" ]]; then
  echo "MANALOOM_RELEASE_BUILD_ONLY deve ser 0 ou 1" >&2
  exit 2
fi
readonly BUILD_ONLY
if [[ "$BUILD_ONLY" == "0" ]]; then
  require_live_mutation_approval "ManaLoom Flutter Web deployment"
  readonly LIVE_MUTATION_APPROVED=1
else
  readonly LIVE_MUTATION_APPROVED=0
fi
if [[ ! -f "$ENV_FILE" && "$BUILD_ONLY" == "0" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=scripts/lib/manaloom_safe_env.sh
  source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
  load_manaloom_env_keys "$ENV_FILE" \
    EASYPANEL_API_TOKEN EASYPANEL_BASE_URL EASYPANEL_PROJECT_NAME \
    EASYPANEL_SERVER_IP EASYPANEL_SSH_KEY EASYPANEL_SSH_USER \
    MANALOOM_API_BASE_URL MANALOOM_EASYPANEL_SSH_HOST \
    MANALOOM_EASYPANEL_SSH_KEY MANALOOM_FLUTTER_WEB_IMAGE_REPO \
    MANALOOM_FLUTTER_WEB_SERVICE MANALOOM_REMOTE_BUILD_ROOT \
    MANALOOM_WEB_PUBLIC_HOST SENTRY_DSN SENTRY_MOBILE_DSN
fi

API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
PUBLIC_HOST="${MANALOOM_WEB_PUBLIC_HOST:-evolution-manaloom-web-public.2ta7qx.easypanel.host}"
PUBLIC_BASE_URL="https://$PUBLIC_HOST"
PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
SERVICE="${MANALOOM_FLUTTER_WEB_SERVICE:-manaloom-app}"
SWARM_SERVICE="${PROJECT}_${SERVICE}"
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

for tool in git jq python3 shasum; do
  require_tool "$tool"
done

# shellcheck source=scripts/lib/manaloom_flutter_release_sdk.sh
source "$ROOT_DIR/scripts/lib/manaloom_flutter_release_sdk.sh"
resolve_manaloom_release_flutter
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
validate_manaloom_release_api_base_url "$API_BASE_URL"
MANALOOM_EXPECTED_SENTRY_DSN_SHA256="${MANALOOM_EXPECTED_SENTRY_DSN_SHA256:-$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256}"
validate_manaloom_exact_coordinate sentry_dsn_sha256 \
  "$MANALOOM_EXPECTED_SENTRY_DSN_SHA256" \
  "$MANALOOM_PRODUCTION_SENTRY_DSN_SHA256"
if [[ -z "${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}" ]]; then
  SENTRY_MOBILE_DSN="$(read_manaloom_keychain_secret \
    "$MANALOOM_SENTRY_DSN_KEYCHAIN_SERVICE" || true)"
fi

if [[ "$BUILD_ONLY" == "0" ]]; then
  for tool in curl ssh tar; do
    require_tool "$tool"
  done
  for key in SSH_HOST SSH_KEY EASYPANEL_BASE_URL EASYPANEL_API_TOKEN; do
    if [[ -z "${!key:-}" ]]; then
      echo "variavel obrigatoria ausente: $key" >&2
      exit 2
    fi
  done
  SSH_KEY="$(python3 - "$ROOT_DIR" "$SSH_KEY" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
candidate = Path(sys.argv[2]).expanduser()
if not candidate.is_absolute():
    candidate = root / candidate
print(candidate.resolve())
PY
)"
  if [[ ! -f "$SSH_KEY" ]]; then
    echo "chave SSH do deploy web nao e legivel" >&2
    exit 2
  fi
  validate_manaloom_exact_coordinate public_host "$PUBLIC_HOST" \
    "$MANALOOM_PRODUCTION_PUBLIC_HOST"
  validate_manaloom_exact_coordinate project "$PROJECT" \
    "$MANALOOM_PRODUCTION_EASYPANEL_PROJECT"
  validate_manaloom_exact_coordinate flutter_web_service "$SERVICE" \
    manaloom-app
  validate_manaloom_exact_coordinate flutter_web_image_repo "$IMAGE_REPO" \
    localhost:5000/manaloom/app-web
  validate_manaloom_exact_coordinate remote_build_root "$REMOTE_BUILD_ROOT" \
    "$MANALOOM_PRODUCTION_REMOTE_BUILD_ROOT"
  validate_manaloom_easypanel_base_url "$EASYPANEL_BASE_URL"
  initialize_manaloom_secure_ssh "$SSH_HOST"
fi

trpc_post() {
  local procedure="$1"
  local payload="$2"
  curl -fsS \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$payload" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$procedure"
}

DEPLOY_MUTATION_STARTED=0
DEPLOY_COMMITTED=0
SOURCE_MUTATED=0
PREVIOUS_SOURCE_IMAGE=""
ROLLBACK_SOURCE_IMAGE=""
PREVIOUS_SPEC_IMAGE=""
PREVIOUS_RUNNING_IMAGE=""
PREVIOUS_UPDATE_STATE=""
PREVIOUS_RELEASE_HASH=""

rollback_flutter_web() {
  local runtime_status=1 configured_status=1 health_status=1
  local services_json configured_image rollback_state release_hash

  echo "deploy Flutter Web falhou; restaurando origem e digest anteriores" >&2
  if [[ "$SOURCE_MUTATED" == "1" && -n "$ROLLBACK_SOURCE_IMAGE" ]]; then
    trpc_post services.app.updateSourceImage "$(jq -cn \
      --arg project "$PROJECT" \
      --arg service "$SERVICE" \
      --arg image "$ROLLBACK_SOURCE_IMAGE" \
      '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null || true
    trpc_post services.app.deployService "$(jq -cn \
      --arg project "$PROJECT" \
      --arg service "$SERVICE" \
      '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null || true
  fi

  if [[ -n "$PREVIOUS_SPEC_IMAGE" ]]; then
    for _ in $(seq 1 30); do
      rollback_state="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
        "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); spec=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); running=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1); printf '%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\"" 2>/dev/null || true)"
      if [[ "$rollback_state" == "1/1|$PREVIOUS_SPEC_IMAGE|$PREVIOUS_SPEC_IMAGE" ]]; then
        runtime_status=0
        break
      fi
      sleep 2
    done
    if [[ "$runtime_status" != "0" ]] &&
       ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
docker service update \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --rollback-order stop-first \\
  --detach=true \\
  --image '$PREVIOUS_SPEC_IMAGE' \\
  '$SWARM_SERVICE' >/dev/null
for attempt in \$(seq 1 60); do
  replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1)
  spec=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
  running=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1)
  update=\$(docker service inspect '$SWARM_SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}')
  if [ \"\$replicas\" = '1/1' ] && [ \"\$spec\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     [ \"\$running\" = '$PREVIOUS_SPEC_IMAGE' ] && \\
     { [ -z \"\$update\" ] || [ \"\$update\" = completed ] || [ \"\$update\" = rollback_completed ]; }; then
    exit 0
  fi
  case \"\$update\" in paused|rollback_paused) break ;; esac
  sleep 2
done
docker service ps '$SWARM_SERVICE' --no-trunc >&2
exit 1
"; then
      runtime_status=0
    fi
  fi

  if [[ "$SOURCE_MUTATED" == "1" ]]; then
    if services_json="$(trpc_post projects.listProjectsAndServices null)" &&
       configured_image="$(jq -er \
         --arg project "$PROJECT" \
         --arg service "$SERVICE" \
         '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
         <<<"$services_json")" &&
       [[ "$configured_image" == "$ROLLBACK_SOURCE_IMAGE" ]]; then
      configured_status=0
    fi
  else
    configured_status=0
  fi

  for _ in $(seq 1 30); do
    if release_hash="$(curl -fsS "$PUBLIC_BASE_URL/app/release.json" 2>/dev/null | \
         shasum -a 256 | awk '{print $1}')" &&
       [[ "$release_hash" == "$PREVIOUS_RELEASE_HASH" ]]; then
      health_status=0
      break
    fi
    sleep 2
  done

  if [[ "$runtime_status" == "0" && "$configured_status" == "0" &&
        "$health_status" == "0" ]]; then
    echo "rollback Flutter Web comprovado: origem, digest e release.json restaurados" >&2
    return 0
  fi
  echo "CRITICAL: rollback Flutter Web nao foi comprovado (runtime=$runtime_status configured=$configured_status health=$health_status)" >&2
  return 1
}

cleanup() {
  local status="${1:-$?}"
  trap - EXIT
  if [[ "$status" != "0" && "$DEPLOY_MUTATION_STARTED" == "1" &&
        "$DEPLOY_COMMITTED" != "1" ]]; then
    rollback_flutter_web || status=1
  fi
  if [[ -n "${WEB_RELEASE_TMP:-}" && -d "$WEB_RELEASE_TMP" ]]; then
    rm -rf "$WEB_RELEASE_TMP"
  fi
  if [[ -n "${WORKTREE_DIR:-}" && -d "$WORKTREE_DIR" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
  fi
  if [[ "$LIVE_MUTATION_APPROVED" == "1" && -n "${REMOTE_DIR:-}" &&
        -n "${MANALOOM_SECURE_SSH_KNOWN_HOSTS:-}" ]]; then
    ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "rm -rf '$REMOTE_DIR'" >/dev/null 2>&1 || true
  fi
  cleanup_manaloom_secure_ssh
  exit "$status"
}
trap 'cleanup $?' EXIT

# The shared identity helper preserves the legacy failure contract:
# "HEAD local nao esta alinhado com origin/master" now fails earlier with the
# exact source/head/origin values and also rejects a dirty release checkout.
IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="${MANALOOM_RELEASE_SOURCE_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}" \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
SHA="$(jq -r '.git_sha' <<<"$IDENTITY_JSON")"
SHORT_SHA="$(jq -r '.short_sha' <<<"$IDENTITY_JSON")"
VERSION="$(jq -r '.version' <<<"$IDENTITY_JSON")"
SOURCE_COMMITTED_AT="$(jq -r '.source_committed_at' <<<"$IDENTITY_JSON")"
IMAGE="$IMAGE_REPO:$SHORT_SHA"
RELEASE_DIR="${MANALOOM_RELEASE_DIR:-$HOME/.manaloom/releases/$VERSION/$SHORT_SHA}"
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
  --no-pub
)
SENTRY_RELEASE_DSN="${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}"
REQUIRE_SENTRY="${MANALOOM_RELEASE_REQUIRE_SENTRY:-$([[ "$BUILD_ONLY" == "0" ]] && printf 1 || printf 0)}"
if [[ "$REQUIRE_SENTRY" != "0" && "$REQUIRE_SENTRY" != "1" ]]; then
  echo "MANALOOM_RELEASE_REQUIRE_SENTRY deve ser 0 ou 1" >&2
  exit 2
fi
# A local build-only candidate may be produced without credentials. Any web
# deployment is publication and therefore remains fail-closed without a DSN.
if [[ "$BUILD_ONLY" == "0" && -z "$SENTRY_RELEASE_DSN" ]] ||
   [[ "$REQUIRE_SENTRY" == "1" && -z "$SENTRY_RELEASE_DSN" ]]; then
  echo "deploy web recusado: SENTRY_MOBILE_DSN/SENTRY_DSN ausente" >&2
  exit 2
fi
resolve_manaloom_release_sentry_dsn "$SENTRY_RELEASE_DSN" "$REQUIRE_SENTRY"
if [[ -n "$SENTRY_RELEASE_DSN" ]]; then
  build_args+=(--dart-define="SENTRY_DSN=$SENTRY_RELEASE_DSN")
fi

(
  cd "$WORKTREE_DIR/app"
  "$MANALOOM_FLUTTER_BIN_RESOLVED" pub get --enforce-lockfile
  "$MANALOOM_FLUTTER_BIN_RESOLVED" build "${build_args[@]}"
)

grep -Fq '<base href="/app/">' "$WORKTREE_DIR/app/build/web/index.html"
BUILT_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 "$WORKTREE_DIR/scripts/manaloom_generate_release_sbom.py" \
  --app-dir "$WORKTREE_DIR/app" \
  --dart-bin "$MANALOOM_RELEASE_DART_BIN_RESOLVED" \
  --git-sha "$SHA" \
  --source-committed-at "$SOURCE_COMMITTED_AT" \
  --output "$WORKTREE_DIR/app/build/web/sbom.cdx.json" >/dev/null
python3 "$WORKTREE_DIR/scripts/manaloom_osv_scan_sbom.py" \
  --sbom "$WORKTREE_DIR/app/build/web/sbom.cdx.json" \
  --output "$WORKTREE_DIR/app/build/web/osv-scan.json" >/dev/null

INDEX_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/index.html" | awk '{print $1}')"
BOOTSTRAP_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/flutter_bootstrap.js" | awk '{print $1}')"
MAIN_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/main.dart.js" | awk '{print $1}')"
SERVICE_WORKER_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/flutter_service_worker.js" | awk '{print $1}')"
SBOM_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/sbom.cdx.json" | awk '{print $1}')"
OSV_SCAN_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/osv-scan.json" | awk '{print $1}')"
jq -e --arg sbom_sha256 "$SBOM_SHA256" \
  '.status == "passed" and .sbom_sha256 == $sbom_sha256 and .vulnerability_count == 0' \
  "$WORKTREE_DIR/app/build/web/osv-scan.json" >/dev/null
LOTUS_INDEX_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/assets/assets/lotus/index.html" | awk '{print $1}')"
LOTUS_APP_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/assets/assets/lotus/js/app.min.js" | awk '{print $1}')"
LOTUS_STYLES_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/build/web/assets/assets/lotus/css/styles.min.css" | awk '{print $1}')"
jq -n \
  --arg version "$VERSION" \
  --arg git_sha "$SHA" \
  --arg short_sha "$SHORT_SHA" \
  --arg built_at "$BUILT_AT" \
  --arg source_committed_at "$SOURCE_COMMITTED_AT" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_release "manaloom-web@$SHORT_SHA" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  --arg index_sha256 "$INDEX_SHA256" \
  --arg bootstrap_sha256 "$BOOTSTRAP_SHA256" \
  --arg main_sha256 "$MAIN_SHA256" \
  --arg service_worker_sha256 "$SERVICE_WORKER_SHA256" \
  --arg sbom_sha256 "$SBOM_SHA256" \
  --arg osv_scan_sha256 "$OSV_SCAN_SHA256" \
  --arg lotus_index_sha256 "$LOTUS_INDEX_SHA256" \
  --arg lotus_app_sha256 "$LOTUS_APP_SHA256" \
  --arg lotus_styles_sha256 "$LOTUS_STYLES_SHA256" \
  --argjson sentry_configured "$([[ -n "$SENTRY_RELEASE_DSN" ]] && printf true || printf false)" \
  '{
    schema_version: 1,
    product: "manaloom",
    platform: "web",
    version: $version,
    git_sha: $git_sha,
    short_sha: $short_sha,
    built_at: $built_at,
    source_committed_at: $source_committed_at,
    api_base_url: $api_base_url,
    sentry_release: $sentry_release,
    sentry_configured: $sentry_configured,
    sentry_dsn_sha256: (if ($sentry_dsn_sha256 | length) > 0 then $sentry_dsn_sha256 else null end),
    artifacts: {
      "index.html": $index_sha256,
      "flutter_bootstrap.js": $bootstrap_sha256,
      "main.dart.js": $main_sha256,
      "flutter_service_worker.js": $service_worker_sha256,
      "sbom.cdx.json": $sbom_sha256,
      "osv-scan.json": $osv_scan_sha256,
      "assets/assets/lotus/index.html": $lotus_index_sha256,
      "assets/assets/lotus/js/app.min.js": $lotus_app_sha256,
      "assets/assets/lotus/css/styles.min.css": $lotus_styles_sha256
    }
  }' > "$WORKTREE_DIR/app/build/web/release.json"
jq -e --arg sha "$SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version and .platform == "web"' \
  "$WORKTREE_DIR/app/build/web/release.json" >/dev/null

if [[ "$BUILD_ONLY" == "1" ]]; then
  WEB_RELEASE_DIR="$RELEASE_DIR/web"
  WEB_RELEASE_TMP="$RELEASE_DIR/.web.$$.tmp"
  rm -rf "$WEB_RELEASE_TMP"
  mkdir -p "$WEB_RELEASE_TMP"
  cp -R "$WORKTREE_DIR/app/build/web/." "$WEB_RELEASE_TMP/"
  printf '%s\n' "$IDENTITY_JSON" > "$WEB_RELEASE_TMP/release-identity.json"
  (
    cd "$WEB_RELEASE_TMP"
    shasum -a 256 \
      index.html \
      flutter_bootstrap.js \
      main.dart.js \
      flutter_service_worker.js \
      assets/assets/lotus/index.html \
      assets/assets/lotus/js/app.min.js \
      assets/assets/lotus/css/styles.min.css \
      release-identity.json \
      release.json \
      sbom.cdx.json \
      osv-scan.json > SHA256SUMS
  )
  rm -rf "$WEB_RELEASE_DIR"
  mv "$WEB_RELEASE_TMP" "$WEB_RELEASE_DIR"
  printf '{"status":"built","platform":"web","version":"%s","git_sha":"%s","release_dir":"%s","manifest":"%s"}\n' \
    "$VERSION" "$SHA" "$WEB_RELEASE_DIR" "$WEB_RELEASE_DIR/release.json"
  exit 0
fi

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$WORKTREE_DIR/app/Dockerfile.web" "$WORKTREE_DIR/app/web/nginx.conf" "$WORKTREE_DIR/app/build/web"
fi

COPYFILE_DISABLE=1 tar --no-mac-metadata -C "$WORKTREE_DIR/app" -czf - Dockerfile.web web/nginx.conf build/web | \
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "rm -rf '$REMOTE_DIR' && mkdir -p '$REMOTE_DIR' && tar -xzf - -C '$REMOTE_DIR'"

# Capture the final remote registry RepoDigest after both tag pushes. All
# deployment/configuration calls below use only this immutable reference.
# shellcheck disable=SC2087
IMAGE_DIGEST_REF="$(
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" <<REMOTE |
    extract_manaloom_repo_digest_ref "$IMAGE_REPO"
set -euo pipefail
cd '$REMOTE_DIR'
docker build -f Dockerfile.web -t '$IMAGE' -t '$IMAGE_REPO:latest' . >&2
docker push '$IMAGE' >&2
docker push '$IMAGE_REPO:latest' >&2
image_digest_ref="\$(
  docker image inspect '$IMAGE' \
    --format '{{range .RepoDigests}}{{println .}}{{end}}' |
    awk -v expected_repo='$IMAGE_REPO' \
      'index(\$0, expected_repo "@sha256:") == 1 {print; exit}'
)"
image_digest="\${image_digest_ref#'$IMAGE_REPO@sha256:'}"
if [[ "\$image_digest_ref" != '$IMAGE_REPO@sha256:'"\$image_digest" ||
      ! "\$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo 'push remoto nao produziu RepoDigest SHA-256 valido para Flutter Web' >&2
  exit 2
fi
printf '%s\n' "\$image_digest_ref"
REMOTE
)"
image_digest="${IMAGE_DIGEST_REF#"$IMAGE_REPO@sha256:"}"
if [[ "$IMAGE_DIGEST_REF" != "$IMAGE_REPO@sha256:$image_digest" ||
      ! "$image_digest" =~ ^[0-9a-f]{64}$ ]]; then
  echo "push remoto retornou RepoDigest invalido para Flutter Web: $IMAGE_DIGEST_REF" >&2
  exit 2
fi
readonly IMAGE_DIGEST_REF

SERVICES_JSON="$(trpc_post projects.listProjectsAndServices null)"
if ! jq -e --arg project "$PROJECT" --arg service "$SERVICE" \
  '.json.services[]? | select(.projectName == $project and .name == $service and .type == "app")' \
  >/dev/null <<<"$SERVICES_JSON"; then
  echo "deploy recusado: servico Flutter Web precisa existir para permitir rollback" >&2
  exit 2
fi
PREVIOUS_SOURCE_IMAGE="$(jq -er \
  --arg project "$PROJECT" \
  --arg service "$SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$SERVICES_JSON")"
PREVIOUS_RUNTIME_STATE="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); spec=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); running=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1); update=\$(docker service inspect '$SWARM_SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}' 2>/dev/null || true); printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec\" \"\$running\" \"\$update\"")"
IFS='|' read -r previous_replicas PREVIOUS_SPEC_IMAGE PREVIOUS_RUNNING_IMAGE \
  PREVIOUS_UPDATE_STATE \
  <<<"$PREVIOUS_RUNTIME_STATE"
if [[ "$previous_replicas" != "1/1" ||
      "$PREVIOUS_RUNNING_IMAGE" != "$PREVIOUS_SPEC_IMAGE" ||
      ( -n "$PREVIOUS_UPDATE_STATE" &&
        "$PREVIOUS_UPDATE_STATE" != "completed" &&
        "$PREVIOUS_UPDATE_STATE" != "rollback_completed" ) ||
      ! "$PREVIOUS_SPEC_IMAGE" =~ @sha256:[0-9a-f]{64}$ ]]; then
  echo "deploy recusado: baseline Flutter Web nao e rollback-safe: $PREVIOUS_RUNTIME_STATE" >&2
  exit 2
fi
ROLLBACK_SOURCE_IMAGE="$PREVIOUS_SPEC_IMAGE"
if [[ "$PREVIOUS_SOURCE_IMAGE" != "$ROLLBACK_SOURCE_IMAGE" ]]; then
  echo "origem EasyPanel anterior sera normalizada para o digest imutavel da spec durante eventual rollback" >&2
fi
PREVIOUS_RELEASE_HASH="$(curl -fsS "$PUBLIC_BASE_URL/app/release.json" | \
  shasum -a 256 | awk '{print $1}')"

DEPLOY_MUTATION_STARTED=1
ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "
set -euo pipefail
docker service update \\
  --update-failure-action rollback \\
  --update-monitor 30s \\
  --rollback-failure-action pause \\
  --rollback-monitor 30s \\
  --rollback-order stop-first \\
  --detach=true \\
  '$SWARM_SERVICE' >/dev/null
"
SOURCE_MUTATED=1
trpc_post services.app.updateSourceImage "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" --arg image "$IMAGE_DIGEST_REF" '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null
trpc_post services.app.updateDeploy "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" '{projectName:$project,serviceName:$service,deploy:{command:null,replicas:1,zeroDowntime:false}}')" >/dev/null
trpc_post services.app.deployService "$(jq -cn --arg project "$PROJECT" --arg service "$SERVICE" '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null

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

for _ in $(seq 1 60); do
  RUNTIME_STATE="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "replicas=\$(docker service ls --filter name='$SWARM_SERVICE' --format '{{.Replicas}}' | head -1); spec_image=\$(docker service inspect '$SWARM_SERVICE' --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || true); running_image=\$(docker service ps '$SWARM_SERVICE' --filter desired-state=running --format '{{.Image}}' | head -1); update_state=\$(docker service inspect '$SWARM_SERVICE' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}' 2>/dev/null || true); printf '%s|%s|%s|%s' \"\$replicas\" \"\$spec_image\" \"\$running_image\" \"\$update_state\"")"
  if [[ "$RUNTIME_STATE" == "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|completed" ||
        "$RUNTIME_STATE" == "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|" ]]; then
    break
  fi
  IFS='|' read -r _ _ _ update_state <<<"$RUNTIME_STATE"
  case "$update_state" in paused|rollback_paused|rollback_completed) break ;; esac
  sleep 2
done
if [[ "$RUNTIME_STATE" != "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|completed" &&
      "$RUNTIME_STATE" != "1/1|$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|" ]]; then
  echo "servico Flutter Web nao convergiu: $RUNTIME_STATE" >&2
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "docker service ps '$SWARM_SERVICE' --no-trunc" >&2
  exit 1
fi

SERVICES_JSON="$(trpc_post projects.listProjectsAndServices null)"
CONFIGURED_IMAGE="$(jq -er \
  --arg project "$PROJECT" \
  --arg service "$SERVICE" \
  '.json.services[] | select(.projectName == $project and .name == $service and .type == "app") | .source.image' \
  <<<"$SERVICES_JSON")"
if [[ "$CONFIGURED_IMAGE" != "$IMAGE_DIGEST_REF" ]]; then
  echo "Flutter Web convergiu sem o digest exato na origem EasyPanel: $CONFIGURED_IMAGE" >&2
  exit 2
fi

for _ in $(seq 1 30); do
  APP_CODE="$(curl -sS -o /tmp/manaloom_app_web_index.html -w '%{http_code}' "$PUBLIC_BASE_URL/app/")"
  if [[ "$APP_CODE" == "200" ]] && grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_index.html; then
    break
  fi
  sleep 2
done

[[ "$APP_CODE" == "200" ]]
grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_index.html
BOOTSTRAP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_BASE_URL/app/flutter_bootstrap.js")"
RELEASE_HEADERS="$(mktemp /tmp/manaloom_app_release_headers.XXXXXX)"
RELEASE_CODE="$(curl -sS -D "$RELEASE_HEADERS" -o /tmp/manaloom_app_release.json -w '%{http_code}' "$PUBLIC_BASE_URL/app/release.json")"
DEEP_LINK_CODE="$(curl -sS -o /tmp/manaloom_app_web_deep.html -w '%{http_code}' "$PUBLIC_BASE_URL/app/decks")"
ROOT_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_BASE_URL/")"
[[ "$BOOTSTRAP_CODE" == "200" ]]
[[ "$RELEASE_CODE" == "200" ]]
[[ "$DEEP_LINK_CODE" == "200" ]]
[[ "$ROOT_CODE" == "200" ]]
grep -Fq '<base href="/app/">' /tmp/manaloom_app_web_deep.html
jq -e --arg sha "$SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version and .platform == "web"' \
  /tmp/manaloom_app_release.json >/dev/null
grep -Eqi '^cache-control:[[:space:]]*no-cache, no-store, must-revalidate' "$RELEASE_HEADERS"
APP_HEADERS="$(mktemp /tmp/manaloom_app_headers.XXXXXX)"
curl -fsS -D "$APP_HEADERS" -o /dev/null "$PUBLIC_BASE_URL/app/"
grep -Eqi '^content-security-policy:' "$APP_HEADERS"
BOOTSTRAP_HEADERS="$(mktemp /tmp/manaloom_bootstrap_headers.XXXXXX)"
curl -fsS -D "$BOOTSTRAP_HEADERS" -o /dev/null "$PUBLIC_BASE_URL/app/flutter_bootstrap.js"
grep -Eqi '^cache-control:[[:space:]]*no-cache, must-revalidate' "$BOOTSTRAP_HEADERS"

rm -f /tmp/manaloom_app_web_index.html /tmp/manaloom_app_web_deep.html \
  /tmp/manaloom_app_release.json "$RELEASE_HEADERS" "$APP_HEADERS" "$BOOTSTRAP_HEADERS"

DEPLOY_COMMITTED=1
jq -cn \
  --arg service "$SWARM_SERVICE" \
  --arg image "$IMAGE" \
  --arg image_digest_ref "$IMAGE_DIGEST_REF" \
  --arg version "$VERSION" \
  --arg git_sha "$SHA" \
  --arg app_url "$PUBLIC_BASE_URL/app/" \
  --argjson root_code "$ROOT_CODE" \
  --argjson app_code "$APP_CODE" \
  --argjson bootstrap_code "$BOOTSTRAP_CODE" \
  --argjson release_code "$RELEASE_CODE" \
  --argjson deep_link_code "$DEEP_LINK_CODE" \
  '{
    status: "deployed",
    service: $service,
    image: $image,
    image_digest_ref: $image_digest_ref,
    version: $version,
    git_sha: $git_sha,
    app_url: $app_url,
    root_code: $root_code,
    app_code: $app_code,
    bootstrap_code: $bootstrap_code,
    release_code: $release_code,
    deep_link_code: $deep_link_code
  }'

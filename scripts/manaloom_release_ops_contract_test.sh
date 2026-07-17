#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/manaloom-release-ops-contract.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

SHELL_SCRIPTS=(
  scripts/manaloom_build_android_release.sh
  scripts/manaloom_build_beta_release.sh
  scripts/manaloom_deploy_backend_image.sh
  scripts/manaloom_deploy_flutter_web.sh
  scripts/manaloom_full_restore_drill.sh
  scripts/manaloom_offsite_backup.sh
  scripts/manaloom_publish_android_release.sh
  scripts/manaloom_release_identity.sh
  scripts/manaloom_release_observability_gate.sh
  scripts/manaloom_verify_android_release_artifacts.sh
)

for relative in "${SHELL_SCRIPTS[@]}"; do
  bash -n "$ROOT_DIR/$relative"
done
PYTHONPYCACHEPREFIX="$TMP_DIR/pycache" \
  python3 -m py_compile \
    "$ROOT_DIR/scripts/manaloom_generate_release_sbom.py" \
    "$ROOT_DIR/scripts/manaloom_validate_production_origins.py"

REQUIRED_WEB_ORIGIN='https://evolution-manaloom-web-public.2ta7qx.easypanel.host'
VALID_ORIGINS="$REQUIRED_WEB_ORIGIN,https://admin.manaloom.example"
VALIDATED_ORIGINS="$(
  MANALOOM_ALLOWED_ORIGINS="$VALID_ORIGINS" \
    python3 "$ROOT_DIR/scripts/manaloom_validate_production_origins.py"
)"
if [[ "$VALIDATED_ORIGINS" != "$VALID_ORIGINS" ]]; then
  echo "validador CORS alterou uma allowlist valida" >&2
  exit 1
fi
INVALID_ORIGIN_LISTS=(
  '*'
  "$REQUIRED_WEB_ORIGIN/"
  "http://evolution-manaloom-web-public.2ta7qx.easypanel.host"
  "$REQUIRED_WEB_ORIGIN,https://localhost"
  "$REQUIRED_WEB_ORIGIN,$REQUIRED_WEB_ORIGIN"
)
for invalid_origins in "${INVALID_ORIGIN_LISTS[@]}"; do
  if MANALOOM_ALLOWED_ORIGINS="$invalid_origins" \
    python3 "$ROOT_DIR/scripts/manaloom_validate_production_origins.py" \
      >/dev/null 2>&1; then
    echo "validador CORS aceitou wildcard/origem nao exata" >&2
    exit 1
  fi
done

NGINX="$ROOT_DIR/app/web/nginx.conf"
grep -Fq '"/app/release.json" "no-cache, no-store, must-revalidate"' "$NGINX"
grep -Fq '"/app/flutter_bootstrap.js" "no-cache, must-revalidate"' "$NGINX"
grep -Fq '"/app/main.dart.js" "no-cache, must-revalidate"' "$NGINX"
grep -Fq '~*^/app/assets/assets/lotus/ "no-cache, must-revalidate"' "$NGINX"
grep -Fq 'Content-Security-Policy' "$NGINX"
grep -Fq "object-src 'none'" "$NGINX"
grep -Fq 'Permissions-Policy "camera=(self), microphone=(), geolocation=()"' "$NGINX"
if [[ "$(grep -c 'add_header Cache-Control' "$NGINX")" != "1" ]]; then
  echo "nginx deve declarar Cache-Control uma unica vez no server" >&2
  exit 1
fi

OFFSITE_PLAN="$("$ROOT_DIR/scripts/manaloom_offsite_backup.sh" \
  --source /tmp/not-executed.dump \
  --destination s3://manaloom-contract/backups \
  --recipient age1contractonlynotarealrecipient)"
jq -e '.status == "dry_run" and .writes_performed == false and .encryption == "age-x25519"' <<<"$OFFSITE_PLAN" >/dev/null

RESTORE_PLAN="$("$ROOT_DIR/scripts/manaloom_full_restore_drill.sh" \
  --backup /tmp/not-executed.dump \
  --min-tables 80)"
jq -e '.status == "dry_run" and .writes_performed == false and .mode == "full" and .runner == "isolated_local_docker"' <<<"$RESTORE_PLAN" >/dev/null

OBSERVABILITY_PLAN="$("$ROOT_DIR/scripts/manaloom_release_observability_gate.sh" \
  --device contract-device \
  --release-manifest /tmp/not-executed-release-manifest.json)"
jq -e '.status == "dry_run" and .release_identity_required == true and .sentry_ingestion_required == true and .fcm_registration_required == true and .fcm_delivery_required == true and .stateful_api_write_on_execute == true and .writes_performed == false' <<<"$OBSERVABILITY_PLAN" >/dev/null

if "$ROOT_DIR/scripts/manaloom_offsite_backup.sh" \
  --source /tmp/not-executed.dump \
  --destination s3://manaloom-contract/backups \
  --recipient age1contractonlynotarealrecipient \
  --execute >/dev/null 2>&1; then
  echo "backup off-site aceitou --execute sem acknowledgement" >&2
  exit 1
fi
if "$ROOT_DIR/scripts/manaloom_full_restore_drill.sh" \
  --backup /tmp/not-executed.dump \
  --execute >/dev/null 2>&1; then
  echo "restore drill aceitou --execute sem acknowledgement" >&2
  exit 1
fi
if MANALOOM_RELEASE_OBSERVABILITY_EXECUTE=1 \
  "$ROOT_DIR/scripts/manaloom_release_observability_gate.sh" \
    --device contract-device \
    --release-manifest /tmp/not-executed-release-manifest.json \
    --execute >/dev/null 2>&1; then
  echo "observability gate aceitou escrita stateful sem acknowledgement" >&2
  exit 1
fi

IDENTITY_ORIGIN="$TMP_DIR/identity-origin.git"
IDENTITY_REPO="$TMP_DIR/identity-repo"
git init --quiet --bare --initial-branch=master "$IDENTITY_ORIGIN"
git init --quiet --initial-branch=master "$IDENTITY_REPO"
git -C "$IDENTITY_REPO" remote add origin "$IDENTITY_ORIGIN"
mkdir -p "$IDENTITY_REPO/app"
printf 'name: manaloom_contract\nversion: 1.2.3+45\n' > "$IDENTITY_REPO/app/pubspec.yaml"
git -C "$IDENTITY_REPO" add app/pubspec.yaml
git -C "$IDENTITY_REPO" \
  -c user.name='ManaLoom Contract' \
  -c user.email='contract@manaloom.invalid' \
  commit --quiet -m 'release identity fixture'
git -C "$IDENTITY_REPO" push --quiet -u origin master

IDENTITY_JSON="$(
  MANALOOM_RELEASE_ROOT_DIR="$IDENTITY_REPO" \
  MANALOOM_RELEASE_FETCH_ORIGIN=0 \
  MANALOOM_RELEASE_REQUIRE_CLEAN=1 \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
jq -e --arg sha "$(git -C "$IDENTITY_REPO" rev-parse HEAD)" \
  '.git_sha == $sha and (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+\\+[1-9][0-9]*$"))' \
  <<<"$IDENTITY_JSON" >/dev/null

SOURCE_COMMITTED_AT="$(git -C "$ROOT_DIR" show -s --format=%cI HEAD)"
python3 "$ROOT_DIR/scripts/manaloom_generate_release_sbom.py" \
  --app-dir "$ROOT_DIR/app" \
  --git-sha "$(git -C "$ROOT_DIR" rev-parse HEAD)" \
  --source-committed-at "$SOURCE_COMMITTED_AT" \
  --output "$TMP_DIR/sbom.cdx.json" >/dev/null
jq -e '.bomFormat == "CycloneDX" and .specVersion == "1.5" and
  (.components | length) > 20 and
  any(.components[]; .name == "flutter") and
  (any(.components[]; .name == "patrol") | not)' \
  "$TMP_DIR/sbom.cdx.json" >/dev/null

grep -Fq 'MANALOOM_RELEASE_REQUIRE_SENTRY' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'permissions_gate' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'release.json' "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq 'assets/assets/lotus/index.html' "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq 'web.git_sha == android.git_sha == source.git_sha' "$ROOT_DIR/scripts/manaloom_build_beta_release.sh"
grep -Fq 'MANALOOM_RELEASE_OBSERVABILITY_EVIDENCE' "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq 'SOURCE_IDENTITY_JSON' "$ROOT_DIR/scripts/manaloom_release_observability_gate.sh"
grep -Fq 'artifact_installation: "not_proven"' "$ROOT_DIR/scripts/manaloom_release_observability_gate.sh"
grep -Fq -- "--env-add MANALOOM_ALLOWED_ORIGINS='\$ALLOWED_ORIGINS_CANONICAL'" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'spec_allowed_origins_sha256' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'runtime_allowed_origins_sha256' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"

printf '{"status":"passed","contracts":%s}\n' "${#SHELL_SCRIPTS[@]}"

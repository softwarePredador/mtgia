#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/manaloom-release-ops-contract.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# The contract and its SBOM must use the exact release SDK, never a Dart found
# independently on PATH.
# shellcheck source=scripts/lib/manaloom_flutter_release_sdk.sh
source "$ROOT_DIR/scripts/lib/manaloom_flutter_release_sdk.sh"
resolve_manaloom_release_flutter
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"

if [[ "$MANALOOM_PRODUCTION_TRAEFIK_LOGICAL_IP" != "10.11.0.202" ||
      "$MANALOOM_PRODUCTION_PROXY_TRANSPORT_PEER_IPV4" != "10.11.0.4" ||
      "$MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS" != "10.11.0.4/32" ]]; then
  echo "contrato de proxy de producao misturou IP logico e peer de transporte" >&2
  exit 1
fi
grep -Fq 'lb-easypanel' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
if grep -Fq 'expected_proxy_ip="${MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS%/32}"' \
  "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"; then
  echo "deploy voltou a derivar o IP logico da allowlist de transporte" >&2
  exit 1
fi
for web_deploy in \
  scripts/manaloom_deploy_flutter_web.sh \
  scripts/manaloom_deploy_public_web.sh; do
  if ! grep -Fq 'extract_manaloom_repo_digest_ref "$IMAGE_REPO"' \
    "$ROOT_DIR/$web_deploy"; then
    echo "deploy web nao filtra o MOTD antes de validar RepoDigest: $web_deploy" >&2
    exit 1
  fi
done

MOTD_DIGEST="$TMP_DIR/repo-digest-output"
printf '%s\n' \
  'Welcome to Ubuntu' \
  'System restart required' \
  'localhost:5000/manaloom/cartinhas@sha256:e439d218bc603cc766388634d2d51de4430938573f483f3326df7f385ba0fd3a' \
  >"$MOTD_DIGEST"
PARSED_DIGEST="$(
  extract_manaloom_repo_digest_ref \
    'localhost:5000/manaloom/cartinhas' <"$MOTD_DIGEST"
)"
if [[ "$PARSED_DIGEST" != \
      'localhost:5000/manaloom/cartinhas@sha256:e439d218bc603cc766388634d2d51de4430938573f483f3326df7f385ba0fd3a' ]]; then
  echo "parser de RepoDigest nao filtrou o MOTD SSH" >&2
  exit 1
fi
if printf '%s\n' 'Welcome to Ubuntu' |
   extract_manaloom_repo_digest_ref \
     'localhost:5000/manaloom/cartinhas' >/dev/null 2>&1; then
  echo "parser de RepoDigest aceitou saida sem digest" >&2
  exit 1
fi

SHELL_SCRIPTS=(
  scripts/lib/manaloom_flutter_release_sdk.sh
  scripts/lib/manaloom_release_runtime_contract.sh
  scripts/lib/manaloom_safe_env.sh
  scripts/manaloom_build_android_release.sh
  scripts/manaloom_build_beta_release.sh
  scripts/manaloom_battle_product_gate.sh
  scripts/manaloom_deep_ai_alignment_tester.sh
  scripts/manaloom_deploy_backend_image.sh
  scripts/manaloom_deploy_flutter_web.sh
  scripts/manaloom_deploy_public_web.sh
  scripts/manaloom_easypanel_backup.sh
  scripts/manaloom_full_restore_drill.sh
  scripts/manaloom_global_battle_closure.sh
  scripts/manaloom_install_remote_backup_cron.sh
  scripts/manaloom_offsite_backup.sh
  scripts/manaloom_pg_hermes_sqlite_contract_audit.sh
  scripts/manaloom_publish_android_release.sh
  scripts/manaloom_release_identity.sh
  scripts/manaloom_release_observability_gate.sh
  scripts/manaloom_secret_scan.sh
  scripts/manaloom_verify_android_release_artifacts.sh
  scripts/validate_sentry_mobile_ingestion.sh
  scripts/validate_sentry_mobile_local.sh
  scripts/quality_gate_resolution_corpus.sh
  server/bin/with_new_server_pg.sh
)

for relative in "${SHELL_SCRIPTS[@]}"; do
  bash -n "$ROOT_DIR/$relative"
done
PYTHONPYCACHEPREFIX="$TMP_DIR/pycache" \
  python3 -m py_compile \
    "$ROOT_DIR/scripts/manaloom_generate_release_sbom.py" \
    "$ROOT_DIR/scripts/manaloom_live_credential_audit.py" \
    "$ROOT_DIR/scripts/manaloom_osv_scan_sbom.py" \
    "$ROOT_DIR/scripts/manaloom_read_env.py" \
    "$ROOT_DIR/scripts/manaloom_validate_production_origins.py" \
    "$ROOT_DIR/server/bin/audit_easypanel_runtime_alignment.py" \
    "$ROOT_DIR/server/test/new_server_pg_caller_mode_contract_test.py" \
    "$ROOT_DIR/server/test/release_sbom_scope_test.py"

PYTHONDONTWRITEBYTECODE=1 \
  python3 "$ROOT_DIR/server/test/new_server_pg_caller_mode_contract_test.py"
PYTHONDONTWRITEBYTECODE=1 \
  python3 "$ROOT_DIR/server/test/release_sbom_scope_test.py"

SAFE_ENV_FIXTURE="$TMP_DIR/safe.env"
SAFE_ENV_MARKER="$TMP_DIR/env-code-executed"
# The fixture must preserve command substitution literally.
# shellcheck disable=SC2016
printf 'API_TOKEN=$(touch %s)\nEMPTY_VALUE=\nQUOTED_VALUE="literal value"\n' \
  "$SAFE_ENV_MARKER" >"$SAFE_ENV_FIXTURE"
SAFE_VALUE="$(python3 "$ROOT_DIR/scripts/manaloom_read_env.py" \
  --file "$SAFE_ENV_FIXTURE" --key API_TOKEN)"
if [[ "$SAFE_VALUE" != "\$(touch $SAFE_ENV_MARKER)" || -e "$SAFE_ENV_MARKER" ]]; then
  echo "dotenv seguro executou ou alterou valor literal" >&2
  exit 1
fi
printf '%s\n' 'PATH=/tmp/untrusted' >"$SAFE_ENV_FIXTURE"
if python3 "$ROOT_DIR/scripts/manaloom_read_env.py" \
  --file "$SAFE_ENV_FIXTURE" --key PATH >/dev/null 2>&1; then
  echo "dotenv seguro aceitou PATH" >&2
  exit 1
fi
printf '%s\n' 'TOKEN=one' 'TOKEN=two' >"$SAFE_ENV_FIXTURE"
if python3 "$ROOT_DIR/scripts/manaloom_read_env.py" \
  --file "$SAFE_ENV_FIXTURE" --key TOKEN >/dev/null 2>&1; then
  echo "dotenv seguro aceitou chave duplicada" >&2
  exit 1
fi

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
if "$ROOT_DIR/scripts/manaloom_easypanel_backup.sh" >/dev/null 2>&1; then
  echo "backup EasyPanel aceitou leitura live sem acknowledgement" >&2
  exit 1
fi
if "$ROOT_DIR/scripts/manaloom_install_remote_backup_cron.sh" >/dev/null 2>&1; then
  echo "instalador de backup aceitou mutacao live sem acknowledgement" >&2
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
FORBIDDEN_DART_BIN="$TMP_DIR/forbidden-dart-bin"
FORBIDDEN_DART_MARKER="$TMP_DIR/global-dart-was-used"
mkdir -p "$FORBIDDEN_DART_BIN"
cat > "$FORBIDDEN_DART_BIN/dart" <<EOF
#!/bin/sh
touch '$FORBIDDEN_DART_MARKER'
exit 99
EOF
chmod +x "$FORBIDDEN_DART_BIN/dart"
PATH="$FORBIDDEN_DART_BIN:$PATH" \
  python3 "$ROOT_DIR/scripts/manaloom_generate_release_sbom.py" \
  --app-dir "$ROOT_DIR/app" \
  --dart-bin "$MANALOOM_RELEASE_DART_BIN_RESOLVED" \
  --gradle-lock "$ROOT_DIR/app/android/app/gradle.lockfile" \
  --git-sha "$(git -C "$ROOT_DIR" rev-parse HEAD)" \
  --source-committed-at "$SOURCE_COMMITTED_AT" \
  --output "$TMP_DIR/sbom.cdx.json" >/dev/null
if [[ -e "$FORBIDDEN_DART_MARKER" ]]; then
  echo "SBOM executou o Dart global em vez do SDK de release" >&2
  exit 1
fi
jq -e '.bomFormat == "CycloneDX" and .specVersion == "1.5" and
  (.components | length) > 20 and
  any(.components[]; .name == "flutter") and
  any(.components[]; .name == "meta" and .version == "1.18.0") and
  any(.components[]; .name == "test_api" and .version == "0.7.11") and
  any(.components[]; .group == "io.sentry" and .name == "sentry-android" and .version == "8.36.0") and
  any(.components[]; .group == "com.google.mlkit" and .name == "text-recognition" and .version == "16.0.1") and
  any(.components[];
    .group == "com.squareup.okhttp" and .name == "okhttp" and
    .version == "2.7.5" and .scope == "excluded" and
    any(.properties[];
      .name == "manaloom:release-membership-evidence" and
      .value == "gradle-lock-configuration-membership")) and
  all(.components[] | select(.scope == "excluded");
    ([.properties[] |
      select(.name == "manaloom:gradle-configurations") |
      .value | split(",")[]] |
     index("releaseRuntimeClasspath")) == null) and
  (any(.components[]; .name == "patrol") | not)' \
  "$TMP_DIR/sbom.cdx.json" >/dev/null

grep -Fq 'MANALOOM_RELEASE_REQUIRE_SENTRY' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'EXPECTED_VERSION="8.30.1"' "$ROOT_DIR/scripts/manaloom_secret_scan.sh"
python3 "$ROOT_DIR/scripts/manaloom_live_credential_audit.py" >/dev/null
grep -Fq 'MANALOOM_RELEASE_FLUTTER_VERSION="3.44.6"' "$ROOT_DIR/scripts/lib/manaloom_flutter_release_sdk.sh"
grep -Fq 'pub get --enforce-lockfile' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'pub get --enforce-lockfile' "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq -- "--dart-bin \"\$MANALOOM_RELEASE_DART_BIN_RESOLVED\"" "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq -- "--dart-bin \"\$MANALOOM_RELEASE_DART_BIN_RESOLVED\"" "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq -- '--android-release-artifact "$AAB"' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'manaloom:gradle-aab-dependency-parity' "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq 'manaloom:android-release-artifact-sha256' "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq -- '--no-pub' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq -- '--no-pub' "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq 'permissions_gate' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'release.json' "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq 'assets/assets/lotus/index.html' "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq 'web.git_sha == android.git_sha == source.git_sha' "$ROOT_DIR/scripts/manaloom_build_beta_release.sh"
grep -Fq 'MANALOOM_RELEASE_OBSERVABILITY_EVIDENCE' "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq 'SOURCE_IDENTITY_JSON' "$ROOT_DIR/scripts/manaloom_release_observability_gate.sh"
grep -Fq 'artifact_installation: "confirmed"' "$ROOT_DIR/scripts/manaloom_release_observability_gate.sh"
grep -Fq 'MANALOOM_RELEASE_STARTUP_PROOF status=captured' "$ROOT_DIR/scripts/manaloom_release_observability_gate.sh"
grep -Fq 'scope: "exact_signed_apk"' "$ROOT_DIR/scripts/manaloom_release_observability_gate.sh"
grep -Fq -- '--dart-define="RELEASE_STARTUP_PROOF=true"' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq -- "--env-add MANALOOM_ALLOWED_ORIGINS='\$ALLOWED_ORIGINS_CANONICAL'" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'spec_allowed_origins_sha256' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'runtime_allowed_origins_sha256' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq "source \"\$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh\"" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'BEGIN TRANSACTION READ ONLY;' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq "name = 'add_privacy_and_post_game_sync_contracts'" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq "name = 'persist_deck_validation_review_state'" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq "name = 'align_cards_reserved_runtime_schema'" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'migration_039_ready' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'migration_040_ready' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'require_live_mutation_approval "deploy do backend ManaLoom"' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'readonly LIVE_MUTATION_APPROVED=1' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq '.checks.battle_runtime.status == "healthy"' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq '.checks.battle_runtime.engines.xmage.status == "healthy"' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq '.checks.battle_runtime.engines.forge.status == "healthy"' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq '.checks.battle_runtime.engines.native.status == "healthy"' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq '.checks.battle_runtime.mode == "auto"' "$ROOT_DIR/scripts/manaloom_product_smoke.sh"
grep -Fq 'FROM dart:3.12.2@sha256:13140e26d84f4fda57cea31942222112aeb2eec10e5e6874c1c0f70beed189ab' "$ROOT_DIR/server/Dockerfile"
grep -Fq 'RUN mkdir -p /out' "$ROOT_DIR/server/Dockerfile"
grep -Fq 'dart run dart_frog_cli:dart_frog build' "$ROOT_DIR/server/Dockerfile"
grep -Fq 'dart compile exe build/bin/server.dart' "$ROOT_DIR/server/Dockerfile"
grep -Fq 'USER 10001:10001' "$ROOT_DIR/server/Dockerfile"
if awk '/ AS runtime$/{runtime=1} runtime{print}' "$ROOT_DIR/server/Dockerfile" | \
  grep -Fq 'COPY server/ .'; then
  echo "runtime backend ainda copia source/testes" >&2
  exit 1
fi
grep -Fq -- '--read-only' "$ROOT_DIR/server/bin/with_new_server_pg.sh"
# Contract checks intentionally match literal shell source.
# shellcheck disable=SC2016
grep -Fq 'load_manaloom_env_keys "$ENV_FILE"' "$ROOT_DIR/server/bin/with_new_server_pg.sh"
grep -Fq 'MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256' "$ROOT_DIR/server/bin/with_new_server_pg.sh"
grep -Fq '[[ "$line" == \#* ]] && continue' "$ROOT_DIR/server/bin/with_new_server_pg.sh"
grep -Fq '[[ "$line" == \#* ]] && continue' "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
grep -Fq 'require_postgres_write_approval' "$ROOT_DIR/server/bin/with_new_server_pg.sh"
grep -Fq '<verify-metadata>true</verify-metadata>' "$ROOT_DIR/app/android/gradle/verification-metadata.xml"
for deploy_script in \
  scripts/manaloom_deploy_backend_image.sh \
  scripts/manaloom_deploy_flutter_web.sh \
  scripts/manaloom_deploy_public_web.sh \
  scripts/manaloom_publish_android_release.sh; do
  # Contract checks intentionally match literal shell source.
  # shellcheck disable=SC2016
  grep -Fq 'initialize_manaloom_secure_ssh "$SSH_HOST"' "$ROOT_DIR/$deploy_script"
done
grep -Fq 'validate_manaloom_easypanel_base_url' "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'validate_manaloom_easypanel_base_url' "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq 'validate_manaloom_easypanel_base_url' "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq 'FROM nginx:1.30.3-alpine@sha256:0d3b80406a13a767339fbe2f41406d6c7da727ab89cf8fae399e81f780f814d1' "$ROOT_DIR/app/Dockerfile.web"
grep -Fq "docker image inspect '\$IMAGE_REPO:\$short_sha'" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq -- "--image '\$image_digest_ref'" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq "image_digest_ref: \$image_digest_ref" "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq "docker image inspect '\$IMAGE'" "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq "1/1|\$IMAGE_DIGEST_REF|\$IMAGE_DIGEST_REF" "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
grep -Fq "image_digest_ref: \$image_digest_ref" "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
if grep -Fq '%%@*' \
  "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh" \
  "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"; then
  echo "deploy de container removeu o digest antes de validar convergencia" >&2
  exit 1
fi

printf '{"status":"passed","contracts":%s}\n' "${#SHELL_SCRIPTS[@]}"

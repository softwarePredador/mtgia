#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
FIXTURE_ROOT="$(mktemp -d /tmp/manaloom-release-capabilities.XXXXXX)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

REPO="$FIXTURE_ROOT/repo"
REMOTE="$FIXTURE_ROOT/origin.git"
git init --bare --quiet "$REMOTE"
git init --quiet "$REPO"
git -C "$REPO" config user.name contract-test
git -C "$REPO" config user.email contract-test@localhost
mkdir -p "$REPO/app" "$REPO/server/config"
printf 'version: 1.0.0+1\n' > "$REPO/app/pubspec.yaml"
cp "$ROOT_DIR/server/config/release_capabilities.json" \
  "$REPO/server/config/release_capabilities.json"
git -C "$REPO" add app/pubspec.yaml server/config/release_capabilities.json
git -C "$REPO" commit --quiet -m fixture
git -C "$REPO" branch -M master
git -C "$REPO" remote add origin "$REMOTE"
git -C "$REPO" push --quiet -u origin master
SHA="$(git -C "$REPO" rev-parse HEAD)"

IDENTITY_JSON="$(
  MANALOOM_RELEASE_ROOT_DIR="$REPO" \
  MANALOOM_RELEASE_SOURCE_SHA="$SHA" \
  MANALOOM_RELEASE_FETCH_ORIGIN=0 \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
EXPECTED_DIGEST="$(shasum -a 256 "$REPO/server/config/release_capabilities.json" | awk '{print $1}')"
EXPECTED_COUNT="$(jq -r '.capabilities | length' "$REPO/server/config/release_capabilities.json")"
[[ "$EXPECTED_DIGEST" == \
  "ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d" ]]
jq -e \
  --arg sha "$SHA" \
  --arg digest "$EXPECTED_DIGEST" \
  --argjson count "$EXPECTED_COUNT" '
  .git_sha == $sha and
  .release_capabilities.schema_version == "release_capabilities_v1" and
  .release_capabilities.configuration_status == "valid" and
  .release_capabilities.policy_digest_sha256 == $digest and
  .release_capabilities.capability_count == $count and
  (.release_capabilities.capabilities | length) == $count and
  all(.release_capabilities.capabilities[];
    .release_capability == "off" and .allowed == false)
' >/dev/null <<<"$IDENTITY_JSON"

# The shell gate, source blob and backend parser must name the same closed set.
# shellcheck source=scripts/lib/manaloom_release_capabilities_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh"
jq -e --argjson expected "$MANALOOM_RELEASE_CAPABILITY_KEYS_JSON" \
  '.capabilities | keys == $expected' \
  "$ROOT_DIR/server/config/release_capabilities.json" >/dev/null
BACKEND_KEYS_JSON="$(
  sed -n "/^const releaseCapabilityKeys = <String>{/,/^};/p" \
    "$ROOT_DIR/server/lib/release_capability_policy.dart" |
    sed -nE "s/^[[:space:]]*'([^']+)',/\1/p" |
    jq -Rsc 'split("\n") | map(select(length > 0)) | sort'
)"
jq -e --argjson expected "$MANALOOM_RELEASE_CAPABILITY_KEYS_JSON" \
  '$expected == sort' >/dev/null <<<"$BACKEND_KEYS_JSON"

manaloom_load_release_capabilities_from_git "$REPO" "$SHA"
if manaloom_require_public_app_release_open \
  "$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON" >/dev/null 2>&1; then
  echo "contrato abriu /app com a matriz all-OFF" >&2
  exit 1
fi
PUBLIC_APP_OPEN_FIXTURE="$(jq -c '
  .live_verified_as_of = "2026-08-14T18:30:00Z" |
  .capabilities.catalog_private.release_capability = "on" |
  .capabilities.catalog_private.allowed = true |
  .capabilities.catalog_private.live_verified_as_of = "2026-08-14T18:30:00Z"
' <<<"$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON")"
manaloom_require_public_app_release_open "$PUBLIC_APP_OPEN_FIXTURE"
PUBLIC_APP_UNVERIFIED_FIXTURE="$(jq -c \
  '.live_verified_as_of = null' <<<"$PUBLIC_APP_OPEN_FIXTURE")"
if manaloom_require_public_app_release_open \
  "$PUBLIC_APP_UNVERIFIED_FIXTURE" >/dev/null 2>&1; then
  echo "contrato abriu /app sem verificacao live datada" >&2
  exit 1
fi

expect_invalid_policy() {
  local label="$1"
  local filter="$2"
  jq "$filter" "$ROOT_DIR/server/config/release_capabilities.json" \
    > "$REPO/server/config/release_capabilities.json"
  git -C "$REPO" add server/config/release_capabilities.json
  git -C "$REPO" commit --quiet -m "$label"
  local invalid_sha
  invalid_sha="$(git -C "$REPO" rev-parse HEAD)"
  if (
    source "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh"
    manaloom_load_release_capabilities_from_git "$REPO" "$invalid_sha"
  ) 2>/dev/null; then
    # shellcheck disable=SC2031
    echo "contrato aceitou policy invalida: $label" >&2
    exit 1
  fi
}

expect_invalid_policy missing-key 'del(.capabilities.ads)'
expect_invalid_policy extra-key '.capabilities.unknown_capability = .capabilities.ads'
expect_invalid_policy non-default-deny '.capabilities.ads.allowed = true'

git -C "$REPO" rm --quiet server/config/release_capabilities.json
git -C "$REPO" commit --quiet -m missing-policy
MISSING_POLICY_SHA="$(git -C "$REPO" rev-parse HEAD)"
if (
  source "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh"
  manaloom_load_release_capabilities_from_git "$REPO" "$MISSING_POLICY_SHA"
) 2>/dev/null; then
  echo "contrato aceitou policy ausente" >&2
  exit 1
fi

if (
  source "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh"
  manaloom_load_release_capabilities_from_git "$REPO" "$SHA"
  unknown_json="$(jq -c '.unexpected = true' \
    <<<"$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON")"
  manaloom_require_exact_release_capabilities fixture "$unknown_json"
) 2>/dev/null; then
  echo "contrato aceitou chave desconhecida no receipt" >&2
  exit 1
fi

for script in \
  manaloom_build_android_release.sh \
  manaloom_deploy_flutter_web.sh \
  manaloom_build_beta_release.sh \
  manaloom_publish_android_release.sh \
  manaloom_deploy_backend_image.sh; do
  grep -Fq 'release_capabilities' "$ROOT_DIR/scripts/$script"
done
# These assertions intentionally match literal jq source.
# shellcheck disable=SC2016
grep -Fq '.release_capabilities == $release_capabilities' \
  "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
# shellcheck disable=SC2016
grep -Fq '.release_capabilities == $release_capabilities' \
  "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq 'manaloom_require_exact_release_capabilities' \
  "$ROOT_DIR/scripts/manaloom_deploy_backend_image.sh"
grep -Fq 'manaloom_require_public_app_release_open' \
  "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"

BATTLE_SIDECAR_DEPLOY="$ROOT_DIR/scripts/manaloom_deploy_battle_sidecars.sh"
grep -Fq 'manaloom_load_release_capabilities_from_git' \
  "$BATTLE_SIDECAR_DEPLOY"
grep -Fq 'battle_batch, battle_live e battle_coach estao off no SHA committed' \
  "$BATTLE_SIDECAR_DEPLOY"
capability_gate_line="$(grep -n -m1 'manaloom_load_release_capabilities_from_git' \
  "$BATTLE_SIDECAR_DEPLOY" | cut -d: -f1)"
capability_block_line="$(grep -n -m1 'battle_batch, battle_live e battle_coach estao off no SHA committed' \
  "$BATTLE_SIDECAR_DEPLOY" | cut -d: -f1)"
approval_gate_line="$(grep -n -m1 'require_live_mutation_approval' \
  "$BATTLE_SIDECAR_DEPLOY" | cut -d: -f1)"
first_archive_line="$(grep -n -m1 'git archive' \
  "$BATTLE_SIDECAR_DEPLOY" | cut -d: -f1)"
if (( capability_gate_line >= approval_gate_line ||
      capability_block_line >= approval_gate_line ||
      capability_gate_line >= first_archive_line )); then
  echo "deploy dos sidecars valida capabilities tarde demais" >&2
  exit 1
fi

echo "manaloom release capabilities contract: PASS"

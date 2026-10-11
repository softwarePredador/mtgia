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
cp "$ROOT_DIR/server/config/release_capabilities_cohort.json" \
  "$REPO/server/config/release_capabilities_cohort.json"
git -C "$REPO" add app/pubspec.yaml server/config/release_capabilities.json \
  server/config/release_capabilities_cohort.json
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
  "ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d" ]] || {
  echo "digest de server/config/release_capabilities.json mudou: $EXPECTED_DIGEST" >&2
  exit 1
}
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

# D-13: a matriz all-OFF sai como release de plano de controle; com capability
# on, o gate de abertura decide; matriz incoerente nunca vira plano de controle.
resolved_mode() {
  (
    manaloom_resolve_public_app_release_mode "$1" >/dev/null 2>&1 || exit 2
    printf '%s' "$MANALOOM_PUBLIC_APP_RELEASE_MODE"
  )
}
[[ "$(resolved_mode "$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON")" == "control_plane" ]] || {
  echo "D-13: a matriz all-OFF nao saiu como plano de controle" >&2; exit 1; }
[[ "$(resolved_mode "$PUBLIC_APP_OPEN_FIXTURE")" == "product_open" ]] || {
  echo "D-13: a abertura verificada nao saiu como product_open" >&2; exit 1; }
for incoherent in "$PUBLIC_APP_UNVERIFIED_FIXTURE" \
  "$(jq -c '.capabilities.ads.allowed = true' <<<"$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON")" \
  "$(jq -c '.capabilities.ads.release_capability = "on"' <<<"$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON")" \
  "$(jq -c '.capabilities = {}' <<<"$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON")" \
  'nao e json'; do
  if resolved_mode "$incoherent" >/dev/null; then
    echo "D-13: matriz incoerente virou release do /app: $incoherent" >&2
    exit 1
  fi
done

expect_invalid_policy() {
  local label="$1"
  local filter="$2"
  git -C "$REPO" show \
    "$SHA:server/config/release_capabilities.json" |
    jq "$filter" > "$REPO/server/config/release_capabilities.json"
  git -C "$REPO" add server/config/release_capabilities.json
  git -C "$REPO" commit --quiet -m "$label"
  local invalid_sha
  invalid_sha="$(git -C "$REPO" rev-parse HEAD)"
  if bash -c '
    set -euo pipefail
    source "$1"
    manaloom_load_release_capabilities_from_git "$2" "$3"
  ' _ "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh" \
    "$REPO" "$invalid_sha" 2>/dev/null; then
    # shellcheck disable=SC2031
    echo "contrato aceitou policy invalida: $label" >&2
    exit 1
  fi
}

expect_invalid_policy missing-key 'del(.capabilities.ads)'
expect_invalid_policy extra-key '.capabilities.unknown_capability = .capabilities.ads'
expect_invalid_policy non-default-deny '.capabilities.ads.allowed = true'
expect_invalid_policy invalid-release-enum \
  '.capabilities.ads.release_capability = "future_unknown"'
expect_invalid_policy invalid-allowed-type '.capabilities.ads.allowed = "false"'
expect_invalid_policy invalid-top-level-implementation-status \
  '.implementation_status = "future_unknown"'
expect_invalid_policy invalid-entry-implementation-status \
  '.capabilities.battle_batch.implementation_status = "future_unknown"'

# S-07 / BT-COH-001 (D-104): sem pedido, so as 29 off; com
# MANALOOM_RELEASE_CAPABILITY_MATRIX=cohort-2026-10, so a matriz da coorte, com a
# politica versionada da matriz no mesmo SHA. Qualquer outra recusa.
# jq source, not shell expansion.
# shellcheck disable=SC2016
COHORT_FILTER='reduce ("account_registration", "catalog_private",
  "collection_private", "decks_private", "life_counter_local") as $key (.;
  .capabilities[$key].release_capability = "on" |
  .capabilities[$key].allowed = true)'
commit_matrix_fixture() {
  local label="$1" policy_filter="$2" matrix_filter="${3:-.}"
  git -C "$REPO" show "$SHA:server/config/release_capabilities.json" |
    jq "$policy_filter" > "$REPO/server/config/release_capabilities.json"
  if [[ "$matrix_filter" == "absent" ]]; then
    rm -f "$REPO/server/config/release_capabilities_cohort.json"
  else
    git -C "$REPO" show "$SHA:server/config/release_capabilities_cohort.json" |
      jq "$matrix_filter" > "$REPO/server/config/release_capabilities_cohort.json"
  fi
  git -C "$REPO" add -A server/config
  git -C "$REPO" commit --quiet --allow-empty -m "$label"
  git -C "$REPO" rev-parse HEAD
}
load_with_matrix() {
  local matrix="$1" candidate_sha="$2"
  MANALOOM_RELEASE_CAPABILITY_MATRIX="$matrix" bash -c '
    set -euo pipefail
    source "$1"
    manaloom_load_release_capabilities_from_git "$2" "$3"
    printf "%s|%s|%s\n" "$MANALOOM_RELEASE_CAPABILITY_MATRIX_NAME" \
      "$MANALOOM_RELEASE_CAPABILITIES_ON_JSON" \
      "$MANALOOM_RELEASE_CAPABILITIES_ON_PYTHON"
  ' _ "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh" \
    "$REPO" "$candidate_sha"
}
expect_matrix_refused() {
  local label="$1" matrix="$2" candidate_sha="$3"
  if load_with_matrix "$matrix" "$candidate_sha" >/dev/null 2>&1; then
    echo "S-07: contrato aceitou $label (matriz pedida: '${matrix:-nenhuma}')" >&2
    exit 1
  fi
}

[[ "$(load_with_matrix "" "$SHA")" == "all-off|[]|[]" ]] || {
  echo "S-07: o padrao sem pedido deixou de ser as 29 off" >&2; exit 1; }
COHORT_SHA="$(commit_matrix_fixture cohort "$COHORT_FILTER")"
EXPECTED_COHORT='cohort-2026-10|["account_registration","catalog_private","collection_private","decks_private","life_counter_local"]'
EXPECTED_COHORT+="|['account_registration', 'catalog_private', 'collection_private', 'decks_private', 'life_counter_local']"
[[ "$(load_with_matrix cohort-2026-10 "$COHORT_SHA")" == "$EXPECTED_COHORT" ]] || {
  echo "S-07: a matriz da coorte pedida explicitamente foi recusada" >&2; exit 1; }
expect_matrix_refused "a matriz da coorte sem pedido explicito" "" "$COHORT_SHA"
expect_matrix_refused "a matriz all-OFF quando a coorte foi pedida" \
  cohort-2026-10 "$SHA"
expect_matrix_refused "matriz desconhecida" cohort-2026-11 "$COHORT_SHA"
expect_matrix_refused "pedido all-off explicito fora da lista fechada" \
  all-off "$SHA"
expect_matrix_refused "a coorte com uma capability a mais (ads)" cohort-2026-10 \
  "$(commit_matrix_fixture cohort-plus-ads "$COHORT_FILTER |
    .capabilities.ads.release_capability = \"on\" |
    .capabilities.ads.allowed = true")"
expect_matrix_refused "a coorte com uma capability a menos" cohort-2026-10 \
  "$(commit_matrix_fixture cohort-minus-life-counter "$COHORT_FILTER |
    .capabilities.life_counter_local.release_capability = \"off\" |
    .capabilities.life_counter_local.allowed = false")"
expect_matrix_refused "capability on com allowed=false" cohort-2026-10 \
  "$(commit_matrix_fixture cohort-on-not-allowed "$COHORT_FILTER |
    .capabilities.decks_private.allowed = false")"
expect_matrix_refused "politica da matriz com uma capability a mais" \
  cohort-2026-10 \
  "$(commit_matrix_fixture matrix-plus-ads "$COHORT_FILTER" \
    '.capabilities_on = (.capabilities_on + ["ads"] | sort)')"
expect_matrix_refused "politica da matriz com cadastro aberto" cohort-2026-10 \
  "$(commit_matrix_fixture matrix-open-registration "$COHORT_FILTER" \
    '.registration_admission = "open"')"
expect_matrix_refused "politica da matriz com outro nome" cohort-2026-10 \
  "$(commit_matrix_fixture matrix-renamed "$COHORT_FILTER" \
    '.matrix = "cohort-2026-11"')"
expect_matrix_refused "politica da matriz ausente no SHA" cohort-2026-10 \
  "$(commit_matrix_fixture matrix-absent "$COHORT_FILTER" absent)"

MIXED_DIGEST_JSON="$(jq -c \
  '.policy_digest_sha256 = ("b" * 64)' \
  <<<"$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON")"
if manaloom_require_exact_release_capabilities \
  mixed-digest "$MIXED_DIGEST_JSON" >/dev/null 2>&1; then
  echo "contrato aceitou digest de policy misto" >&2
  exit 1
fi

git -C "$REPO" rm --quiet server/config/release_capabilities.json
git -C "$REPO" commit --quiet -m missing-policy
MISSING_POLICY_SHA="$(git -C "$REPO" rev-parse HEAD)"
if bash -c '
  set -euo pipefail
  source "$1"
  manaloom_load_release_capabilities_from_git "$2" "$3"
' _ "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh" \
  "$REPO" "$MISSING_POLICY_SHA" 2>/dev/null; then
  echo "contrato aceitou policy ausente" >&2
  exit 1
fi

if (
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
grep -Fq 'manaloom_resolve_public_app_release_mode' \
  "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
if grep -Eq '^[[:space:]]*manaloom_require_public_app_release_open' \
  "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"; then
  echo "D-13: o deploy do /app voltou a exigir capability on com a matriz all-OFF" >&2
  exit 1
fi

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

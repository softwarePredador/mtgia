#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

for tool in git jq shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done

IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="${MANALOOM_RELEASE_SOURCE_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}" \
  MANALOOM_RELEASE_REQUIRE_CLEAN=1 \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
SHA="$(jq -r '.git_sha' <<<"$IDENTITY_JSON")"
SHORT_SHA="$(jq -r '.short_sha' <<<"$IDENTITY_JSON")"
VERSION="$(jq -r '.version' <<<"$IDENTITY_JSON")"
RELEASE_DIR="${MANALOOM_RELEASE_DIR:-$HOME/.manaloom/releases/$VERSION/$SHORT_SHA}"
mkdir -p "$RELEASE_DIR"

common_env=(
  MANALOOM_RELEASE_SOURCE_SHA="$SHA"
  MANALOOM_RELEASE_REQUIRE_CLEAN=1
  MANALOOM_RELEASE_REQUIRE_SENTRY="${MANALOOM_RELEASE_REQUIRE_SENTRY:-0}"
  MANALOOM_RELEASE_DIR="$RELEASE_DIR"
)

env "${common_env[@]}" \
  MANALOOM_RELEASE_BUILD_ONLY=1 \
  "$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"

env "${common_env[@]}" \
  "$ROOT_DIR/scripts/manaloom_build_android_release.sh"

ANDROID_MANIFEST="$RELEASE_DIR/release-manifest.json"
WEB_MANIFEST="$RELEASE_DIR/web/release.json"
APK="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.apk"
AAB="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.aab"
for artifact in "$ANDROID_MANIFEST" "$WEB_MANIFEST" "$APK" "$AAB"; do
  if [[ ! -f "$artifact" ]]; then
    echo "artefato beta ausente: $artifact" >&2
    exit 1
  fi
done
(
  cd "$RELEASE_DIR"
  shasum -a 256 -c SHA256SUMS >/dev/null
)
(
  cd "$RELEASE_DIR/web"
  shasum -a 256 -c SHA256SUMS >/dev/null
)

jq -e --arg sha "$SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version and .platform == "android"' \
  "$ANDROID_MANIFEST" >/dev/null
jq -e --arg sha "$SHA" --arg version "$VERSION" \
  '.git_sha == $sha and .version == $version and .platform == "web"' \
  "$WEB_MANIFEST" >/dev/null

APK_SHA256="$(shasum -a 256 "$APK" | awk '{print $1}')"
AAB_SHA256="$(shasum -a 256 "$AAB" | awk '{print $1}')"
WEB_MANIFEST_SHA256="$(shasum -a 256 "$WEB_MANIFEST" | awk '{print $1}')"
ANDROID_MANIFEST_SHA256="$(shasum -a 256 "$ANDROID_MANIFEST" | awk '{print $1}')"
ANDROID_SENTRY_CONFIGURED="$(jq -r '.sentry_configured' "$ANDROID_MANIFEST")"
WEB_SENTRY_CONFIGURED="$(jq -r '.sentry_configured' "$WEB_MANIFEST")"
PUBLISHABLE_WITH_SENTRY=false
if [[ "$ANDROID_SENTRY_CONFIGURED" == "true" && "$WEB_SENTRY_CONFIGURED" == "true" ]]; then
  PUBLISHABLE_WITH_SENTRY=true
fi
jq -n \
  --arg version "$VERSION" \
  --arg git_sha "$SHA" \
  --arg short_sha "$SHORT_SHA" \
  --arg apk "$(basename "$APK")" \
  --arg apk_sha256 "$APK_SHA256" \
  --arg aab "$(basename "$AAB")" \
  --arg aab_sha256 "$AAB_SHA256" \
  --arg android_manifest_sha256 "$ANDROID_MANIFEST_SHA256" \
  --arg web_manifest_sha256 "$WEB_MANIFEST_SHA256" \
  --argjson publishable_with_sentry "$PUBLISHABLE_WITH_SENTRY" \
  '{
    schema_version: 1,
    status: "candidate_built",
    channel: "free_beta",
    version: $version,
    git_sha: $git_sha,
    short_sha: $short_sha,
    publishable_with_sentry: $publishable_with_sentry,
    subjects: {
      android_apk: {file: $apk, sha256: $apk_sha256},
      android_aab: {file: $aab, sha256: $aab_sha256},
      android_manifest: {file: "release-manifest.json", sha256: $android_manifest_sha256},
      web_manifest: {file: "web/release.json", sha256: $web_manifest_sha256}
    },
    identity_invariant: "web.git_sha == android.git_sha == source.git_sha"
  }' > "$RELEASE_DIR/beta-candidate.json"

(
  cd "$RELEASE_DIR"
  shasum -a 256 beta-candidate.json > beta-candidate.SHA256SUMS
)

printf '{"status":"candidate_built","channel":"free_beta","version":"%s","git_sha":"%s","release_dir":"%s","manifest":"%s"}\n' \
  "$VERSION" "$SHA" "$RELEASE_DIR" "$RELEASE_DIR/beta-candidate.json"

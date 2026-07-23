#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
API_BASE_URL="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
KEYSTORE="${MANALOOM_ANDROID_KEYSTORE:-$HOME/.manaloom/signing/android/manaloom-upload.jks}"
KEY_ALIAS="${MANALOOM_ANDROID_KEY_ALIAS:-manaloom-upload}"
STORE_PASSWORD_SERVICE="${MANALOOM_ANDROID_STORE_PASSWORD_SERVICE:-manaloom-android-upload-store-password}"
KEY_PASSWORD_SERVICE="${MANALOOM_ANDROID_KEY_PASSWORD_SERVICE:-manaloom-android-upload-key-password}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

for tool in git jarsigner jq keytool python3 security shasum unzip; do
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
if [[ -z "${SENTRY_MOBILE_DSN:-}" ]]; then
  SENTRY_MOBILE_DSN="$(read_manaloom_keychain_secret \
    "$MANALOOM_SENTRY_DSN_KEYCHAIN_SERVICE" || true)"
fi
resolve_manaloom_release_java
resolve_manaloom_android_build_tools

if [[ ! -f "$KEYSTORE" ]]; then
  echo "keystore Android ausente: $KEYSTORE" >&2
  exit 2
fi

# Shared release identity enforces source == HEAD == origin/master and a clean
# checkout before any signed artifact is produced.
IDENTITY_JSON="$(
  MANALOOM_RELEASE_SOURCE_SHA="${MANALOOM_RELEASE_SOURCE_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}" \
    "$ROOT_DIR/scripts/manaloom_release_identity.sh"
)"
SHA="$(jq -r '.git_sha' <<<"$IDENTITY_JSON")"
SHORT_SHA="$(jq -r '.short_sha' <<<"$IDENTITY_JSON")"
VERSION="$(jq -r '.version' <<<"$IDENTITY_JSON")"
SOURCE_COMMITTED_AT="$(jq -r '.source_committed_at' <<<"$IDENTITY_JSON")"
VERSION_CODE="${VERSION##*+}"
if [[ -n "${MANALOOM_ANDROID_MIN_VERSION_CODE:-}" &&
      ! "${MANALOOM_ANDROID_MIN_VERSION_CODE}" =~ ^[1-9][0-9]*$ ]]; then
  echo "MANALOOM_ANDROID_MIN_VERSION_CODE deve ser inteiro positivo" >&2
  exit 2
fi
if [[ -n "${MANALOOM_ANDROID_MIN_VERSION_CODE:-}" &&
      "$VERSION_CODE" -lt "$MANALOOM_ANDROID_MIN_VERSION_CODE" ]]; then
  echo "versionCode $VERSION_CODE abaixo do minimo exigido ${MANALOOM_ANDROID_MIN_VERSION_CODE}" >&2
  exit 2
fi
REQUIRE_SENTRY="${MANALOOM_RELEASE_REQUIRE_SENTRY:-0}"
if [[ "$REQUIRE_SENTRY" != "0" && "$REQUIRE_SENTRY" != "1" ]]; then
  echo "MANALOOM_RELEASE_REQUIRE_SENTRY deve ser 0 ou 1" >&2
  exit 2
fi
if [[ "$REQUIRE_SENTRY" == "1" && -z "${SENTRY_MOBILE_DSN:-}" ]]; then
  echo "build Android recusado: SENTRY_MOBILE_DSN ausente" >&2
  exit 2
fi
SENTRY_RELEASE_DSN="${SENTRY_MOBILE_DSN:-}"
resolve_manaloom_release_sentry_dsn "$SENTRY_RELEASE_DSN" "$REQUIRE_SENTRY"

STORE_PASSWORD="$(security find-generic-password -a "$USER" -s "$STORE_PASSWORD_SERVICE" -w)"
KEY_PASSWORD="$(security find-generic-password -a "$USER" -s "$KEY_PASSWORD_SERVICE" -w)"
WORKTREE_DIR="$(mktemp -d /tmp/manaloom-android-release.XXXXXX)"
RELEASE_DIR="${MANALOOM_RELEASE_DIR:-$HOME/.manaloom/releases/$VERSION/$SHORT_SHA}"

cleanup() {
  rm -f "$WORKTREE_DIR/app/android/key.properties" 2>/dev/null || true
  git -C "$ROOT_DIR" worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

git -C "$ROOT_DIR" worktree add --detach "$WORKTREE_DIR" "$SHA" >/dev/null
umask 077
{
  printf 'storePassword=%s\n' "$STORE_PASSWORD"
  printf 'keyPassword=%s\n' "$KEY_PASSWORD"
  printf 'keyAlias=%s\n' "$KEY_ALIAS"
  printf 'storeFile=%s\n' "$KEYSTORE"
} > "$WORKTREE_DIR/app/android/key.properties"

GRADLE_LOCK_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/android/app/gradle.lockfile" | awk '{print $1}')"
GRADLE_DISTRIBUTION_SHA256="$(
  awk -F= '/^distributionSha256Sum=/{print $2; exit}' \
    "$WORKTREE_DIR/app/android/gradle/wrapper/gradle-wrapper.properties"
)"
JAVA_VERSION="$($MANALOOM_RELEASE_JAVA_BIN_RESOLVED -XshowSettings:properties -version 2>&1 | awk -F'= ' '/^[[:space:]]*java.runtime.version =/{print $2; exit}')"
APKSIGNER_SHA256="$(shasum -a 256 "$MANALOOM_APKSIGNER" | awk '{print $1}')"
AAPT_SHA256="$(shasum -a 256 "$MANALOOM_AAPT" | awk '{print $1}')"
jq -n \
  --arg git_sha "$SHA" \
  --arg version "$VERSION" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  --arg flutter_version "$MANALOOM_RELEASE_FLUTTER_VERSION" \
  --arg flutter_revision "$MANALOOM_RELEASE_FLUTTER_REVISION" \
  --arg engine_revision "$MANALOOM_RELEASE_FLUTTER_ENGINE_REVISION" \
  --arg dart_version "$MANALOOM_RELEASE_DART_VERSION" \
  --arg gradle_distribution_sha256 "$GRADLE_DISTRIBUTION_SHA256" \
  --arg gradle_lock_sha256 "$GRADLE_LOCK_SHA256" \
  --arg java_version "$JAVA_VERSION" \
  --arg java_vendor "$MANALOOM_RELEASE_JAVA_VENDOR" \
  --arg android_build_tools_version "$MANALOOM_ANDROID_BUILD_TOOLS_VERSION" \
  --arg apksigner_sha256 "$APKSIGNER_SHA256" \
  --arg aapt_sha256 "$AAPT_SHA256" \
  '{
    schema_version: 1,
    status: "release",
    release_identity_embedded: true,
    features: {
      scanner_release_enabled: true
    },
    git_sha: $git_sha,
    version: $version,
    api_base_url: $api_base_url,
    sentry_dsn_sha256: (if ($sentry_dsn_sha256 | length) > 0 then $sentry_dsn_sha256 else null end),
    toolchain: {
      flutter_version: $flutter_version,
      flutter_revision: $flutter_revision,
      engine_revision: $engine_revision,
      dart_version: $dart_version,
      gradle_distribution_sha256: $gradle_distribution_sha256,
      gradle_lock_sha256: $gradle_lock_sha256,
      java_version: $java_version,
      java_vendor: $java_vendor,
      android_build_tools_version: $android_build_tools_version,
      apksigner_sha256: $apksigner_sha256,
      aapt_sha256: $aapt_sha256
    }
  }' > "$WORKTREE_DIR/app/assets/release/release-identity.json"
EMBEDDED_IDENTITY_SOURCE_SHA256="$(shasum -a 256 "$WORKTREE_DIR/app/assets/release/release-identity.json" | awk '{print $1}')"

build_args=(
  --release
  --dart-define="API_BASE_URL=$API_BASE_URL"
  --dart-define="PUBLIC_API_BASE_URL=$API_BASE_URL"
  --dart-define="SENTRY_ENVIRONMENT=production"
  --dart-define="SENTRY_RELEASE=manaloom-android@$SHORT_SHA"
  --dart-define="RELEASE_GIT_SHA=$SHA"
  --dart-define="RELEASE_IDENTITY_SHA256=$EMBEDDED_IDENTITY_SOURCE_SHA256"
  --dart-define="RELEASE_STARTUP_PROOF=true"
  --dart-define="ENABLE_SCANNER_RELEASE=true"
  --no-version-check
  --no-pub
)
if [[ -n "$SENTRY_RELEASE_DSN" ]]; then
  build_args+=(--dart-define="SENTRY_DSN=$SENTRY_RELEASE_DSN")
fi

(
  cd "$WORKTREE_DIR/app"
  "$MANALOOM_FLUTTER_BIN_RESOLVED" pub get --enforce-lockfile
  "$MANALOOM_FLUTTER_BIN_RESOLVED" build appbundle "${build_args[@]}"
  "$MANALOOM_FLUTTER_BIN_RESOLVED" build apk "${build_args[@]}"
)

mkdir -p "$RELEASE_DIR"
APK="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.apk"
AAB="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.aab"
cp "$WORKTREE_DIR/app/build/app/outputs/flutter-apk/app-release.apk" "$APK"
cp "$WORKTREE_DIR/app/build/app/outputs/bundle/release/app-release.aab" "$AAB"
chmod 600 "$APK" "$AAB"

APK_EMBEDDED_IDENTITY="$(unzip -p "$APK" assets/flutter_assets/assets/release/release-identity.json)"
AAB_EMBEDDED_IDENTITY="$(unzip -p "$AAB" base/assets/flutter_assets/assets/release/release-identity.json)"
EXPECTED_EMBEDDED_IDENTITY="$(jq -cS . "$WORKTREE_DIR/app/assets/release/release-identity.json")"
if [[ "$(jq -cS . <<<"$APK_EMBEDDED_IDENTITY")" != "$EXPECTED_EMBEDDED_IDENTITY" ||
      "$(jq -cS . <<<"$AAB_EMBEDDED_IDENTITY")" != "$EXPECTED_EMBEDDED_IDENTITY" ]]; then
  echo "identidade embarcada diverge entre source, APK e AAB" >&2
  exit 1
fi
printf '%s\n' "$EXPECTED_EMBEDDED_IDENTITY" | jq -S . > "$RELEASE_DIR/embedded-release-identity.json"
EMBEDDED_IDENTITY_SHA256="$(shasum -a 256 "$RELEASE_DIR/embedded-release-identity.json" | awk '{print $1}')"

APKSIGNER="$MANALOOM_APKSIGNER"
AAPT="$MANALOOM_AAPT"

APK_CERT="$($APKSIGNER verify --verbose --print-certs "$APK" | awk -F': ' '/Signer #1 certificate SHA-256 digest:/{print tolower($2); exit}')"
KEY_CERT="$(keytool -list -v -keystore "$KEYSTORE" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" 2>/dev/null | awk -F': ' '/SHA256:/{print tolower($2); exit}' | tr -d ':')"
validate_manaloom_android_release_certificate "$APK_CERT"
if [[ "$APK_CERT" != "$KEY_CERT" ]]; then
  echo "certificado do APK diverge da upload key" >&2
  exit 1
fi

jarsigner -verify "$AAB" >"$RELEASE_DIR/aab-verification.txt" 2>&1
grep -Fq 'jar verified' "$RELEASE_DIR/aab-verification.txt"
BADGING="$($AAPT dump badging "$APK" | head -1)"
printf '%s\n' "$BADGING" | grep -Fq "name='com.mtgia.mtg_app'"
"$WORKTREE_DIR/scripts/manaloom_verify_android_release_artifacts.sh" \
  --apk "$APK" \
  --expected-package com.mtgia.mtg_app \
  --expected-version "$VERSION" \
  --expected-cert-sha256 "$APK_CERT" \
  --report "$RELEASE_DIR/android-verification.json" >/dev/null

printf '%s\n' "$IDENTITY_JSON" > "$RELEASE_DIR/release-identity.json"
python3 "$WORKTREE_DIR/scripts/manaloom_generate_release_sbom.py" \
  --app-dir "$WORKTREE_DIR/app" \
  --dart-bin "$MANALOOM_RELEASE_DART_BIN_RESOLVED" \
  --gradle-lock "$WORKTREE_DIR/app/android/app/gradle.lockfile" \
  --android-release-artifact "$AAB" \
  --git-sha "$SHA" \
  --source-committed-at "$SOURCE_COMMITTED_AT" \
  --output "$RELEASE_DIR/sbom.cdx.json" >/dev/null
python3 "$WORKTREE_DIR/scripts/manaloom_osv_scan_sbom.py" \
  --sbom "$RELEASE_DIR/sbom.cdx.json" \
  --output "$RELEASE_DIR/osv-scan.json" >/dev/null

APK_SHA256="$(shasum -a 256 "$APK" | awk '{print $1}')"
AAB_SHA256="$(shasum -a 256 "$AAB" | awk '{print $1}')"
SBOM_SHA256="$(shasum -a 256 "$RELEASE_DIR/sbom.cdx.json" | awk '{print $1}')"
OSV_SCAN_SHA256="$(shasum -a 256 "$RELEASE_DIR/osv-scan.json" | awk '{print $1}')"
jq -e --arg sbom_sha256 "$SBOM_SHA256" \
  '.schema_version == 2 and .status == "passed" and
   .sbom_sha256 == $sbom_sha256 and .vulnerability_count == 0 and
   .blocking_vulnerability_count == 0 and
   .release_vulnerability_count == 0 and
   .total_vulnerability_count ==
     (.blocking_vulnerability_count + .excluded_vulnerability_count) and
   .observed_vulnerability_count ==
     (.release_vulnerability_count + .non_release_vulnerability_count)' \
  "$RELEASE_DIR/osv-scan.json" >/dev/null
jq -n \
  --arg version "$VERSION" \
  --arg git_sha "$SHA" \
  --arg short_sha "$SHORT_SHA" \
  --arg source_committed_at "$SOURCE_COMMITTED_AT" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_release "manaloom-android@$SHORT_SHA" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  --arg apk "$(basename "$APK")" \
  --arg apk_sha256 "$APK_SHA256" \
  --arg aab "$(basename "$AAB")" \
  --arg aab_sha256 "$AAB_SHA256" \
  --arg sbom_sha256 "$SBOM_SHA256" \
  --arg osv_scan_sha256 "$OSV_SCAN_SHA256" \
  --arg embedded_identity_sha256 "$EMBEDDED_IDENTITY_SHA256" \
  --arg certificate_sha256 "$APK_CERT" \
  --argjson sentry_configured "$([[ -n "$SENTRY_RELEASE_DSN" ]] && printf true || printf false)" \
  '{
    schema_version: 1,
    product: "manaloom",
    platform: "android",
    version: $version,
    git_sha: $git_sha,
    short_sha: $short_sha,
    source_committed_at: $source_committed_at,
    api_base_url: $api_base_url,
    sentry_release: $sentry_release,
    sentry_configured: $sentry_configured,
    sentry_dsn_sha256: (if ($sentry_dsn_sha256 | length) > 0 then $sentry_dsn_sha256 else null end),
    artifacts: {
      apk: {file: $apk, sha256: $apk_sha256},
      aab: {file: $aab, sha256: $aab_sha256},
      sbom: {file: "sbom.cdx.json", sha256: $sbom_sha256},
      vulnerability_scan: {file: "osv-scan.json", sha256: $osv_scan_sha256, status: "passed"},
      embedded_release_identity: {file: "embedded-release-identity.json", sha256: $embedded_identity_sha256}
    },
    signing: {certificate_sha256: $certificate_sha256},
    permissions_gate: "passed"
  }' > "$RELEASE_DIR/release-manifest.json"

jq -n \
  --arg apk "$(basename "$APK")" \
  --arg apk_sha256 "$APK_SHA256" \
  --arg aab "$(basename "$AAB")" \
  --arg aab_sha256 "$AAB_SHA256" \
  --arg sbom_sha256 "$SBOM_SHA256" \
  --arg osv_scan_sha256 "$OSV_SCAN_SHA256" \
  --arg embedded_identity_sha256 "$EMBEDDED_IDENTITY_SHA256" \
  --arg git_sha "$SHA" \
  --arg version "$VERSION" \
  --arg api_base_url "$API_BASE_URL" \
  --arg sentry_dsn_sha256 "$MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED" \
  --arg builder "scripts/manaloom_build_android_release.sh" \
  '{
    _type: "https://in-toto.io/Statement/v1",
    subject: [
      {name: $apk, digest: {sha256: $apk_sha256}},
      {name: $aab, digest: {sha256: $aab_sha256}},
      {name: "sbom.cdx.json", digest: {sha256: $sbom_sha256}},
      {name: "osv-scan.json", digest: {sha256: $osv_scan_sha256}},
      {name: "embedded-release-identity.json", digest: {sha256: $embedded_identity_sha256}}
    ],
    predicateType: "https://slsa.dev/provenance/v1",
    predicate: {
      buildDefinition: {
        buildType: "https://manaloom.local/build/flutter-android-release/v1",
        externalParameters: {
          git_sha: $git_sha,
          version: $version,
          api_base_url: $api_base_url,
          sentry_dsn_sha256: (if ($sentry_dsn_sha256 | length) > 0 then $sentry_dsn_sha256 else null end)
        },
        internalParameters: {builder_script: $builder},
        resolvedDependencies: [{uri: "git+https://github.com/softwarePredador/mtgia.git", digest: {gitCommit: $git_sha}}]
      },
      runDetails: {builder: {id: $builder}, metadata: {invocationId: ($git_sha + ":" + $version)}}
    }
  }' > "$RELEASE_DIR/provenance.intoto.json"

(
  cd "$RELEASE_DIR"
  shasum -a 256 \
    "$(basename "$APK")" \
    "$(basename "$AAB")" \
    android-verification.json \
    embedded-release-identity.json \
    provenance.intoto.json \
    release-identity.json \
    release-manifest.json \
    sbom.cdx.json \
    osv-scan.json > SHA256SUMS
)

printf '{"status":"built","version":"%s","git_sha":"%s","apk":"%s","aab":"%s","certificate_sha256":"%s","manifest":"%s","sbom":"%s","osv_scan":"%s","provenance":"%s"}\n' \
  "$VERSION" "$SHA" "$APK" "$AAB" "$APK_CERT" "$RELEASE_DIR/release-manifest.json" "$RELEASE_DIR/sbom.cdx.json" "$RELEASE_DIR/osv-scan.json" "$RELEASE_DIR/provenance.intoto.json"

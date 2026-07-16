#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
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

for tool in adb flutter git jarsigner keytool security shasum; do
  require_tool "$tool"
done

if [[ ! -f "$KEYSTORE" ]]; then
  echo "keystore Android ausente: $KEYSTORE" >&2
  exit 2
fi

git -C "$ROOT_DIR" fetch origin master --quiet
SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)"
ORIGIN_SHA="$(git -C "$ROOT_DIR" rev-parse origin/master)"
if [[ "$SHA" != "$ORIGIN_SHA" ]]; then
  echo "HEAD local nao esta alinhado com origin/master; faca push antes do build." >&2
  exit 2
fi

SHORT_SHA="$(git -C "$ROOT_DIR" rev-parse --short=12 "$SHA")"
VERSION="$(awk '/^version:/{print $2; exit}' "$ROOT_DIR/app/pubspec.yaml")"
if [[ -z "$VERSION" ]]; then
  echo "versao ausente em app/pubspec.yaml" >&2
  exit 2
fi

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

build_args=(
  --release
  --dart-define="API_BASE_URL=$API_BASE_URL"
  --dart-define="PUBLIC_API_BASE_URL=$API_BASE_URL"
  --dart-define="SENTRY_ENVIRONMENT=production"
  --dart-define="SENTRY_RELEASE=manaloom-android@$SHORT_SHA"
  --no-version-check
)
if [[ -n "${SENTRY_MOBILE_DSN:-}" ]]; then
  build_args+=(--dart-define="SENTRY_DSN=$SENTRY_MOBILE_DSN")
fi

(
  cd "$WORKTREE_DIR/app"
  flutter pub get
  flutter build appbundle "${build_args[@]}"
  flutter build apk "${build_args[@]}"
)

mkdir -p "$RELEASE_DIR"
APK="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.apk"
AAB="$RELEASE_DIR/manaloom-$VERSION-$SHORT_SHA.aab"
cp "$WORKTREE_DIR/app/build/app/outputs/flutter-apk/app-release.apk" "$APK"
cp "$WORKTREE_DIR/app/build/app/outputs/bundle/release/app-release.aab" "$AAB"
chmod 600 "$APK" "$AAB"

APKSIGNER="$(find "$HOME/Library/Android/sdk/build-tools" -type f -name apksigner | sort -V | tail -1)"
AAPT="$(find "$HOME/Library/Android/sdk/build-tools" -type f -name aapt | sort -V | tail -1)"
if [[ -z "$APKSIGNER" || -z "$AAPT" ]]; then
  echo "apksigner/aapt ausente no Android SDK" >&2
  exit 2
fi

APK_CERT="$($APKSIGNER verify --verbose --print-certs "$APK" | awk -F': ' '/Signer #1 certificate SHA-256 digest:/{print tolower($2); exit}')"
KEY_CERT="$(keytool -list -v -keystore "$KEYSTORE" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" 2>/dev/null | awk -F': ' '/SHA256:/{print tolower($2); exit}' | tr -d ':')"
if [[ "$APK_CERT" != "$KEY_CERT" ]]; then
  echo "certificado do APK diverge da upload key" >&2
  exit 1
fi

jarsigner -verify "$AAB" >"$RELEASE_DIR/aab-verification.txt" 2>&1
grep -Fq 'jar verified' "$RELEASE_DIR/aab-verification.txt"
BADGING="$($AAPT dump badging "$APK" | head -1)"
printf '%s\n' "$BADGING" | grep -Fq "name='com.mtgia.mtg_app'"
(
  cd "$RELEASE_DIR"
  shasum -a 256 "$(basename "$APK")" "$(basename "$AAB")" > SHA256SUMS
)

printf '{"status":"built","version":"%s","git_sha":"%s","apk":"%s","aab":"%s","certificate_sha256":"%s"}\n' \
  "$VERSION" "$SHA" "$APK" "$AAB" "$APK_CERT"

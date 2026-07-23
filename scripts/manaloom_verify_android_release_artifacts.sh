#!/usr/bin/env bash
set -euo pipefail

APK=""
EXPECTED_PACKAGE="com.mtgia.mtg_app"
EXPECTED_VERSION=""
EXPECTED_CERT_SHA256=""
REPORT=""

usage() {
  cat <<'EOF'
Uso: manaloom_verify_android_release_artifacts.sh --apk FILE [opcoes]

Opcoes:
  --expected-package ID
  --expected-version SEMVER
  --expected-cert-sha256 HEX
  --report FILE
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apk) APK="${2:-}"; shift 2 ;;
    --expected-package) EXPECTED_PACKAGE="${2:-}"; shift 2 ;;
    --expected-version) EXPECTED_VERSION="${2:-}"; shift 2 ;;
    --expected-cert-sha256) EXPECTED_CERT_SHA256="${2:-}"; shift 2 ;;
    --report) REPORT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$APK" || ! -f "$APK" ]]; then
  echo "APK ausente: ${APK:-nao informado}" >&2
  exit 2
fi

command -v jq >/dev/null 2>&1 || {
  echo "ferramenta obrigatoria ausente: jq" >&2
  exit 2
}

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
ANDROID_BUILD_TOOLS_VERSION="${MANALOOM_ANDROID_BUILD_TOOLS_VERSION:-35.0.0}"
APKSIGNER="${MANALOOM_APKSIGNER:-$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_VERSION/apksigner}"
AAPT="${MANALOOM_AAPT:-$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_VERSION/aapt}"
if [[ -z "$APKSIGNER" || -z "$AAPT" ]]; then
  echo "apksigner/aapt ausente no Android SDK" >&2
  exit 2
fi

VERIFY_OUTPUT="$($APKSIGNER verify --verbose --print-certs "$APK")"
grep -Fxq 'Verifies' <<<"$VERIFY_OUTPUT"

BADGING="$($AAPT dump badging "$APK")"
PACKAGE_LINE="$(awk '/^package:/{print; exit}' <<<"$BADGING")"
PACKAGE_NAME="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<<"$PACKAGE_LINE")"
VERSION_NAME="$(sed -n "s/.*versionName='\([^']*\)'.*/\1/p" <<<"$PACKAGE_LINE")"
VERSION_CODE="$(sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" <<<"$PACKAGE_LINE")"
CERT_SHA256="$(awk -F': ' '/Signer #1 certificate SHA-256 digest:/{print tolower($2); exit}' <<<"$VERIFY_OUTPUT" | tr -d ':')"

if [[ -z "$VERSION_NAME" || -z "$VERSION_CODE" || -z "$CERT_SHA256" ]]; then
  echo "APK sem versao ou certificado verificavel" >&2
  exit 1
fi
if grep -Eq '^application-debuggable|testOnly=.true.|test-only' <<<"$BADGING"; then
  echo "APK de release marcado como debuggable/testOnly" >&2
  exit 1
fi

if [[ "$PACKAGE_NAME" != "$EXPECTED_PACKAGE" ]]; then
  echo "package id divergente: esperado=$EXPECTED_PACKAGE atual=$PACKAGE_NAME" >&2
  exit 1
fi
if [[ -n "$EXPECTED_VERSION" && "$VERSION_NAME" != "${EXPECTED_VERSION%%+*}" ]]; then
  echo "versionName divergente: esperado=${EXPECTED_VERSION%%+*} atual=$VERSION_NAME" >&2
  exit 1
fi
if [[ -n "$EXPECTED_VERSION" && "$VERSION_CODE" != "${EXPECTED_VERSION##*+}" ]]; then
  echo "versionCode divergente: esperado=${EXPECTED_VERSION##*+} atual=$VERSION_CODE" >&2
  exit 1
fi
if [[ -n "$EXPECTED_CERT_SHA256" ]]; then
  NORMALIZED_EXPECTED_CERT="$(tr '[:upper:]' '[:lower:]' <<<"$EXPECTED_CERT_SHA256" | tr -d ':[:space:]')"
  if [[ "$CERT_SHA256" != "$NORMALIZED_EXPECTED_CERT" ]]; then
    echo "certificado APK divergente" >&2
    exit 1
  fi
fi

PERMISSIONS="$($AAPT dump permissions "$APK" | sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p" | sort -u)"
if grep -Fxq 'android.permission.CAMERA' <<<"$PERMISSIONS"; then
  echo "APK de beta nao pode declarar camera com Scanner DEFERRED_BY_SCOPE" >&2
  exit 1
fi
if grep -Fq 'android.hardware.camera' <<<"$BADGING"; then
  echo "APK de beta nao pode declarar feature de camera com Scanner DEFERRED_BY_SCOPE" >&2
  exit 1
fi
UNEXPECTED=()
while IFS= read -r permission; do
  [[ -z "$permission" ]] && continue
  case "$permission" in
    android.permission.INTERNET|\
    android.permission.POST_NOTIFICATIONS|\
    android.permission.WAKE_LOCK|\
    android.permission.ACCESS_NETWORK_STATE|\
    com.google.android.c2dm.permission.RECEIVE|\
    "$EXPECTED_PACKAGE.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION") ;;
    *) UNEXPECTED+=("$permission") ;;
  esac
done <<<"$PERMISSIONS"

if [[ ${#UNEXPECTED[@]} -gt 0 ]]; then
  printf 'permissoes Android nao aprovadas:\n' >&2
  printf '  %s\n' "${UNEXPECTED[@]}" >&2
  exit 1
fi

REPORT_JSON="$(jq -n \
  --arg status passed \
  --arg apk "$APK" \
  --arg package "$PACKAGE_NAME" \
  --arg version_name "$VERSION_NAME" \
  --arg version_code "$VERSION_CODE" \
  --arg certificate_sha256 "$CERT_SHA256" \
  --arg permissions "$PERMISSIONS" \
  '{
    status: $status,
    apk: $apk,
    package: $package,
    version_name: $version_name,
    version_code: $version_code,
    certificate_sha256: $certificate_sha256,
    permissions: ($permissions | split("\n") | map(select(length > 0)))
  }')"

if [[ -n "$REPORT" ]]; then
  mkdir -p "$(dirname "$REPORT")"
  printf '%s\n' "$REPORT_JSON" > "$REPORT"
fi
printf '%s\n' "$REPORT_JSON"

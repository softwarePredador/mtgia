#!/usr/bin/env bash

readonly MANALOOM_PRODUCTION_API_BASE_URL="https://evolution-cartinhas.2ta7qx.easypanel.host"
# shellcheck disable=SC2034 # consumed by release scripts after sourcing
readonly MANALOOM_PRODUCTION_PUBLIC_HOST="evolution-manaloom-web-public.2ta7qx.easypanel.host"
# shellcheck disable=SC2034 # consumed by release scripts after sourcing
readonly MANALOOM_PRODUCTION_EASYPANEL_PROJECT="evolution"
# shellcheck disable=SC2034 # consumed by release scripts after sourcing
readonly MANALOOM_PRODUCTION_REMOTE_BUILD_ROOT="/opt/manaloom/deploy"
readonly MANALOOM_PRODUCTION_TRUSTED_PROXY_HOPS="1"
readonly MANALOOM_PRODUCTION_TRUSTED_PROXY_NETWORK="easypanel"
readonly MANALOOM_PRODUCTION_TRUSTED_PROXY_SUBNET="10.11.0.0/16"
readonly MANALOOM_PRODUCTION_TRAEFIK_LOGICAL_IP="10.11.0.202"
# Docker Swarm preserves the client-facing Traefik task address above for
# routing, but connections received by backend tasks originate from the
# overlay network load-balancer endpoint. Keep the transport trust boundary
# separate and exact: widening this value to the overlay subnet would allow an
# unrelated service on the shared network to forge X-Forwarded-For.
readonly MANALOOM_PRODUCTION_PROXY_TRANSPORT_PEER_IPV4="10.11.0.4"
readonly MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS="${MANALOOM_PRODUCTION_PROXY_TRANSPORT_PEER_IPV4}/32"
readonly MANALOOM_PRODUCTION_SENTRY_DSN_SHA256="2e1cc23c01e5b7d989edc2f1d046c3e7de34a3fa57e995c0f2e6252902153e49"
readonly MANALOOM_PRODUCTION_SENTRY_ORG_SLUG="rafa-pz"
readonly MANALOOM_PRODUCTION_SENTRY_PROJECT_SLUG="manaloom"
readonly MANALOOM_SENTRY_DSN_KEYCHAIN_SERVICE="manaloom-sentry-dsn"
readonly MANALOOM_SENTRY_AUTH_TOKEN_KEYCHAIN_SERVICE="manaloom-sentry-auth-token"
readonly MANALOOM_JWT_SECRET_KEYCHAIN_SERVICE="manaloom-jwt-secret"
readonly MANALOOM_JWT_SECRET_KEYCHAIN_ACCOUNT="production"
readonly MANALOOM_APPROVED_ANDROID_CERT_SHA256="15f8d20ca28992a0ce010d6c0b45f365fe10e67cc349b634daf04564a50e3c28"
readonly MANALOOM_RELEASE_JAVA_VERSION="17.0.19+10"
readonly MANALOOM_RELEASE_JAVA_VENDOR="Eclipse Adoptium"
readonly MANALOOM_ANDROID_BUILD_TOOLS_VERSION="35.0.0"
readonly MANALOOM_ANDROID_APKSIGNER_SHA256="b47549e373b895ce6ca620d0c7887e674d9615ffa837a86ac601dcfd04adb0f0"
readonly MANALOOM_ANDROID_AAPT_SHA256="c0b5427aeabbbe05023ee2a55e3a9877c99ce57245bb15c21d4802326b86d099"

validate_manaloom_exact_coordinate() {
  local label="${1:-coordinate}"
  local candidate="${2:-}"
  local expected="${3:-}"
  if [[ -z "$candidate" || "$candidate" != "$expected" ]]; then
    echo "$label de release diverge do destino aprovado" >&2
    return 2
  fi
}

read_manaloom_keychain_secret() {
  local service="${1:-}"
  local account="${2:-${USER:-}}"
  if [[ -z "$service" || -z "$account" ]] ||
     ! command -v security >/dev/null 2>&1; then
    return 1
  fi
  security find-generic-password -a "$account" -s "$service" -w 2>/dev/null
}

extract_manaloom_repo_digest_ref() {
  local expected_repo="${1:-}"
  if [[ -z "$expected_repo" || "$expected_repo" == *[[:space:]]* ||
        "$expected_repo" == *@* ]]; then
    return 2
  fi
  awk -v expected_repo="$expected_repo" '
    index($0, expected_repo "@sha256:") == 1 &&
    $0 ~ /@sha256:[0-9a-f]{64}$/ {
      digest = $0
    }
    END {
      if (digest == "") exit 1
      print digest
    }
  '
}

validate_manaloom_easypanel_base_url() {
  local candidate="${1:-}"
  local expected_hash="${MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256:-}"
  local actual_hash
  if [[ ! "$expected_hash" =~ ^[0-9a-f]{64}$ ]]; then
    echo "MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256 deve fixar o endpoint EasyPanel aprovado" >&2
    return 2
  fi
  if ! python3 - "$candidate" <<'PY'
import sys
from urllib.parse import urlsplit

url = urlsplit(sys.argv[1])
valid = (
    url.scheme == "https"
    and bool(url.hostname)
    and url.username is None
    and url.password is None
    and url.path in ("", "/")
    and not url.query
    and not url.fragment
)
raise SystemExit(0 if valid else 1)
PY
  then
    echo "EASYPANEL_BASE_URL deve ser uma origem HTTPS sem credenciais, query ou path" >&2
    return 2
  fi
  candidate="${candidate%/}"
  actual_hash="$(printf '%s' "$candidate" | shasum -a 256 | awk '{print $1}')"
  if [[ "$actual_hash" != "$expected_hash" ]]; then
    echo "EASYPANEL_BASE_URL diverge do fingerprint aprovado" >&2
    return 2
  fi
  MANALOOM_EASYPANEL_BASE_URL_RESOLVED="$candidate"
  readonly MANALOOM_EASYPANEL_BASE_URL_RESOLVED
  export MANALOOM_EASYPANEL_BASE_URL_RESOLVED
}

validate_manaloom_ssh_target_syntax() {
  local target="${1:-}"
  local user host label
  local -a labels
  if [[ -z "$target" || "$target" == -* || "$target" == *[[:space:]]* ||
        "$target" != *@* ]]; then
    echo "destino SSH de release deve usar user@host sem opcoes ou espacos" >&2
    return 2
  fi
  user="${target%%@*}"
  host="${target#*@}"
  if [[ -z "$user" || -z "$host" || "$host" == *"@"* ||
        ${#user} -gt 32 || ${#host} -gt 253 ||
        ! "$user" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ||
        ! "$host" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ||
        "$host" == *. || "$host" == *..* ]]; then
    echo "destino SSH de release invalido" >&2
    return 2
  fi
  IFS='.' read -r -a labels <<<"$host"
  for label in "${labels[@]}"; do
    if [[ -z "$label" || ${#label} -gt 63 ||
          ! "$label" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]]; then
      echo "host SSH de release invalido" >&2
      return 2
    fi
  done
}

initialize_manaloom_secure_ssh() {
  local target="${1:-}"
  local host expected scan_file verified_file line fingerprint
  validate_manaloom_ssh_target_syntax "$target" || return $?
  host="${target#*@}"
  expected="${MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256:-}"
  if [[ ! "$expected" =~ ^SHA256:[A-Za-z0-9+/]{43}$ ]]; then
    echo "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256 deve fixar o host SSH aprovado" >&2
    return 2
  fi
  for tool in ssh ssh-keyscan ssh-keygen; do
    command -v "$tool" >/dev/null 2>&1 || {
      echo "ferramenta obrigatoria ausente: $tool" >&2
      return 2
    }
  done

  scan_file="$(mktemp /tmp/manaloom-ssh-scan.XXXXXX)"
  verified_file="$(mktemp /tmp/manaloom-ssh-known-hosts.XXXXXX)"
  chmod 600 "$scan_file" "$verified_file"
  ssh-keyscan -T 10 "$host" >"$scan_file" 2>/dev/null || true
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "$line" == \#* ]] && continue
    fingerprint="$(printf '%s\n' "$line" | ssh-keygen -lf - -E sha256 2>/dev/null | awk '{print $2}')"
    if [[ "$fingerprint" == "$expected" ]]; then
      printf '%s\n' "$line" >>"$verified_file"
    fi
  done <"$scan_file"
  rm -f "$scan_file"
  if [[ ! -s "$verified_file" ]]; then
    rm -f "$verified_file"
    echo "fingerprint SSH diverge da ancora aprovada" >&2
    return 1
  fi

  MANALOOM_SECURE_SSH_KNOWN_HOSTS="$verified_file"
  readonly MANALOOM_SECURE_SSH_KNOWN_HOSTS
  export MANALOOM_SECURE_SSH_KNOWN_HOSTS

  # shellcheck disable=SC2329 # installed intentionally as a secure wrapper
  ssh() {
    local -a filtered
    filtered=()
    while (( $# > 0 )); do
      if [[ "$1" == "-o" && $# -ge 2 &&
            ( "$2" == StrictHostKeyChecking=* || "$2" == UserKnownHostsFile=* ) ]]; then
        shift 2
        continue
      fi
      if [[ "$1" == -oStrictHostKeyChecking=* || "$1" == -oUserKnownHostsFile=* ]]; then
        shift
        continue
      fi
      filtered+=("$1")
      shift
    done
    command ssh \
      -o StrictHostKeyChecking=yes \
      -o "UserKnownHostsFile=$MANALOOM_SECURE_SSH_KNOWN_HOSTS" \
      "${filtered[@]}"
  }
  # shellcheck disable=SC2329 # installed intentionally as a secure wrapper
  scp() {
    local -a filtered
    filtered=()
    while (( $# > 0 )); do
      if [[ "$1" == "-o" && $# -ge 2 &&
            ( "$2" == StrictHostKeyChecking=* || "$2" == UserKnownHostsFile=* ) ]]; then
        shift 2
        continue
      fi
      if [[ "$1" == -oStrictHostKeyChecking=* || "$1" == -oUserKnownHostsFile=* ]]; then
        shift
        continue
      fi
      filtered+=("$1")
      shift
    done
    command scp \
      -o StrictHostKeyChecking=yes \
      -o "UserKnownHostsFile=$MANALOOM_SECURE_SSH_KNOWN_HOSTS" \
      "${filtered[@]}"
  }
}

cleanup_manaloom_secure_ssh() {
  if [[ -n "${MANALOOM_SECURE_SSH_KNOWN_HOSTS:-}" ]]; then
    rm -f "$MANALOOM_SECURE_SSH_KNOWN_HOSTS"
  fi
}

validate_manaloom_release_api_base_url() {
  local candidate="${1:-}"
  if [[ "$candidate" != "$MANALOOM_PRODUCTION_API_BASE_URL" ]]; then
    echo "API_BASE_URL de release recusada: use a origem HTTPS de producao aprovada" >&2
    return 2
  fi
}

validate_manaloom_android_release_certificate() {
  local candidate="${1:-}"
  candidate="$(tr '[:upper:]' '[:lower:]' <<<"$candidate" | tr -d ':[:space:]')"
  if [[ "$candidate" != "$MANALOOM_APPROVED_ANDROID_CERT_SHA256" ]]; then
    echo "certificado Android diverge do upload certificate aprovado" >&2
    return 2
  fi
  MANALOOM_RELEASE_ANDROID_CERT_SHA256_RESOLVED="$candidate"
  readonly MANALOOM_RELEASE_ANDROID_CERT_SHA256_RESOLVED
  export MANALOOM_RELEASE_ANDROID_CERT_SHA256_RESOLVED
}

resolve_manaloom_release_java() {
  local candidate java_bin properties actual_version actual_vendor
  candidate="${MANALOOM_JAVA_HOME:-$HOME/.manaloom/toolchains/temurin-17.0.19+10/Contents/Home}"
  candidate="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$candidate")"
  java_bin="$candidate/bin/java"
  if [[ ! -f "$java_bin" || ! -x "$java_bin" ]]; then
    echo "Java de release ausente: $java_bin" >&2
    return 2
  fi
  properties="$($java_bin -XshowSettings:properties -version 2>&1)"
  actual_version="$(awk -F'= ' '/^[[:space:]]*java.runtime.version =/{print $2; exit}' <<<"$properties")"
  actual_vendor="$(awk -F'= ' '/^[[:space:]]*java.vendor =/{print $2; exit}' <<<"$properties")"
  if [[ "$actual_version" != "$MANALOOM_RELEASE_JAVA_VERSION" ||
        "$actual_vendor" != "$MANALOOM_RELEASE_JAVA_VENDOR" ]]; then
    echo "Java de release incompativel: esperado $MANALOOM_RELEASE_JAVA_VENDOR $MANALOOM_RELEASE_JAVA_VERSION, encontrado ${actual_vendor:-desconhecido} ${actual_version:-desconhecido}" >&2
    return 2
  fi
  JAVA_HOME="$candidate"
  MANALOOM_RELEASE_JAVA_BIN_RESOLVED="$java_bin"
  readonly JAVA_HOME
  readonly MANALOOM_RELEASE_JAVA_BIN_RESOLVED
  export JAVA_HOME
  export MANALOOM_RELEASE_JAVA_BIN_RESOLVED
}

resolve_manaloom_android_build_tools() {
  local sdk_root build_tools apksigner aapt apksigner_sha256 aapt_sha256
  sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
  sdk_root="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$sdk_root")"
  build_tools="$sdk_root/build-tools/$MANALOOM_ANDROID_BUILD_TOOLS_VERSION"
  apksigner="$build_tools/apksigner"
  aapt="$build_tools/aapt"
  if [[ ! -f "$apksigner" || ! -x "$apksigner" || ! -f "$aapt" || ! -x "$aapt" ]]; then
    echo "Android build-tools $MANALOOM_ANDROID_BUILD_TOOLS_VERSION ausente em $sdk_root" >&2
    return 2
  fi
  apksigner_sha256="$(shasum -a 256 "$apksigner" | awk '{print $1}')"
  aapt_sha256="$(shasum -a 256 "$aapt" | awk '{print $1}')"
  if [[ "$apksigner_sha256" != "$MANALOOM_ANDROID_APKSIGNER_SHA256" ||
        "$aapt_sha256" != "$MANALOOM_ANDROID_AAPT_SHA256" ]]; then
    echo "Android build-tools divergem dos binarios macOS arm64 aprovados" >&2
    return 2
  fi
  MANALOOM_APKSIGNER="$apksigner"
  MANALOOM_AAPT="$aapt"
  MANALOOM_ANDROID_BUILD_TOOLS_DIR_RESOLVED="$build_tools"
  readonly MANALOOM_APKSIGNER
  readonly MANALOOM_AAPT
  readonly MANALOOM_ANDROID_BUILD_TOOLS_DIR_RESOLVED
  export MANALOOM_APKSIGNER
  export MANALOOM_AAPT
  export MANALOOM_ANDROID_BUILD_TOOLS_DIR_RESOLVED
}

resolve_manaloom_release_sentry_dsn() {
  local dsn="${1:-}"
  local required="${2:-0}"
  local expected="${MANALOOM_EXPECTED_SENTRY_DSN_SHA256:-}"
  local actual=""

  if [[ "$required" != "0" && "$required" != "1" ]]; then
    echo "required do contrato Sentry deve ser 0 ou 1" >&2
    return 2
  fi
  if [[ -z "$dsn" ]]; then
    if [[ "$required" == "1" ]]; then
      echo "DSN Sentry de release ausente" >&2
      return 2
    fi
  else
    if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
      echo "MANALOOM_EXPECTED_SENTRY_DSN_SHA256 deve fixar o projeto Sentry aprovado" >&2
      return 2
    fi
    actual="$(printf '%s' "$dsn" | shasum -a 256 | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
      echo "DSN Sentry diverge do fingerprint aprovado" >&2
      return 2
    fi
  fi

  MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED="$actual"
  readonly MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED
  export MANALOOM_RELEASE_SENTRY_DSN_SHA256_RESOLVED
}

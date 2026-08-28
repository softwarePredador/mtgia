#!/usr/bin/env bash
set -euo pipefail

umask 077
PATH="/usr/bin:/bin"
export PATH

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)"
SERVER_DIR="$ROOT_DIR/server"
HELPER="$ROOT_DIR/scripts/manaloom_dart_frog_offline_build.dart"
ADAPTER_PUBLISHED=0
ADAPTER_PUBLISHED_DIGEST=""
ADAPTER_PUBLISHED_INODE=""
ADAPTER_OWNER_NONCE=""
OWNER_MARKER="$SERVER_DIR/build/.manaloom_offline_build_owner"

cleanup_failed_publication() {
  local status="$?"
  trap - EXIT INT TERM
  if [[ "$status" -ne 0 && "$ADAPTER_PUBLISHED" != "1" &&
        -n "$ADAPTER_OWNER_NONCE" && -f "$OWNER_MARKER" &&
        ! -L "$OWNER_MARKER" &&
        "$(<"$OWNER_MARKER")" == "$ADAPTER_OWNER_NONCE" &&
        -d "$SERVER_DIR/build" && ! -L "$SERVER_DIR/build" ]]; then
    ADAPTER_PUBLISHED_DIGEST="$(build_tree_digest 2>/dev/null || true)"
    ADAPTER_PUBLISHED_INODE="$(stat -f '%i' "$SERVER_DIR/build" 2>/dev/null || true)"
    if [[ -n "$ADAPTER_PUBLISHED_DIGEST" &&
          -n "$ADAPTER_PUBLISHED_INODE" ]]; then
      ADAPTER_PUBLISHED=1
      rm -f "$OWNER_MARKER"
    fi
  fi
  if [[ "$status" -ne 0 && "$ADAPTER_PUBLISHED" == "1" &&
        -d "$SERVER_DIR/build" && ! -L "$SERVER_DIR/build" ]]; then
    current_digest="$(build_tree_digest 2>/dev/null || true)"
    current_inode="$(stat -f '%i' "$SERVER_DIR/build" 2>/dev/null || true)"
    if [[ -n "$ADAPTER_PUBLISHED_DIGEST" &&
          "$current_digest" == "$ADAPTER_PUBLISHED_DIGEST" &&
          "$current_inode" == "$ADAPTER_PUBLISHED_INODE" ]]; then
      rm -rf "$SERVER_DIR/build"
    else
      echo "BLOCKED_OFFLINE_BUILD_ADAPTER[cleanup_ownership_lost]: build publicado mudou; cleanup recusado" >&2
    fi
  fi
  exit "$status"
}
trap cleanup_failed_publication EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

readonly EXPECTED_PUBSPEC_SHA256="9226196bf5bd2a7f08b70a517ef50b9cc27d22dd8aa980465c12f0c542ca236a"
readonly EXPECTED_LOCK_SHA256="de183cafcafb95d22a5826bd854593531eedb0b7896869ede3a122c10531298a"
readonly EXPECTED_PACKAGE_CONFIG_SHA256="259c4324f36b3f6e7ee1ae62e1e11b68cc80a134aa9e8d830f61a8f00220cc50"
readonly EXPECTED_PACKAGE_GRAPH_SHA256="5d55a7dce0e0c13a349fb2f8e30423ae1f09a1094295e3ec841dc2f0e817c015"
readonly EXPECTED_HOSTED_CACHE_SHA256="ae80d74ced0479063622112f4455afb6752a40724c6f2dfa509c5dd3451845ae"
readonly EXPECTED_LOCAL_LINTS_SHA256="27488032ab6854d718a8c42ca5fc369071ea79d450a86d2b609d79e99158d90d"
readonly EXPECTED_DART_BIN_SHA256="25c92a6f53e9e44935e7cf0afc7cfe532fc2c24add6fc0f389e9f19ce95a29ca"
readonly EXPECTED_DART_VM_SHA256="ee45b54879152de44a8937c4f331d8f19fd492c52de7bb11d7444d3d9065e66d"
readonly EXPECTED_DARTDEV_SNAPSHOT_SHA256="70cfadad96543bffe8eb6a3a333c6a2d8ca4321713180d385d33d25d5200587d"
readonly EXPECTED_DART_SDK_TREE_SHA256="09c6a65f114f4d8f1cbc02402461653449012ecb81972a406d6657d9584870e3"
readonly EXPECTED_DART_VERSION_FILE_SHA256="657062bd6c016c431fe7658173ba3611697eeb21357fd82faef0b7d21a491c3f"
readonly EXPECTED_FLUTTER_VERSION_JSON_SHA256="9809948372bd1645e5ff4628e2314d826bc2dffde10daf59fb0ff6964ea92ea2"
readonly EXPECTED_ENGINE_STAMP_SHA256="da542b0f96099ed316a4ed5c60e809dd498105bd91a6aaf0055c28979c914afa"
readonly EXPECTED_FLUTTER_SCRIPT_SHA256="7d486c33b30a0cf1ea5146231c68bb8f966cdb4e087c5cd8b37e14513f536e7d"
readonly EXPECTED_FLUTTER_PUBSPEC_SHA256="c0e57dc9aee87273c1ff2cd3778959cb57eb5daa7a89f5f8568ab9e8ccd1cd4d"
readonly EXPECTED_DART_FROG_BUNDLE_SOURCE_SHA256="3a45f026916bdf443dbdac93e7860f1e73060de8f6bf490e378728f040c4b4f3"

fail() {
  local code="$1"
  shift
  echo "BLOCKED_OFFLINE_BUILD_ADAPTER[$code]: $*" >&2
  exit 66
}

if [[ "$#" -ne 1 || "$1" != "build" ]]; then
  echo "BLOCKED_OFFLINE_BUILD_ADAPTER[usage]: uso exato: $0 build" >&2
  exit 64
fi

if [[ -e "$SERVER_DIR/build" || -L "$SERVER_DIR/build" ]]; then
  fail "preexisting_build" \
    "server/build preexistente não pode ser apagado nem reutilizado"
fi
if [[ -e "$SERVER_DIR/.dart_frog" || -L "$SERVER_DIR/.dart_frog" ]]; then
  fail "preexisting_dart_frog_state" \
    "server/.dart_frog preexistente não pode ser apagado nem reutilizado"
fi

for tool in awk find grep jq sed shasum sort stat uuidgen xargs sandbox-exec; do
  command -v "$tool" >/dev/null 2>&1 ||
    fail "missing_tool" "ferramenta obrigatória ausente: $tool"
done

# shellcheck source=scripts/lib/manaloom_dart_toolchain.sh
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_flutter_root || fail "flutter_resolution" "Flutter pinado ausente"

FLUTTER_ROOT="$(CDPATH='' cd -- "$MANALOOM_FLUTTER_ROOT_RESOLVED" && pwd -P)"
EXPECTED_DART_BIN="$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart"
DART_BIN="$EXPECTED_DART_BIN"
if [[ -n "${MANALOOM_DART_BIN:-}" ]]; then
  if [[ "$MANALOOM_DART_BIN" != /* || ! -e "$MANALOOM_DART_BIN" ]]; then
    fail "dart_override_invalid" \
      "MANALOOM_DART_BIN deve apontar ao binário absoluto pinado"
  fi
  REQUESTED_DART_BIN="$(
    CDPATH='' cd -- "$(dirname -- "$MANALOOM_DART_BIN")" && pwd -P
  )/$(basename -- "$MANALOOM_DART_BIN")"
  if [[ "$REQUESTED_DART_BIN" != "$EXPECTED_DART_BIN" ]]; then
    fail "dart_outside_flutter_pin" \
      "Dart deve ser derivado exclusivamente do Flutter 3.44.6 aprovado"
  fi
fi

PACKAGE_CONFIG="$SERVER_DIR/.dart_tool/package_config.json"
PACKAGE_GRAPH="$SERVER_DIR/.dart_tool/package_graph.json"
PUBSPEC="$SERVER_DIR/pubspec.yaml"
LOCKFILE="$SERVER_DIR/pubspec.lock"
LOCAL_LINTS="$ROOT_DIR/tools/manaloom_lints"
FLUTTER_VERSION_JSON="$FLUTTER_ROOT/bin/cache/flutter.version.json"
DART_VERSION_FILE="$FLUTTER_ROOT/bin/cache/dart-sdk/version"
DART_SDK_ROOT="$FLUTTER_ROOT/bin/cache/dart-sdk"
DART_VM="$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dartvm"
DARTDEV_SNAPSHOT="$FLUTTER_ROOT/bin/cache/dart-sdk/bin/snapshots/dartdev_aot.dart.snapshot"
ENGINE_STAMP="$FLUTTER_ROOT/bin/cache/engine.stamp"
FLUTTER_SCRIPT="$FLUTTER_ROOT/bin/flutter"
FLUTTER_PUBSPEC="$FLUTTER_ROOT/packages/flutter/pubspec.yaml"

for required_file in \
  "$HELPER" \
  "$PACKAGE_CONFIG" \
  "$PACKAGE_GRAPH" \
  "$PUBSPEC" \
  "$LOCKFILE" \
  "$DART_BIN" \
  "$DART_VM" \
  "$DARTDEV_SNAPSHOT" \
  "$DART_VERSION_FILE" \
  "$FLUTTER_VERSION_JSON" \
  "$ENGINE_STAMP" \
  "$FLUTTER_SCRIPT" \
  "$FLUTTER_PUBSPEC"; do
  if [[ ! -f "$required_file" || -L "$required_file" ]]; then
    fail "missing_or_linked_input" "entrada regular obrigatória ausente"
  fi
done
if [[ ! -d "$LOCAL_LINTS" || -L "$LOCAL_LINTS" ]]; then
  fail "local_dependency_missing" "tools/manaloom_lints ausente ou linked"
fi

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

build_tree_digest() {
  {
    find "$SERVER_DIR/build" -type f \
      ! -name '.manaloom_offline_build_owner' -print |
      sed "s#^$SERVER_DIR/build/##" |
      LC_ALL=C sort |
      while IFS= read -r relative_path; do
        printf '%s\0%s\0' \
          "$relative_path" "$(sha256_file "$SERVER_DIR/build/$relative_path")"
      done
  } | shasum -a 256 | awk '{print $1}'
}

dart_sdk_tree_digest() {
  {
    find "$DART_SDK_ROOT" -type f -print |
      sed "s#^$DART_SDK_ROOT/##" |
      LC_ALL=C sort |
      while IFS= read -r relative_path; do
        printf '%s\0%s\0' \
          "$relative_path" "$(sha256_file "$DART_SDK_ROOT/$relative_path")"
      done
  } | shasum -a 256 | awk '{print $1}'
}

require_file_hash() {
  local label="$1"
  local file="$2"
  local expected="$3"
  local actual
  actual="$(sha256_file "$file")"
  if [[ "$actual" != "$expected" ]]; then
    fail "${label}_digest_mismatch" "digest de $label diverge do pin versionado"
  fi
}

require_file_hash "pubspec" "$PUBSPEC" "$EXPECTED_PUBSPEC_SHA256"
require_file_hash "pubspec_lock" "$LOCKFILE" "$EXPECTED_LOCK_SHA256"
require_file_hash "dart_binary" "$DART_BIN" "$EXPECTED_DART_BIN_SHA256"
require_file_hash "dart_vm" "$DART_VM" "$EXPECTED_DART_VM_SHA256"
require_file_hash \
  "dartdev_snapshot" "$DARTDEV_SNAPSHOT" "$EXPECTED_DARTDEV_SNAPSHOT_SHA256"
require_file_hash \
  "dart_version_file" "$DART_VERSION_FILE" "$EXPECTED_DART_VERSION_FILE_SHA256"
require_file_hash \
  "flutter_version_json" "$FLUTTER_VERSION_JSON" \
  "$EXPECTED_FLUTTER_VERSION_JSON_SHA256"
require_file_hash "engine_stamp" "$ENGINE_STAMP" "$EXPECTED_ENGINE_STAMP_SHA256"
require_file_hash "flutter_script" "$FLUTTER_SCRIPT" "$EXPECTED_FLUTTER_SCRIPT_SHA256"
require_file_hash \
  "flutter_pubspec" "$FLUTTER_PUBSPEC" "$EXPECTED_FLUTTER_PUBSPEC_SHA256"

if [[ -n "$(find "$DART_SDK_ROOT" ! -type f ! -type d -print -quit)" ]]; then
  fail "dart_sdk_special_entity" \
    "SDK Dart contém symlink ou entidade especial"
fi
DART_SDK_DIGEST_BEFORE="$(dart_sdk_tree_digest)"
if [[ "$DART_SDK_DIGEST_BEFORE" != "$EXPECTED_DART_SDK_TREE_SHA256" ]]; then
  fail "dart_sdk_tree_digest_mismatch" \
    "árvore integral do SDK Dart diverge do pin versionado"
fi

DART_VERSION_OUTPUT="$(
  sandbox-exec -p '(version 1) (allow default) (deny network*)' \
    "$DART_BIN" --version 2>&1
)"
if [[ "$(awk '{print $4}' <<<"$DART_VERSION_OUTPUT")" != "3.12.2" ]]; then
  fail "dart_executable_version_mismatch" \
    "binário Dart validado deve anunciar versão 3.12.2"
fi

if [[ "$(<"$DART_VERSION_FILE")" != "3.12.2" ]]; then
  fail "dart_version_mismatch" "Dart SDK deve ser 3.12.2"
fi
if [[ "$(<"$ENGINE_STAMP")" != "83675ed27633283e7fc296c8bca22e841224c096" ]]; then
  fail "engine_revision_mismatch" "engine Flutter diverge do pin"
fi
jq -e '
  .frameworkVersion == "3.44.6" and
  .flutterVersion == "3.44.6" and
  .frameworkRevision == "ee80f08bbf97172ec030b8751ceab557177a34a6" and
  .engineRevision == "83675ed27633283e7fc296c8bca22e841224c096" and
  .dartSdkVersion == "3.12.2"
' "$FLUTTER_VERSION_JSON" >/dev/null ||
  fail "flutter_metadata_mismatch" "metadados Flutter/Dart divergiram"

PACKAGE_CONFIG_DIGEST="$(
  pub_cache_uri="$(jq -er '.pubCache | select(type == "string")' "$PACKAGE_CONFIG")"
  jq -cS --arg prefix "$pub_cache_uri" '
    .pubCache = "<PUB_CACHE>" |
    .packages |= map(
      if (.rootUri | startswith($prefix))
      then .rootUri = ("<PUB_CACHE>" + (.rootUri | ltrimstr($prefix)))
      else .
      end
    )
  ' "$PACKAGE_CONFIG" | shasum -a 256 | awk '{print $1}'
)"
if [[ "$PACKAGE_CONFIG_DIGEST" != "$EXPECTED_PACKAGE_CONFIG_SHA256" ]]; then
  fail "package_config_digest_mismatch" \
    "package_config normalizado diverge do pin versionado"
fi
PACKAGE_GRAPH_DIGEST="$(
  jq -cS . "$PACKAGE_GRAPH" | shasum -a 256 | awk '{print $1}'
)"
if [[ "$PACKAGE_GRAPH_DIGEST" != "$EXPECTED_PACKAGE_GRAPH_SHA256" ]]; then
  fail "package_graph_digest_mismatch" \
    "package_graph canônico diverge do pin versionado"
fi

jq -e '
  .generator == "pub" and
  .generatorVersion == "3.12.2" and
  (.packages | length) == 110 and
  ([.packages[] | select(.name == "server" and .rootUri == "../")] | length) == 1 and
  ([.packages[] | select(
    .name == "manaloom_lints" and
    .rootUri == "../../tools/manaloom_lints"
  )] | length) == 1 and
  ([.packages[] | select(
    .name == "dart_frog_cli" and
    (.rootUri | endswith("/dart_frog_cli-1.2.14"))
  )] | length) == 1 and
  ([.packages[] | select(
    .name == "dart_frog" and
    (.rootUri | endswith("/dart_frog-1.2.6"))
  )] | length) == 1 and
  ([.packages[] | select(
    .name == "dart_frog_gen" and
    (.rootUri | endswith("/dart_frog_gen-2.1.0"))
  )] | length) == 1 and
  ([.packages[] | select(
    .name == "mason" and
    (.rootUri | endswith("/mason-0.1.2"))
  )] | length) == 1
' "$PACKAGE_CONFIG" >/dev/null ||
  fail "package_config_semantic_mismatch" "package_config não preserva os pins"
jq -e '
  .roots == ["server"] and
  (.packages | length) == 110 and
  ([.packages[] | select(.name == "dart_frog_cli" and .version == "1.2.14")] | length) == 1 and
  ([.packages[] | select(.name == "dart_frog" and .version == "1.2.6")] | length) == 1 and
  ([.packages[] | select(.name == "dart_frog_gen" and .version == "2.1.0")] | length) == 1 and
  ([.packages[] | select(.name == "mason" and .version == "0.1.2")] | length) == 1
' "$PACKAGE_GRAPH" >/dev/null ||
  fail "package_graph_semantic_mismatch" "package_graph não preserva os pins"

CONFIG_PACKAGE_NAMES="$(jq -r '.packages[].name' "$PACKAGE_CONFIG" | LC_ALL=C sort)"
GRAPH_PACKAGE_NAMES="$(jq -r '.packages[].name' "$PACKAGE_GRAPH" | LC_ALL=C sort)"
if [[ "$CONFIG_PACKAGE_NAMES" != "$GRAPH_PACKAGE_NAMES" ]]; then
  fail "package_closure_mismatch" \
    "package_config e package_graph não têm o mesmo fechamento"
fi

PUB_CACHE_URI="$(jq -er '.pubCache | select(type == "string")' "$PACKAGE_CONFIG")"
case "$PUB_CACHE_URI" in
  file:///*) ;;
  *) fail "pub_cache_uri_invalid" "pubCache deve ser URI file absoluta" ;;
esac
if [[ "$PUB_CACHE_URI" == *%* ]]; then
  fail "pub_cache_uri_encoded" "pubCache percent-encoded não é aceito"
fi
PUB_CACHE_PATH="${PUB_CACHE_URI#file://}"
HOSTED_ROOT="$PUB_CACHE_PATH/hosted/pub.dev"
if [[ ! -d "$HOSTED_ROOT" || -L "$HOSTED_ROOT" ]]; then
  fail "hosted_cache_missing" "cache hosted pinado ausente"
fi

HOSTED_DIRECTORIES="$(
  jq -r --arg prefix "$PUB_CACHE_URI/hosted/pub.dev/" '
    .packages[] |
    select(.rootUri | startswith($prefix)) |
    .rootUri | ltrimstr($prefix)
  ' "$PACKAGE_CONFIG" | LC_ALL=C sort
)"
if [[ "$(printf '%s\n' "$HOSTED_DIRECTORIES" | grep -c '.')" -ne 108 ]]; then
  fail "hosted_cache_count_mismatch" "cache deve resolver 108 pacotes hosted"
fi
while IFS= read -r directory_name; do
  if [[ ! "$directory_name" =~ ^[a-zA-Z0-9_.+-]+$ ]]; then
    fail "hosted_cache_path_invalid" "nome de diretório hosted inválido"
  fi
  package_directory="$HOSTED_ROOT/$directory_name"
  if [[ ! -d "$package_directory" || -L "$package_directory" ]]; then
    fail "hosted_cache_package_missing" "pacote hosted ausente ou linked"
  fi
  if [[ -n "$(find "$package_directory" ! -type f ! -type d -print -quit)" ]]; then
    fail "hosted_cache_special_entity" \
      "cache hosted contém symlink ou entidade especial"
  fi
done <<<"$HOSTED_DIRECTORIES"

hosted_cache_digest() {
  {
    while IFS= read -r directory_name; do
      find "$HOSTED_ROOT/$directory_name" -type f -print0
    done <<<"$HOSTED_DIRECTORIES"
  } |
    xargs -0 -n 256 shasum -a 256 |
    sed "s#  $HOSTED_ROOT/#  #" |
    LC_ALL=C sort |
    shasum -a 256 |
    awk '{print $1}'
}

HOSTED_CACHE_DIGEST_BEFORE="$(hosted_cache_digest)"
if [[ "$HOSTED_CACHE_DIGEST_BEFORE" != "$EXPECTED_HOSTED_CACHE_SHA256" ]]; then
  fail "hosted_cache_digest_mismatch" "árvore do cache hosted diverge do pin"
fi

if [[ -n "$(find "$LOCAL_LINTS" ! -type f ! -type d -print -quit)" ]]; then
  fail "local_lints_special_entity" \
    "tools/manaloom_lints contém symlink ou entidade especial"
fi
LOCAL_LINTS_DIGEST="$(
  find "$LOCAL_LINTS" -type f -print0 |
    xargs -0 -n 256 shasum -a 256 |
    sed "s#  $LOCAL_LINTS/#  #" |
    LC_ALL=C sort |
    shasum -a 256 |
    awk '{print $1}'
)"
if [[ "$LOCAL_LINTS_DIGEST" != "$EXPECTED_LOCAL_LINTS_SHA256" ]]; then
  fail "local_lints_digest_mismatch" \
    "árvore de tools/manaloom_lints diverge do pin"
fi

DART_FROG_CLI_ROOT_URI="$(
  jq -er '.packages[] | select(.name == "dart_frog_cli") | .rootUri' \
    "$PACKAGE_CONFIG"
)"
case "$DART_FROG_CLI_ROOT_URI" in
  file:///*) ;;
  *) fail "dart_frog_cli_root_invalid" "dart_frog_cli não resolve localmente" ;;
esac
DART_FROG_CLI_ROOT="${DART_FROG_CLI_ROOT_URI#file://}"
DART_FROG_BUNDLE_SOURCE="$DART_FROG_CLI_ROOT/lib/src/commands/build/templates/dart_frog_prod_server_bundle.dart"
if [[ ! -f "$DART_FROG_BUNDLE_SOURCE" || -L "$DART_FROG_BUNDLE_SOURCE" ]]; then
  fail "dart_frog_bundle_missing" "bundle Dart Frog pinado ausente"
fi
require_file_hash \
  "dart_frog_bundle_source" "$DART_FROG_BUNDLE_SOURCE" \
  "$EXPECTED_DART_FROG_BUNDLE_SOURCE_SHA256"

SHELL_ADAPTER_SHA256_BEFORE="$(sha256_file "$0")"
HELPER_SHA256_BEFORE="$(sha256_file "$HELPER")"
PUBSPEC_SHA256_BEFORE="$(sha256_file "$PUBSPEC")"
LOCK_SHA256_BEFORE="$(sha256_file "$LOCKFILE")"
PACKAGE_CONFIG_RAW_SHA256_BEFORE="$(sha256_file "$PACKAGE_CONFIG")"
PACKAGE_GRAPH_RAW_SHA256_BEFORE="$(sha256_file "$PACKAGE_GRAPH")"
DART_FROG_BUNDLE_SOURCE_SHA256_BEFORE="$(sha256_file "$DART_FROG_BUNDLE_SOURCE")"

INPUT_ATTESTATION_BEFORE="$(
  {
    printf '%s\n' "$(sha256_file "$PUBSPEC")  pubspec.yaml"
    printf '%s\n' "$(sha256_file "$LOCKFILE")  pubspec.lock"
    printf '%s\n' "$PACKAGE_CONFIG_DIGEST  package_config.normalized.json"
    printf '%s\n' "$PACKAGE_GRAPH_DIGEST  package_graph.canonical.json"
    printf '%s\n' "$HOSTED_CACHE_DIGEST_BEFORE  hosted_cache.tree"
    printf '%s\n' "$LOCAL_LINTS_DIGEST  manaloom_lints.tree"
    printf '%s\n' "$SHELL_ADAPTER_SHA256_BEFORE  adapter.sh"
    printf '%s\n' "$HELPER_SHA256_BEFORE  adapter.dart"
    printf '%s\n' "$PACKAGE_CONFIG_RAW_SHA256_BEFORE  package_config.raw.json"
    printf '%s\n' "$PACKAGE_GRAPH_RAW_SHA256_BEFORE  package_graph.raw.json"
    printf '%s\n' "$(sha256_file "$DART_BIN")  dart.bin"
    printf '%s\n' "$(sha256_file "$DART_VM")  dart.vm"
    printf '%s\n' "$(sha256_file "$DARTDEV_SNAPSHOT")  dartdev.snapshot"
    printf '%s\n' "$DART_SDK_DIGEST_BEFORE  dart_sdk.tree"
    printf '%s\n' "$(sha256_file "$DART_VERSION_FILE")  dart.version"
    printf '%s\n' "$(sha256_file "$FLUTTER_VERSION_JSON")  flutter.version.json"
    printf '%s\n' "$(sha256_file "$ENGINE_STAMP")  flutter.engine.stamp"
    printf '%s\n' "$(sha256_file "$FLUTTER_SCRIPT")  flutter.script"
    printf '%s\n' "$(sha256_file "$FLUTTER_PUBSPEC")  flutter.pubspec"
    printf '%s\n' "$DART_FROG_BUNDLE_SOURCE_SHA256_BEFORE  dart_frog.bundle.dart"
  } | LC_ALL=C sort | shasum -a 256 | awk '{print $1}'
)"

readonly NETWORK_SANDBOX_PROFILE='(version 1)
(allow default)
(deny network*)'
ADAPTER_OWNER_NONCE="$(uuidgen)"
OWNER_MARKER_SHA256="$(printf '%s\n' "$ADAPTER_OWNER_NONCE" | shasum -a 256 | awk '{print $1}')"
set +e
HELPER_SUMMARY="$(
  sandbox-exec -p "$NETWORK_SANDBOX_PROFILE" \
    env \
      -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
      -u http_proxy -u https_proxy -u all_proxy \
      DART_DISABLE_ANALYTICS=1 \
      DART_SUPPRESS_ANALYTICS=true \
      CI=true \
      MANALOOM_OFFLINE_BUILD_FLUTTER_VERSION=3.44.6 \
      MANALOOM_OFFLINE_BUILD_HELPER_SHA256="$HELPER_SHA256_BEFORE" \
      MANALOOM_OFFLINE_BUILD_PUBSPEC_SHA256="$PUBSPEC_SHA256_BEFORE" \
      MANALOOM_OFFLINE_BUILD_LOCK_SHA256="$LOCK_SHA256_BEFORE" \
      MANALOOM_OFFLINE_BUILD_PACKAGE_CONFIG_SHA256="$PACKAGE_CONFIG_RAW_SHA256_BEFORE" \
      MANALOOM_OFFLINE_BUILD_PACKAGE_GRAPH_SHA256="$PACKAGE_GRAPH_RAW_SHA256_BEFORE" \
      MANALOOM_OFFLINE_BUILD_DART_BIN_SHA256="$EXPECTED_DART_BIN_SHA256" \
      MANALOOM_OFFLINE_BUILD_DART_VM_SHA256="$EXPECTED_DART_VM_SHA256" \
      MANALOOM_OFFLINE_BUILD_DARTDEV_SNAPSHOT_SHA256="$EXPECTED_DARTDEV_SNAPSHOT_SHA256" \
      MANALOOM_OFFLINE_BUILD_DART_SDK_TREE_SHA256="$EXPECTED_DART_SDK_TREE_SHA256" \
      MANALOOM_OFFLINE_BUILD_OWNER_NONCE="$ADAPTER_OWNER_NONCE" \
      "$DART_BIN" \
      --packages="$PACKAGE_CONFIG" \
      "$HELPER" build "$SERVER_DIR"
)"
HELPER_STATUS="$?"
set -e
if [[ -d "$SERVER_DIR/build" && ! -L "$SERVER_DIR/build" &&
      -f "$OWNER_MARKER" && ! -L "$OWNER_MARKER" &&
      "$(<"$OWNER_MARKER")" == "$ADAPTER_OWNER_NONCE" ]]; then
  ADAPTER_PUBLISHED_DIGEST="$(build_tree_digest)"
  ADAPTER_PUBLISHED_INODE="$(stat -f '%i' "$SERVER_DIR/build")"
  ADAPTER_PUBLISHED=1
  rm -f "$OWNER_MARKER"
elif [[ -e "$SERVER_DIR/build" || -L "$SERVER_DIR/build" ]]; then
  fail "published_build_ownership_invalid" \
    "helper deixou build sem o nonce de ownership desta rodada"
fi
if [[ "$HELPER_STATUS" -ne 0 ]]; then
  fail "helper_exit_$HELPER_STATUS" \
    "helper offline terminou com status não zero"
fi
if ! jq -e '
  .classification == "PASS_OFFLINE_BUILD_ADAPTER" and
  .adapter_version == "1" and
  .dart == "3.12.2" and
  .flutter == "3.44.6" and
  .dart_frog_cli == "1.2.14" and
  .dart_frog == "1.2.6" and
  (.routes | type == "number") and
  (.build_digest | test("^[0-9a-f]{64}$")) and
  (.ownership_marker_sha256 | test("^[0-9a-f]{64}$"))
' <<<"$HELPER_SUMMARY" >/dev/null; then
  fail "helper_summary_invalid" "helper não produziu atestado válido"
fi
HELPER_BUILD_DIGEST="$(jq -er '.build_digest' <<<"$HELPER_SUMMARY")"
HELPER_OWNER_MARKER_DIGEST="$(
  jq -er '.ownership_marker_sha256' <<<"$HELPER_SUMMARY"
)"
if [[ "$ADAPTER_PUBLISHED" != "1" ||
      "$HELPER_BUILD_DIGEST" != "$ADAPTER_PUBLISHED_DIGEST" ||
      "$HELPER_OWNER_MARKER_DIGEST" != "$OWNER_MARKER_SHA256" ]]; then
  fail "published_build_digest_mismatch" \
    "árvore publicada não corresponde ao digest emitido pelo helper"
fi

require_file_hash "pubspec_after" "$PUBSPEC" "$EXPECTED_PUBSPEC_SHA256"
require_file_hash "pubspec_lock_after" "$LOCKFILE" "$EXPECTED_LOCK_SHA256"
require_file_hash \
  "package_config_raw_after" "$PACKAGE_CONFIG" \
  "$PACKAGE_CONFIG_RAW_SHA256_BEFORE"
require_file_hash \
  "package_graph_raw_after" "$PACKAGE_GRAPH" \
  "$PACKAGE_GRAPH_RAW_SHA256_BEFORE"
require_file_hash "dart_binary_after" "$DART_BIN" "$EXPECTED_DART_BIN_SHA256"
require_file_hash "dart_vm_after" "$DART_VM" "$EXPECTED_DART_VM_SHA256"
require_file_hash \
  "dartdev_snapshot_after" "$DARTDEV_SNAPSHOT" \
  "$EXPECTED_DARTDEV_SNAPSHOT_SHA256"
DART_SDK_DIGEST_AFTER="$(dart_sdk_tree_digest)"
if [[ "$DART_SDK_DIGEST_AFTER" != "$DART_SDK_DIGEST_BEFORE" ]]; then
  fail "dart_sdk_tree_mutated" \
    "árvore integral do SDK Dart mudou durante o build"
fi
require_file_hash \
  "dart_version_file_after" "$DART_VERSION_FILE" \
  "$EXPECTED_DART_VERSION_FILE_SHA256"
require_file_hash \
  "flutter_version_json_after" "$FLUTTER_VERSION_JSON" \
  "$EXPECTED_FLUTTER_VERSION_JSON_SHA256"
require_file_hash \
  "engine_stamp_after" "$ENGINE_STAMP" "$EXPECTED_ENGINE_STAMP_SHA256"
require_file_hash \
  "flutter_script_after" "$FLUTTER_SCRIPT" "$EXPECTED_FLUTTER_SCRIPT_SHA256"
require_file_hash \
  "flutter_pubspec_after" "$FLUTTER_PUBSPEC" \
  "$EXPECTED_FLUTTER_PUBSPEC_SHA256"
require_file_hash \
  "adapter_shell_after" "$0" "$SHELL_ADAPTER_SHA256_BEFORE"
require_file_hash \
  "adapter_helper_after" "$HELPER" "$HELPER_SHA256_BEFORE"
require_file_hash \
  "dart_frog_bundle_source_after" "$DART_FROG_BUNDLE_SOURCE" \
  "$DART_FROG_BUNDLE_SOURCE_SHA256_BEFORE"
HOSTED_CACHE_DIGEST_AFTER="$(hosted_cache_digest)"
if [[ "$HOSTED_CACHE_DIGEST_AFTER" != "$HOSTED_CACHE_DIGEST_BEFORE" ]]; then
  fail "hosted_cache_mutated" "cache hosted foi alterado durante o build"
fi
LOCAL_LINTS_DIGEST_AFTER="$(
  find "$LOCAL_LINTS" -type f -print0 |
    xargs -0 -n 256 shasum -a 256 |
    sed "s#  $LOCAL_LINTS/#  #" |
    LC_ALL=C sort |
    shasum -a 256 |
    awk '{print $1}'
)"
if [[ "$LOCAL_LINTS_DIGEST_AFTER" != "$LOCAL_LINTS_DIGEST" ]]; then
  fail "local_lints_mutated" \
    "tools/manaloom_lints mudou durante o build"
fi
if [[ ! -f "$SERVER_DIR/build/bin/server.dart" ||
      ! -f "$SERVER_DIR/build/.dart_tool/package_config.json" ||
      -d "$SERVER_DIR/build/build" ]]; then
  fail "build_output_invalid" "build final não satisfaz a árvore mínima"
fi
if [[ "$(build_tree_digest)" != "$ADAPTER_PUBLISHED_DIGEST" ]]; then
  fail "published_build_mutated" "build mudou após sua publicação atômica"
fi

printf '%s\n' "$HELPER_SUMMARY"
printf '%s\n' \
  "offline_build_adapter_network_guard=macos_sandbox_deny_all" \
  "offline_build_adapter_input_attestation=$INPUT_ATTESTATION_BEFORE" \
  "offline_build_adapter_hosted_cache_sha256=$HOSTED_CACHE_DIGEST_AFTER"
trap - EXIT INT TERM

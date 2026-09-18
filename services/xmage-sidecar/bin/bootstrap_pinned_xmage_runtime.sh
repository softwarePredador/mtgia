#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SIDECAR_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
REPOSITORY_ROOT="$(CDPATH='' cd -- "$SIDECAR_DIR/../.." && pwd)"
XMAGE_COMMIT="$(tr -d '[:space:]' <"$SIDECAR_DIR/XMAGE_COMMIT")"
XMAGE_PATCH_COMMIT="$(tr -d '[:space:]' <"$SIDECAR_DIR/XMAGE_PATCH_COMMIT")"
XMAGE_VERSION="1.4.60"
SQLITE_JDBC_VERSION="3.53.2.0"
XMAGE_PATCH_REPOSITORY="https://github.com/softwarePredador/mage.git"
XMAGE_PATCH_FILE="$REPOSITORY_ROOT/docs/qa/evidence/LOREHOLD_CANDIDATE_FOCUSED_TESTS_2026-07-29.patch"
XMAGE_PATCH_SHA256="24f6e88e082a222b60e2fb890898e43d3c7ef971ee6e38550aa476f371733642"
XMAGE_PATCH_TREE="cacc9649f20ddf450528073251acd91e1d41c152"

case "$(uname -s)" in
  Darwin)
    DEFAULT_CACHE_ROOT="${HOME:?HOME is required}/Library/Caches/ManaLoom/xmage-runtime"
    ;;
  *)
    DEFAULT_CACHE_ROOT="${XDG_CACHE_HOME:-${HOME:?HOME is required}/.cache}/manaloom/xmage-runtime"
    ;;
esac
CACHE_ROOT="${MANALOOM_XMAGE_RUNTIME_CACHE_DIR:-$DEFAULT_CACHE_ROOT}"
PIN_KEY="${XMAGE_COMMIT}+patch.${XMAGE_PATCH_COMMIT}"
RUNTIME_DIR="$CACHE_ROOT/$PIN_KEY"
RUNTIME_ZIP="$RUNTIME_DIR/mage-server-$XMAGE_VERSION.zip"
RUNTIME_MARKER="$RUNTIME_DIR/runtime-pin.txt"
PIN_FINGERPRINT="xmage=$XMAGE_VERSION commit=$XMAGE_COMMIT patch=$XMAGE_PATCH_COMMIT tree=$XMAGE_PATCH_TREE sqlite-jdbc=$SQLITE_JDBC_VERSION"
MAVEN_REPO_LOCAL="${MAVEN_REPO_LOCAL:-${HOME:?HOME is required}/.m2/repository}"
MAVEN_PIN_MARKER="$MAVEN_REPO_LOCAL/.manaloom-xmage-pin"
MAVEN_PIN_FINGERPRINT="$XMAGE_COMMIT patch=$XMAGE_PATCH_COMMIT xmage=$XMAGE_VERSION sqlite-jdbc=$SQLITE_JDBC_VERSION"

case "$CACHE_ROOT" in
  /*) ;;
  *)
    echo "MANALOOM_XMAGE_RUNTIME_CACHE_DIR must be absolute" >&2
    exit 2
    ;;
esac
case "$MAVEN_REPO_LOCAL" in
  /*) ;;
  *)
    echo "MAVEN_REPO_LOCAL must be absolute" >&2
    exit 2
    ;;
esac

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 2
  }
}

runtime_ready() {
  [[ -s "$RUNTIME_ZIP" && -r "$RUNTIME_MARKER" ]] || return 1
  local marker_fingerprint marker_sha observed_sha
  marker_fingerprint="$(sed -n '1p' "$RUNTIME_MARKER")"
  marker_sha="$(sed -n '2s/^sha256=//p' "$RUNTIME_MARKER")"
  [[ "$marker_fingerprint" == "$PIN_FINGERPRINT" ]] || return 1
  [[ "$marker_sha" =~ ^[0-9a-f]{64}$ ]] || return 1
  observed_sha="$(shasum -a 256 "$RUNTIME_ZIP" | awk '{print $1}')"
  [[ "$observed_sha" == "$marker_sha" ]] || return 1
  unzip -tq "$RUNTIME_ZIP" >/dev/null
}

maven_artifacts_ready() {
  [[ -s "$MAVEN_REPO_LOCAL/org/mage/mage-common/$XMAGE_VERSION/mage-common-$XMAGE_VERSION.jar" ]] &&
    [[ -s "$MAVEN_REPO_LOCAL/org/mage/mage-sets/$XMAGE_VERSION/mage-sets-$XMAGE_VERSION.jar" ]] &&
    [[ -r "$MAVEN_PIN_MARKER" ]] &&
    [[ "$(<"$MAVEN_PIN_MARKER")" == "$MAVEN_PIN_FINGERPRINT" ]]
}

for command_name in git java mvn shasum unzip; do
  require_command "$command_name"
done

if runtime_ready && maven_artifacts_ready; then
  printf '%s\n' "$RUNTIME_ZIP"
  exit 0
fi

if runtime_ready; then
  "$SCRIPT_DIR/bootstrap_pinned_xmage_maven.sh" >&2
  maven_artifacts_ready || {
    echo "Pinned XMage Maven artifacts failed verification" >&2
    exit 1
  }
  printf '%s\n' "$RUNTIME_ZIP"
  exit 0
fi

java_version="$(java -version 2>&1 | sed -n '1p')"
if [[ "$java_version" != *'17.'* ]]; then
  echo "Pinned XMage runtime assembly requires Java 17: $java_version" >&2
  exit 2
fi

observed_patch_sha="$(shasum -a 256 "$XMAGE_PATCH_FILE" | awk '{print $1}')"
if [[ ! "$XMAGE_COMMIT" =~ ^[0-9a-f]{40}$ ||
      ! "$XMAGE_PATCH_COMMIT" =~ ^[0-9a-f]{40}$ ||
      "$observed_patch_sha" != "$XMAGE_PATCH_SHA256" ]]; then
  echo "Governed XMage patch identity is invalid" >&2
  exit 2
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-xmage-runtime-bootstrap.XXXXXX")"
cleanup() {
  find "$WORK_DIR" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Building governed XMage runtime $PIN_KEY" >&2
git -C "$WORK_DIR" init -q xmage
git -C "$WORK_DIR/xmage" remote add upstream https://github.com/magefree/mage.git
git -C "$WORK_DIR/xmage" fetch --depth 1 upstream "$XMAGE_COMMIT" >&2
git -C "$WORK_DIR/xmage" checkout -q --detach FETCH_HEAD
test "$(git -C "$WORK_DIR/xmage" rev-parse HEAD)" = "$XMAGE_COMMIT"
git -C "$WORK_DIR/xmage" apply --check --unidiff-zero "$XMAGE_PATCH_FILE"
git -C "$WORK_DIR/xmage" apply \
  --unidiff-zero --whitespace=nowarn "$XMAGE_PATCH_FILE"
git -C "$WORK_DIR/xmage" add -A
test "$(git -C "$WORK_DIR/xmage" write-tree)" = "$XMAGE_PATCH_TREE"
git -C "$WORK_DIR/xmage" reset --hard -q "$XMAGE_COMMIT"
git -C "$WORK_DIR/xmage" remote add governed "$XMAGE_PATCH_REPOSITORY"
git -C "$WORK_DIR/xmage" fetch --depth 2 governed "$XMAGE_PATCH_COMMIT" >&2
test "$(git -C "$WORK_DIR/xmage" rev-parse FETCH_HEAD)" = "$XMAGE_PATCH_COMMIT"
test "$(git -C "$WORK_DIR/xmage" rev-parse FETCH_HEAD^)" = "$XMAGE_COMMIT"
test "$(git -C "$WORK_DIR/xmage" rev-parse 'FETCH_HEAD^{tree}')" = "$XMAGE_PATCH_TREE"
git -C "$WORK_DIR/xmage" checkout -q --detach FETCH_HEAD

grep -A2 '<artifactId>sqlite-jdbc</artifactId>' \
  "$WORK_DIR/xmage/Mage.Server/pom.xml" | grep -Fq "$SQLITE_JDBC_VERSION"

mvn -B -Dmaven.repo.local="$MAVEN_REPO_LOCAL" \
  -f "$WORK_DIR/xmage/pom.xml" -pl Mage.Server -am install \
  -DskipTests -Djacoco.skip=true >&2
mvn -B -Dmaven.repo.local="$MAVEN_REPO_LOCAL" \
  -f "$WORK_DIR/xmage/Mage.Server/pom.xml" package assembly:single \
  -DskipTests -Djacoco.skip=true >&2

ASSEMBLED_ZIP="$WORK_DIR/xmage/Mage.Server/target/mage-server.zip"
if [[ ! -s "$ASSEMBLED_ZIP" ]]; then
  echo "XMage assembly did not produce mage-server.zip" >&2
  exit 1
fi
unzip -tq "$ASSEMBLED_ZIP" >/dev/null

mkdir -p "$RUNTIME_DIR"
mkdir -p "$MAVEN_REPO_LOCAL"
zip_tmp="$RUNTIME_ZIP.tmp.$$"
marker_tmp="$RUNTIME_MARKER.tmp.$$"
maven_marker_tmp="$MAVEN_PIN_MARKER.tmp.$$"
cp "$ASSEMBLED_ZIP" "$zip_tmp"
zip_sha="$(shasum -a 256 "$zip_tmp" | awk '{print $1}')"
{
  printf '%s\n' "$PIN_FINGERPRINT"
  printf 'sha256=%s\n' "$zip_sha"
} >"$marker_tmp"
printf '%s\n' "$MAVEN_PIN_FINGERPRINT" >"$maven_marker_tmp"
mv -f "$zip_tmp" "$RUNTIME_ZIP"
mv -f "$marker_tmp" "$RUNTIME_MARKER"
mv -f "$maven_marker_tmp" "$MAVEN_PIN_MARKER"

if ! runtime_ready || ! maven_artifacts_ready; then
  echo "Cached XMage runtime failed post-write verification" >&2
  exit 1
fi
printf '%s\n' "$RUNTIME_ZIP"

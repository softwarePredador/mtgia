#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SIDECAR_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
REPOSITORY_ROOT="$(CDPATH='' cd -- "$SIDECAR_DIR/../.." && pwd)"
XMAGE_COMMIT="$(tr -d '[:space:]' < "$SIDECAR_DIR/XMAGE_COMMIT")"
XMAGE_PATCH_COMMIT="$(tr -d '[:space:]' < "$SIDECAR_DIR/XMAGE_PATCH_COMMIT")"
XMAGE_VERSION="1.4.60"
SQLITE_JDBC_VERSION="3.53.2.0"
XMAGE_PATCH_REPOSITORY="https://github.com/softwarePredador/mage.git"
XMAGE_PATCH_FILE="$REPOSITORY_ROOT/docs/qa/evidence/LOREHOLD_CANDIDATE_FOCUSED_TESTS_2026-07-29.patch"
XMAGE_PATCH_SHA256="24f6e88e082a222b60e2fb890898e43d3c7ef971ee6e38550aa476f371733642"
XMAGE_PATCH_TREE="cacc9649f20ddf450528073251acd91e1d41c152"
MAVEN_REPO_LOCAL="${MAVEN_REPO_LOCAL:-${HOME:?HOME is required}/.m2/repository}"
PIN_MARKER="$MAVEN_REPO_LOCAL/.manaloom-xmage-pin"
PIN_FINGERPRINT="$XMAGE_COMMIT patch=$XMAGE_PATCH_COMMIT xmage=$XMAGE_VERSION sqlite-jdbc=$SQLITE_JDBC_VERSION"

case "$MAVEN_REPO_LOCAL" in
  /*) ;;
  *)
    echo "MAVEN_REPO_LOCAL must be an absolute path: $MAVEN_REPO_LOCAL" >&2
    exit 2
    ;;
esac

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 2
  }
}

artifact_ready() {
  [[ -s "$MAVEN_REPO_LOCAL/org/mage/mage-common/$XMAGE_VERSION/mage-common-$XMAGE_VERSION.jar" ]] &&
    [[ -s "$MAVEN_REPO_LOCAL/org/mage/mage-sets/$XMAGE_VERSION/mage-sets-$XMAGE_VERSION.jar" ]] &&
    [[ -r "$PIN_MARKER" ]] &&
    [[ "$(<"$PIN_MARKER")" == "$PIN_FINGERPRINT" ]]
}

if artifact_ready; then
  echo "Pinned XMage Maven artifacts already available in $MAVEN_REPO_LOCAL"
  exit 0
fi

require_command git
require_command mvn
require_command shasum

OBSERVED_XMAGE_PATCH_SHA256="$(
  shasum -a 256 "$XMAGE_PATCH_FILE" | awk '{print $1}'
)"
if [[ ! "$XMAGE_COMMIT" =~ ^[0-9a-f]{40}$ ||
      ! "$XMAGE_PATCH_COMMIT" =~ ^[0-9a-f]{40}$ ||
      "$OBSERVED_XMAGE_PATCH_SHA256" != "$XMAGE_PATCH_SHA256" ]]; then
  echo "Governed XMage patch identity is invalid" >&2
  exit 2
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-xmage-bootstrap.XXXXXX")"
cleanup() {
  find "$WORK_DIR" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

git -C "$WORK_DIR" init -q xmage
git -C "$WORK_DIR/xmage" remote add upstream https://github.com/magefree/mage.git
git -C "$WORK_DIR/xmage" fetch --depth 1 upstream "$XMAGE_COMMIT"
git -C "$WORK_DIR/xmage" checkout --detach FETCH_HEAD
test "$(git -C "$WORK_DIR/xmage" rev-parse HEAD)" = "$XMAGE_COMMIT"
git -C "$WORK_DIR/xmage" apply --check --unidiff-zero "$XMAGE_PATCH_FILE"
git -C "$WORK_DIR/xmage" apply \
  --unidiff-zero --whitespace=nowarn "$XMAGE_PATCH_FILE"
git -C "$WORK_DIR/xmage" add -A
test "$(git -C "$WORK_DIR/xmage" write-tree)" = "$XMAGE_PATCH_TREE"
git -C "$WORK_DIR/xmage" reset --hard -q "$XMAGE_COMMIT"
git -C "$WORK_DIR/xmage" remote add governed "$XMAGE_PATCH_REPOSITORY"
git -C "$WORK_DIR/xmage" fetch --depth 2 governed "$XMAGE_PATCH_COMMIT"
test "$(git -C "$WORK_DIR/xmage" rev-parse FETCH_HEAD)" = \
  "$XMAGE_PATCH_COMMIT"
test "$(git -C "$WORK_DIR/xmage" rev-parse FETCH_HEAD^)" = "$XMAGE_COMMIT"
test "$(git -C "$WORK_DIR/xmage" rev-parse FETCH_HEAD^{tree})" = \
  "$XMAGE_PATCH_TREE"
git -C "$WORK_DIR/xmage" checkout -q --detach FETCH_HEAD

# Fail closed if the dependency graph at the exact pin differs from the
# reviewed production build. Do not rewrite an upstream dependency downward.
grep -A2 '<artifactId>sqlite-jdbc</artifactId>' \
  "$WORK_DIR/xmage/Mage.Server/pom.xml" | grep -Fq "$SQLITE_JDBC_VERSION"

mvn -B \
  -Dmaven.repo.local="$MAVEN_REPO_LOCAL" \
  -f "$WORK_DIR/xmage/pom.xml" \
  -pl Mage.Server \
  -am \
  install \
  -DskipTests \
  -Djacoco.skip=true

mkdir -p "$MAVEN_REPO_LOCAL"
marker_tmp="$PIN_MARKER.tmp.$$"
printf '%s\n' "$PIN_FINGERPRINT" >"$marker_tmp"
mv -f "$marker_tmp" "$PIN_MARKER"

if ! artifact_ready; then
  echo "Pinned XMage Maven bootstrap completed without required artifacts" >&2
  exit 1
fi

echo "Installed pinned XMage $XMAGE_COMMIT with governed patch $XMAGE_PATCH_COMMIT in $MAVEN_REPO_LOCAL"

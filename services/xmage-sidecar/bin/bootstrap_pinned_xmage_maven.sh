#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SIDECAR_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
XMAGE_COMMIT="$(tr -d '[:space:]' < "$SIDECAR_DIR/XMAGE_COMMIT")"
XMAGE_VERSION="1.4.60"
SQLITE_JDBC_VERSION="3.50.2.0"
MAVEN_REPO_LOCAL="${MAVEN_REPO_LOCAL:-${HOME:?HOME is required}/.m2/repository}"
PIN_MARKER="$MAVEN_REPO_LOCAL/.manaloom-xmage-pin"
PIN_FINGERPRINT="$XMAGE_COMMIT xmage=$XMAGE_VERSION sqlite-jdbc=$SQLITE_JDBC_VERSION"

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
require_command perl

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-xmage-bootstrap.XXXXXX")"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

git -C "$WORK_DIR" init -q xmage
git -C "$WORK_DIR/xmage" remote add origin https://github.com/magefree/mage.git
git -C "$WORK_DIR/xmage" fetch --depth 1 origin "$XMAGE_COMMIT"
git -C "$WORK_DIR/xmage" checkout --detach FETCH_HEAD
test "$(git -C "$WORK_DIR/xmage" rev-parse HEAD)" = "$XMAGE_COMMIT"

# Keep the host bootstrap aligned with the pinned production Docker build.
perl -0pi -e \
  's#<version>3\.32\.3\.2</version>#<version>3.50.2.0</version>#' \
  "$WORK_DIR/xmage/Mage.Server/pom.xml"
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

echo "Installed pinned XMage $XMAGE_COMMIT artifacts in $MAVEN_REPO_LOCAL"

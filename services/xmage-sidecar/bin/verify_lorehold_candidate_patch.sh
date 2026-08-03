#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SIDECAR_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
REPOSITORY_ROOT="$(CDPATH='' cd -- "$SIDECAR_DIR/../.." && pwd)"

EXPECTED_PIN="2c43ec8cdb5cd475d47e6b555a4077151f476a3b"
MIRACLE_SOURCE_COMMIT="03cc893d7c982c195ffc3f8e3083e9123b5c17d0"
LOREHOLD_SOURCE_COMMIT="0e6ca9cacaf612d00f18d68d39531c0666f570c1"
PATCH_SHA256="24f6e88e082a222b60e2fb890898e43d3c7ef971ee6e38550aa476f371733642"
PATCH_FILE="$REPOSITORY_ROOT/docs/qa/evidence/LOREHOLD_CANDIDATE_FOCUSED_TESTS_2026-07-29.patch"
UPSTREAM_URL="https://github.com/magefree/mage.git"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 2
  }
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
    return
  fi
  sha256sum "$1" | awk '{print $1}'
}

require_command awk
require_command git
require_command grep
require_command mvn
require_command sort

ACTUAL_PIN="$(tr -d '[:space:]' <"$SIDECAR_DIR/XMAGE_COMMIT")"
if [[ "$ACTUAL_PIN" != "$EXPECTED_PIN" ]]; then
  echo "Canonical pin changed; refusing to verify the Lorehold patch." >&2
  echo "expected=$EXPECTED_PIN actual=$ACTUAL_PIN" >&2
  exit 1
fi

if [[ ! -s "$PATCH_FILE" ]]; then
  echo "Lorehold patch not found: $PATCH_FILE" >&2
  exit 1
fi

ACTUAL_PATCH_SHA256="$(sha256_file "$PATCH_FILE")"
if [[ "$ACTUAL_PATCH_SHA256" != "$PATCH_SHA256" ]]; then
  echo "Lorehold patch digest mismatch." >&2
  echo "expected=$PATCH_SHA256 actual=$ACTUAL_PATCH_SHA256" >&2
  exit 1
fi

JAVA17_HOME="${XMAGE_LOREHOLD_JAVA_HOME:-}"
if [[ -z "$JAVA17_HOME" && -x /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home/bin/java ]]; then
  JAVA17_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
elif [[ -z "$JAVA17_HOME" && -n "${JAVA_HOME:-}" ]]; then
  JAVA17_HOME="$JAVA_HOME"
fi

if [[ -n "$JAVA17_HOME" ]]; then
  case "$JAVA17_HOME" in
    /*) ;;
    *)
      echo "XMAGE_LOREHOLD_JAVA_HOME must be an absolute path." >&2
      exit 2
      ;;
  esac
  if [[ ! -x "$JAVA17_HOME/bin/java" ]]; then
    echo "Java executable not found under $JAVA17_HOME." >&2
    exit 2
  fi
  JAVA_COMMAND="$JAVA17_HOME/bin/java"
else
  require_command java
  JAVA_COMMAND="$(command -v java)"
fi

JAVA_VERSION="$("$JAVA_COMMAND" -version 2>&1 | head -n 1)"
if [[ "$JAVA_VERSION" != *'"17.'* ]]; then
  echo "Lorehold candidate verification requires Java 17." >&2
  echo "detected=$JAVA_VERSION" >&2
  exit 2
fi

MAVEN_REPO_LOCAL="${MAVEN_REPO_LOCAL:-${HOME:?HOME is required}/.m2/repository}"
case "$MAVEN_REPO_LOCAL" in
  /*) ;;
  *)
    echo "MAVEN_REPO_LOCAL must be an absolute path." >&2
    exit 2
    ;;
esac
MAVEN_REPO_ARG="-Dmaven.repo.local=$MAVEN_REPO_LOCAL"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-lorehold-patch.XXXXXX")"
cleanup() {
  find "$WORK_DIR" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

git -C "$WORK_DIR" init -q xmage
git -C "$WORK_DIR/xmage" remote add origin "$UPSTREAM_URL"
git -C "$WORK_DIR/xmage" fetch --depth 1 origin "$EXPECTED_PIN"
git -C "$WORK_DIR/xmage" checkout -q --detach FETCH_HEAD
test "$(git -C "$WORK_DIR/xmage" rev-parse HEAD)" = "$EXPECTED_PIN"

git -C "$WORK_DIR/xmage" apply --check --unidiff-zero "$PATCH_FILE"
git -C "$WORK_DIR/xmage" apply --unidiff-zero --whitespace=nowarn "$PATCH_FILE"

changed_paths() {
  {
    git -C "$WORK_DIR/xmage" diff --name-only
    git -C "$WORK_DIR/xmage" ls-files --others --exclude-standard
  } | LC_ALL=C sort -u
}

CHANGED_COUNT="$(
  changed_paths |
    wc -l |
    tr -d '[:space:]'
)"
if [[ "$CHANGED_COUNT" != "17" ]]; then
  echo "Unexpected Lorehold patch scope: $CHANGED_COUNT files." >&2
  exit 1
fi

CHANGED_PATHS="$(changed_paths)"
for required_path in \
  "Mage.Sets/src/mage/cards/l/LoreholdTheHistorian.java" \
  "Mage.Sets/src/mage/sets/SecretsOfStrixhaven.java" \
  "Mage.Server/src/main/java/mage/server/TableController.java" \
  "Mage.Tests/src/test/java/org/mage/test/cards/abilities/keywords/MiracleTest.java" \
  "Mage.Tests/src/test/java/org/mage/test/game/MatchOptionsRuntimeBoundaryTest.java" \
  "Mage/src/main/java/mage/abilities/common/MiracleGrantedAbility.java" \
  "Mage/src/main/java/mage/abilities/effects/common/cost/MiracleCostModifier.java" \
  "Mage/src/main/java/mage/abilities/effects/common/cost/MiracleCostModifierFlat.java" \
  "Mage/src/main/java/mage/abilities/keyword/MiracleAbility.java" \
  "Mage/src/main/java/mage/game/match/MatchOptions.java" \
  "Mage/src/main/java/mage/game/permanent/PermanentCard.java" \
  "Mage/src/main/java/mage/game/permanent/PermanentImpl.java" \
  "Mage/src/main/java/mage/util/CardUtil.java" \
  "Mage/src/main/java/mage/util/functions/MiracleCostModifierCreator.java" \
  "Mage/src/main/java/mage/watchers/Watcher.java" \
  "Mage/src/main/java/mage/watchers/Watchers.java" \
  "Mage/src/main/java/mage/watchers/common/MiracleGrantedWatcher.java"; do
  printf '%s\n' "$CHANGED_PATHS" | grep -Fxq "$required_path" || {
    echo "Required patch path missing: $required_path" >&2
    exit 1
  }
done

if printf '%s\n' "$CHANGED_PATHS" |
  grep -Eq '(^|/)(XMAGE_COMMIT|pom\.xml|Dockerfile)$'; then
  echo "Lorehold patch attempted to change a pin or build identity file." >&2
  exit 1
fi

if [[ -n "$JAVA17_HOME" ]]; then
  export JAVA_HOME="$JAVA17_HOME"
  export PATH="$JAVA17_HOME/bin:$PATH"
fi

mvn -B \
  -Dstyle.color=never \
  "$MAVEN_REPO_ARG" \
  -f "$WORK_DIR/xmage/pom.xml" \
  -pl Mage.Tests \
  -am \
  -Dtest=MiracleTest,MatchOptionsRuntimeBoundaryTest \
  -Dsurefire.failIfNoSpecifiedTests=false \
  -Djacoco.skip=true \
  test

echo "LOREHOLD_PATCH_VERIFY=pass"
echo "LOREHOLD_PATCH_BASE=$EXPECTED_PIN"
echo "LOREHOLD_PATCH_SHA256=$PATCH_SHA256"
echo "LOREHOLD_SOURCE_PR=15591"
echo "LOREHOLD_SOURCE_COMMITS=$MIRACLE_SOURCE_COMMIT,$LOREHOLD_SOURCE_COMMIT"
echo "LOREHOLD_CANONICAL_PIN_CHANGED=false"
echo "LOREHOLD_POSTGRES_MUTATIONS=0"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SIDECAR_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
REPOSITORY_ROOT="$(CDPATH='' cd -- "$SIDECAR_DIR/../.." && pwd)"

FROM_PIN="34d81ea4995ce15d7e1a788dc6d2a3595d35bcec"
TO_PIN="2c43ec8cdb5cd475d47e6b555a4077151f476a3b"
UPSTREAM_URL="https://github.com/magefree/mage.git"

ADDED_PATCH="$REPOSITORY_ROOT/docs/qa/evidence/XMAGE_PRODUCT_SCOPE_ADDED_CARDS_TESTS_34d81ea_2c43ec8.patch"
EXECUTABLE_PATCH="$REPOSITORY_ROOT/docs/qa/evidence/XMAGE_PRODUCT_SCOPE_EXECUTABLE_TESTS_34d81ea_2c43ec8.patch"
PRESENTATION_PATCH="$REPOSITORY_ROOT/docs/qa/evidence/XMAGE_PRODUCT_SCOPE_PRESENTATION_EQUIVALENCE_TESTS_34d81ea_2c43ec8.patch"
EVIDENCE="$REPOSITORY_ROOT/docs/qa/evidence/XMAGE_PRODUCT_SCOPE_FOCUSED_TEST_EVIDENCE_34d81ea_2c43ec8_2026-07-30.json"

ADDED_PATCH_SHA256="b780f68d61d06f4c16e63c9a562f22b5e1f7ea187fef9f46242be00fb81b7133"
EXECUTABLE_PATCH_SHA256="5bf913c5224d495e5fa702097833e3fb9db7a12dbc7472e0229ad76a3206ce0b"
PRESENTATION_PATCH_SHA256="796b7952d77f5e72cecc0c0f6792cd55ae393562944b41334179c80f345861f9"
EVIDENCE_SHA256="072733572f51c80496dc112f186eee428e27d63c809af4d5b19dc98934245f5b"

ADDED_SOURCE="Mage.Tests/src/test/java/org/mage/test/cards/single/manaloom/ManaLoomProductInScopeMarvelCardsTest.java"
EXECUTABLE_SOURCE="Mage.Tests/src/test/java/org/mage/test/cards/single/XmagePinProductScopeTransitionTest.java"
PRESENTATION_SOURCE="Mage.Tests/src/test/java/org/mage/test/cards/single/XmageProductInScopePresentationEquivalenceTest.java"
ADDED_SOURCE_SHA256="42f63ed2d359bca3d51e1caf1ba2fe925f2bd5bcf66579f0c9a27bbe37704316"
EXECUTABLE_SOURCE_SHA256="49428ceb929f2bb8b1b1a6f35292742e726e27474c352a817d5ddff609921250"
PRESENTATION_SOURCE_SHA256="9270f7dce337b943c6b3979b1e27a8b7a68cc81042beccbe2cf1280057859369"

ADDED_CLASS="org.mage.test.cards.single.manaloom.ManaLoomProductInScopeMarvelCardsTest"
EXECUTABLE_CLASS="org.mage.test.cards.single.XmagePinProductScopeTransitionTest"
PRESENTATION_CLASS="org.mage.test.cards.single.XmageProductInScopePresentationEquivalenceTest"
TO_TEST_CLASSES="$ADDED_CLASS,$EXECUTABLE_CLASS,$PRESENTATION_CLASS"

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

require_digest() {
  local file="$1"
  local expected="$2"
  local actual=""
  if [[ ! -s "$file" ]]; then
    echo "Required semantic evidence is missing: $file" >&2
    exit 1
  fi
  actual="$(sha256_file "$file")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Semantic evidence digest mismatch: $file" >&2
    echo "expected=$expected actual=$actual" >&2
    exit 1
  fi
}

clone_pin() {
  local destination="$1"
  local pin="$2"
  git init -q "$destination"
  git -C "$destination" remote add origin "$UPSTREAM_URL"
  git -C "$destination" fetch -q --depth 1 origin "$pin"
  git -C "$destination" checkout -q --detach FETCH_HEAD
  if [[ "$(git -C "$destination" rev-parse HEAD)" != "$pin" ]]; then
    echo "Exact XMage pin checkout failed: $pin" >&2
    exit 1
  fi
}

apply_test_patch() {
  local checkout="$1"
  local patch="$2"
  git -C "$checkout" apply --check --unidiff-zero "$patch"
  git -C "$checkout" apply \
    --unidiff-zero \
    --whitespace=nowarn \
    "$patch"
}

assert_changed_paths() {
  local checkout="$1"
  shift
  local observed=""
  local expected=""
  observed="$(
    {
      git -C "$checkout" diff --name-only
      git -C "$checkout" ls-files --others --exclude-standard
    } | LC_ALL=C sort -u
  )"
  expected="$(printf '%s\n' "$@" | LC_ALL=C sort)"
  if [[ "$observed" != "$expected" ]]; then
    echo "Product-scope patches changed an unexpected path." >&2
    printf 'observed:\n%s\nexpected:\n%s\n' "$observed" "$expected" >&2
    exit 1
  fi
  if printf '%s\n' "$observed" |
    grep -Ev '^Mage\.Tests/src/test/java/' >/dev/null; then
    echo "Product-scope patches attempted to change non-test sources." >&2
    exit 1
  fi
}

require_report() {
  local file="$1"
  local expected_tests="$2"
  if [[ ! -s "$file" ]]; then
    echo "Expected Surefire report is missing: $file" >&2
    exit 1
  fi
  if ! grep -Eq \
    "<testsuite .*tests=\"$expected_tests\".*errors=\"0\".*skipped=\"0\".*failures=\"0\"" \
    "$file"; then
    echo "Surefire report did not contain the expected passing suite: $file" >&2
    exit 1
  fi
}

require_command awk
require_command git
require_command grep
require_command jq
require_command mvn
require_command sort

ACTUAL_PIN="$(tr -d '[:space:]' <"$SIDECAR_DIR/XMAGE_COMMIT")"
if [[ "$ACTUAL_PIN" != "$TO_PIN" ]]; then
  echo "Canonical pin changed; refusing to reuse transition tests." >&2
  echo "expected=$TO_PIN actual=$ACTUAL_PIN" >&2
  exit 1
fi

require_digest "$ADDED_PATCH" "$ADDED_PATCH_SHA256"
require_digest "$EXECUTABLE_PATCH" "$EXECUTABLE_PATCH_SHA256"
require_digest "$PRESENTATION_PATCH" "$PRESENTATION_PATCH_SHA256"
require_digest "$EVIDENCE" "$EVIDENCE_SHA256"

if grep -Eq '(/tmp/|/Library/|/Users/)' "$EVIDENCE"; then
  echo "Versioned evidence contains a machine-local absolute path." >&2
  exit 1
fi

jq -e \
  --arg from "$FROM_PIN" \
  --arg to "$TO_PIN" \
  '
    .from_pin == $from and
    .to_pin == $to and
    .combined_test_count == 68 and
    .combined_execution.tests == 68 and
    .combined_execution.failures == 0 and
    .combined_execution.errors == 0 and
    .combined_execution.skipped == 0 and
    (.combined_execution.reports | length) == 4 and
    ([.combined_execution.reports[].tests] | add) == 68 and
    (.focused_runs | length) == 3 and
    .product_scope.direct_focused_test_card_count == 31 and
    (.product_scope.direct_focused_test_cards | sort) ==
      ([.focused_runs[].cards[]] | unique | sort) and
    .product_scope.product_in_scope_direct_focused_test_card_count == 29 and
    .product_scope.external_runtime_gap_quarantine_card_count == 2 and
    (.product_scope.external_runtime_gap_quarantine_cards | sort) ==
      (["Mandate of Peace", "Planetarium of Wan Shi Tong"] | sort) and
    .product_scope.exact_non_executable_card_count == 5 and
    (.product_scope.exact_non_executable_cards | sort) ==
      ([
        "Avengers Tower",
        "Black Panther, Vanguard",
        "Currency Converter",
        "Metallic Mimic",
        "The Ruinous Wrecking Crew"
      ] | sort) and
    .validation.patch_count == 3 and
    .validation.source_count == 3 and
    .validation.execution_report_count == 4 and
    .validation.separate_maven_repositories_per_pin == true and
    .validation.from_pin_maven_repository !=
      .validation.to_pin_maven_repository and
    (.validation.from_pin_maven_repository | endswith("/m2-from")) and
    (.validation.to_pin_maven_repository | endswith("/m2-to")) and
    .validation.same_java_major_version == 17 and
    .validation.java_runtime_isolated == true and
    .validation.path_placeholders_normalized == true and
    .validation.local_absolute_paths_present == false and
    .presentation_equivalence.from_pin_result.maven_repository !=
      .presentation_equivalence.to_pin_result.maven_repository and
    (.presentation_equivalence.from_pin_result.maven_repository |
      endswith("/m2-from")) and
    (.presentation_equivalence.to_pin_result.maven_repository |
      endswith("/m2-to")) and
    .presentation_equivalence.from_pin_result.java_version == "17.0.10" and
    .presentation_equivalence.to_pin_result.java_version == "17.0.10" and
    .presentation_equivalence.obligation_count == 11 and
    .presentation_equivalence.test_method_count == 12 and
    (.presentation_equivalence.obligations | length) == 11 and
    .stability_recheck.consecutive_passes == 3 and
    .stability_recheck.included_in_combined_test_count == false and
    .mandate_of_peace_test_is_promotion_evidence == false
  ' "$EVIDENCE" >/dev/null

JAVA17_HOME="${XMAGE_PRODUCT_SCOPE_JAVA_HOME:-}"
if [[ -z "$JAVA17_HOME" &&
  -x /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home/bin/java ]]; then
  JAVA17_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
elif [[ -z "$JAVA17_HOME" && -n "${JAVA_HOME:-}" ]]; then
  JAVA17_HOME="$JAVA_HOME"
fi

if [[ -n "$JAVA17_HOME" ]]; then
  case "$JAVA17_HOME" in
    /*) ;;
    *)
      echo "XMAGE_PRODUCT_SCOPE_JAVA_HOME must be an absolute path." >&2
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
  echo "Product-scope semantic verification requires Java 17." >&2
  echo "detected=$JAVA_VERSION" >&2
  exit 2
fi

if [[ -n "$JAVA17_HOME" ]]; then
  export JAVA_HOME="$JAVA17_HOME"
  export PATH="$JAVA17_HOME/bin:$PATH"
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-product-scope-tests.XXXXXX")"
TO_CHECKOUT="$WORK_DIR/xmage-to"
FROM_CHECKOUT="$WORK_DIR/xmage-from"
M2_TO="$WORK_DIR/m2-to"
M2_FROM="$WORK_DIR/m2-from"
cleanup() {
  find "$WORK_DIR" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

mkdir -p "$M2_TO" "$M2_FROM"
if [[ "$M2_TO" == "$M2_FROM" ||
  "$M2_TO" != */m2-to ||
  "$M2_FROM" != */m2-from ]]; then
  echo "Separate per-pin Maven repositories were not created." >&2
  exit 1
fi

clone_pin "$TO_CHECKOUT" "$TO_PIN"
clone_pin "$FROM_CHECKOUT" "$FROM_PIN"

apply_test_patch "$TO_CHECKOUT" "$ADDED_PATCH"
apply_test_patch "$TO_CHECKOUT" "$EXECUTABLE_PATCH"
apply_test_patch "$TO_CHECKOUT" "$PRESENTATION_PATCH"
apply_test_patch "$FROM_CHECKOUT" "$PRESENTATION_PATCH"

assert_changed_paths \
  "$TO_CHECKOUT" \
  "$ADDED_SOURCE" \
  "$EXECUTABLE_SOURCE" \
  "$PRESENTATION_SOURCE"
assert_changed_paths \
  "$FROM_CHECKOUT" \
  "$PRESENTATION_SOURCE"

require_digest "$TO_CHECKOUT/$ADDED_SOURCE" "$ADDED_SOURCE_SHA256"
require_digest "$TO_CHECKOUT/$EXECUTABLE_SOURCE" "$EXECUTABLE_SOURCE_SHA256"
require_digest "$TO_CHECKOUT/$PRESENTATION_SOURCE" "$PRESENTATION_SOURCE_SHA256"
require_digest "$FROM_CHECKOUT/$PRESENTATION_SOURCE" "$PRESENTATION_SOURCE_SHA256"

mvn -B -q \
  -Dstyle.color=never \
  "-Dmaven.repo.local=$M2_TO" \
  -f "$TO_CHECKOUT/pom.xml" \
  -pl Mage.Tests \
  -am \
  -DskipTests \
  clean install

mvn -B -q \
  -Dstyle.color=never \
  "-Dmaven.repo.local=$M2_TO" \
  -f "$TO_CHECKOUT/Mage.Tests/pom.xml" \
  "-Dtest=$TO_TEST_CLASSES" \
  -Djacoco.skip=true \
  clean test

mvn -B -q \
  -Dstyle.color=never \
  "-Dmaven.repo.local=$M2_FROM" \
  -f "$FROM_CHECKOUT/pom.xml" \
  -pl Mage.Tests \
  -am \
  -DskipTests \
  clean install

mvn -B -q \
  -Dstyle.color=never \
  "-Dmaven.repo.local=$M2_FROM" \
  -f "$FROM_CHECKOUT/Mage.Tests/pom.xml" \
  "-Dtest=$PRESENTATION_CLASS" \
  -Djacoco.skip=true \
  clean test

require_report \
  "$TO_CHECKOUT/Mage.Tests/target/surefire-reports/TEST-$ADDED_CLASS.xml" \
  15
require_report \
  "$TO_CHECKOUT/Mage.Tests/target/surefire-reports/TEST-$EXECUTABLE_CLASS.xml" \
  29
require_report \
  "$TO_CHECKOUT/Mage.Tests/target/surefire-reports/TEST-$PRESENTATION_CLASS.xml" \
  12
require_report \
  "$FROM_CHECKOUT/Mage.Tests/target/surefire-reports/TEST-$PRESENTATION_CLASS.xml" \
  12

echo "XMAGE_PRODUCT_SCOPE_SEMANTIC_TESTS=pass"
echo "XMAGE_PRODUCT_SCOPE_SEMANTIC_TESTS_FROM_PIN=$FROM_PIN"
echo "XMAGE_PRODUCT_SCOPE_SEMANTIC_TESTS_TO_PIN=$TO_PIN"
echo "XMAGE_PRODUCT_SCOPE_SEMANTIC_TESTS_TOTAL=68"
echo "XMAGE_PRODUCT_SCOPE_SEMANTIC_TEST_REPORTS=4"
echo "XMAGE_PRODUCT_SCOPE_MAVEN_REPOSITORIES_SEPARATE=true"
echo "XMAGE_PRODUCT_SCOPE_JAVA_MAJOR=17"
echo "XMAGE_PRODUCT_SCOPE_CARD_SOURCE_MUTATIONS=0"

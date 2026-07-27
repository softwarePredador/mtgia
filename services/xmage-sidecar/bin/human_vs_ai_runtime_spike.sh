#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SIDECAR_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
SERVER_HOST="${XMAGE_SERVER_HOST:-127.0.0.1}"
SERVER_PORT="${XMAGE_SERVER_PORT:-17171}"
RUNTIME_RUNS="${BL7_RUNTIME_RUNS:-3}"
MATCH_TIMEOUT_MS="${BL7_MATCH_TIMEOUT_MS:-180000}"
IDLE_TIMEOUT_MS="${BL7_IDLE_TIMEOUT_MS:-20000}"
RUN_TIMEOUT_PROBE="${BL7_RUNTIME_TIMEOUT_PROBE:-true}"
TIMEOUT_PROBE_MS="${BL7_TIMEOUT_PROBE_MS:-1000}"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 2
  }
}

require_positive_integer() {
  [[ "$2" =~ ^[1-9][0-9]*$ ]] || {
    echo "$1 must be a positive integer" >&2
    exit 2
  }
}

case "$SERVER_HOST" in
  127.0.0.1 | localhost | ::1)
    ;;
  *)
    echo "BL7 runtime spike only accepts a loopback XMage server" >&2
    exit 2
    ;;
esac

require_positive_integer "XMAGE_SERVER_PORT" "$SERVER_PORT"
require_positive_integer "BL7_RUNTIME_RUNS" "$RUNTIME_RUNS"
require_positive_integer "BL7_MATCH_TIMEOUT_MS" "$MATCH_TIMEOUT_MS"
require_positive_integer "BL7_IDLE_TIMEOUT_MS" "$IDLE_TIMEOUT_MS"
require_positive_integer "BL7_TIMEOUT_PROBE_MS" "$TIMEOUT_PROBE_MS"
[[ "$RUN_TIMEOUT_PROBE" == "true" || "$RUN_TIMEOUT_PROBE" == "false" ]] || {
  echo "BL7_RUNTIME_TIMEOUT_PROBE must be true or false" >&2
  exit 2
}
require_command java
require_command mvn

"$SCRIPT_DIR/bootstrap_pinned_xmage_maven.sh"

AUDIT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-bl7-runtime-client.XXXXXX")"
cleanup() {
  find "$AUDIT_DIR" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

(
  cd "$SIDECAR_DIR"
  mvn -B -Dstyle.color=never \
    -DincludeScope=test \
    -Dmdep.outputFile="$AUDIT_DIR/dependencies.classpath" \
    dependency:build-classpath \
    test-compile
)

DEPENDENCY_CLASSPATH=""
IFS= read -r DEPENDENCY_CLASSPATH <"$AUDIT_DIR/dependencies.classpath" \
  || [[ -n "$DEPENDENCY_CLASSPATH" ]]
RUNTIME_CLASSPATH="$SIDECAR_DIR/target/test-classes:$SIDECAR_DIR/target/classes:$DEPENDENCY_CLASSPATH"

echo "BL7_RUNTIME_SCOPE=isolated_test_only_loopback"
echo "BL7_RUNTIME_RUNS_REQUESTED=$RUNTIME_RUNS"

for ((run_index = 1; run_index <= RUNTIME_RUNS; run_index++)); do
  run_id="bl7_${$}_${run_index}"
  echo "BL7_RUNTIME_RUN_START=$run_index"
  (
    cd "$AUDIT_DIR"
    java \
      --add-opens java.base/java.io=ALL-UNNAMED \
      -Xms128m \
      -Xmx1g \
      -Djava.awt.headless=true \
      -Djava.net.preferIPv4Stack=true \
      -cp "$RUNTIME_CLASSPATH" \
      com.manaloom.xmage.HumanVsAiRuntimeSpikeMain \
      "--host=$SERVER_HOST" \
      "--port=$SERVER_PORT" \
      "--timeout-ms=$MATCH_TIMEOUT_MS" \
      "--idle-timeout-ms=$IDLE_TIMEOUT_MS" \
      "--run-id=$run_id"
  )
  echo "BL7_RUNTIME_RUN_PASS=$run_index"
done

echo "BL7_RUNTIME_RUNS_COMPLETED=$RUNTIME_RUNS"

if [[ "$RUN_TIMEOUT_PROBE" == "true" ]]; then
  echo "BL7_RUNTIME_TIMEOUT_PROBE_START=true"
  (
    cd "$AUDIT_DIR"
    java \
      --add-opens java.base/java.io=ALL-UNNAMED \
      -Xms128m \
      -Xmx1g \
      -Djava.awt.headless=true \
      -Djava.net.preferIPv4Stack=true \
      -cp "$RUNTIME_CLASSPATH" \
      com.manaloom.xmage.HumanVsAiRuntimeSpikeMain \
      "--host=$SERVER_HOST" \
      "--port=$SERVER_PORT" \
      "--timeout-ms=$TIMEOUT_PROBE_MS" \
      "--idle-timeout-ms=$IDLE_TIMEOUT_MS" \
      "--expect-timeout=true" \
      "--run-id=timeout_${$}"
  )
  echo "BL7_RUNTIME_TIMEOUT_PROBE_PASS=true"
fi

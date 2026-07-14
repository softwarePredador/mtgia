#!/usr/bin/env bash
set -euo pipefail

XMAGE_SERVER_PORT="${XMAGE_SERVER_PORT:-17171}"
XMAGE_CONFIG="/opt/xmage/config/config.xml"
read -r -a server_java_opts <<<"${XMAGE_SERVER_JAVA_OPTS:--Xms256m -Xmx2g}"
read -r -a sidecar_java_opts <<<"${XMAGE_SIDECAR_JAVA_OPTS:--Xms128m -Xmx512m}"

sed -i 's/serverAddress="[^"]*"/serverAddress="127.0.0.1"/' "$XMAGE_CONFIG"
sed -i "s/port=\"[0-9]*\"/port=\"${XMAGE_SERVER_PORT}\"/" "$XMAGE_CONFIG"

cd /opt/xmage
sidecar_pid=""
server_jar="$(find /opt/xmage/lib -maxdepth 1 -name 'mage-server-*.jar' -print -quit)"
if [[ -z "$server_jar" ]]; then
  echo "XMage server jar is missing from the runtime image" >&2
  exit 1
fi
java \
  --add-opens java.base/java.io=ALL-UNNAMED \
  "${server_java_opts[@]}" \
  -Dxmage.testMode=true \
  -jar "$server_jar" \
  -testMode=true &
xmage_pid=$!

cleanup() {
  if [[ -n "$sidecar_pid" ]]; then
    kill "$sidecar_pid" 2>/dev/null || true
  fi
  kill "$xmage_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for _attempt in $(seq 1 120); do
  if (echo > "/dev/tcp/127.0.0.1/${XMAGE_SERVER_PORT}") 2>/dev/null; then
    break
  fi
  if ! kill -0 "$xmage_pid" 2>/dev/null; then
    echo "XMage server exited before becoming ready" >&2
    exit 1
  fi
  sleep 1
done

if ! (echo > "/dev/tcp/127.0.0.1/${XMAGE_SERVER_PORT}") 2>/dev/null; then
  echo "XMage server did not become ready within 120 seconds" >&2
  exit 1
fi

cd /opt/manaloom
java \
  --add-opens java.base/java.io=ALL-UNNAMED \
  "${sidecar_java_opts[@]}" \
  -jar xmage-sidecar.jar &
sidecar_pid=$!

wait -n "$xmage_pid" "$sidecar_pid"

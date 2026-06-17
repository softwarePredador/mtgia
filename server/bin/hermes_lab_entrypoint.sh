#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/opt/data}"
WORKSPACE_ROOT="${HERMES_WORKSPACE_ROOT:-$HERMES_HOME/workspace}"
REPO_DIR="${HERMES_REPO_DIR:-$WORKSPACE_ROOT/mtgia}"
REPO_URL="${HERMES_REPO_URL:-https://github.com/softwarePredador/mtgia.git}"
REPO_REF="${HERMES_REPO_REF:-master}"
REPO_AUTO_SYNC="${HERMES_REPO_AUTO_SYNC:-0}"
FLUTTER_BIN="/opt/tools/flutter/bin"
DART_BIN="/opt/tools/flutter/bin/cache/dart-sdk/bin"
PUB_CACHE_BIN="/root/.pub-cache/bin"

mkdir -p "$HERMES_HOME" "$WORKSPACE_ROOT" "$HERMES_HOME/.config"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  git clone --branch "$REPO_REF" --single-branch "$REPO_URL" "$REPO_DIR"
else
  git -C "$REPO_DIR" fetch --all --prune || true
  if [[ "$REPO_AUTO_SYNC" == "1" ]]; then
    git -C "$REPO_DIR" checkout "$REPO_REF"
    git -C "$REPO_DIR" pull --ff-only origin "$REPO_REF"
  fi
fi

cat > "$HERMES_HOME/.profile" <<EOF
export PATH=$FLUTTER_BIN:$DART_BIN:$PUB_CACHE_BIN:\$PATH
export HERMES_HOME=$HERMES_HOME
export MANALOOM_WORKSPACE=$REPO_DIR
export HERMES_REPO_DIR=$REPO_DIR
EOF

export HOME="$HERMES_HOME"
export PATH="$FLUTTER_BIN:$DART_BIN:$PUB_CACHE_BIN:$PATH"

cd "$HERMES_HOME"
exec /init /opt/hermes/docker/main-wrapper.sh gateway

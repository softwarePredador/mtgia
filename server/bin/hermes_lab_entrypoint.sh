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

touch "$HERMES_HOME/.env"

upsert_env_file() {
  local key="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    return 0
  fi
  python3 - "$HERMES_HOME/.env" "$key" "$value" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
lines = path.read_text().splitlines() if path.exists() else []
prefix = f"{key}="
updated = False
out = []
for line in lines:
    if line.startswith(prefix):
        out.append(f"{key}={value}")
        updated = True
    else:
        out.append(line)
if not updated:
    out.append(f"{key}={value}")
path.write_text("\n".join(out).rstrip() + "\n")
PY
}

upsert_env_file "OPENAI_API_KEY" "${OPENAI_API_KEY:-}"
upsert_env_file "API_SERVER_KEY" "${API_SERVER_KEY:-}"

export HOME="$HERMES_HOME"
export PATH="$FLUTTER_BIN:$DART_BIN:$PUB_CACHE_BIN:$PATH"

cd "$HERMES_HOME"

if [[ -n "${HERMES_MODEL:-}" ]]; then
  hermes config set model "$HERMES_MODEL" >/dev/null 2>&1 || true
fi

if [[ "${HERMES_CRON_BOOTSTRAP:-1}" == "1" ]]; then
  if ! python3 /opt/bootstrap/hermes_lab_cron_bootstrap.py; then
    if [[ "${HERMES_CRON_BOOTSTRAP_REQUIRED:-1}" == "1" ]]; then
      echo "hermes_lab_cron_bootstrap failed and HERMES_CRON_BOOTSTRAP_REQUIRED=1" >&2
      exit 1
    fi
  fi
fi

# This wrapper already runs under the image's /init entrypoint. Calling back
# into the Docker wrapper chain again makes startup harder to reason about and
# can reintroduce upstream main-wrapper environment quirks. Launch the gateway
# directly so HERMES_HOME, PATH and workspace bootstrap stay intact.
exec hermes gateway run

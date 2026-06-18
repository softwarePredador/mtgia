#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

exec python3 "$SERVER_BIN_DIR/manaloom_ops_daemon.py"

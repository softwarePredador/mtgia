#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
BLOCKED: server/bin/optimizer_loop.sh is a historical mutating entrypoint and is disabled.
Use server/bin/master_optimizer_preflight.sh for the governed optimizer preflight.
EOF

exit 2

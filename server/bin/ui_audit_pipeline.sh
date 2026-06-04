#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -f "$script_dir/ui_audit_pipeline.py" ]; then
  exec python3 "$script_dir/ui_audit_pipeline.py" "$@"
fi

exec python3 /opt/data/scripts/ui_audit_pipeline.py "$@"

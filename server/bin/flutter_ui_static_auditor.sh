#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -f "$script_dir/flutter_ui_static_auditor.py" ]; then
  exec python3 "$script_dir/flutter_ui_static_auditor.py" "$@"
fi

exec python3 /opt/data/scripts/flutter_ui_static_auditor.py "$@"

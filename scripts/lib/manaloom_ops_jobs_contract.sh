#!/usr/bin/env bash

# S-01: the jobs the ops daemon schedules for a committed release policy.
#
# The list comes from the daemon of the same commit
# (server/bin/manaloom_ops_daemon.py --print-enabled-jobs), never from a copy
# kept in a deploy script or a test, so the post-deploy check and the scheduler
# cannot drift apart. Like the capabilities contract, only committed blobs
# count: the working tree is never release evidence.
readonly MANALOOM_OPS_DAEMON_PATH="server/bin/manaloom_ops_daemon.py"
readonly MANALOOM_OPS_POLICY_PATH="server/config/release_capabilities.json"

manaloom_ops_jobs_block() {
  echo "BLOCKED: jobs do manaloom-ops: $1" >&2
  return 2
}

# Publishes, as readonly:
# - MANALOOM_OPS_ENABLED_JOBS_JSON: the daemon output, a JSON list;
# - MANALOOM_OPS_ENABLED_JOBS_PYTHON: the same list as a Python literal with
#   single quotes, safe to embed in a double-quoted remote `python3 -c`.
manaloom_load_ops_enabled_jobs_from_git() {
  local source_root="$1"
  local source_sha="$2"
  local names_json names_python

  if ! names_json="$(
    work_dir="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-ops-jobs.XXXXXX")" || exit 2
    trap 'rm -rf "$work_dir"' EXIT
    git -C "$source_root" show "$source_sha:$MANALOOM_OPS_DAEMON_PATH" \
      >"$work_dir/manaloom_ops_daemon.py" 2>/dev/null || exit 2
    git -C "$source_root" show "$source_sha:$MANALOOM_OPS_POLICY_PATH" \
      >"$work_dir/release_capabilities.json" 2>/dev/null || exit 2
    PYTHONDONTWRITEBYTECODE=1 python3 -I "$work_dir/manaloom_ops_daemon.py" \
      --print-enabled-jobs "$work_dir/release_capabilities.json"
  )"; then
    manaloom_ops_jobs_block \
      "o daemon do SHA candidato nao publicou a lista de jobs da politica"
    return 2
  fi

  # Closed shape: a non-empty list of distinct snake_case names. Anything else
  # could break out of the remote python3 -c quoting.
  if ! names_python="$(python3 -I -c '
import json
import re
import sys

names = json.loads(sys.argv[1])
if not (
    isinstance(names, list)
    and names
    and len(set(names)) == len(names)
    and all(isinstance(n, str) and re.fullmatch(r"[a-z][a-z0-9_]*", n) for n in names)
):
    sys.exit(2)
print(repr(names))
' "$names_json" 2>/dev/null)"; then
    manaloom_ops_jobs_block "lista de jobs fora do contrato: $names_json"
    return 2
  fi

  # Public readonly outputs are consumed by scripts that source this library.
  # shellcheck disable=SC2034
  readonly MANALOOM_OPS_ENABLED_JOBS_JSON="$names_json"
  # shellcheck disable=SC2034
  readonly MANALOOM_OPS_ENABLED_JOBS_PYTHON="$names_python"
}

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
python_bin="${PYTHON_BIN:-python3}"

artifact_root="${MANALOOM_OPS_ARTIFACT_DIR:-/data/manaloom-ops/artifacts}"
export MANALOOM_BATTLE_RULE_PROMOTION_GATE_DIR="${MANALOOM_BATTLE_RULE_PROMOTION_GATE_DIR:-$artifact_root/battle_rule_promotion_gate}"
export MANALOOM_KNOWLEDGE_DB="${MANALOOM_KNOWLEDGE_DB:-${HERMES_KNOWLEDGE_DB:-/data/manaloom-ops/knowledge.db}}"
default_evidence_file="$artifact_root/battle_rule_focused_evidence/latest_evidence.json"
if [ -z "${MANALOOM_BATTLE_RULE_PROMOTION_EVIDENCE_FILE:-}" ] && [ -f "$default_evidence_file" ]; then
  export MANALOOM_BATTLE_RULE_PROMOTION_EVIDENCE_FILE="$default_evidence_file"
fi

cd "$repo_root"
exec "$python_bin" "$script_dir/manaloom_battle_rule_promotion_gate.py" "$@"

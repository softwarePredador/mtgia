#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
python_bin="${PYTHON_BIN:-python3}"

artifact_root="${MANALOOM_OPS_ARTIFACT_DIR:-/data/manaloom-ops/artifacts}"
export MANALOOM_CARD_DATA_GAP_REVIEW_DIR="${MANALOOM_CARD_DATA_GAP_REVIEW_DIR:-$artifact_root/card_data_gap_review}"
export MANALOOM_KNOWLEDGE_DB="${MANALOOM_KNOWLEDGE_DB:-${HERMES_KNOWLEDGE_DB:-/data/manaloom-ops/knowledge.db}}"

cd "$repo_root"
exec "$python_bin" "$script_dir/manaloom_card_data_gap_review.py" "$@"

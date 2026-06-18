#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
python_bin="${PYTHON_BIN:-python3}"

artifact_root="${MANALOOM_OPS_ARTIFACT_DIR:-/data/manaloom-ops/artifacts}"
export MANALOOM_NEW_CARD_CANDIDATE_REVIEW_DIR="${MANALOOM_NEW_CARD_CANDIDATE_REVIEW_DIR:-$artifact_root/new_card_candidate_review}"
export MANALOOM_KNOWLEDGE_DB="${MANALOOM_KNOWLEDGE_DB:-${HERMES_KNOWLEDGE_DB:-/data/manaloom-ops/knowledge.db}}"
export MTGIA_ENV_FILE="${MTGIA_ENV_FILE:-$repo_root/server/.env}"

cd "$repo_root"
exec "$python_bin" "$script_dir/manaloom_new_card_candidate_review.py" "$@"

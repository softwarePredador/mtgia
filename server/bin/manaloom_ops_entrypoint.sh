#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="${MANALOOM_REPO:-$(CDPATH= cd -- "$SERVER_BIN_DIR/../.." && pwd)}"
DATA_ROOT="${MANALOOM_OPS_DATA_DIR:-/data/manaloom-ops}"
LOCK_DIR="${MANALOOM_OPS_LOCK_DIR:-$DATA_ROOT/locks}"
ARTIFACT_DIR="${MANALOOM_OPS_ARTIFACT_DIR:-$DATA_ROOT/artifacts}"
KNOWLEDGE_DB="${HERMES_KNOWLEDGE_DB:-$DATA_ROOT/knowledge.db}"
ENV_FILE="${MTGIA_ENV_FILE:-$REPO_ROOT/server/.env}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
MANALOOM_DART_BIN="${MANALOOM_DART_BIN:-dart}"
PULL_CRON="${PULL_LEARNING_EVENTS_CRON:-*/30 * * * *}"
SYNC_CRON="${AUTO_SYNC_LEARNED_DECKS_CRON:-0 */2 * * *}"
PREFLIGHT_CRON="${MASTER_OPTIMIZER_PREFLIGHT_CRON:-15 * * * *}"
RUN_PREFLIGHT_ON_BOOT="${MANALOOM_RUN_PREFLIGHT_ON_BOOT:-0}"

mkdir -p "$LOCK_DIR" "$ARTIFACT_DIR" "$(dirname "$KNOWLEDGE_DB")"

cat > /etc/cron.d/manaloom-ops <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.pub-cache/bin
MTGIA_HOME=$REPO_ROOT
MTGIA_SYNC_HOME=$REPO_ROOT
MTGIA_SYNC_SERVER_DIR=$REPO_ROOT/server
MTGIA_ENV_FILE=$ENV_FILE
MTGIA_SYNC_GIT_PULL=0
PYTHON_BIN=$PYTHON_BIN
MANALOOM_DART_BIN=$MANALOOM_DART_BIN
HERMES_KNOWLEDGE_DB=$KNOWLEDGE_DB
HERMES_ARTIFACT_DIR=$ARTIFACT_DIR/hermes_auto_sync
MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR=$ARTIFACT_DIR/master_optimizer_preflight
$PULL_CRON root flock -n $LOCK_DIR/pull_learning_events.lock bash -lc 'cd "$MTGIA_HOME" && ./server/bin/pull_learning_events.sh' >> /proc/1/fd/1 2>> /proc/1/fd/2
$SYNC_CRON root flock -n $LOCK_DIR/auto_sync_learned_decks.lock bash -lc 'cd "$MTGIA_HOME" && ./server/bin/auto_sync_learned_decks.sh' >> /proc/1/fd/1 2>> /proc/1/fd/2
$PREFLIGHT_CRON root flock -n $LOCK_DIR/master_optimizer_preflight.lock bash -lc 'cd "$MTGIA_HOME" && ./server/bin/master_optimizer_preflight.sh' >> /proc/1/fd/1 2>> /proc/1/fd/2
EOF

chmod 0644 /etc/cron.d/manaloom-ops

echo "manaloom_ops_entrypoint configured"
echo "repo_root=$REPO_ROOT"
echo "data_root=$DATA_ROOT"
echo "env_file=$ENV_FILE"
echo "knowledge_db=$KNOWLEDGE_DB"
echo "pull_cron=$PULL_CRON"
echo "sync_cron=$SYNC_CRON"
echo "preflight_cron=$PREFLIGHT_CRON"

if [[ "$RUN_PREFLIGHT_ON_BOOT" == "1" ]]; then
  flock -n "$LOCK_DIR/master_optimizer_preflight.lock" bash -lc \
    "cd '$REPO_ROOT' && ./server/bin/master_optimizer_preflight.sh" \
    >> /proc/1/fd/1 2>> /proc/1/fd/2 || true
fi

exec cron -f -L 15

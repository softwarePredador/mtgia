#!/usr/bin/env bash
set -euo pipefail

# Keeps the Hermes documentation branch auditing the current product code.
#
# Intended runtime:
#   /opt/data/scripts/manaloom-docs-branch-sync.sh
#
# The script intentionally merges origin/master into codex/hermes-analysis-docs.
# It never mutates master and it aborts cleanly if a conflict appears.

REPO="${MANALOOM_WORKSPACE:-/opt/data/workspace/mtgia}"
REMOTE="${HERMES_GIT_REMOTE:-origin}"
MASTER_BRANCH="${HERMES_MASTER_BRANCH:-master}"
DOCS_BRANCH="${HERMES_DOCS_BRANCH:-codex/hermes-analysis-docs}"
STATE_DIR="${HERMES_STATE_DIR:-/opt/data/data/manaloom}"
REPORT_DIR="${HERMES_DOCS_SYNC_REPORT_DIR:-/opt/data/artifacts/hermes_docs_branch_sync}"
PUSH="${HERMES_DOCS_SYNC_PUSH:-1}"
DRY_RUN="${HERMES_DOCS_SYNC_DRY_RUN:-0}"
ALLOW_ROOT="${HERMES_DOCS_SYNC_ALLOW_ROOT:-1}"

mkdir -p "$STATE_DIR" "$REPORT_DIR"

timestamp="$(date -u +"%Y%m%d_%H%M%S")"
report="$REPORT_DIR/docs_branch_sync_${timestamp}.md"
lock_dir="$STATE_DIR/docs_branch_sync.lock"

write_report() {
  local status="$1"
  local details="$2"
  {
    echo "# Hermes Docs Branch Sync"
    echo
    echo "- status: ${status}"
    echo "- timestamp_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "- repo: ${REPO}"
    echo "- remote: ${REMOTE}"
    echo "- master_branch: ${MASTER_BRANCH}"
    echo "- docs_branch: ${DOCS_BRANCH}"
    echo "- dry_run: ${DRY_RUN}"
    echo "- push: ${PUSH}"
    echo
    echo "## Details"
    echo
    echo "${details}"
  } > "$report"
  echo "HERMES_DOCS_SYNC_REPORT: $report"
}

if [[ "${EUID:-$(id -u)}" == "0" && "$ALLOW_ROOT" != "1" ]]; then
  write_report "blocked_root_user" "Run this cron as the hermes user, not root. Set HERMES_DOCS_SYNC_ALLOW_ROOT=1 only when the runtime is a root-owned container."
  exit 64
fi

if ! mkdir "$lock_dir" 2>/dev/null; then
  write_report "skipped_locked" "Another docs branch sync is already running: ${lock_dir}"
  exit 0
fi

cleanup() {
  rmdir "$lock_dir" 2>/dev/null || true
}
trap cleanup EXIT

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true

if [[ -n "$(git status --porcelain)" ]]; then
  write_report "blocked_dirty_worktree" "The Hermes workspace has uncommitted changes. Refusing to checkout or merge before an audit."
  git status --short
  exit 2
fi

git fetch --quiet --prune "$REMOTE" \
  "+refs/heads/${MASTER_BRANCH}:refs/remotes/${REMOTE}/${MASTER_BRANCH}" \
  "+refs/heads/${DOCS_BRANCH}:refs/remotes/${REMOTE}/${DOCS_BRANCH}"

if ! git show-ref --verify --quiet "refs/remotes/${REMOTE}/${MASTER_BRANCH}"; then
  write_report "blocked_missing_master" "Remote branch ${REMOTE}/${MASTER_BRANCH} was not found after fetch."
  exit 3
fi

if ! git show-ref --verify --quiet "refs/remotes/${REMOTE}/${DOCS_BRANCH}"; then
  write_report "blocked_missing_docs_branch" "Remote branch ${REMOTE}/${DOCS_BRANCH} was not found after fetch."
  exit 4
fi

if git show-ref --verify --quiet "refs/heads/${DOCS_BRANCH}"; then
  git checkout --quiet "$DOCS_BRANCH"
else
  git checkout --quiet -b "$DOCS_BRANCH" "${REMOTE}/${DOCS_BRANCH}"
fi

git merge --ff-only --quiet "${REMOTE}/${DOCS_BRANCH}"

docs_before="$(git rev-parse HEAD)"
master_sha="$(git rev-parse "${REMOTE}/${MASTER_BRANCH}")"

if git merge-base --is-ancestor "$master_sha" HEAD; then
  write_report "up_to_date" "Docs branch already contains ${REMOTE}/${MASTER_BRANCH}@${master_sha}."
  exit 0
fi

if [[ "$DRY_RUN" == "1" ]]; then
  write_report "would_merge" "Docs branch ${docs_before} would merge ${REMOTE}/${MASTER_BRANCH}@${master_sha}."
  exit 0
fi

set +e
merge_output="$(git merge --no-ff --no-edit "${REMOTE}/${MASTER_BRANCH}" 2>&1)"
merge_status=$?
set -e

if [[ "$merge_status" -ne 0 ]]; then
  conflict_status="$(git status --short)"
  git merge --abort >/dev/null 2>&1 || true
  write_report "blocked_merge_conflict" "Merge failed and was aborted.\n\n\`\`\`\n${merge_output}\n${conflict_status}\n\`\`\`"
  exit 5
fi

docs_after="$(git rev-parse HEAD)"

if [[ "$PUSH" == "1" ]]; then
  if ! git push --quiet "$REMOTE" "HEAD:${DOCS_BRANCH}"; then
    write_report "blocked_push_failed" "Merge commit ${docs_after} was created locally, but push to ${REMOTE}/${DOCS_BRANCH} failed. Manual triage is required before audits continue."
    exit 6
  fi
fi

write_report "merged" "Merged ${REMOTE}/${MASTER_BRANCH}@${master_sha} into ${DOCS_BRANCH}.\n\n- before: ${docs_before}\n- after: ${docs_after}"

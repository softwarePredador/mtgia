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
RESTORE_BRANCH="${HERMES_DOCS_SYNC_RESTORE_BRANCH:-${HERMES_REPO_REF:-$MASTER_BRANCH}}"
STATE_DIR="${HERMES_STATE_DIR:-/opt/data/data/manaloom}"
REPORT_DIR="${HERMES_DOCS_SYNC_REPORT_DIR:-/opt/data/artifacts/hermes_docs_branch_sync}"
PUSH="${HERMES_DOCS_SYNC_PUSH:-1}"
DRY_RUN="${HERMES_DOCS_SYNC_DRY_RUN:-0}"
ALLOW_ROOT="${HERMES_DOCS_SYNC_ALLOW_ROOT:-1}"
STALE_LOCK_SECONDS="${HERMES_DOCS_SYNC_STALE_LOCK_SECONDS:-900}"
GIT_USER_NAME="${HERMES_GIT_USER_NAME:-Hermes Agent}"
GIT_USER_EMAIL="${HERMES_GIT_USER_EMAIL:-hermes-agent@local.invalid}"
GIT_PUSH_TOKEN="${HERMES_GITHUB_TOKEN:-${GITHUB_TOKEN:-${GH_TOKEN:-}}}"
GIT_TERMINAL_PROMPT=0
export GIT_TERMINAL_PROMPT

mkdir -p "$STATE_DIR" "$REPORT_DIR"

timestamp="$(date -u +"%Y%m%d_%H%M%S")"
report="$REPORT_DIR/docs_branch_sync_${timestamp}.md"
lock_dir="$STATE_DIR/docs_branch_sync.lock"
docs_checked_out=0
quarantine_details=""

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

quarantine_untracked_files() {
  local untracked_count
  untracked_count="$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
  if [[ "$untracked_count" == "0" ]]; then
    return 0
  fi

  local quarantine_dir="$REPORT_DIR/untracked_quarantine_${timestamp}"
  mkdir -p "$quarantine_dir"
  while IFS= read -r -d '' path; do
    mkdir -p "$quarantine_dir/$(dirname "$path")"
    mv -- "$path" "$quarantine_dir/$path"
  done < <(git ls-files --others --exclude-standard -z)

  quarantine_details="Quarantined ${untracked_count} untracked file(s) before branch sync: ${quarantine_dir}"
  echo "$quarantine_details"
}

restore_workspace() {
  if [[ "$docs_checked_out" != "1" ]]; then
    return 0
  fi

  if git show-ref --verify --quiet "refs/remotes/${REMOTE}/${RESTORE_BRANCH}"; then
    if git show-ref --verify --quiet "refs/heads/${RESTORE_BRANCH}"; then
      git checkout --quiet "$RESTORE_BRANCH"
      git merge --ff-only --quiet "${REMOTE}/${RESTORE_BRANCH}"
    else
      git checkout --quiet -b "$RESTORE_BRANCH" "${REMOTE}/${RESTORE_BRANCH}"
    fi
    docs_checked_out=0
    return 0
  fi

  echo "failed to restore workspace branch ${RESTORE_BRANCH}" >&2
  return 7
}

finish() {
  local status="$1"
  local details="$2"
  local exit_code="${3:-0}"
  if ! restore_workspace; then
    write_report "blocked_restore_failed" "${details}\n\nWorkspace restore to ${RESTORE_BRANCH} failed after docs sync."
    exit 7
  fi
  write_report "$status" "$details"
  exit "$exit_code"
}

if [[ "${EUID:-$(id -u)}" == "0" && "$ALLOW_ROOT" != "1" ]]; then
  write_report "blocked_root_user" "Run this cron as the hermes user, not root. Set HERMES_DOCS_SYNC_ALLOW_ROOT=1 only when the runtime is a root-owned container."
  exit 64
fi

if ! mkdir "$lock_dir" 2>/dev/null; then
  stale_lock="$(
    python3 - "$lock_dir" "$STALE_LOCK_SECONDS" <<'PY'
from __future__ import annotations

import os
import sys
import time
from pathlib import Path

path = Path(sys.argv[1])
threshold = int(sys.argv[2])
try:
    age = time.time() - path.stat().st_mtime
except FileNotFoundError:
    print("missing")
    raise SystemExit(0)
print("stale" if age >= threshold else "fresh")
PY
  )"
  if [[ "$stale_lock" == "stale" ]]; then
    rm -rf "$lock_dir"
    if mkdir "$lock_dir" 2>/dev/null; then
      echo "removed stale docs branch sync lock: ${lock_dir}"
    else
      write_report "skipped_locked" "Another docs branch sync is already running after stale lock cleanup attempt: ${lock_dir}"
      exit 0
    fi
  else
    write_report "skipped_locked" "Another docs branch sync is already running: ${lock_dir}"
    exit 0
  fi
fi

if [[ ! -f "$lock_dir/pid" ]]; then
  echo "$$" > "$lock_dir/pid" 2>/dev/null || true
fi

if [[ ! -d "$lock_dir" ]]; then
  write_report "skipped_locked" "Another docs branch sync is already running: ${lock_dir}"
  exit 0
fi

cleanup() {
  rm -f "$lock_dir/pid" 2>/dev/null || true
  rmdir "$lock_dir" 2>/dev/null || true
}
trap cleanup EXIT

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true
if [[ -z "$(git config --get user.name || true)" ]]; then
  git config --global user.name "$GIT_USER_NAME"
fi
if [[ -z "$(git config --get user.email || true)" ]]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi
remote_url="$(git remote get-url "$REMOTE" 2>/dev/null || true)"
remote_push_url="$(git remote get-url --push "$REMOTE" 2>/dev/null || true)"
if [[ -z "$remote_push_url" ]]; then
  remote_push_url="$remote_url"
fi
push_blocked_missing_token=0
if [[ "$PUSH" == "1" && -z "$GIT_PUSH_TOKEN" && "$remote_push_url" == *github.com* ]]; then
  push_blocked_missing_token=1
fi
if [[ -n "$GIT_PUSH_TOKEN" ]]; then
  repo_path=""
  case "$remote_url" in
    git@github.com:*)
      repo_path="${remote_url#git@github.com:}"
      ;;
    https://github.com/*)
      repo_path="${remote_url#https://github.com/}"
      ;;
    https://*@github.com/*)
      repo_path="${remote_url#*@github.com/}"
      ;;
  esac
  if [[ -n "$repo_path" ]]; then
    repo_path="${repo_path%.git}.git"
    git remote set-url --push "$REMOTE" "https://x-access-token:${GIT_PUSH_TOKEN}@github.com/${repo_path}"
  fi
fi

tracked_dirty="$(git status --porcelain --untracked-files=no)"
if [[ -n "$tracked_dirty" ]]; then
  write_report "blocked_dirty_worktree" "The Hermes workspace has tracked uncommitted changes. Refusing to checkout or merge before an audit.\n\n\`\`\`\n${tracked_dirty}\n\`\`\`"
  git status --short --untracked-files=no
  exit 2
fi

quarantine_untracked_files

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
  # The Hermes checkout is operational state, not the source of truth for docs.
  # If a prior run left a local merge commit that could not be pushed, recover
  # from the remote branch before creating a fresh merge from current master.
  git reset --hard --quiet "${REMOTE}/${DOCS_BRANCH}"
else
  git checkout --quiet -b "$DOCS_BRANCH" "${REMOTE}/${DOCS_BRANCH}"
fi
docs_checked_out=1

docs_before="$(git rev-parse HEAD)"
master_sha="$(git rev-parse "${REMOTE}/${MASTER_BRANCH}")"
remote_docs_before="$(git rev-parse "${REMOTE}/${DOCS_BRANCH}")"

if git merge-base --is-ancestor "$master_sha" HEAD; then
  docs_current="$(git rev-parse HEAD)"
  if [[ "$PUSH" == "1" && "$docs_current" != "$remote_docs_before" ]]; then
    if ! git push --quiet "$REMOTE" "HEAD:${DOCS_BRANCH}"; then
      finish "blocked_push_failed" "Docs branch already contains ${REMOTE}/${MASTER_BRANCH}@${master_sha} locally, but push to ${REMOTE}/${DOCS_BRANCH} failed. Manual credential triage is required before audits continue." 6
    fi
    finish "pushed_up_to_date" "Pushed local docs branch ${docs_current} to ${REMOTE}/${DOCS_BRANCH}; it already contained ${REMOTE}/${MASTER_BRANCH}@${master_sha}.\n\n${quarantine_details}"
  fi
  finish "up_to_date" "Docs branch already contains ${REMOTE}/${MASTER_BRANCH}@${master_sha}.\n\n${quarantine_details}"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  finish "would_merge" "Docs branch ${docs_before} would merge ${REMOTE}/${MASTER_BRANCH}@${master_sha}.\n\n${quarantine_details}"
fi

if [[ "$push_blocked_missing_token" == "1" ]]; then
  finish "would_merge_push_token_missing" "Docs branch ${docs_before} would merge ${REMOTE}/${MASTER_BRANCH}@${master_sha}, but ${REMOTE} push URL requires GitHub credentials and no HERMES_GITHUB_TOKEN/GITHUB_TOKEN/GH_TOKEN is configured. Remote docs sync remains manual until a token is configured.\n\n${quarantine_details}"
fi

set +e
merge_output="$(git merge --no-ff --no-edit "${REMOTE}/${MASTER_BRANCH}" 2>&1)"
merge_status=$?
set -e

if [[ "$merge_status" -ne 0 ]]; then
  conflict_status="$(git status --short)"
  git merge --abort >/dev/null 2>&1 || true
  finish "blocked_merge_conflict" "Merge failed and was aborted.\n\n\`\`\`\n${merge_output}\n${conflict_status}\n\`\`\`"
fi

docs_after="$(git rev-parse HEAD)"

if [[ "$PUSH" == "1" ]]; then
  if ! git push --quiet "$REMOTE" "HEAD:${DOCS_BRANCH}"; then
    finish "blocked_push_failed" "Merge commit ${docs_after} was created locally, but push to ${REMOTE}/${DOCS_BRANCH} failed. Manual triage is required before audits continue." 6
  fi
fi

finish "merged" "Merged ${REMOTE}/${MASTER_BRANCH}@${master_sha} into ${DOCS_BRANCH}.\n\n- before: ${docs_before}\n- after: ${docs_after}\n\n${quarantine_details}"

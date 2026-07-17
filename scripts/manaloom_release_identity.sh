#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${MANALOOM_RELEASE_ROOT_DIR:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
SOURCE_SHA="${MANALOOM_RELEASE_SOURCE_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
REQUIRE_CLEAN="${MANALOOM_RELEASE_REQUIRE_CLEAN:-1}"
FETCH_ORIGIN="${MANALOOM_RELEASE_FETCH_ORIGIN:-1}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

for tool in git jq; do
  require_tool "$tool"
done

case "$REQUIRE_CLEAN" in
  0|1) ;;
  *)
    echo "MANALOOM_RELEASE_REQUIRE_CLEAN deve ser 0 ou 1" >&2
    exit 2
    ;;
esac

case "$FETCH_ORIGIN" in
  0|1) ;;
  *)
    echo "MANALOOM_RELEASE_FETCH_ORIGIN deve ser 0 ou 1" >&2
    exit 2
    ;;
esac

if [[ "$FETCH_ORIGIN" == "1" ]]; then
  git -C "$ROOT_DIR" fetch origin master --quiet
fi

if ! SHA="$(git -C "$ROOT_DIR" rev-parse --verify "$SOURCE_SHA^{commit}" 2>/dev/null)"; then
  echo "MANALOOM_RELEASE_SOURCE_SHA nao resolve para um commit: $SOURCE_SHA" >&2
  exit 2
fi

HEAD_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)"
ORIGIN_SHA="$(git -C "$ROOT_DIR" rev-parse origin/master)"
if [[ "$SHA" == "$HEAD_SHA" && "$SHA" == "$ORIGIN_SHA" ]]; then
  :
else
  echo "release recusado: source, HEAD e origin/master devem apontar para o mesmo SHA" >&2
  echo "source=$SHA head=$HEAD_SHA origin_master=$ORIGIN_SHA" >&2
  exit 2
fi

if [[ "$REQUIRE_CLEAN" == "1" ]]; then
  DIRTY_COUNT="$(git -C "$ROOT_DIR" status --porcelain=v1 --untracked-files=all | wc -l | tr -d ' ')"
  if [[ "$DIRTY_COUNT" != "0" ]]; then
    echo "release recusado: worktree possui $DIRTY_COUNT alteracao(oes) rastreada(s) ou nao rastreada(s)" >&2
    exit 2
  fi
fi

VERSION="$(git -C "$ROOT_DIR" show "$SHA:app/pubspec.yaml" | awk '/^version:/{print $2; exit}')"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[1-9][0-9]*$ ]]; then
  echo "versao mobile invalida; esperado semver+build positivo, recebido: ${VERSION:-ausente}" >&2
  exit 2
fi

SHORT_SHA="$(git -C "$ROOT_DIR" rev-parse --short=12 "$SHA")"
SOURCE_COMMITTED_AT="$(git -C "$ROOT_DIR" show -s --format=%cI "$SHA")"

jq -n \
  --arg version "$VERSION" \
  --arg git_sha "$SHA" \
  --arg short_sha "$SHORT_SHA" \
  --arg source_committed_at "$SOURCE_COMMITTED_AT" \
  --argjson worktree_clean "$([[ "$REQUIRE_CLEAN" == "1" ]] && printf true || printf false)" \
  '{
    schema_version: 1,
    product: "manaloom",
    version: $version,
    git_sha: $git_sha,
    short_sha: $short_sha,
    source_committed_at: $source_committed_at,
    source_ref: "origin/master",
    worktree_clean_required: $worktree_clean
  }'

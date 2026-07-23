#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
MODE="${1:---install}"

check_hooks() {
  local hooks_path approval
  hooks_path="$(git -C "$ROOT_DIR" config --local --get core.hooksPath || true)"
  approval="$(
    git -C "$ROOT_DIR" config --local --bool --get \
      manaloom.localGates.disposablePostgres 2>/dev/null || true
  )"
  if [[ "$hooks_path" != ".githooks" ]]; then
    echo "hooks locais não estão ativos: core.hooksPath=$hooks_path" >&2
    return 1
  fi
  if [[ "$approval" != "true" ]]; then
    echo "PostgreSQL local descartável não está aprovado neste checkout" >&2
    return 1
  fi
  for hook in pre-commit pre-push; do
    if [[ ! -x "$ROOT_DIR/.githooks/$hook" ]]; then
      echo "hook ausente ou não executável: .githooks/$hook" >&2
      return 1
    fi
  done
  echo "Hooks locais ativos e PostgreSQL descartável aprovado neste checkout."
}

case "$MODE" in
  --install)
    git -C "$ROOT_DIR" config --local core.hooksPath .githooks
    git -C "$ROOT_DIR" config --local \
      manaloom.localGates.disposablePostgres true
    chmod 755 \
      "$ROOT_DIR/.githooks/pre-commit" \
      "$ROOT_DIR/.githooks/pre-push" \
      "$ROOT_DIR/scripts/manaloom_install_local_hooks.sh" \
      "$ROOT_DIR/scripts/manaloom_local_ci.sh" \
      "$ROOT_DIR/scripts/manaloom_tbls_local_gate.sh"
    check_hooks
    ;;
  --check)
    check_hooks
    ;;
  *)
    echo "uso: $0 --install|--check" >&2
    exit 2
    ;;
esac

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
MODE="${1:---check}"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

if ! command -v "$DART_BIN" >/dev/null 2>&1; then
  echo "Dart SDK não encontrado: $DART_BIN" >&2
  exit 2
fi

if ! "$DART_BIN" mcp-server --help >/dev/null 2>&1; then
  echo "O SDK atual não expõe 'dart mcp-server' (requer Dart 3.9+)." >&2
  exit 1
fi

case "$MODE" in
  --check)
    echo "Dart/Flutter MCP disponível em: $DART_BIN mcp-server"
    ;;
  --configure-codex)
    if ! command -v codex >/dev/null 2>&1; then
      echo "Codex CLI não encontrado; o MCP não foi configurado." >&2
      exit 2
    fi
    if codex mcp list 2>/dev/null | awk '{print $1}' | grep -qx dart; then
      echo "Dart MCP já está configurado no Codex."
      exit 0
    fi
    codex mcp add dart -- "$DART_BIN" mcp-server --force-roots-fallback
    echo "Dart MCP configurado. Reinicie a sessão do agente para carregar a ferramenta."
    ;;
  *)
    echo "Uso: ./scripts/manaloom_dart_mcp_preflight.sh [--check|--configure-codex]" >&2
    exit 2
    ;;
esac

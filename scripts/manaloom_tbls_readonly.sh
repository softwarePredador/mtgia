#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v tbls >/dev/null 2>&1; then
  echo "tbls não está instalado. Consulte https://github.com/k1LoW/tbls#install" >&2
  exit 2
fi

if [[ -z "${TBLS_DSN:-}" ]]; then
  echo "TBLS_DSN read-only é obrigatório; o valor nunca é gravado ou exibido." >&2
  exit 2
fi

cd "$ROOT_DIR"
tbls doc \
  "$TBLS_DSN" \
  "$ROOT_DIR/docs/generated/tbls" \
  --config "$ROOT_DIR/.tbls.yml" \
  --er-format mermaid \
  --sort

echo "Documentação tbls gerada em docs/generated/tbls (consulta read-only)."

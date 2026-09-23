#!/usr/bin/env bash
set -euo pipefail

# Refresh do catálogo de referência (BT-CAT-01; decisões D-33 e D-34 do dono).
#
# Roda dentro da imagem de ops (server/Dockerfile.manaloom-ops), que tem o
# código-fonte, python3 e psycopg2, agendado pelo manaloom_ops_daemon.py como
# `manaloom_catalog_reference_refresh`. Não roda na imagem da API: desde
# 5edf7ce66 ela só leva os executáveis AOT, e o antigo
# `docker exec <api> dart run bin/sync_cards.dart` quebrava ali.
#
# O job lê o bulk `default_cards` da Scryfall e grava só dado de referência
# (cards, sets, card_legalities, com os preços em cards), sob o contrato
# catalog_reference_apply_v1: upsert idempotente, receipt por execução e
# nenhuma tabela de usuário.
#
# Uso:
#   ./server/bin/cron_sync_cards.sh                  # agendado; aplica só depois da ativação
#   ./server/bin/cron_sync_cards.sh --mode dry-run   # somente leitura, gera o receipt
#   MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
#     ./server/bin/cron_sync_cards.sh --mode activate    # primeira execução, supervisionada
#   MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
#     ./server/bin/cron_sync_cards.sh --mode deactivate  # pausa o apply agendado

ROOT="${MTGIA_HOME:-$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if ! "$PYTHON_BIN" -c 'import psycopg2' >/dev/null 2>&1; then
  echo "cron_sync_cards: psycopg2 indisponível; rode na imagem de ops (manaloom-ops)." >&2
  exit 2
fi

args=("server/bin/sync_catalog_reference_from_scryfall.py")
if [[ -n "${MANALOOM_CATALOG_REFERENCE_OUTPUT_DIR:-}" ]]; then
  args+=("--output-dir" "$MANALOOM_CATALOG_REFERENCE_OUTPUT_DIR")
fi

exec "$PYTHON_BIN" "${args[@]}" "$@"

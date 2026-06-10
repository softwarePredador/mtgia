#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cron: sync SEMANAL de rulings de cartas (MTGJSON AtomicCards)
# ============================================================
#
# Popula `card_rulings` ({date, text} por oracle_id). Exposto em
# GET /cards/{id}/rulings e usado como referência de regras.
#
# POR QUE SEMANAL:
#   Rulings novas chegam com lançamentos/erratas (cadência baixa). O bulk
#   AtomicCards é grande; semanal é suficiente. Idempotente via
#   ON CONFLICT (oracle_id, comment_hash).
#
# CRONTAB (toda terça-feira às 3:30 AM):
#   30 3 * * 2 /path/to/server/bin/cron_sync_rulings.sh >> /var/log/mtg_rulings.log 2>&1
#
# DOCKER:
#   docker exec -t -w /app <container> dart run bin/sync_rulings.dart
#
# Variáveis opcionais:
#   APP_DIR            (default: dir do script/..)
#   SYNC_RULINGS_ARGS  (args extras, ex: "--force")
# ============================================================

APP_DIR="${APP_DIR:-$(dirname "$0")/..}"
cd "$APP_DIR"

echo "============================================================"
echo "🔄 $(date '+%Y-%m-%d %H:%M:%S') - Sync de rulings (MTGJSON)"
echo "============================================================"

dart run bin/sync_rulings.dart ${SYNC_RULINGS_ARGS:-}

echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - Sync de rulings concluído"
echo ""

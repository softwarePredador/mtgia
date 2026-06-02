#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cron: snapshot DIÁRIO de preços em price_history
# ============================================================
#
# Copia o preço atual de cada carta (cards.price) para price_history
# com a data de hoje. Alimenta tendências/gráficos de preço.
#
# POR QUE DIÁRIO (após o sync de preços):
#   Deve rodar DEPOIS do sync de preços (cron_sync_prices_mtgjson.sh às 4h)
#   para snapshotar o valor já atualizado do dia. Idempotente via
#   ON CONFLICT (card_id, price_date).
#
# CRONTAB (todo dia às 4:30 AM — após o sync de preços das 4:00):
#   30 4 * * * /path/to/server/bin/cron_snapshot_price_history.sh >> /var/log/mtg_price_history.log 2>&1
#
# DOCKER:
#   docker exec -t -w /app <container> dart run bin/snapshot_price_history.dart
#
# Variáveis opcionais:
#   APP_DIR  (default: dir do script/..)
# ============================================================

APP_DIR="${APP_DIR:-$(dirname "$0")/..}"
cd "$APP_DIR"

echo "============================================================"
echo "📊 $(date '+%Y-%m-%d %H:%M:%S') - Snapshot de price_history"
echo "============================================================"

dart run bin/snapshot_price_history.dart

echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - Snapshot de price_history concluído"
echo ""

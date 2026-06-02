#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cron: sync SEMANAL de staples por formato (Scryfall)
# ============================================================
#
# Atualiza `format_staples` com as cartas mais populares por formato e
# arquétipo (ordenadas por EDHREC rank). Alimenta o pool de candidatos do
# optimize e os fallbacks de completion.
#
# POR QUE SEMANAL:
#   Popularidade de staples muda devagar; semanal evita drift sem custo
#   diário. (Recomendação do próprio bin/sync_staples.dart.)
#
# CRONTAB (toda segunda-feira às 3:00 AM):
#   0 3 * * 1 /path/to/server/bin/cron_sync_staples.sh >> /var/log/mtg_staples.log 2>&1
#
# DOCKER:
#   docker exec -t -w /app <container> dart run bin/sync_staples.dart ALL
#
# Variáveis opcionais:
#   APP_DIR             (default: dir do script/..)
#   SYNC_STAPLES_FORMAT (default: ALL — ou um formato específico)
# ============================================================

APP_DIR="${APP_DIR:-$(dirname "$0")/..}"
cd "$APP_DIR"

echo "============================================================"
echo "🔄 $(date '+%Y-%m-%d %H:%M:%S') - Sync de staples (Scryfall)"
echo "============================================================"

dart run bin/sync_staples.dart "${SYNC_STAPLES_FORMAT:-ALL}"

echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - Sync de staples concluído"
echo ""

#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cron: sync SEMANAL de combos (Commander Spellbook)
# ============================================================
#
# Baixa o bulk variants.json (~500MB, streaming) e popula
# `card_combos` + `combo_cards`. Consumido em weakness-analysis para
# detectar combos completos e near-miss (a 1 carta) no deck.
#
# POR QUE SEMANAL:
#   A base de combos muda lentamente; o download é pesado. O script tem
#   cache local de 24h (use --force para ignorar). Semanal mantém a base
#   fresca sem custo diário de banda.
#
# CRONTAB (toda segunda-feira às 3:30 AM):
#   30 3 * * 1 /path/to/server/bin/cron_sync_combos.sh >> /var/log/mtg_combos.log 2>&1
#
# DOCKER:
#   docker exec -t -w /app <container> dart run bin/sync_combos.dart
#
# Variáveis opcionais:
#   APP_DIR           (default: dir do script/..)
#   SYNC_COMBOS_ARGS  (args extras, ex: "--force --keep-file")
# ============================================================

APP_DIR="${APP_DIR:-$(dirname "$0")/..}"
cd "$APP_DIR"

echo "============================================================"
echo "🔄 $(date '+%Y-%m-%d %H:%M:%S') - Sync de combos (Commander Spellbook)"
echo "============================================================"

dart run bin/sync_combos.dart ${SYNC_COMBOS_ARGS:-}

echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - Sync de combos concluído"
echo ""

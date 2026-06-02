#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cron: snapshot DIÁRIO de tendências EDHREC (camada de aprendizado)
# ============================================================
#
# Captura inclusion_rate/synergy/trend por carta para cada commander
# presente nos decks do app, populando `edhrec_card_snapshots`.
#
# POR QUE DIÁRIO:
#   A lógica de tendência (rising/falling/stable) em
#   lib/ai/edhrec_trend_service.dart::getCardTrends é uma SÉRIE TEMPORAL:
#   compara o snapshot mais recente com snapshots anteriores. Sem captura
#   periódica não há histórico e a tendência fica permanentemente "stable"
#   (sinal inerte para recommendations/optimize).
#
# IDEMPOTENTE: se já existe snapshot de hoje para um commander, pula
#   (a menos que --force). Seguro para reexecução no mesmo dia.
#
# CRONTAB (todo dia às 5:00 AM):
#   0 5 * * * /path/to/server/bin/cron_snapshot_edhrec.sh >> /var/log/mtg_edhrec.log 2>&1
#
# DOCKER:
#   docker exec -t -w /app <container> dart run bin/snapshot_edhrec.dart
#
# Variáveis opcionais:
#   APP_DIR              (default: dir do script/..)
#   SNAPSHOT_EDHREC_ARGS (args extras, ex: "--limit=50 --delay-ms=500")
# ============================================================

APP_DIR="${APP_DIR:-$(dirname "$0")/..}"
cd "$APP_DIR"

echo "============================================================"
echo "🔄 $(date '+%Y-%m-%d %H:%M:%S') - Snapshot EDHREC (tendências)"
echo "============================================================"

dart run bin/snapshot_edhrec.dart ${SNAPSHOT_EDHREC_ARGS:-}

echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - Snapshot EDHREC concluído"
echo ""

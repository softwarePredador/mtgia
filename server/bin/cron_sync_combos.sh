#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cron: sync SEMANAL de combos (Commander Spellbook)
# ============================================================
#
# Baixa o bulk variants.json (~500MB, streaming) e popula
# `card_combos` + `combo_cards`. O consumidor era POST /ai/weakness-analysis,
# removida na D-31 (BT-AI-029, 2026-09-28): hoje nenhuma rota lê essas
# tabelas.
#
# PAUSADO (D-83, 2026-09-28). O job só roda com
# MANALOOM_COMBO_SYNC_AUTHORIZED=1. Sem ela, sai 0 com um recibo de pausa,
# sem baixar o bulk e sem tocar o banco. Nenhum agendador do código chama este
# script (nem o daemon de ops, nem o manifesto de jobs que ele gera, nem o
# bootstrap do Hermes); a pausa aqui cobre um agendamento de fora do código,
# como a linha de crontab abaixo, que a documentação antiga sugeria. Voltar a
# rodar pede um consumidor para as tabelas e a palavra do dono do catálogo.
#
# POR QUE SEMANAL:
#   A base de combos muda lentamente; o download é pesado. O script tem
#   cache local de 24h (use --force para ignorar). Semanal mantém a base
#   fresca sem custo diário de banda.
#
# CRONTAB (histórico; não instale enquanto o job estiver pausado):
#   30 3 * * 1 /path/to/server/bin/cron_sync_combos.sh >> /var/log/mtg_combos.log 2>&1
#
# DOCKER:
#   docker exec -t -w /app <container> dart run bin/sync_combos.dart
#
# Variáveis opcionais:
#   APP_DIR           (default: dir do script/..)
#   SYNC_COMBOS_ARGS  (args extras, ex: "--force --keep-file")
# ============================================================

if [[ "${MANALOOM_COMBO_SYNC_AUTHORIZED:-}" != "1" ]]; then
  printf '{"job":"cron_sync_combos","status":"paused","decision":"D-83","reason":"card_combos_without_consumer","at":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  exit 0
fi

APP_DIR="${APP_DIR:-$(dirname "$0")/..}"
cd "$APP_DIR"

echo "============================================================"
echo "🔄 $(date '+%Y-%m-%d %H:%M:%S') - Sync de combos (Commander Spellbook)"
echo "============================================================"

dart run bin/sync_combos.dart ${SYNC_COMBOS_ARGS:-}

echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - Sync de combos concluído"
echo ""

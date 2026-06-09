#!/usr/bin/env bash
# Master Optimizer Loop — pipeline completa de otimizacao do Lorehold
# Baseado em HERMES_NEXT_STEPS_2026-06-09.md
#
# Ordem: sync PG -> sync SQLite -> forensic -> baseline -> slot scan -> quality gate
# Se qualquer passo falhar, para o ciclo.
#
# Cron: a cada 6h. Uso leve por execucao (forensic=5 seeds, baseline=20 jogos, slot=3/games).

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────
SECRETS_FILE="${MANALOOM_SECRETS:-/opt/data/secrets/manaloom-postgres.env}"
MW="/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge"
BASE="/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports"
SQLITE_DB="${MW}/scripts/knowledge.db"
DECK_ID="${MANALOOM_OPTIMIZER_DECK_ID:-6}"
GAMES="${MANALOOM_OPTIMIZER_GAMES:-3}"
TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"

# ── Secrets ───────────────────────────────────────────────────────────────
if [ ! -f "$SECRETS_FILE" ]; then
  echo "FATAL: Secrets not found at $SECRETS_FILE"
  exit 1
fi
set -a
. "$SECRETS_FILE"
set +a

# ── Clean stale locks ─────────────────────────────────────────────────────
rm -f /tmp/optimizer_v3.lock

echo "=== Master Optimizer Loop ==="
echo "deck_id=$DECK_ID games=$GAMES ts=$TIMESTAMP"

# ── Step 1: Sync battle rules to PG ───────────────────────────────────────
echo "[1/6] Sync PG..."
python3 "${MW}/scripts/sync_battle_card_rules_pg.py" \
  --sqlite-db "$SQLITE_DB" \
  --apply-pg \
  --report "${BASE}/sync_pg_${TIMESTAMP}.json"

# ── Step 2: Refresh SQLite from PG ────────────────────────────────────────
echo "[2/6] Sync SQLite..."
python3 "${MW}/scripts/sync_battle_card_rules_pg.py" \
  --sqlite-db "$SQLITE_DB" \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report "${BASE}/sync_sqlite_${TIMESTAMP}.json"

# ── Step 3: Forensic audit ────────────────────────────────────────────────
echo "[3/7] Forensic audit..."
FORENSIC_JSON="${BASE}/forensic_${TIMESTAMP}.json"
python3 "${MW}/scripts/battle_forensic_audit.py" \
  --generate 5 \
  --seed "$(date +%s | tail -c6)" \
  --sqlite-db "$SQLITE_DB" \
  --report \
  --json-report "$FORENSIC_JSON"

# ── Step 3.5: Auto-promote battle rules ────────────────────────────────────
echo "[3.5/7] Auto-promote battle rules..."
python3 "${MW}/scripts/auto_promote_battle_rules.py" \
  --forensic-json "$FORENSIC_JSON" \
  --min-seen-count 3 \
  --min-heuristic-count 5 \
  --apply

# ── Step 4: Baseline ──────────────────────────────────────────────────────
echo "[4/7] Baseline..."
python3 "${MW}/scripts/master_optimizer_baseline.py" \
  --deck-id "$DECK_ID" \
  --games "$GAMES" \
  --report

# ── Step 5: Slot scan (categorias principais) ─────────────────────────────
echo "[5/7] Slot optimizer..."
CATEGORIES=(ramp draw removal protection wincon wipe tutor engine)
for CAT in "${CATEGORIES[@]}"; do
  echo "  Slot scan: $CAT"
  python3 "${MW}/scripts/slot_optimizer.py" \
    --deck-id "$DECK_ID" \
    --games "$GAMES" \
    --max-per-category 5 \
    --category "$CAT" \
    --phase phase1 || echo "  WARN: slot scan $CAT falhou, continuando"
done

# ── Step 6: Quality gate ──────────────────────────────────────────────────
echo "[6/7] Quality gate..."
python3 "${MW}/scripts/master_optimizer_quality_gate.py" \
  --deck-id "$DECK_ID" \
  --limit 15 \
  --report

echo "=== Loop completo ==="

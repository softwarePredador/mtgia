# Hermes next steps - PostgreSQL optimizer loop

Date: 2026-06-09
Scope: make Hermes use PostgreSQL as the reviewable source of truth for battle
rules and keep SQLite only as the fast runtime cache for simulations.

## Secret handling

- Keep local `.env` ignored by Git. Never commit database credentials.
- Runtime secret file expected by cron scripts:
  `/opt/data/secrets/manaloom-postgres.env`
- Required variables in that file:
  `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`
- Optional variable:
  `DATABASE_URL`
- Python scripts now accept `DATABASE_URL`, `DB_*` and `PG*` variables.

## One-time configuration check

Run inside the Hermes container:

```bash
cd /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts
set -a
. /opt/data/secrets/manaloom-postgres.env
set +a
python3 - <<'PY'
from db_helper import sanitized_database_target
print(sanitized_database_target())
PY
```

The output must show only `host:port/database`, never the password.

## Required sync order

Run this before any optimizer cycle:

```bash
cd /opt/data/workspace/mtgia
set -a
. /opt/data/secrets/manaloom-postgres.env
set +a

python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --apply-pg \
  --report docs/hermes-analysis/master_optimizer_reports/sync_battle_card_rules_pg_$(date -u +%Y%m%d_%H%M%S).json

python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_cache_sync_$(date -u +%Y%m%d_%H%M%S).json
```

Meaning:

- `--apply-pg` pushes curated/local executable card rules into PostgreSQL.
- `--apply-sqlite-from-pg` refreshes Hermes SQLite from PostgreSQL.
- SQLite remains a cache, not the long-term source of truth.

## Validation order for Lorehold

Run after the sync order:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py \
  --generate 20 \
  --seed 1100 \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --report docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_$(date -u +%Y%m%d_%H%M%S).md \
  --json-report docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_$(date -u +%Y%m%d_%H%M%S).json \
  --fail-on-high

python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py \
  --deck-id 14 \
  --games 50 \
  --report

python3 docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py \
  --deck-id 14 \
  --games 10 \
  --max-per-category 12 \
  --phase phase1 \
  --reset-current-baseline

python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py \
  --deck-id 14 \
  --limit 20 \
  --report
```

## Promotion gate

Do not copy a Hermes swap into the real product deck until all checks pass:

- PostgreSQL sync succeeded.
- SQLite cache was refreshed from PostgreSQL.
- Forensic audit returns `critical=0` and `high=0`.
- Baseline and slot scan use the same current deck freeze.
- Quality gate confirms no stale swap targets.
- Replay audit has no unresolved rule/timing issue.
- Handoff report is generated before product apply.

## Validation performed on 2026-06-09

Remote target:

- SSH/container runtime: Hermes container `d5fe57bf9de2`
- Runtime secret configured at `/opt/data/secrets/manaloom-postgres.env`
- Database target check printed only `host:port/database`.

Executed successfully:

- PostgreSQL upsert report:
  `docs/hermes-analysis/master_optimizer_reports/sync_battle_card_rules_pg_hermes_20260609_after_high_rules.json`
- SQLite cache refresh report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_cache_sync_hermes_20260609_after_high_rules.json`
- Forensic audit JSON:
  `docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_hermes_20260609_after_high_rules.json`
- Forensic result: `critical=0`, `high=0`, `medium=45`, `low=1`.
- Lorehold baseline smoke: deck `14`, `120` total games, `29.2%` WR.

Important follow-up:

- Baseline reported `cards=99`. Confirm whether this is library-only with the
  commander tracked separately. If not, fix deck materialization before trusting
  large optimizer runs.
- Medium findings are allowed for exploration, but product-facing swaps should
  keep promoting recurring `needs_review`/heuristic cards into verified PG rules.

## Cron expectation

The cron scripts already source `/opt/data/secrets/manaloom-postgres.env`.
The expected order is:

1. Sync real meta decks from PostgreSQL.
2. Sync card metadata from PostgreSQL into SQLite cache.
3. Sync battle card rules into PostgreSQL.
4. Refresh battle card rules from PostgreSQL into SQLite cache.
5. Run preflight.
6. Run baseline.
7. Run slot scan.
8. Run quality gate.
9. Run confirmation and full confirmation.
10. Run replay audit and product handoff.

If any step fails, stop the cycle and keep the latest report as the handoff for
the fixing agent.

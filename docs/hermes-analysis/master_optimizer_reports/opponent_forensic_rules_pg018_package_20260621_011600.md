# PG-018 Opponent Forensic Rule Package

- scope: replace forensic-blocking `functional_tags_json` runtime evidence for two opponent cards found in 64-seed Lorehold battle audits.
- cards: `Jin-Gitaxias, Core Augur`; `Chandra, Flameshaper`.
- source of truth: PostgreSQL `cards`, `card_battle_rules`, `card_function_tags`.
- local runtime cache after apply: Hermes SQLite via `sync_battle_card_rules_pg.py --apply-sqlite-from-pg`.
- backup table: `manaloom_deploy_audit.pg018_opponent_forensic_rules_20260621_011600`.

## Commands

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a
source server/.env
set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/opponent_forensic_rules_pg018_precheck_20260621_011600.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/opponent_forensic_rules_pg018_apply_20260621_011600.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/opponent_forensic_rules_pg018_postcheck_20260621_011600.sql
```

## Rollback

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a
source server/.env
set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/opponent_forensic_rules_pg018_rollback_20260621_011600.sql
```

## Modeling Notes

- `Jin-Gitaxias, Core Augur`: runtime proxy uses `draw_cards` with `count=7`/`draw_count=7`; beginning-of-end-step timing and opponent maximum-hand-size reduction remain unmodeled.
- `Chandra, Flameshaper`: runtime proxy uses `ramp_permanent` with `mana_produced=3`; loyalty timing, impulse selection, token copy, and divided damage modes remain unmodeled.
- This package is a forensic-gate unblocker, not a claim of full oracle-fidelity for both cards.

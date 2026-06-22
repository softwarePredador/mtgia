# PG-019 Jin-Gitaxias Non-Wheel Correction

- scope: correct PG-018 `Jin-Gitaxias, Core Augur` proxy so draw seven is not treated as a multiplayer wheel.
- source of truth: PostgreSQL `card_battle_rules`.
- runtime dependency: `battle_analyst_v9.is_wheel_like_card` now respects explicit `wheel_like=false`.
- backup table: `manaloom_deploy_audit.pg019_jin_gitaxias_non_wheel_20260621_013900`.

## Commands

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a
source server/.env
set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/jin_gitaxias_non_wheel_pg019_precheck_20260621_013900.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/jin_gitaxias_non_wheel_pg019_apply_20260621_013900.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/jin_gitaxias_non_wheel_pg019_postcheck_20260621_013900.sql
```

## Rollback

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a
source server/.env
set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/jin_gitaxias_non_wheel_pg019_rollback_20260621_013900.sql
```

## Evidence Reason

The 64-seed post-PG-018 runs no longer had forensic blockers, but both surfaced `wheel_opponent_refill_risk` because `Jin-Gitaxias, Core Augur` used the generic count>=7 wheel path. Oracle text draws only for its controller; opponents' maximum hand size reduction remains unmodeled.

# PG-021 Global Attack Rule Scope Package

Status: `applied_and_postchecked`

## Purpose

Correct three anti-combat battle rules whose oracle text is global but whose PG-016 runtime scope was modeled as controller-only or defender-hand-size:

- `Silent Arbiter`: global `max_attackers=1` per combat, not `max_attackers_against_you`.
- `Magus of the Moat`: global non-flying attack filter, including its controller.
- `Ensnaring Bridge`: global power filter using the Bridge controller hand size.

## Local Evidence

- Engine patch: `battle_analyst_v9.py` now applies table-wide attack limits and global attack filters before defender-specific taxes/limits.
- Regression tests added in `battle_combat_tests.py`:
  - Magus controlled by the attacker blocks that player's own non-flying ground attacker.
  - Silent Arbiter limits the total number of attackers across combat.
  - Ensnaring Bridge test now uses controller hand-size naming.
- Test evidence:
  - `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py`
  - `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`

## Execution

From repo root:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/global_attack_rule_scope_pg021_precheck_20260621_043814.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/global_attack_rule_scope_pg021_apply_20260621_043814.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/global_attack_rule_scope_pg021_postcheck_20260621_043814.sql
```

Rollback:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/global_attack_rule_scope_pg021_rollback_20260621_043814.sql
```

## Post-Apply Required

After apply, refresh Hermes battle rules from PostgreSQL and rerun the 64-seed baseline before treating any candidate deck swap as canonical.

## Execution Result

- Precheck on PostgreSQL returned `ready_to_apply=true`.
- Apply completed with `INSERT 0 3` backup rows and `UPDATE 3`.
- Initial postcheck SQL had a scoped CTE bug after the first result row; the first result already reported `postcheck_passed=true`.
- Corrected postcheck re-run completed successfully:
  `rule_rows=3`, `silent_global_ok=true`, `magus_global_ok=true`,
  `bridge_controller_hand_ok=true`, `postcheck_passed=true`.
- PG -> SQLite battle-rule sync report:
  `battle_card_rules_sqlite_from_pg_pg021_global_attack_scope_20260621_043814.json`,
  `apply_sqlite_from_pg=true`, `sqlite_inserted_or_updated=4`.

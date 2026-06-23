# PG064 Deck 6 Recruiter of the Guard Package

Status: applied_validated.

Scope:

- `Recruiter of the Guard`: creature ETB tutor for a creature card with toughness 2 or less, revealed and put into hand.
- The prior `small_creature` placeholder is replaced by `creature_toughness_lte_2`.
- PostgreSQL deck membership is checked through deck UUID `528c877f-f829-4207-95e6-73981776c323` (`Runtime Lorehold Learned 19e93de3cca`), not through the Hermes SQLite integer deck id.
- No deck list or `deck_cards` mutation.

Runtime evidence before PG apply:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- New passing test:
  `test_recruiter_of_the_guard_etb_tutors_toughness_two_creature_to_hand`

Central auditor note:

- The package precheck passed before apply:
  `new_rule_key_rows_already_present=0` and `backup_table_exists=0`.
- The apply output is present in the worktree and reports `SELECT 2`,
  `INSERT 0 1`, `UPDATE 2`, and `COMMIT`.

SQL artifacts:

- Precheck: `deck6_recruiter_guard_pg064_precheck_20260623_025848.sql`
- Apply: `deck6_recruiter_guard_pg064_apply_20260623_025848.sql`
- Postcheck: `deck6_recruiter_guard_pg064_postcheck_20260623_025848.sql`
- Apply output: `deck6_recruiter_guard_pg064_apply_20260623_025848.out`
- Postcheck output: `deck6_recruiter_guard_pg064_postcheck_20260623_025848.out`
- Rollback: `deck6_recruiter_guard_pg064_rollback_20260623_025848.sql`

Expected precheck before apply:

- `target_cards=1`
- `target_in_deck6=1`
- `target_rule_rows=2`
- `current_curated_runtime_rows=1`
- `current_generated_review_only_rows=1`
- `current_trusted_missing_hash_rows=1`
- `new_rule_key_rows_already_present=0`
- `live_oracle_hash_matches=1`
- `active_review_only_rows=1`
- `backup_table_exists=0`

Expected postcheck after apply:

- `target_runtime_rows=1`
- `target_hash_mismatch_rows=0`
- `target_bad_effect_rows=0`
- `target_bad_target_rows=0`
- `target_bad_destination_rows=0`
- `target_bad_scope_rows=0`
- `old_active_shadow_rows=0`
- `backup_rows=2`

Observed postcheck:

- `target_rule_rows=3`
- `target_runtime_rows=1`
- `target_hash_mismatch_rows=0`
- `target_bad_effect_rows=0`
- `target_bad_target_rows=0`
- `target_bad_destination_rows=0`
- `target_bad_scope_rows=0`
- `old_active_shadow_rows=0`
- `backup_rows=2`

Post-apply sync/audit:

- SQLite-from-PG sync:
  `battle_card_rules_sqlite_from_pg_pg064_deck6_recruiter_guard_20260623_025848.json`.
- Deck 6 auditor:
  `deck_card_battle_rule_coherence_audit_deck6_20260623_030307.json`
  reports `high=27`, `pass=73`; `Recruiter of the Guard` reports
  `pass/coherent_for_current_gate`.
- Global auditor:
  `deck_card_battle_rule_coherence_audit_20260623_030307.json`
  reports `high=111`, `medium=15`, `pass=79`.

Focused event:

- `deck6_recruiter_guard_pg064_focused_events_20260623_025848.jsonl` proves
  `rule_logical_key=battle_rule_v1:423a8aa67b5cf450f4c4fb47ca50ae46`.

Commands:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_precheck_20260623_025848.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_apply_20260623_025848.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_postcheck_20260623_025848.sql
```

Rollback command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_rollback_20260623_025848.sql
```

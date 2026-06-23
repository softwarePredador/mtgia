# PG063 Deck 608 Tutor/Search Package

Status: applied_validated.

Collision handling:

- The first prepared package used PG062 numbering before the worktree revealed
  an already-applied `PG062 Deck 6 L1 Fetchland Cleanup`.
- The temporary tutor/search PG062 rows were rolled back with the package
  rollback, `manaloom_deploy_audit.pg062_deck608_tutor_search_20260623_024856`
  was dropped, and the package was reapplied as PG063.
- Verified remaining backup table:
  `manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856`.

Scope:

- `Enlightened Tutor`: artifact/enchantment tutor to library top.
- `Idyllic Tutor`: enchantment tutor to hand.
- `Goblin Engineer`: creature ETB artifact tutor to graveyard; activated reanimation clause is annotation-only.
- `Imperial Recruiter`: creature ETB power-2-or-less tutor to hand.

Runtime evidence before PG apply:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- New passing tests:
  - `test_enlightened_tutor_puts_artifact_or_enchantment_on_library_top`
  - `test_idyllic_tutor_finds_enchantment_to_hand_only`
  - `test_goblin_engineer_etb_tutors_artifact_to_graveyard`
  - `test_imperial_recruiter_etb_tutors_power_two_creature_to_hand`

Runtime evidence after PG -> SQLite/snapshot sync:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed again against the synced cache/snapshot state.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed `7` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed `8` tests.

SQL artifacts:

- Precheck: `deck608_tutor_search_pg063_precheck_20260623_024856.sql`
- Apply: `deck608_tutor_search_pg063_apply_20260623_024856.sql`
- Postcheck: `deck608_tutor_search_pg063_postcheck_20260623_024856.sql`
- Postcheck output: `deck608_tutor_search_pg063_postcheck_20260623_024856.out`
- Rollback: `deck608_tutor_search_pg063_rollback_20260623_024856.sql`

Expected precheck before apply:

- `target_cards=4`
- `target_rule_rows=8`
- `current_curated_runtime_rows=3`
- `current_generated_review_only_rows=5`
- `current_trusted_missing_hash_rows=3`
- `new_rule_key_rows_already_present=0`
- `target_names_missing_cards=0`

Expected postcheck after apply:

- `target_runtime_rows=4`
- `target_hash_mismatch_rows=0`
- `target_bad_effect_rows=0`
- `target_bad_target_rows=0`
- `target_bad_destination_rows=0`
- `target_bad_scope_rows=0`
- `target_bad_runtime_scope_rows=0`
- `old_active_shadow_rows=0`
- `backup_rows=8`

Observed apply output:

- `SELECT 8`: backup rows captured.
- `INSERT 0 4`: four curated runtime rules inserted.
- `UPDATE 8`: eight superseded broad/shadow rows disabled.

Observed postcheck:

- `target_runtime_rows=4`
- `target_hash_mismatch_rows=0`
- `target_bad_effect_rows=0`
- `target_bad_target_rows=0`
- `target_bad_destination_rows=0`
- `target_bad_scope_rows=0`
- `target_bad_runtime_scope_rows=0`
- `old_active_shadow_rows=0`
- `backup_rows=8`

Post-apply sync/audit:

- SQLite-from-PG sync:
  `battle_card_rules_sqlite_from_pg_pg063_deck608_tutor_search_20260623_024856.json`.
- Deck 608 auditor:
  `deck_card_battle_rule_coherence_audit_deck608_20260623_025416.json`
  reports `high=34`, `medium=6`, `pass=28`.
- Target cards in Deck 608 auditor:
  `Enlightened Tutor`, `Idyllic Tutor`, `Goblin Engineer`, and
  `Imperial Recruiter` all report `pass/coherent_for_current_gate` with one
  trusted runtime rule and zero review-only rows.
- Global auditor:
  `deck_card_battle_rule_coherence_audit_20260623_025416.json`
  reports `high=112`, `medium=15`, `pass=78`.

Commands:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck608_tutor_search_pg063_precheck_20260623_024856.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck608_tutor_search_pg063_apply_20260623_024856.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck608_tutor_search_pg063_postcheck_20260623_024856.sql
```

Rollback command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/deck608_tutor_search_pg063_rollback_20260623_024856.sql
```

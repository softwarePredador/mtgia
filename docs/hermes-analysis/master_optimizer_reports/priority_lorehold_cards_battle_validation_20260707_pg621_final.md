# Priority Lorehold Cards Battle Validation - 2026-07-07 PG620/PG621

## Scope

User-prioritized cards and families:

- Battle verification list: 24 cards.
- Functional classification list: 9 cards.

## Result

- PostgreSQL battle coverage: `24/24` cards have at least one `verified` + `auto` executable rule.
- PostgreSQL functional coverage: `9/9` cards have functional tags and semantic-v2 coverage.
- PG620 promoted the three residual active rules:
  - `Hit the Mother Lode`: `discover_10_as_one_card_value_component_v1` and `discover_10_treasure_difference_average_v1`.
  - `Improvisation Capstone`: `exile_value_free_casts_paradigm_annotation_v1`.
  - `Tibalt's Trickery`: `counterspell_with_random_replacement_annotation_v1`.
- PG621 fixed the discovered Command Tower ambiguity:
  - `Command Tower` and `Command Tower // Command Tower` now use `commander_identity_land_mana_source_v1`.
  - Runtime derives available colors from the active commander when `commander_identity_mana_source=true`.

## Database Evidence

- PG620 dry-run: `promoted_rows=4`, `verified_auto_rows=4`, rolled back.
- PG620 apply: `promoted_rows=4`, `verified_auto_rows=4`, committed.
- PG620 postcheck: `target_rows=4`, `verified_auto_rows=4`, `hash_matched_rows=4`.
- PG620 backup table: `manaloom_deploy_audit.pg620_priority_free_cast_residual_runtime_20260707_backup`, `4` rows.
- PG620 PG -> SQLite sync: `pg_rows_loaded=10`, `sqlite_inserted_or_updated=10`, `canonical_snapshot_rows_exported=6946`.
- PG621 dry-run: `updated_rows=2`, `verified_scope_rows=2`, rolled back.
- PG621 apply: `updated_rows=2`, `verified_scope_rows=2`, committed.
- PG621 backup table: `manaloom_deploy_audit.pg621_command_tower_commander_identity_mana_20260707_backup`, `2` rows.
- PG621 PG -> SQLite sync: `pg_rows_loaded=3`, `sqlite_inserted_or_updated=4`, `canonical_snapshot_rows_exported=6946`.

## Runtime And Registry Evidence

- `test_priority_lorehold_card_runtime.py`: `Ran 11 tests`, `OK`.
- `test_reviewed_battle_card_rules.py`: `Ran 32 tests`, `OK`.
- `py_compile`: OK for `battle_analyst_v9.py`, `test_priority_lorehold_card_runtime.py`, and `test_reviewed_battle_card_rules.py`.
- Direct `battle_mana_tests.py` execution is not applicable through unittest/pytest because it is a `register_tests` plug-in file; mana behavior changed here is covered by `test_priority_lorehold_card_runtime.py`.

## Alignment Gates

- `xmage_strategy_consistency_audit_20260707_pg621_priority_cards_final`: `pass`, `26/26`.
- `operational_surface_alignment_audit_20260707_pg621_priority_cards_final`: `pass`.
- `pg_hermes_sqlite_contract_audit_20260707_pg621_priority_cards_final`: `pass`, `51/51`.

## Residual Notes

- Disabled `needs_review`/`deprecated` shadow rows remain present for history and are not executable.
- The prioritized list is closed; this does not close the global all-card XMage adapter backlog.

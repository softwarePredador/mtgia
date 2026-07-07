# Priority Lorehold Cards E2E Validation - 2026-07-07

Status: `pass`

Scope: priority validation requested for 24 Lorehold-related cards/families:

- Battle-rule verification partials: Lorehold, the Historian; Farewell; Fellwar Stone; Flawless Maneuver; Hit the Mother Lode; Improvisation Capstone; Land Tax; Library of Leng; Scroll Rack; Swords to Plowshares; Talisman of Conviction; Teferi's Protection; Tibalt's Trickery.
- Adapter/runtime concerns: Command Tower; Sol Ring; Thor, God of Thunder.
- Functional classification concerns: Furygale Flocking; Molecule Man; Pearl Medallion; Prismari Pianist; Redirect Lightning; The Mind Stone; The Scarlet Witch; Thor, God of Thunder; Turbulent Steppe.

## Result

- PostgreSQL target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.
- Priority card status by logical name: `24/24` resolved in `cards`, `24/24` with trusted executable battle rule and non-empty `oracle_hash`, `24/24` with functional tags, `24/24` present in `card_intelligence_snapshot`.
- The "no adapter yet" items were stale for `Command Tower`, `Sol Ring`, and `Thor, God of Thunder`: all already had trusted runtime rules. This pass validated them and fixed the land key/runtime surface where needed.
- Real runtime gap fixed: `Turbulent Steppe` now supports `enters_tapped_unless_opponents_control_lands_count` and uses `source_colors`/`basic_land_subtype_colors` for mana-color inference.
- Real data-contract gap fixed: 44 trusted executable PG rules were missing `oracle_hash`; package `pg623_trusted_oracle_hash_backfill_new_server` backfilled all 44 from `md5(cards.oracle_text)` and synced them to SQLite.

## PostgreSQL Packages Applied

- `priority_lorehold_cards_20260707_land_rule_key_fix_apply.sql`
  - Updated `Command Tower` to scope-specific key `battle_rule_v1:8a974d0b2c767176f8066c7932447896`.
  - Updated `Turbulent Steppe` to scope-specific key `battle_rule_v1:a614845f052c61eaa22e619e7b288e17`.
  - Postcheck: both cards had `matching_runtime_rows=1` and `remaining_generic_key_rows=0`.
- `pg623_trusted_oracle_hash_backfill_new_server_apply.sql`
  - Precheck: `candidate_rows=44`, `candidates_with_oracle_text=44`, `candidates_missing_oracle_text=0`.
  - Apply: `updated_rows=44`.
  - Postcheck: `trusted_executable_rules_missing_oracle_hash=0`, `pg623_marked_rows=44`, `pg623_rows_matching_current_oracle_text=44`, `pg623_rows_mismatching_current_oracle_text=0`.

## Sync Evidence

- `priority_lorehold_cards_20260707_pg_to_sqlite_sync.json`: `selected_card_count=24`, `pg_rows_loaded=27`, `input_rows=36`, `sqlite_inserted_or_updated=55`, `canonical_snapshot_rows_exported=6945`.
- `priority_lorehold_cards_20260707_land_key_fix_pg_to_sqlite_sync.json`: `selected_card_count=2`, `pg_rows_loaded=3`, `input_rows=3`, `sqlite_inserted_or_updated=6`, `canonical_snapshot_rows_exported=6945`.
- `pg623_trusted_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`: `selected_card_count=44`, `pg_rows_loaded=65`, `input_rows=85`, `sqlite_inserted_or_updated=109`, `canonical_snapshot_rows_exported=6945`.

## Runtime And Audit Evidence

- `test_priority_lorehold_card_runtime.py`: `12/12 pass`.
- `priority_lorehold_cards_20260707_existing_runtime_test_results.json`: `36/36 pass`.
- `priority_lorehold_cards_20260707_token_maker_runtime_test_results.json`: `3/3 pass` for token-maker family checks covering Furygale Flocking / Prismari Pianist rules and deck 607 cache resolution.
- `test_reviewed_battle_card_rules.py::ReviewedBattleCardRulesTests.test_reviewed_rule_payload_contains_expected_cards`: `pass`.
- `py_compile` on touched runtime/test files: `pass`.
- `xmage_strategy_consistency_audit_20260707_priority_lorehold_cards_final_after_pg623`: `26/26 pass`.
- `operational_surface_alignment_audit_20260707_priority_lorehold_cards_final_after_pg623`: `pass`.
- `pg_hermes_sqlite_contract_audit_20260707_priority_lorehold_cards_final_after_pg623`: `51/51 pass`.

## Runtime Families Covered

- Mana sources: `Command Tower`, `Sol Ring`, `Fellwar Stone`, `Talisman of Conviction`, `Turbulent Steppe`.
- Modal wipe / exile: `Farewell`.
- Protection / interaction: `Flawless Maneuver`, `Teferi's Protection`, `Swords to Plowshares`, `Redirect Lightning`, `Library of Leng`, `Scroll Rack`.
- Lorehold miracle/rummage: `Lorehold, the Historian`, `Molecule Man`, `Land Tax`, `Scroll Rack`.
- Big-spell/free-cast/discover: `Hit the Mother Lode`, `Improvisation Capstone`, `Tibalt's Trickery`.
- Token-maker: `Furygale Flocking`, `Prismari Pianist`.
- Cost reduction/spellslinger: `Pearl Medallion`, `The Scarlet Witch`.
- Noncreature trigger damage: `Thor, God of Thunder`.
- Utility/passive artifact classification: `The Mind Stone`.

Remaining note: this closes focused battle/runtime validation for this priority list. It does not claim natural battle sampling evidence for every card draw/cast in long deck simulations; that remains a separate deck-optimization gate.

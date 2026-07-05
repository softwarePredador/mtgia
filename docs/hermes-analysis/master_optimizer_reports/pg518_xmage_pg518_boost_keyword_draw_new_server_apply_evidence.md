# PG518 Boost Keyword Draw Apply Evidence

Generated on 2026-07-05 for deploy id
`xmage_pg518_boost_keyword_draw_new_server`.

## Scope

PG518 promotes only local-XMage-backed instant spells with the exact fixed
pattern:

- target creature gets a fixed power/toughness boost until end of turn;
- that same target gains one supported keyword until end of turn;
- controller draws one card.

Runtime scope:

- `xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1`

Promoted cards:

- `Guided Strike`
- `Moment of Defiance`
- `Wildsize`

Blocked neighbors:

- `Ancestral Anger`
- `Fists of Flame`

Those neighbors remain blocked because their XMage/Oracle behavior uses dynamic
boost sizing rather than the fixed boost/keyword/draw pattern.

## PostgreSQL Apply

Package files:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg518_xmage_pg518_boost_keyword_draw_new_server_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg518_xmage_pg518_boost_keyword_draw_new_server_manifest.json`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg518_xmage_pg518_boost_keyword_draw_new_server_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg518_xmage_pg518_boost_keyword_draw_new_server_apply.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg518_xmage_pg518_boost_keyword_draw_new_server_postcheck.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg518_xmage_pg518_boost_keyword_draw_new_server_rollback.sql`

Execution:

- Precheck: each promoted card had `target_card_rows=1`; no existing rule row
  or shadow row needed deprecation.
- Apply: `deprecated_shadow_rows=0`, `upserted_rows=3`, `COMMIT`.
- Postcheck: all three promoted cards have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Hermes/SQLite Sync

Sync report:
`docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg518_boost_keyword_draw_new_server.json`.

- `selected_card_count=3`.
- `pg_rows_loaded=3`.
- `sqlite_inserted_or_updated=3`.
- `canonical_snapshot_rows_exported=6034`.

The canonical snapshot file was refreshed at
`docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`.

## Validation

- Focused unit suite:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py test_xmage_batch_pg_package_builder.py`
  reports `842` tests passing.
- Focused runtime smoke without override resolved `Guided Strike` through
  `get_card_effect`, gave `Active Bear` `+1/+0`, granted `first_strike`, drew
  `Fresh Card`, moved `Guided Strike` to graveyard, and emitted
  `composite_rule_resolved`.
- Battle package end-to-end validation:
  `docs/hermes-analysis/master_optimizer_reports/battle_package_end_to_end_validation_20260705_pg518_boost_keyword_draw_new_server.md`
  reports `pass` for PostgreSQL, SQLite, canonical snapshot, and runtime lookup.
- XMage strategy consistency: `26/26` pass.
- Operational surface alignment: `pass`.
- Legacy contamination: `pass`.
- PG/Hermes/SQLite contract: `51/51` pass.

## Queue And Readiness

Pre-PG518 authoritative queue:

- `target_identity_count=25983`.
- `xmage_authoritative_source_count=25669`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25669`.
- Candidate exact split: `proposal_count=3`,
  `safe_for_batch_pg_package_count=3`.

Post-sync authoritative queue:

- `target_identity_count=25980`.
- `xmage_authoritative_source_count=25666`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25666`.
- Final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`.

Global readiness after this sync:

- `battle_and_oracle_ready=4970`.
- `battle_family_mapper_required=28903`.
- `snapshot_has_any_rule=6037`.
- `snapshot_has_verified_rule=4792`.

## Decision

PG518 is applied, synced, and validated. Do not rebuild it from the pre-PG518
candidate queue. The next global card-adaptation wave must start from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg518_boost_keyword_draw_new_server.md`.

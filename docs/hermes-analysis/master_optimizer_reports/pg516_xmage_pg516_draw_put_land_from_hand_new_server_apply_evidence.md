# PG516 Draw Put Land From Hand Apply Evidence

Generated on 2026-07-05 for deploy id
`xmage_pg516_draw_put_land_from_hand_new_server`.

## Scope

PG516 promotes only local-XMage-backed instant/sorcery spells with fixed draw
count plus `PutCardFromHandOntoBattlefieldEffect(StaticFilters.FILTER_CARD_LAND_A)`.

Promoted cards:

- `Embrace the Paradox`
- `Eureka Moment`
- `Growth Spiral`
- `Lessons from Life`

Blocked neighbor:

- `Mind into Matter` remains blocked because it uses `X` and permits a
  permanent card with mana value X or less, not a fixed land-card pattern.

## Runtime Mapping

Runtime scope:

- `xmage_fixed_draw_put_land_from_hand_spell_v1`

Runtime behavior:

- resolve fixed `DrawCardSourceControllerEffect`;
- then select a land card from the controller's hand, including a land just
  drawn by the first component;
- move it to the battlefield, respecting the exact tapped flag from XMage and
  Oracle;
- emit replay evidence through `put_land_from_hand_to_battlefield_resolved`.

## PostgreSQL Apply

Package files:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_manifest.json`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_apply.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_postcheck.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_rollback.sql`

Execution:

- Precheck: each promoted card had `target_card_rows=1`; `Growth Spiral` and
  `Eureka Moment` each had two nonmatching existing rows scheduled for shadow
  deprecation.
- Apply: `deprecated_shadow_rows=4`, `upserted_rows=4`, `COMMIT`.
- Postcheck: all four promoted cards have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Hermes/SQLite Sync

Sync report:
`docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg516_draw_put_land_from_hand_new_server.json`.

- `selected_card_count=4`.
- `pg_rows_loaded=4`.
- `sqlite_inserted_or_updated=8`.
- `canonical_snapshot_rows_exported=6026`.

The canonical snapshot file was refreshed at
`docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`.

## Validation

- Focused runtime smoke without override resolved `Growth Spiral` from
  `get_card_effect`, drew `Island`, and put that newly drawn land onto the
  battlefield.
- Combined exact-scope/runtime/package suite:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py test_xmage_batch_pg_package_builder.py`
  reports `834` tests passing in
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg516_draw_put_land_from_hand_new_server_unittest.out`.
- Battle package end-to-end validation:
  `docs/hermes-analysis/master_optimizer_reports/battle_package_end_to_end_validation_20260705_pg516_draw_put_land_from_hand_new_server.md`
  reports `pass` for PostgreSQL, SQLite, canonical snapshot, and runtime lookup.
- XMage strategy consistency: `26/26` pass.
- Operational surface alignment: `pass`.
- Legacy contamination: `pass`.
- PG/Hermes/SQLite contract: `51/51` pass.

## Queue And Readiness

Pre-PG516 authoritative queue:

- `target_identity_count=25992`.
- `xmage_authoritative_source_count=25678`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25678`.
- Candidate exact split: `proposal_count=4`,
  `safe_for_batch_pg_package_count=4`.

Post-sync authoritative queue:

- `target_identity_count=25988`.
- `xmage_authoritative_source_count=25674`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25674`.
- Final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`.

Global readiness after this sync:

- `battle_and_oracle_ready=4962`.
- `battle_family_mapper_required=28911`.
- `snapshot_has_any_rule=6029`.
- `snapshot_has_verified_rule=4784`.

## Decision

PG516 is applied, synced, and validated. Do not rebuild it from the pre-PG516
candidate queue. The next global card-adaptation wave must start from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg516_draw_put_land_from_hand_new_server.md`.

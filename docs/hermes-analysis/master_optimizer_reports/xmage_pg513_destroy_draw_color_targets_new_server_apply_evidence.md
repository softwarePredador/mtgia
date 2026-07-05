# PG513 Destroy/Draw Color Targets Apply Evidence

Generated on 2026-07-05 for deploy id
`xmage_pg513_destroy_draw_color_targets_new_server`.

## Scope

PG513 promotes only local-XMage-backed exact destroy-target patterns that were
unblocked by color-target parsing and `DestroyTargetEffect(true)` support.

Promoted cards:

- `Annihilate`: destroy target nonblack creature, then draw a card.
- `Execute`: destroy target white creature, then draw a card.
- `Slay`: destroy target green creature, then draw a card.
- `Eastern Paladin`: activated `{B}{B}, {T}` destroy target green creature.

Unsupported dynamic draw counts, X target counts, extra clauses, modal effects,
and broad `xmage_*_review_v1` rows remain blocked.

## Source And Runtime Mapping

XMage source files:

- `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/a/Annihilate.java`
- `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/e/EasternPaladin.java`
- `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/e/Execute.java`
- `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/Slay.java`

Runtime scopes:

- `xmage_destroy_target_and_draw_card_spell_v1` for `Annihilate`, `Execute`,
  and `Slay`.
- `xmage_permanent_simple_activated_destroy_target_v1` for `Eastern Paladin`.

Runtime lookup evidence:
`docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_runtime_get_card_effect.out`.

## PostgreSQL Apply

Package files:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_package.md`.
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_manifest.json`.
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_precheck.sql`.
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_apply.sql`.
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_postcheck.sql`.
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_rollback.sql`.

Execution:

- Precheck: each promoted card had `target_card_rows=1`,
  `existing_rule_rows=0`, and `expected_rule_rows_before=0`.
- Apply: `deprecated_shadow_rows=0`, `upserted_rows=4`, `COMMIT`.
- Postcheck: all four promoted cards have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Hermes/SQLite Sync

Sync report:
`docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg513_destroy_draw_color_targets_new_server.json`.

- `selected_card_count=4`.
- `pg_rows_loaded=4`.
- `sqlite_inserted_or_updated=4`.
- `canonical_snapshot_rows_exported=6016`.

The canonical snapshot file was refreshed at
`docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`.

## Validation

- Focused parser/runtime tests pass for destroy+draw color targets and
  activated green-creature destroy.
- Combined exact-scope/runtime suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_unittest.out`
  reports `822` tests passing.
- Battle package end-to-end validation:
  `docs/hermes-analysis/master_optimizer_reports/battle_package_end_to_end_validation_20260705_pg513_destroy_draw_color_targets_new_server.md`
  reports `pass` for PostgreSQL, SQLite, canonical snapshot, runtime lookup,
  and no-override battle execution.
- XMage strategy consistency:
  `26/26` pass.
- Operational surface alignment:
  `39/39` pass.
- Legacy contamination:
  `32/32` pass.
- PG/Hermes/SQLite contract:
  `51/51` pass.

## Queue And Readiness

Pre-PG513 authoritative queue:

- `target_identity_count=26005`.
- `xmage_authoritative_source_count=25691`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25691`.
- Candidate exact split: `proposal_count=4`,
  `safe_for_batch_pg_package_count=4`.

Post-sync authoritative queue:

- `target_identity_count=26001`.
- `xmage_authoritative_source_count=25687`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25687`.
- Final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`.

Global readiness after this sync:

- `battle_and_oracle_ready=4949`.
- `battle_family_mapper_required=28924`.
- `snapshot_has_any_rule=6019`.
- `snapshot_has_verified_rule=4771`.

## Decision

PG513 is applied, synced, and validated. Do not rebuild it from the pre-PG513
candidate queue. The next global card-adaptation wave must start from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg513_destroy_draw_color_targets_new_server.md`.

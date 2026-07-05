# PG512 Nonred/Nonwhite Damage Targets Apply Evidence

Generated on 2026-07-05 for deploy id
`xmage_pg512_nonred_nonwhite_damage_targets_new_server`.

## Scope

PG512 promotes only fixed direct-damage spells whose local XMage source and
Oracle text agree on an exact nonred/nonwhite creature target filter.

Promoted cards:

- `Strafe`: 3 damage to target nonred creature.
- `Sunlance`: 3 damage to target nonwhite creature.

Excluded neighbors remain blocked when they require modal handling, multiple
targets, X amounts, or unsupported target semantics.

## Source And Runtime Mapping

- XMage classes checked:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/Strafe.java`
  and
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/Sunlance.java`.
- ManaLoom scope: `xmage_fixed_damage_target_spell_v1`.
- `target_constraints`:
  - `Strafe`: `{"card_types":["creature"],"exclude_colors":["R"]}`.
  - `Sunlance`: `{"card_types":["creature"],"exclude_colors":["W"]}`.

Runtime lookup evidence:
`docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_runtime_get_card_effect.out`.

## PostgreSQL Apply

Package files:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_package.md`.
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_manifest.json`.
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_precheck.sql`.
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_apply.sql`.
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_postcheck.sql`.
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_rollback.sql`.

Execution:

- Precheck: `target_card_rows=1`, `existing_rule_rows=0`, and
  `expected_rule_rows_before=0` for each promoted card.
- Apply: `deprecated_shadow_rows=0`, `upserted_rows=2`, `COMMIT`.
- Postcheck: both promoted cards have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Hermes/SQLite Sync

Sync report:
`docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg512_nonred_nonwhite_damage_targets_new_server.json`.

- `selected_card_count=2`.
- `pg_rows_loaded=2`.
- `sqlite_inserted_or_updated=2`.
- `canonical_snapshot_rows_exported=6012`.

The canonical snapshot file was refreshed at
`docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`.

## Validation

- Focused nonred/nonwhite target tests pass.
- Combined exact-scope/runtime suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg512_nonred_nonwhite_damage_targets_new_server_unittest.out`
  reports `819` tests passing.
- XMage strategy consistency:
  `26/26` pass.
- Operational surface alignment:
  `39/39` pass.
- Legacy contamination:
  `32/32` pass.
- PG/Hermes/SQLite contract:
  `51/51` pass.

## Queue And Readiness

Pre-PG512 authoritative queue:

- `target_identity_count=26008`.
- `xmage_authoritative_source_count=25694`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25694`.
- Candidate exact split: `proposal_count=2`,
  `safe_for_batch_pg_package_count=2`, promoted by this package.

Post-sync authoritative queue:

- `target_identity_count=26005`.
- `xmage_authoritative_source_count=25691`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25691`.
- Final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`.

Global readiness after this sync:

- `battle_and_oracle_ready=4945`.
- `battle_family_mapper_required=28928`.
- `snapshot_has_any_rule=6015`.
- `snapshot_has_verified_rule=4767`.

Note: the observed readiness/queue delta since the pre-PG512 baseline is three
identities. PG512 directly promotes `Strafe` and `Sunlance`; the additional
ready identity comes from the already-applied Entreat runtime/rule refresh in
the local `Apply Entreat runtime gate evidence` commit.

## Decision

PG512 is applied, synced, and validated. Do not rebuild it from the pre-PG512
candidate queue. The next global card-adaptation wave must start from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg512_nonred_nonwhite_damage_targets_new_server.md`.

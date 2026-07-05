# PG506 Apply Evidence - Activated Damaged Creature Target

Generated at: `2026-07-05T12:47:38Z`

## Package

- Deploy id: `xmage_pg506_activated_damaged_creature_target_new_server`
- Runtime scopes:
  - `xmage_permanent_simple_activated_destroy_target_v1`
  - `xmage_permanent_simple_activated_damage_v1`
- Cards:
  - `Ogre Siegebreaker`
  - `Opportunist`
  - `Witch's Mist`

## PostgreSQL Execution

- Precheck: `3` target card rows, `0` existing expected rules, `0` shadow rows
  to deprecate.
- Apply: `deprecated_shadow_rows=0`, `upserted_rows=3`, `COMMIT`.
- Postcheck: all `3` rows have promoted rule, `verified` review status,
  `auto` execution status, and matching Oracle hash.
- Field postcheck:
  - `Ogre Siegebreaker`: destroy target
    `creature_damaged_this_turn`, cost `{2}{B}{R}`, no tap.
  - `Opportunist`: direct damage target `creature_damaged_this_turn`, damage
    `1`, cost `{0}`, requires tap.
  - `Witch's Mist`: destroy target `creature_damaged_this_turn`, cost `{2}{B}`,
    requires tap.

## Cache And Runtime

- PG -> Hermes/SQLite sync:
  `pg_rows_loaded=3`, `sqlite_inserted_or_updated=3`,
  `canonical_snapshot_rows_exported=5982`.
- Runtime lookup:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_runtime_get_card_effect.out`
  resolves all `3` cards to the expected runtime scope and
  `damaged_this_turn` target constraint.

## Validation

- Splitter unit suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_splitter_unit_tests.out`
  ran `526` tests and passed.
- Focused target-legality runtime test:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_focused_battle_tests.out`
  completed with exit code `0`.
- Full battle runtime suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_full_battle_suite_post_sync.out`
  contains `632` PASS lines and completed with exit code `0`.
- Governance audits:
  - XMage strategy: `26/26` pass.
  - Deckbuilding contract: `pass`.
  - Operational surface: `39/39` pass.
  - Legacy contamination: `32/32` pass.
  - PG/Hermes/SQLite: `51/51` pass.

## Queue Impact

- Global readiness:
  - `battle_and_oracle_ready=4915`
  - `battle_family_mapper_required=28958`
  - `generic_runtime_or_no_card_rule=360`
  - `oracle_data_sync=4`
  - `commander_legality_sync=3`
  - `oracle_identity_rule_link_or_copy=2`
- Authoritative XMage queue:
  - `target_identity_count=26035`
  - `xmage_authoritative_source_count=25721`
  - `xmage_missing_source_exception_count=314`
  - `xmage_authoritative_parser_gap_count=0`
  - `xmage_authoritative_adapter_required_count=25721`
  - `adapter_work_unit_count=11385`
- Final exact-scope recheck:
  - `proposal_count=0`
  - `safe_for_batch_pg_package_count=0`

## Boundary

PG506 only promotes exact activated abilities whose Oracle text and local XMage
source both target a creature that was dealt damage this turn. It does not
promote broad damaged-creature review rows, modal abilities, unsupported costs,
or any deck mutation.

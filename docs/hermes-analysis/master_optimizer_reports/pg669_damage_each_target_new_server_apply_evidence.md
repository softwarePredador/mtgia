# PG669 damage each target evidence

Date: 2026-07-08

Database target: new-server PostgreSQL via `server/bin/with_new_server_pg.sh`
(`127.0.0.1:15432/halder` wrapper target).

## Scope

Implemented and promoted the exact XMage-to-ManaLoom runtime scope
`xmage_fixed_damage_each_target_spell_v1` for spells whose XMage source uses
`DamageTargetEffect` and whose Oracle/source text says the spell deals a fixed
amount of damage to each of multiple targets.

This scope is separate from divided-damage multi-target spells. PG669 sets:

- `effect = multi_target_damage`
- `battle_model_scope = xmage_fixed_damage_each_target_spell_v1`
- `damage_assignment_mode = each_target`
- `damage_per_target = fixed amount`
- `divided_damage = false`

## Cards promoted

PG669 promoted 6 verified executable rules:

- `Dual Shot` - 1 damage to each of up to two target creatures.
- `Furious Reprisal` - 2 damage to each of two targets.
- `Jagged Lightning` - 3 damage to each of two target creatures.
- `Pinnacle of Rage` - 3 damage to each of two targets.
- `Storm of Steel` - 2 damage to each of up to two targets.
- `Swelter` - 2 damage to each of two target creatures.

Live PostgreSQL verification after apply:

- 6 rows in `card_battle_rules`.
- All 6 have `review_status = verified`.
- All 6 have `execution_status = auto`.
- All 6 have `battle_model_scope = xmage_fixed_damage_each_target_spell_v1`.
- All 6 have `damage_assignment_mode = each_target`.
- All 6 have non-empty `oracle_hash`.

## Blocked by design

The split recheck still blocks broader cases rather than collapsing them into
this scope:

- `Meteor Blast` and other X-count/X-damage cases remain blocked by
  `damage_each_target_oracle_x_not_supported`.
- Modal or mixed-mode cases such as `Consuming Bonfire` remain outside this
  exact scope.

## Runtime and package support

Changed files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`

Runtime behavior:

- `apply_multi_target_damage` now recognizes `damage_assignment_mode =
  each_target`.
- The runtime assigns the full `damage_per_target` to every selected legal
  target.
- Existing divided-damage behavior remains on the old assignment path.

Package-builder behavior:

- PG package manifests now preserve `damage_per_target`,
  `damage_assignment_mode`, and `divided_damage`.
- E2E scenarios for this scope expect total damage equal to
  `damage_per_target * target_count`.

## Evidence files

Candidate and package:

- `xmage_authoritative_exact_scope_split_20260708_pg669_damage_each_target_new_server_candidate.json`
- `xmage_authoritative_exact_scope_split_20260708_pg669_damage_each_target_new_server_candidate.md`
- `pg669_damage_each_target_package_manifest.json`
- `pg669_damage_each_target_package_package.md`
- `pg669_damage_each_target_package_precheck.sql`
- `pg669_damage_each_target_package_apply.sql`
- `pg669_damage_each_target_package_postcheck.sql`
- `pg669_damage_each_target_package_rollback.sql`

Sync and E2E:

- `pg669_damage_each_target_pg_to_sqlite_sync.json`
- `pg669_damage_each_target_e2e_validation.json`
- `pg669_damage_each_target_e2e_validation.md`

Post-backfill checks:

- `pg669b_trusted_rule_oracle_hash_backfill_new_server_package.md`
- `pg669b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `pg669b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `pg669b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `pg669b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- `pg669b_trusted_rule_oracle_hash_backfill_pg_to_sqlite_sync.json`

Final queue/readiness:

- `global_card_oracle_battle_readiness_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server.json`
- `global_card_oracle_battle_readiness_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server.md`
- `xmage_authoritative_adaptation_queue_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server_commander_legal.md`
- `xmage_authoritative_exact_scope_split_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server_recheck.json`
- `xmage_authoritative_exact_scope_split_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server_recheck.md`

Final audits:

- `xmage_strategy_consistency_audit_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server_final.md`
- `operational_surface_alignment_audit_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server_final.md`
- `legacy_contamination_audit_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server_final.md`
- `pg_hermes_sqlite_contract_audit_20260708_post_pg669b_trusted_rule_oracle_hash_backfill_new_server_final.md`

## Measured results

Candidate split:

- `proposal_count = 6`
- `safe_for_batch_pg_package_count = 6`
- `family_counts = {"xmage_fixed_damage_each_target_spell": 6}`
- `scope_counts = {"xmage_fixed_damage_each_target_spell_v1": 6}`

PG package:

- `selected_count = 6`
- `scenario_count = 6`
- backup table: `manaloom_deploy_audit.pg669_damage_each_target_20260708_191811`
- backup rows: `0`, expected because no existing rules were replaced.

E2E:

- status: `pass`
- scenario count: `6`
- event count: `24`
- legal targets received full per-target damage.
- illegal target received `0` damage in every scenario.

PG669B metadata backfill:

- precheck backfillable rows: `44`
- affected card ids: `43`
- unsafe rows: `0`
- rows backfilled: `44`
- postcheck remaining trusted executable missing hash rows: `0`
- postcheck rows with expected hash: `44`

Readiness delta:

- Post-PG668 `battle_and_oracle_ready = 6045`
- Post-PG669B `battle_and_oracle_ready = 6051`
- Post-PG668 `snapshot_has_verified_rule = 6073`
- Post-PG669B `snapshot_has_verified_rule = 6079`
- Post-PG668 `battle_family_mapper_required = 27831`
- Post-PG669B `battle_family_mapper_required = 27825`
- `trusted_rule_oracle_hash_backfill` lane removed after PG669B.

Queue after PG669B:

- `target_identity_count = 24902`
- `xmage_authoritative_source_count = 24589`
- `xmage_missing_source_exception_count = 313`
- `xmage_authoritative_parser_gap_count = 0`
- `xmage_authoritative_adapter_required_count = 24589`
- `direct_damage::targeted_damage_variant_v1 = 757`

Recheck:

- `proposal_count = 0`
- `safe_for_batch_pg_package_count = 0`

Tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split test_xmage_exact_scope_runtime`
  - `Ran 1281 tests`
  - `OK`
- `python3 -m pytest test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py -q`
  - `144 passed`

Audits:

- XMage strategy consistency: `pass`, 26/26.
- Operational surface alignment: `pass`.
- Legacy contamination: `pass`.
- PG/Hermes/SQLite contract: `pass`, 51/51.

## Current status

PG669 is complete and synced. The global goal remains active because the
post-PG669B Commander-legal queue still has 24,589 XMage-authoritative
adapter-required identities and 313 no-local-XMage-source exceptions.

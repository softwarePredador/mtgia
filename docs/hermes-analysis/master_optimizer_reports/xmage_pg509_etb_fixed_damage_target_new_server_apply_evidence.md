# PG509 XMage ETB Fixed Damage Target Apply Evidence

- Date: `2026-07-05`
- Deploy id: `xmage_pg509_etb_fixed_damage_target_new_server`
- Runtime family: `xmage_creature_etb_fixed_damage_target_v1`
- Promoted cards: `5`
- Cards: `Geistcatcher's Rig`, `Goretusk Firebeast`, `Unsparing Boltcaster`, `Viashino Pyromancer`, `Whiptail Moloch`

## Scope

PG509 promotes only fixed creature enters-the-battlefield damage triggers with
exact ManaLoom runtime support:

- fixed damage to target creature with flying;
- fixed damage to target player or planeswalker;
- fixed damage to target creature an opponent controls that was dealt damage this turn;
- fixed damage to target creature you control.

Dynamic ETB damage rows remain blocked. The final split recheck still reports
`etb_damage_target_not_supported=8` for dynamic amount variants, and no safe
PG candidate remains for this exact PG509 subpattern.

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py` now parses the exact PG509 target
  forms and rejects source-target mismatches when XMage source target metadata
  is available.
- `battle_analyst_v9.py` now supports explicit self-controller direct-damage
  targets without changing default any-target behavior toward opponents.
- Direct damage to mandatory creature targets can now mark nonlethal damage
  instead of incorrectly reporting no legal creature target.

## PostgreSQL Evidence

Package files:

- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_package.md`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_manifest.json`
- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_precheck.out`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_apply.out`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_postcheck.out`
- direct field postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_pg_direct_postcheck.out`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_rollback.sql`

Results:

- precheck found one target card row for each promoted card and zero existing
  rule rows for the selected logical keys.
- apply result: `deprecated_shadow_rows=0`, `upserted_rows=5`, `COMMIT`.
- postcheck result: every promoted card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.
- direct field postcheck confirms the expected `battle_model_scope`,
  `etb_damage_amount`, `etb_damage_target`, `target`, `target_controller`,
  `target_constraints`, `review_status=verified`, and `execution_status=auto`
  for all 5 rows.

## Sync And Runtime Evidence

- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_pg_to_sqlite_sync.json`
- Sync result: `selected_card_count=5`, `pg_rows_loaded=5`,
  `sqlite_inserted_or_updated=5`, `canonical_snapshot_rows_exported=5997`.
- Runtime lookup:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_runtime_get_card_effect.out`
- Runtime lookup resolves all 5 cards to
  `xmage_creature_etb_fixed_damage_target_v1` with the expected damage amount,
  target, target controller, logical rule key, and Oracle hash.

## Validation Evidence

- Splitter unit suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_splitter_tests.out`
  - `Ran 529 tests`
  - `OK`
- Focused battle test:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_focused_battle_tests.out`
  - `PASS test_pg509_etb_fixed_damage_respects_restricted_targets`
- Full battle suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg509_etb_fixed_damage_target_new_server_full_battle_suite_post_sync.out`
  - `633` PASS lines
  - `full_battle_suite_exit_code=0`
- XMage strategy consistency:
  `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`
  - `26/26` pass
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260705_post_pg509_etb_fixed_damage_target_new_server_final.md`
  - status `pass`
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260705_post_pg509_etb_fixed_damage_target_new_server_final.md`
  - status `pass`
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260705_post_pg509_etb_fixed_damage_target_new_server_final.md`
  - `51/51` pass
- Deckbuilding contract:
  `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_post_pg509_etb_fixed_damage_target_new_server_final.md`
  - status `pass`

## Queue Impact

Post-PG509 readiness:

- `battle_and_oracle_ready=4930`
- `battle_family_mapper_required=28943`

Post-PG509 authoritative queue:

- `target_identity_count=26020`
- `xmage_authoritative_source_count=25706`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25706`

Final exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `etb_damage_target_not_supported=8`

## Decision

PG509 is applied and should not be rebuilt. The remaining ETB damage backlog is
not this fixed-target subpattern; it is primarily dynamic damage amount logic
that needs a separate runtime/modeling pass.

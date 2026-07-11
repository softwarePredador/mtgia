# PG786 Removal Life Delta Evidence - 2026-07-11

Status: `applied_and_validated_on_new_server`.

## Scope

PG786 promoted exact XMage-backed removal/bounce subpatterns where the battle
runtime can execute the target movement plus a fixed life/damage delta:

- `xmage_return_target_to_hand_and_controller_gain_life_spell_v1`
- `xmage_return_target_to_hand_and_target_controller_loses_life_spell_v1`
- `xmage_exile_target_and_target_controller_gain_life_spell_v1`
- `xmage_exile_target_and_source_controller_loses_life_spell_v1`
- `xmage_exile_target_and_source_controller_damage_spell_v1`

Promoted cards:

- Anguished Unmaking
- Ashes to Ashes
- Dramatic Rescue
- Last Breath
- Narrow Escape
- Vapor Snag

The post-PG786B exact split has no remaining safe PostgreSQL candidate for this
subpattern. It reports only three runtime-partial mana-source proposals.

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added exact splitters for bounce/exile plus controller life gain, target
    controller life gain/loss, source controller life loss, and source
    controller damage.
  - Added `creature_power_2_or_less` target support for Last Breath-style
    Oracle/XMage matching.
- `battle_analyst_v9.py`
  - Added runtime execution and replay event support for
    `target_controller_life_loss_on_resolve`.
  - Preserved existing `target_controller_life_loss_on_destroy` behavior.
- `xmage_batch_pg_package_builder.py`
  - Added E2E scenario generation for the new exact scopes.
- `battle_package_end_to_end_validation.py`
  - Added validation for target-controller life gain/loss and multi-target
    source-controller damage.

## PostgreSQL Apply

PG786 package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg786_removal_life_delta_new_server_package_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg786_removal_life_delta_new_server_package_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg786_removal_life_delta_new_server_package_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg786_removal_life_delta_new_server_package_rollback.sql`

Apply result:

- Deprecated shadow rows: `2`
- Upserted rows: `6`
- Postcheck: `6/6` promoted rows are `verified` + `auto` and have
  `oracle_hash`.

PG786B metadata-only hash backfill:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg786b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg786b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg786b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg786b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

PG786B result:

- Backfilled rows: `55`
- Remaining trusted executable rules missing `oracle_hash`: `0`

## Sync And E2E

Sync artifacts:

- PG786 battle-rule SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg786_removal_life_delta_new_server_pg_to_sqlite_sync.json`
  - PG rows loaded: `6`
  - SQLite inserted/updated: `8`
- PG786 metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg786_removal_life_delta_new_server_metadata_sync.json`
- PG786B battle-rule SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg786b_trusted_rule_oracle_hash_backfill_new_server_sqlite_sync.json`
  - PG rows loaded: `6498`
  - SQLite inserted/updated: `8916`

E2E artifact:

- `docs/hermes-analysis/master_optimizer_reports/pg786_removal_life_delta_new_server_e2e_validation.md`
- Status: `pass`
- Stages passed:
  - PostgreSQL source of truth
  - SQLite Hermes cache
  - canonical snapshot fallback
  - runtime `get_card_effect`
  - battle execution
- Battle scenarios executed: `6`

## Final Counts

Direct PostgreSQL counts after PG786B:

- `raw_verified_battle_cards`: `6375`
- `raw_verified_auto_battle_cards`: `6373`
- `trusted_executable_rules_missing_oracle_hash`: `0`

Global readiness after PG786B:

- `snapshot_has_verified_rule`: `6572`
- `snapshot_has_any_rule`: `7737`
- `battle_and_oracle_ready`: `6547`
- `battle_family_mapper_required`: `27329`

XMage authoritative queue after PG786B:

- `target_identity_count`: `24406`
- `xmage_authoritative_source_count`: `24093`
- `xmage_authoritative_adapter_required_count`: `24093`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`

Post-PG786B exact split:

- `proposal_count`: `3`
- `safe_for_batch_pg_package_count`: `0`
- `proposal_status_counts`: `{"runtime_partial_requires_family_runtime": 3}`

## Final Audits

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260711_post_pg786b_hash_backfill_new_server_final.md`
  - Status: `pass`, `26/26`
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260711_post_pg786b_hash_backfill_new_server_final.md`
  - Status: `pass`
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260711_post_pg786b_hash_backfill_new_server_final.md`
  - Status: `pass`
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260711_post_pg786b_hash_backfill_new_server_final.md`
  - Status: `pass`, `51/51`
- Server target quality gate:
  `./scripts/quality_gate.sh server-target`
  - Status: `pass`

## Next Work

The next executable family should not reuse this removal/life-delta mapper until
new safe subpatterns exist. The current split leaves only three runtime-partial
mana-source proposals from this pass, so the next global wave should select a
new high-volume family/subpattern from the post-PG786B queue.

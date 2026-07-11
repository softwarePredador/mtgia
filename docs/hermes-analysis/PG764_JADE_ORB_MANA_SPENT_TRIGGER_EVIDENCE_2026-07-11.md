# PG764 Jade Orb Mana-Spent Trigger Evidence - 2026-07-11

## Scope

- Promoted `Jade Orb of Dragonkind`.
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/j/JadeOrbOfDragonkind.java`.
- ManaLoom scope: `xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1`.
- Behavior modeled: `{T}: Add {G}`; when that mana is spent on a Dragon creature spell, the cast Dragon gets an additional `+1/+1` counter and gains `hexproof` until the next turn.

## PostgreSQL Package

- Package prefix: `docs/hermes-analysis/master_optimizer_reports/pg764_jade_orb_new_server`.
- Precheck: `target_card_rows=1`, `existing_rule_rows=0`, `would_deprecate_shadow_rows=0`.
- Apply: `upserted_rows=1`, `deprecated_shadow_rows=0`.
- Postcheck: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.
- Database target: `127.0.0.1:15432/halder`.

## Runtime/E2E Evidence

- Focused tests: `7 passed`.
- E2E status: `pass`.
- E2E validated stages: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, battle execution.
- Battle execution result: `trigger_count=1`, `cast_card_plus_one_counters=1`, `cast_card_keywords=["hexproof"]`.

## PG764B Hash Contract Repair

- PG/Hermes/SQLite contract audit after PG764 found old trusted executable `curated` rows missing `oracle_hash`; the new Jade Orb rule already had hash coverage.
- PG764B package prefix: `docs/hermes-analysis/master_optimizer_reports/pg764b_trusted_rule_oracle_hash_backfill_new_server`.
- Precheck: `trusted_executable_rules_missing_oracle_hash=55`, `matched_card_rows=55`, `proposed_hash_rows=55`.
- Apply: `oracle_hash_rows_backfilled=55`.
- Postcheck: `trusted_executable_rules_missing_oracle_hash=0`, `backup_rows=55`, `updated_rows_with_current_oracle_hash=55`.

## Final Audits

- `pg_hermes_sqlite_contract_audit_20260711_post_pg764b_hash_backfill_new_server_final`: `pass`, `51/51`.
- `xmage_strategy_consistency_audit_20260711_post_pg764_jade_orb_new_server`: `pass`, `26/26`.
- `operational_surface_alignment_audit_20260711_post_pg764b_hash_backfill_new_server_final`: `pass`.
- `legacy_contamination_audit_20260711_post_pg764b_hash_backfill_new_server_final`: `pass`.

## Queue/Readiness Delta

- Post-PG763 queue: `target_identity_count=24462`, `xmage_authoritative_adapter_required_count=24149`, `parser_gap=0`, `missing_source=313`.
- Post-PG764B queue: `target_identity_count=24461`, `xmage_authoritative_adapter_required_count=24148`, `parser_gap=0`, `missing_source=313`.
- Final readiness:
  - `snapshot_has_any_rule=7685`
  - `snapshot_has_verified_rule=6517`
  - `battle_and_oracle_ready=6492`
  - `battle_family_mapper_required=27384`
  - `trusted_rule_oracle_hash_backfill=0`

# PG848 Life-Gained Dynamic Mana Evidence - 2026-07-12

Status: `applied_synced_validated`.

## Scope

- Family: `xmage_dynamic_any_one_color_mana_source`
- Runtime scope: `xmage_dynamic_any_one_color_mana_source_permanent_v1`
- Promoted card: `Accomplished Alchemist`
- XMage source pattern:
  - `AnyColorManaAbility`
  - `DynamicManaAbility`
  - `ControllerGainedLifeCount.instance`
  - `PlayerGainedLifeWatcher`

## Runtime Change

- `battle_analyst_v9.py` now supports
  `dynamic_mana_amount_source=controller_life_gained_this_turn`.
- Dynamic mana sources can declare `dynamic_mana_minimum_produced`.
- Accomplished Alchemist-like sources model both abilities safely:
  - minimum 1 mana from independent `{T}: Add one mana of any color.`
  - X mana from life gained this turn when that value is greater.

## PostgreSQL Apply

Evidence:

- `master_optimizer_reports/pg848_life_gained_dynamic_mana_new_server_apply_evidence.md`
- Precheck: `target_card_rows=1`, `existing_rule_rows=0`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=0`
- Apply: `upserted_rows=1`, `deprecated_shadow_rows=0`
- Postcheck: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`

Additional contract cleanup:

- `master_optimizer_reports/pg848_life_gained_dynamic_mana_new_server_oracle_hash_backfill_evidence.md`
- Existing trusted executable PG rules missing `oracle_hash`: `32 -> 0`

## Sync And Validation

- Metadata sync:
  `master_optimizer_reports/pg848_life_gained_dynamic_mana_new_server_metadata_sync.json`
  - requested unique names: `8543`
  - PostgreSQL cards matched: `8734`
  - SQLite cache alias rows: `8673`
  - deck_cards matched: `2699/2699`
- PG -> SQLite battle-rule sync:
  `master_optimizer_reports/pg848_life_gained_dynamic_mana_new_server_pg_sqlite_sync_after_hash_backfill.json`
  - PG rows loaded: `10534`
  - SQLite inserted/updated: `10312`
  - canonical snapshot rows exported: `7798`
- Package E2E:
  `master_optimizer_reports/pg848_life_gained_dynamic_mana_new_server_e2e_after_hash_backfill.md`
  - status: `pass`
  - PostgreSQL source of truth: `pass`
  - SQLite/Hermes cache: `pass`
  - canonical snapshot fallback: `pass`
  - runtime lookup: `pass`
  - battle execution: `pass`
  - Accomplished Alchemist produced `available_mana=3` and
    `conditional_mana=3` after `controller_life_gained_this_turn=3`

## Final Audits

- XMage strategy consistency:
  `master_optimizer_reports/xmage_strategy_consistency_audit_20260712_post_pg848_life_gained_dynamic_mana_new_server.md`
  - `pass`, `26/26`
- Operational surface alignment:
  `master_optimizer_reports/operational_surface_alignment_audit_20260712_post_pg848_life_gained_dynamic_mana_new_server.md`
  - `pass`
- PG/Hermes/SQLite contract:
  `master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260712_post_pg848_life_gained_dynamic_mana_new_server_after_hash_backfill_final.md`
  - `pass`, `51/51`
- Post-PG848 exact-scope recheck:
  `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_post_pg848_life_gained_dynamic_mana_new_server_recheck.md`
  - `proposal_count=0`
  - `safe_for_batch_pg_package_count=0`

## Global Counters After PG848

Source:
`master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg848_life_gained_dynamic_mana_new_server_after_hash_backfill_final.md`

- all known cards: `34331`
- snapshot has verified rule: `6854`
- battle and Oracle ready: `6747`
- battle family mapper required: `27047`
- battle rule verification required: `70`
- generic runtime/no-card-rule: `359`
- official Oracle identity unavailable: `3`

Source:
`master_optimizer_reports/xmage_authoritative_adaptation_queue_20260712_post_pg848_life_gained_dynamic_mana_new_server_commander_legal.md`

- target identity count: `24136`
- XMage authoritative source count: `23823`
- XMage authoritative adapter required count: `23823`
- XMage authoritative parser gap count: `0`
- XMage missing source exceptions: `313`
- adapter work unit count: `11224`

## Next Recommended Work

Continue global completion by selecting the next exact subpattern from the
largest remaining blocked families. Current high-volume queues remain:

- `recursion::xmage_graveyard_return_variant_review_v1`: `1781`
- `draw_engine::xmage_draw_card_variant_review_v1`: `1541`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`: `1060`
- `add_counters::source_add_counters_variant_v1`: `768`
- `direct_damage::targeted_damage_variant_v1`: `731`

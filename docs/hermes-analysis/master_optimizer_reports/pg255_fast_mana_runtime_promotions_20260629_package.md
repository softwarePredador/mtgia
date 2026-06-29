# PG255 Fast Mana Runtime Promotions

Status: `applied_synced_validated`.

Candidate count: `3`

## Cards

- `Ashnod's Altar`: `passive` / `activated_sacrifice_creature_add_two_colorless_mana_v1` / `battle_rule_v1:5fd05007191c6e481e8371724035031c`
- `Chrome Mox`: `ramp_permanent` / `zero_mana_artifact_imprint_nonartifact_nonland_tap_add_imprinted_color_v1` / `battle_rule_v1:4b4ae6ec37e017046c6671e1a5985f17`
- `Mox Diamond`: `ramp_permanent` / `zero_mana_artifact_discard_land_etb_tap_add_any_color_v1` / `battle_rule_v1:0a78dec9b9b2b0b5218b7d0a64a9afb3`

## Focused Runtime Proof

- `test_mox_diamond_discards_land_when_it_unlocks_commander`
- `test_mox_diamond_does_not_spend_last_land_without_payoff`
- `test_mox_diamond_does_not_claim_unaffordable_commander_payoff`
- `test_chrome_mox_imprints_colored_nonartifact_nonland_card`
- `test_chrome_mox_does_not_cast_without_valid_imprint`
- `test_ashnods_altar_sacrifices_token_only_for_contextual_mana_unlock`

## Files

- precheck: `pg255_fast_mana_runtime_promotions_20260629_precheck.sql`
- apply: `pg255_fast_mana_runtime_promotions_20260629_apply.sql`
- postcheck: `pg255_fast_mana_runtime_promotions_20260629_postcheck.sql`
- rollback: `pg255_fast_mana_runtime_promotions_20260629_rollback.sql`
- manifest: `pg255_fast_mana_runtime_promotions_20260629_manifest.json`

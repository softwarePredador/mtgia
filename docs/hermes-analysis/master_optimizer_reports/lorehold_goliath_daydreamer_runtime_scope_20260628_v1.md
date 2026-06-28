# Lorehold Goliath Daydreamer Runtime Scope - 2026-06-28

- Generated at: `2026-06-28T10:45:24Z`
- Status: `runtime_executor_implemented_metadata_pending_pg_or_mapper`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Card: `Goliath Daydreamer`
- Source queue: `lorehold_runtime_gap_family_queue_20260628_v7_operational_queue.json`

## XMage Model

- Source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/g/GoliathDaydreamer.java`
- Classes: `GoliathDaydreamer`, `GoliathDaydreamerExileEffect`, `GoliathDaydreamerCastEffect`
- Observed behavior:
  - Hand-cast instant/sorcery resolves to exile with a dream counter instead of graveyard.
  - Attack trigger casts one owned exiled dream-counter spell without paying mana cost.

## Runtime Implementation

- Added scope: `instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1`
- Added events:
  - `goliath_daydreamer_dream_counter_replacement_marked`
  - `replacement_exiled_on_resolution`
  - `goliath_daydreamer_free_cast`
  - `spell_cast`
  - `spell_resolved`
- Runtime preserves cast context during `apply_effect_immediate`, marks only hand-cast instant/sorcery spells, and clears the dream-counter marker before the free recast resolves.

## Validation

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_goliath_daydreamer_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_static_damage_modifier_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_topdeck_play_runtime.py -q`
- Result: `8 passed in 0.34s`

Neighbor free-cast checks:

- `PASS test_pg102_creative_technique_demonstrates_top_nonland_free_casts`
- `PASS test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them`
- `PASS test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit`
- `PASS test_pg231_velomachus_attack_casts_best_eligible_top_seven_spell_without_paying_mana`

## Remaining Blockers

- No PostgreSQL `card_battle_rules` row was applied in this step.
- Hermes/runtime metadata still needs PG-backed rule promotion or an approved local mapper package before Goliath Daydreamer can be trusted in deck gates.
- No Lorehold deck swap should be generated from this card until metadata sync and exposure-aware gate evidence exist.

## Next Action

`prepare_goliath_daydreamer_metadata_package_or_mapper_then_sync_before_gate`

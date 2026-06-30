# Lorehold From-Scratch Miracle Pressure Conversion v1

- generated_at: `2026-06-30T22:54:09.871492+00:00`
- mode: `from_scratch`
- candidate_key: `challenger_lorehold_miracle_pressure_conversion_v1`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1/miracle_pressure_conversion/knowledge_candidate.db`
- candidate_hash: `a60a4ebc43c01dbd5e4207ec952c2300b5b7131a2f42df37586a5761d0ac94b4`
- protected_baseline_deck_id: `607`
- fixed_opponent_deck_id_for_gate: `607`
- commander_intent_score: `99.008`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Preserve the protected 607 mana, topdeck, miracle, protection, and big-spell floor while replacing redundant high-cost payoffs with a compact conversion package: Squee/Faithless/Wheel/Underworld for rummage value, Birgi for spell-chain mana, Aetherflux as a compact closer, and Boros Charm/Silence for the closing window.

## Required Anchors

- Approach of the Second Sun
- Arcane Signet
- Aetherflux Reservoir
- Bender's Waterskin
- Big Score
- Birgi, God of Storytelling // Harnfel, Horn of Bounty
- Blasphemous Act
- Boros Charm
- Boros Signet
- Call Forth the Tempest
- Creative Technique
- Dawn's Truce
- Deflecting Swat
- Emeria's Call // Emeria, Shattered Skyclave
- Esper Sentinel
- Everything Comes to Dust
- Faithless Looting
- Farewell
- Fellwar Stone
- Flawless Maneuver
- Generous Gift
- Giver of Runes
- High Noon
- Hit the Mother Lode
- Improvisation Capstone
- Insurrection
- Jeska's Will
- Land Tax
- Library of Leng
- Lightning Greaves
- Mizzix's Mastery
- Molecule Man
- Monument to Endurance
- Mother of Runes
- Path to Exile
- Pearl Medallion
- Pinnacle Monk // Mystic Peak
- Promise of Loyalty
- Redirect Lightning
- Reforge the Soul
- Rise of the Eldrazi
- Ruby Medallion
- Scroll Rack
- Sensei's Divining Top
- Silence
- Smothering Tithe
- Sol Ring
- Squee, Goblin Nabob
- Starfall Invocation
- Storm Herd
- Stroke of Midnight
- Surge to Victory
- Swiftfoot Boots
- Swords to Plowshares
- Talisman of Conviction
- Teferi's Protection
- The Mind Stone
- The Scarlet Witch
- Thor, God of Thunder
- Tibalt's Trickery
- Underworld Breach
- Unexpected Windfall
- Victory Chimes
- Wheel of Fortune
- Winds of Abandon

## Counts

- row_count: `94`
- quantity_total: `100`
- land_quantity: `34`
- nonland_quantity: `65`

### Strategy Packages

- `deterministic_finisher`: 7
- `early_plan`: 39
- `graveyard_recursion`: 10
- `hand_filter`: 17
- `pressure_absorber`: 17
- `protection_window`: 17
- `spell_chain_conversion`: 46
- `topdeck_miracle_setup`: 12

### Roles

- `aetherflux_reservoir`: 1
- `approach`: 1
- `board_development`: 1
- `board_wipe`: 5
- `card_advantage`: 1
- `composite_resolution`: 1
- `cost_reduction`: 1
- `creature`: 4
- `damage_wipe`: 2
- `demonstrate_top_nonland_free_cast`: 1
- `discard_trigger_modal_draw_treasure_opponent_life_loss`: 1
- `draw`: 14
- `draw_filter`: 1
- `dynamic_damage_wipe`: 1
- `engine`: 7
- `equipment_haste_shroud`: 1
- `equipment_static_attachment`: 1
- `exile_top_nonland_free_cast`: 1
- `exile_value`: 1
- `gift_destroy_all_creatures_return_own_destroyed_creature`: 1
- `gift_hexproof_indestructible`: 1
- `interaction`: 3
- `land`: 34
- `land_tax`: 1
- `loot`: 1
- `mana_development`: 1
- `manual_review`: 1
- `modal_boros_charm`: 1
- `overload_recursion`: 1
- `passive`: 5
- `protection`: 12
- `pump_all`: 1
- `ramp`: 19
- `redirect_removal`: 2
- `removal`: 10
- `silence_spell`: 1
- `static_cost_reduction`: 1
- `steal_all_creatures`: 1
- `support`: 1
- `token_maker`: 2
- `treasure_maker`: 3
- `tutor`: 1
- `vow_counter_each_player_sacrifice_rest`: 1
- `wincon`: 7
- `wipe`: 5

## Validation Commands

```bash
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_strategy_matrix.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607,608,609,610,611,612,613,614,615,616 --candidate /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion.json --out-prefix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion_matrix
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607 --candidate-db docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1/miracle_pressure_conversion/knowledge_candidate.db --candidate-key challenger_lorehold_miracle_pressure_conversion_v1 --candidate-name Lorehold From-Scratch Miracle Pressure Conversion v1 --candidate-archetype from-scratch-miracle-pressure-conversion --candidate-deck-id 6 --matrix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion_matrix.json --fixed-opponent-deck-ids 607 --opponent-limit 4 --games 1 --game-timeout-seconds 30.0 --isolate-deck-process --stem lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion_fixed607_gate
```

## Decklist

```text
1 Lorehold, the Historian
1 Aetherflux Reservoir
1 Approach of the Second Sun
1 Arcane Signet
1 Bender's Waterskin
1 Big Score
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Blasphemous Act
1 Boros Charm
1 Boros Signet
1 Call Forth the Tempest
1 Creative Technique
1 Dawn's Truce
1 Deflecting Swat
1 Emeria's Call // Emeria, Shattered Skyclave
1 Esper Sentinel
1 Everything Comes to Dust
1 Faithless Looting
1 Farewell
1 Fellwar Stone
1 Flawless Maneuver
1 Generous Gift
1 Giver of Runes
1 High Noon
1 Hit the Mother Lode
1 Improvisation Capstone
1 Insurrection
1 Jeska's Will
1 Land Tax
1 Library of Leng
1 Lightning Greaves
1 Mizzix's Mastery
1 Molecule Man
1 Monument to Endurance
1 Mother of Runes
1 Path to Exile
1 Pearl Medallion
1 Pinnacle Monk // Mystic Peak
1 Promise of Loyalty
1 Redirect Lightning
1 Reforge the Soul
1 Rise of the Eldrazi
1 Ruby Medallion
1 Scroll Rack
1 Sensei's Divining Top
1 Silence
1 Smothering Tithe
1 Sol Ring
1 Squee, Goblin Nabob
1 Starfall Invocation
1 Storm Herd
1 Stroke of Midnight
1 Surge to Victory
1 Swiftfoot Boots
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 The Mind Stone
1 The Scarlet Witch
1 Thor, God of Thunder
1 Tibalt's Trickery
1 Underworld Breach
1 Unexpected Windfall
1 Victory Chimes
1 Wheel of Fortune
1 Winds of Abandon
1 Ancient Tomb
1 Arid Mesa
1 Battlefield Forge
1 Bloodstained Mire
1 Command Beacon
1 Command Tower
1 Eiganjo, Seat of the Empire
1 Elegant Parlor
1 Exotic Orchard
1 Flooded Strand
1 Glittering Massif
1 Marsh Flats
4 Mountain
4 Plains
1 Plaza of Heroes
1 Prismatic Vista
1 Radiant Summit
1 Reliquary Tower
1 Sacred Foundry
1 Scalding Tarn
1 Spectator Seating
1 Sunbaked Canyon
1 Sunbillow Verge
1 Turbulent Steppe
1 Urza's Saga
1 War Room
1 Windswept Heath
1 Wooded Foothills
```

# Lorehold From-Scratch Spell Pressure Topdeck v1

- generated_at: `2026-07-04T22:43:22.428664+00:00`
- mode: `from_scratch`
- candidate_key: `challenger_lorehold_spell_pressure_topdeck_v1`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck/spell_pressure_topdeck/knowledge_candidate.db`
- candidate_hash: `f15211e99627f0dcfab360e1656a13d9dea48f7c158d1e3ec0f1b709dc4f2a2b`
- protected_baseline_deck_id: `607`
- fixed_opponent_deck_id_for_gate: `607`
- commander_intent_score: `98.597`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test the smallest pressure signal that current evidence actually saw: Guttersnipe plus Young Pyromancer, while preserving the 607 topdeck, miracle, opponent-turn mana, protection, and deterministic finisher floor. This is a full-shell pressure contract, not a one-for-one cut.

## Required Anchors

- Approach of the Second Sun
- Arcane Signet
- Bender's Waterskin
- Boros Charm
- Boros Signet
- Call Forth the Tempest
- Creative Technique
- Dawn's Truce
- Deflecting Swat
- Esper Sentinel
- Everything Comes to Dust
- Faithless Looting
- Farewell
- Fellwar Stone
- Flawless Maneuver
- Generous Gift
- Giver of Runes
- Guttersnipe
- High Noon
- Hit the Mother Lode
- Land Tax
- Library of Leng
- Lightning Greaves
- Mizzix's Mastery
- Molecule Man
- Monastery Mentor
- Monument to Endurance
- Mother of Runes
- Path to Exile
- Promise of Loyalty
- Reforge the Soul
- Scroll Rack
- Sensei's Divining Top
- Silence
- Smothering Tithe
- Sol Ring
- Starfall Invocation
- Stroke of Midnight
- Swords to Plowshares
- Talisman of Conviction
- Teferi's Protection
- The Mind Stone
- The Scarlet Witch
- Tibalt's Trickery
- Unexpected Windfall
- Victory Chimes
- Wheel of Fortune
- Winds of Abandon
- Young Pyromancer

## Counts

- row_count: `94`
- quantity_total: `100`
- land_quantity: `34`
- nonland_quantity: `65`

### Strategy Packages

- `deterministic_finisher`: 9
- `early_plan`: 39
- `graveyard_recursion`: 6
- `hand_filter`: 19
- `pressure_absorber`: 19
- `protection_window`: 18
- `spell_chain_conversion`: 47
- `topdeck_miracle_setup`: 15

### Roles

- `approach`: 1
- `board_wipe`: 5
- `card_advantage`: 1
- `composite_resolution`: 1
- `cost_reduction`: 1
- `creature`: 5
- `damage_wipe`: 1
- `deal_damage`: 1
- `demonstrate_top_nonland_free_cast`: 1
- `discard_trigger_modal_draw_treasure_opponent_life_loss`: 1
- `draw`: 17
- `draw_filter`: 1
- `dynamic_damage_wipe`: 1
- `engine`: 3
- `equipment_haste_shroud`: 1
- `exile_top_nonland_free_cast`: 1
- `exile_value`: 1
- `gift_destroy_all_creatures_return_own_destroyed_creature`: 1
- `gift_hexproof_indestructible`: 1
- `interaction`: 5
- `land`: 34
- `land_tax`: 1
- `loot`: 1
- `mana_development`: 1
- `manual_review`: 1
- `modal_boros_charm`: 1
- `overload_recursion`: 1
- `passive`: 5
- `payoff`: 1
- `protection`: 14
- `ramp`: 17
- `redirect_removal`: 2
- `removal`: 10
- `silence_spell`: 1
- `stax`: 1
- `token_maker`: 4
- `treasure_maker`: 2
- `tutor`: 3
- `wincon`: 9
- `wipe`: 4

## Validation Commands

```bash
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_strategy_matrix.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607,608,609,610,611,612,613,614,615,616 --candidate /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_spell_pressure_topdeck.json --out-prefix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_spell_pressure_topdeck_matrix
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607 --candidate-db docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck/spell_pressure_topdeck/knowledge_candidate.db --candidate-key challenger_lorehold_spell_pressure_topdeck_v1 --candidate-name Lorehold From-Scratch Spell Pressure Topdeck v1 --candidate-archetype from-scratch-spell-pressure-topdeck --candidate-deck-id 6 --matrix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_spell_pressure_topdeck_matrix.json --fixed-opponent-deck-ids 607 --opponent-limit 4 --games 1 --game-timeout-seconds 30.0 --isolate-deck-process --stem lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_spell_pressure_topdeck_fixed607_gate
```

## Decklist

```text
1 Lorehold, the Historian
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Bender's Waterskin
1 Boros Charm
1 Boros Signet
1 Brass's Bounty
1 Call Forth the Tempest
1 Chaos Warp
1 Creative Technique
1 Dawn's Truce
1 Deflecting Swat
1 Enlightened Tutor
1 Esper Sentinel
1 Everything Comes to Dust
1 Faithless Looting
1 Farewell
1 Fellwar Stone
1 Flawless Maneuver
1 Gamble
1 Generous Gift
1 Ghostly Prison
1 Giver of Runes
1 Guttersnipe
1 Hexing Squelcher
1 High Noon
1 Hit the Mother Lode
1 Improvisation Capstone
1 Jeska's Will
1 Land Tax
1 Library of Leng
1 Lightning Greaves
1 Mizzix's Mastery
1 Molecule Man
1 Monastery Mentor
1 Monument to Endurance
1 Mother of Runes
1 Olórin's Searing Light
1 Path to Exile
1 Perch Protection
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
1 Soulfire Eruption
1 Starfall Invocation
1 Storm Herd
1 Stroke of Midnight
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 The Mind Stone
1 The Scarlet Witch
1 Tibalt's Trickery
1 Unexpected Windfall
1 Victory Chimes
1 Wheel of Fortune
1 Winds of Abandon
1 Young Pyromancer
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

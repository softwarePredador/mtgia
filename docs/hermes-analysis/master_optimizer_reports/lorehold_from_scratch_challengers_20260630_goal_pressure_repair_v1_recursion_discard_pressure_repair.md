# Lorehold From-Scratch Recursion Discard Pressure Repair v1

- generated_at: `2026-06-30T19:52:58.320890+00:00`
- mode: `from_scratch`
- candidate_key: `challenger_lorehold_recursion_discard_pressure_repair_v1`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1/recursion_discard_pressure_repair/knowledge_candidate.db`
- candidate_hash: `fa1ec5268318b972320b6f51a416cffa0ce483cbbbe93f3ffc17bea033203f5d`
- protected_baseline_deck_id: `607`
- fixed_opponent_deck_id_for_gate: `607`
- commander_intent_score: `94.056`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Keep the observed Squee/recursion discard engine, but repair the confirmed pressure failure by preserving the 607 miracle/topdeck anchors and forcing a denser interaction, protection, and board-wipe package before battle.

## Required Anchors

- Squee, Goblin Nabob
- Library of Leng
- Monument to Endurance
- Faithless Looting
- Wheel of Fortune
- Underworld Breach
- Past in Flames
- Mizzix's Mastery
- Reforge the Soul
- Sensei's Divining Top
- Scroll Rack
- Bender's Waterskin
- Molecule Man
- The Scarlet Witch
- Swords to Plowshares
- Path to Exile
- Stroke of Midnight
- Winds of Abandon
- Generous Gift
- Blasphemous Act
- Farewell
- Promise of Loyalty
- Teferi's Protection
- Deflecting Swat
- Flawless Maneuver
- Dawn's Truce

## Counts

- row_count: `96`
- quantity_total: `100`
- land_quantity: `34`
- nonland_quantity: `65`

### Strategy Packages

- `deterministic_finisher`: 8
- `early_plan`: 39
- `graveyard_recursion`: 13
- `hand_filter`: 20
- `pressure_absorber`: 18
- `protection_window`: 19
- `spell_chain_conversion`: 48
- `topdeck_miracle_setup`: 18

### Roles

- `aetherflux_reservoir`: 1
- `approach`: 1
- `board_wipe`: 3
- `cannot_lose_turn`: 1
- `card_advantage`: 1
- `composite_resolution`: 1
- `cost_reduction`: 1
- `creature`: 6
- `damage_wipe`: 2
- `deal_damage`: 1
- `discard_trigger_modal_draw_treasure_opponent_life_loss`: 1
- `draw`: 17
- `draw_filter`: 1
- `dynamic_damage_wipe`: 1
- `engine`: 7
- `exile_value`: 1
- `gift_hexproof_indestructible`: 1
- `graveyard_flashback_grant`: 1
- `interaction`: 3
- `land`: 34
- `land_tax`: 1
- `loot`: 1
- `mana_development`: 1
- `manual_review`: 1
- `modal_boros_charm`: 1
- `overload_recursion`: 1
- `passive`: 6
- `payoff`: 1
- `protection`: 14
- `ramp`: 17
- `redirect_removal`: 2
- `removal`: 11
- `silence_spell`: 1
- `stax`: 1
- `token_maker`: 2
- `treasure_maker`: 1
- `tutor`: 3
- `vow_counter_each_player_sacrifice_rest`: 1
- `wincon`: 7
- `wipe`: 3

## Validation Commands

```bash
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_strategy_matrix.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607,608,609,610,611,612,613,614,615,616 --candidate /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair.json --out-prefix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_matrix
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607 --candidate-db docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1/recursion_discard_pressure_repair/knowledge_candidate.db --candidate-key challenger_lorehold_recursion_discard_pressure_repair_v1 --candidate-name Lorehold From-Scratch Recursion Discard Pressure Repair v1 --candidate-archetype from-scratch-recursion-discard-pressure-repair --candidate-deck-id 6 --matrix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_matrix.json --fixed-opponent-deck-ids 607 --opponent-limit 4 --games 1 --game-timeout-seconds 45.0 --isolate-deck-process --stem lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_fixed607_gate
```

## Decklist

```text
1 Lorehold, the Historian
1 Aetherflux Reservoir
1 Angel's Grace
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Bender's Waterskin
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Blasphemous Act
1 Boros Charm
1 Boros Signet
1 Brass's Bounty
1 Call Forth the Tempest
1 Chaos Warp
1 Crawlspace
1 Dawn's Truce
1 Deflecting Swat
1 Enlightened Tutor
1 Esper Sentinel
1 Faithless Looting
1 Farewell
1 Fellwar Stone
1 Flawless Maneuver
1 Gamble
1 Generous Gift
1 Giver of Runes
1 Hexing Squelcher
1 High Noon
1 Hit the Mother Lode
1 Improvisation Capstone
1 Jeska's Will
1 Land Tax
1 Library of Leng
1 Mizzix's Mastery
1 Molecule Man
1 Monument to Endurance
1 Mother of Runes
1 Olórin's Searing Light
1 Past in Flames
1 Path to Exile
1 Perch Protection
1 Pinnacle Monk // Mystic Peak
1 Promise of Loyalty
1 Redirect Lightning
1 Reforge the Soul
1 Rise of the Eldrazi
1 Ruby Medallion
1 Scroll Rack
1 Sensei's Divining Top
1 Silence
1 Silent Arbiter
1 Smothering Tithe
1 Sol Ring
1 Soulfire Eruption
1 Squee, Goblin Nabob
1 Storm Herd
1 Stroke of Midnight
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 The Scarlet Witch
1 Tibalt's Trickery
1 Underworld Breach
1 Victory Chimes
1 Wheel of Fortune
1 Winds of Abandon
1 Ancient Tomb
1 Arid Archway
1 Arid Mesa
1 Battlefield Forge
1 Bloodstained Mire
1 Boseiju, Who Shelters All
1 Cavern of Souls
1 Clifftop Retreat
1 Command Beacon
1 Command Tower
1 Conduit Pylons
1 Elegant Parlor
1 Flooded Strand
1 Marsh Flats
4 Mountain
2 Plains
1 Plateau
1 Prismatic Vista
1 Radiant Summit
1 Reliquary Tower
1 Sacred Foundry
1 Scalding Tarn
1 Spectator Seating
1 Sunbaked Canyon
1 Sunbillow Verge
1 The Biblioplex
1 Tocasia's Dig Site
1 Urza's Saga
1 Windswept Heath
1 Wooded Foothills
```

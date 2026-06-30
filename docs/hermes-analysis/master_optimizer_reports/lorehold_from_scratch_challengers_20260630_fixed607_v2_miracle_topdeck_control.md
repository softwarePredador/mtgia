# Lorehold From-Scratch Miracle Topdeck Control v1

- generated_at: `2026-06-30T18:55:27.242163+00:00`
- mode: `from_scratch`
- candidate_key: `challenger_lorehold_miracle_topdeck_control_v1`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630/miracle_topdeck_control/knowledge_candidate.db`
- candidate_hash: `607032a23d48acdc2ff50df390e91931b2c4bc75539ef1294d9bed173e6dadf3`
- protected_baseline_deck_id: `607`
- fixed_opponent_deck_id_for_gate: `607`
- commander_intent_score: `94.653`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Maximize Lorehold's first-draw/miracle timing with topdeck setup, discard-to-top replacement, opponent-turn mana, and enough pressure absorption to survive until the discounted high-impact spell turn.

## Required Anchors

- Sensei's Divining Top
- Scroll Rack
- Library of Leng
- Land Tax
- Bender's Waterskin
- Victory Chimes
- Molecule Man
- The Scarlet Witch
- Mizzix's Mastery
- Approach of the Second Sun

## Counts

- row_count: `96`
- quantity_total: `100`
- land_quantity: `34`
- nonland_quantity: `65`

### Strategy Packages

- `deterministic_finisher`: 9
- `early_plan`: 43
- `graveyard_recursion`: 11
- `hand_filter`: 20
- `pressure_absorber`: 15
- `protection_window`: 19
- `spell_chain_conversion`: 47
- `topdeck_miracle_setup`: 19

### Roles

- `aetherflux_reservoir`: 1
- `approach`: 1
- `board_wipe`: 3
- `cannot_lose_turn`: 1
- `card_advantage`: 1
- `composite_resolution`: 1
- `cost_reduction`: 1
- `creature`: 7
- `damage_wipe`: 2
- `direct_damage`: 1
- `discard_trigger_modal_draw_treasure_opponent_life_loss`: 1
- `draw`: 17
- `dynamic_damage_wipe`: 1
- `engine`: 4
- `exile_value`: 2
- `gift_hexproof_indestructible`: 1
- `interaction`: 3
- `land`: 34
- `land_tax`: 1
- `mana_development`: 1
- `manual_review`: 1
- `modal_boros_charm`: 1
- `overload_recursion`: 1
- `passive`: 5
- `payoff`: 1
- `protection`: 14
- `pump_all`: 1
- `ramp`: 20
- `redirect_removal`: 2
- `removal`: 9
- `silence_spell`: 1
- `stax`: 1
- `token_maker`: 2
- `treasure_maker`: 2
- `tutor`: 4
- `wincon`: 8
- `wipe`: 3

## Validation Commands

```bash
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_strategy_matrix.py --db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607,608,609,610,611,612,613,614,615,616 --candidate /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_miracle_topdeck_control.json --out-prefix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_miracle_topdeck_control_matrix
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py --db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607 --candidate-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630/miracle_topdeck_control/knowledge_candidate.db --candidate-key challenger_lorehold_miracle_topdeck_control_v1 --candidate-name Lorehold From-Scratch Miracle Topdeck Control v1 --candidate-archetype from-scratch-miracle-topdeck-control --candidate-deck-id 6 --matrix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_miracle_topdeck_control_matrix.json --fixed-opponent-deck-ids 607 --opponent-limit 4 --games 1 --game-timeout-seconds 20.0 --isolate-deck-process --stem lorehold_from_scratch_challengers_20260630_fixed607_v2_miracle_topdeck_control_fixed607_gate
```

## Decklist

```text
1 Lorehold, the Historian
1 Aetherflux Reservoir
1 Angel's Grace
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Artist's Talent
1 Austere Command
1 Bender's Waterskin
1 Big Score
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Blasphemous Act
1 Boros Charm
1 Boros Signet
1 Brass's Bounty
1 Call Forth the Tempest
1 Chaos Warp
1 Crawlspace
1 Dance with Calamity
1 Dawn's Truce
1 Deflecting Palm
1 Deflecting Swat
1 Enlightened Tutor
1 Esper Sentinel
1 Fellwar Stone
1 Flawless Maneuver
1 Gamble
1 Giver of Runes
1 Goblin Engineer
1 Hexing Squelcher
1 Hit the Mother Lode
1 Improvisation Capstone
1 Jeska's Will
1 Land Tax
1 Library of Leng
1 Lightning Bolt
1 Mana Vault
1 Mizzix's Mastery
1 Molecule Man
1 Monument to Endurance
1 Mother of Runes
1 Olórin's Searing Light
1 Path to Exile
1 Penance
1 Perch Protection
1 Pinnacle Monk // Mystic Peak
1 Redirect Lightning
1 Reforge the Soul
1 Rise of the Eldrazi
1 Ruby Medallion
1 Scroll Rack
1 Sensei's Divining Top
1 Silence
1 Smothering Tithe
1 Sol Ring
1 Storm Herd
1 Storm-Kiln Artist
1 Surge to Victory
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 The Scarlet Witch
1 Tibalt's Trickery
1 Untimely Malfunction
1 Victory Chimes
1 Wheel of Fortune
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
3 Mountain
3 Plains
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

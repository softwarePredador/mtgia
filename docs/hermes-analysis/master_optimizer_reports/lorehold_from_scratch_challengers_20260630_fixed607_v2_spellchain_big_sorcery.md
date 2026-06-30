# Lorehold From-Scratch Spellchain Big Sorcery v1

- generated_at: `2026-06-30T18:55:27.890982+00:00`
- mode: `from_scratch`
- candidate_key: `challenger_lorehold_spellchain_big_sorcery_v1`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630/spellchain_big_sorcery/knowledge_candidate.db`
- candidate_hash: `1b10a3206e9e8be24ff01e9fb076e1c09a24c269b0968329d0880f911083790a`
- protected_baseline_deck_id: `607`
- fixed_opponent_deck_id_for_gate: `607`
- commander_intent_score: `94.835`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Treat Lorehold as a burst spell-chain commander: early rocks and rituals build ahead of curve, copy engines multiply the decisive instant/sorcery, and compact finishers convert one big turn into a win.

## Required Anchors

- Sol Ring
- Arcane Signet
- Mana Vault
- Birgi, God of Storytelling // Harnfel, Horn of Bounty
- Storm-Kiln Artist
- Mizzix's Mastery
- Aetherflux Reservoir
- Reiterate
- Twinflame
- Heat Shimmer
- Dualcaster Mage
- Jeska's Will

## Counts

- row_count: `97`
- quantity_total: `100`
- land_quantity: `33`
- nonland_quantity: `66`

### Strategy Packages

- `deterministic_finisher`: 11
- `early_plan`: 44
- `graveyard_recursion`: 12
- `hand_filter`: 20
- `pressure_absorber`: 13
- `protection_window`: 18
- `spell_chain_conversion`: 47
- `topdeck_miracle_setup`: 18

### Roles

- `aetherflux_reservoir`: 1
- `approach`: 1
- `board_wipe`: 3
- `card_advantage`: 1
- `combo`: 1
- `composite_resolution`: 1
- `copy_creature_token`: 2
- `copy_spell`: 2
- `cost_reduction`: 1
- `creature`: 6
- `damage_wipe`: 2
- `deal_damage`: 1
- `direct_damage`: 1
- `discard_trigger_modal_draw_treasure_opponent_life_loss`: 1
- `draw`: 17
- `draw_filter`: 1
- `dynamic_damage_wipe`: 1
- `engine`: 6
- `exile_value`: 1
- `gift_destroy_all_creatures_return_own_destroyed_creature`: 1
- `gift_hexproof_indestructible`: 1
- `interaction`: 6
- `land`: 33
- `land_tax`: 1
- `loot`: 1
- `mana_development`: 1
- `manual_review`: 1
- `modal_boros_charm`: 1
- `overload_recursion`: 1
- `passive`: 5
- `payoff`: 1
- `protection`: 14
- `ramp`: 21
- `redirect_removal`: 2
- `removal`: 8
- `silence_spell`: 1
- `stax`: 1
- `threat`: 1
- `token_maker`: 4
- `treasure_maker`: 2
- `tutor`: 3
- `wincon`: 9
- `wipe`: 3

## Validation Commands

```bash
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_strategy_matrix.py --db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607,608,609,610,611,612,613,614,615,616 --candidate /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_spellchain_big_sorcery.json --out-prefix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_spellchain_big_sorcery_matrix
python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py --db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607 --candidate-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630/spellchain_big_sorcery/knowledge_candidate.db --candidate-key challenger_lorehold_spellchain_big_sorcery_v1 --candidate-name Lorehold From-Scratch Spellchain Big Sorcery v1 --candidate-archetype from-scratch-spellchain-big-sorcery --candidate-deck-id 6 --matrix /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_spellchain_big_sorcery_matrix.json --fixed-opponent-deck-ids 607 --opponent-limit 4 --games 1 --game-timeout-seconds 20.0 --isolate-deck-process --stem lorehold_from_scratch_challengers_20260630_fixed607_v2_spellchain_big_sorcery_fixed607_gate
```

## Decklist

```text
1 Lorehold, the Historian
1 Aetherflux Reservoir
1 Apex of Power
1 Approach of the Second Sun
1 Arcane Signet
1 Artist's Talent
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
1 Dawn's Truce
1 Deflecting Palm
1 Deflecting Swat
1 Dragon's Rage Channeler
1 Dualcaster Mage
1 Enlightened Tutor
1 Esper Sentinel
1 Faithless Looting
1 Fellwar Stone
1 Flawless Maneuver
1 Gamble
1 Giver of Runes
1 Heat Shimmer
1 Helm of Awakening
1 Hexing Squelcher
1 Hit the Mother Lode
1 Improvisation Capstone
1 Jeska's Will
1 Land Tax
1 Library of Leng
1 Lightning Bolt
1 Mana Vault
1 Mizzix's Mastery
1 Monument to Endurance
1 Mother of Runes
1 Olórin's Searing Light
1 Path to Exile
1 Perch Protection
1 Pinnacle Monk // Mystic Peak
1 Redirect Lightning
1 Reforge the Soul
1 Reiterate
1 Reprieve
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
1 Storm-Kiln Artist
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 Tibalt's Trickery
1 Twinflame
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
4 Mountain
1 Plains
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

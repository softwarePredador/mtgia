# Lorehold 607 Research Candidate past_in_flames_pinnacle_monk_v1

- generated_at: `2026-06-30T04:05:13.458528+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_607_candidate_20260630_past_in_flames_pinnacle_monk_v1/knowledge_candidate.db`
- candidate_hash: `762905bdf902c78f899566d02209033426c2605ea19949e095f2f4b5d6277262`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test a graveyard-recursion spell-chain sidegrade without touching protected miracle/topdeck, ramp, protection, or finisher anchors. Pinnacle Monk currently occupies the recursion/engine neighborhood by returning one instant or sorcery from the graveyard; Past in Flames turns the graveyard into a one-turn flashback engine for multiple instants and sorceries.

## External Signals

- Past in Flames appears in local Lorehold variant 612.
- Local battle_card_rules has an active auto temporary-flashback rule for Past in Flames.
- The frozen Lorehold matrix repeatedly reports a recursion-role shortfall, so this candidate targets a real structural gap.
- External Lorehold/spellslinger references support flashback and graveyard recasting as a commander-specific support lane, but the swap still requires equal battle proof.

## Swaps

| In | Out |
| --- | --- |
| Past in Flames | Pinnacle Monk // Mystic Peak |

## Counts

- row_count: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Strategy Package Counts

- `deterministic_finisher`: 9
- `early_plan`: 36
- `graveyard_recursion`: 8
- `hand_filter`: 15
- `pressure_absorber`: 18
- `protection_window`: 17
- `spell_chain_conversion`: 43
- `topdeck_miracle_setup`: 12

## Final Decklist

### Commander

1 Lorehold, the Historian

### Nonlands

1 Approach of the Second Sun
1 Arcane Signet
1 Artist's Talent
1 Avatar's Wrath
1 Bender's Waterskin
1 Big Score
1 Blasphemous Act
1 Boros Signet
1 Call Forth the Tempest
1 Creative Technique
1 Dawn's Truce
1 Deflecting Swat
1 Emeria's Call // Emeria, Shattered Skyclave
1 Esper Sentinel
1 Everything Comes to Dust
1 Farewell
1 Fated Clash
1 Fellwar Stone
1 Flawless Maneuver
1 Furygale Flocking
1 Generous Gift
1 Giver of Runes
1 Hexing Squelcher
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
1 Past in Flames
1 Path to Exile
1 Pearl Medallion
1 Prismari Pianist
1 Promise of Loyalty
1 Redirect Lightning
1 Reforge the Soul
1 Rise of the Eldrazi
1 Ruby Medallion
1 Scroll Rack
1 Sensei's Divining Top
1 Smothering Tithe
1 Sol Ring
1 Starfall Invocation
1 Storm Herd
1 Stroke of Midnight
1 Surge to Victory
1 Swiftfoot Boots
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 Tempt with Bunnies
1 The Mind Stone
1 The Scarlet Witch
1 Thor, God of Thunder
1 Tibalt's Trickery
1 Tragic Arrogance
1 Unexpected Windfall
1 Victory Chimes
1 Winds of Abandon

### Lands

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

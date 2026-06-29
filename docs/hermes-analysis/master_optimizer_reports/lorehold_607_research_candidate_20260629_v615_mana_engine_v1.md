# Lorehold 607 Research Candidate v615_mana_engine_v1

- generated_at: `2026-06-29T20:31:10.839644+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260629_v615_mana_engine_v1/knowledge_candidate.db`
- candidate_hash: `f9494816fc96cb7cff6461beda1c306eff09df1c27bd511491b882890590c4fa`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Start from protected deck_607 and import only the 615 cards with promotion-gate trace evidence: Mana Vault for fast mana, Birgi for spell-chain mana, and The One Ring for draw/protection. Keep The Mind Stone in the shell so the One Ring blink/refresh hypothesis remains testable instead of cutting the enabler before evidence exists.

## External Signals

- Promotion gate 2026-06-29 kept deck_607 as baseline but identified deck_615 as the best package-learning candidate.
- deck_615 traces showed Mana Vault cost_paid=20, Birgi spell_cast_mana=25, The One Ring cost_paid=7, and stronger Winota pressure results than deck_607.
- The cuts are narrow same-lane or low-observed slots: Bender's Waterskin is slower ramp, The Scarlet Witch overlaps cost-reduction/engine space, and Molecule Man had access but no recorded use metric in the promotion gate.

## Swaps

| In | Out |
| --- | --- |
| Mana Vault | Bender's Waterskin |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | The Scarlet Witch |
| The One Ring | Molecule Man |

## Counts

- row_count: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Strategy Package Counts

- `deterministic_finisher`: 9
- `early_plan`: 36
- `graveyard_recursion`: 8
- `hand_filter`: 16
- `pressure_absorber`: 19
- `protection_window`: 18
- `spell_chain_conversion`: 43
- `topdeck_miracle_setup`: 11

## Final Decklist

### Commander

1 Lorehold, the Historian

### Nonlands

1 Approach of the Second Sun
1 Arcane Signet
1 Artist's Talent
1 Avatar's Wrath
1 Big Score
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
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
1 Mana Vault
1 Mizzix's Mastery
1 Monument to Endurance
1 Mother of Runes
1 Path to Exile
1 Pearl Medallion
1 Pinnacle Monk // Mystic Peak
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
1 The One Ring
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

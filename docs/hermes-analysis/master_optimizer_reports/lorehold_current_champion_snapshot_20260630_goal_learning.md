# Lorehold Current Champion Snapshot

- Generated at: `2026-06-30T23:36:27Z`
- Status: `current_champion_snapshot`
- Deck id: `607`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Micro-package model: `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_targeted_micro_package_model_20260630_goal_learning.json`
- Planner report: `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_micro_package_model.json`
- Total cards: `100`
- Deck rows: `94`
- Lands: `34`
- Commander count: `1`
- Missing protected anchors: `0`
- Planner next action: `freeze_607_current_champion_snapshot_until_new_cut_evidence`
- Micro-package ready count: `0`
- Seed-safe cut ready count: `0`

## Decision

- `keep_607_as_current_champion`: Trace-targeted hypotheses exist, but no micro-package has both named adds and a seed-safe cut.

## Replacement Contract

- package names exact add cards and cut cards
- cut is seed-safe under the current cut model
- natural gate ties or beats protected 607 on the same opponent and seed window
- miracle/topdeck/spell-volume and pressure-window targets do not regress
- added cards are drawn, cast, resolved, activated, or otherwise used enough to prove impact

## Protected Anchors

- Lorehold, the Historian
- Sensei's Divining Top
- Scroll Rack
- Approach of the Second Sun
- Victory Chimes
- Mizzix's Mastery
- Bender's Waterskin
- Jeska's Will
- Library of Leng

## Validation

- PASS: 100 cards and exactly one commander.
- PASS: protected anchors are present in deck 607.

## Role Counts

- board_wipe: 6
- commander: 1
- creature: 2
- draw: 12
- engine: 2
- land: 34
- protection: 9
- ramp: 15
- removal: 7
- tutor: 1
- unknown: 2
- wincon: 9

## Decklist

```text
1 Lorehold, the Historian
1 Furygale Flocking
1 Improvisation Capstone
1 Prismari Pianist
1 Esper Sentinel
1 Giver of Runes
1 Land Tax
1 Library of Leng
1 Mother of Runes
1 Path to Exile
1 Redirect Lightning
1 Sensei's Divining Top
1 Sol Ring
1 Swords to Plowshares
1 Arcane Signet
1 Artist's Talent
1 Boros Signet
1 Dawn's Truce
1 Fellwar Stone
1 Hexing Squelcher
1 High Noon
1 Lightning Greaves
1 Pearl Medallion
1 Ruby Medallion
1 Scroll Rack
1 Swiftfoot Boots
1 Talisman of Conviction
1 The Mind Stone
1 Tibalt's Trickery
1 Winds of Abandon
1 Bender's Waterskin
1 Deflecting Swat
1 Flawless Maneuver
1 Generous Gift
1 Jeska's Will
1 Monument to Endurance
1 Stroke of Midnight
1 Teferi's Protection
1 Tempt with Bunnies
1 The Scarlet Witch
1 Victory Chimes
1 Avatar's Wrath
1 Big Score
1 Mizzix's Mastery
1 Smothering Tithe
1 Unexpected Windfall
1 Creative Technique
1 Fated Clash
1 Pinnacle Monk // Mystic Peak
1 Promise of Loyalty
1 Reforge the Soul
1 Starfall Invocation
1 Thor, God of Thunder
1 Tragic Arrogance
1 Farewell
1 Molecule Man
1 Surge to Victory
1 Approach of the Second Sun
1 Emeria's Call // Emeria, Shattered Skyclave
1 Hit the Mother Lode
1 Call Forth the Tempest
1 Insurrection
1 Blasphemous Act
1 Everything Comes to Dust
1 Storm Herd
1 Rise of the Eldrazi
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
4 Mountain // Mountain
4 Plains // Plains
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

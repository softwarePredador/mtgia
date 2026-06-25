# Lorehold Generated Candidate Deck PG217

- generated_at: `2026-06-25T12:17:25.847762+00:00`
- status: `generated_isolated_candidate`
- deck_id: `6`
- source_matrix: `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg217_saga_draw_artifact_postsync_v1.json`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260625_pg217_v1/knowledge_candidate.db`
- postgres_writes: `False`
- source_db_mutated: `False`
- candidate_hash: `ef278cefb669df32bc6c921f422f218791252c81bc1e08abf5663f3a02f54036`

## Validation

- validation_status: `passed`
- quantity: `100`
- main_quantity: `99`
- land_count: `33`
- nonland_count: `66`
- distinct_cards: `100`
- role_shortfalls: `{}`
- color_identity_issues: `[]`
- novel_cards_vs_active: `11`
- cuts_vs_active: `11`

## Novel Cards

- Exotic Orchard
- Goblin Engineer
- Improvisation Capstone
- Increasing Vengeance
- Library of Leng
- Monument to Endurance
- Pinnacle Monk // Mystic Peak
- Reforge the Soul
- Restoration Seminar
- The Biblioplex
- Verdant Catacombs

## Cuts From Active Deck

- Aetherflux Reservoir
- Crawlspace
- Drannith Magistrate
- Hall of Heliod's Generosity
- Inspiring Vantage
- Magus of the Moat
- Mana Confluence
- Mox Amber
- Silent Arbiter
- Sphere of Safety
- Windborn Muse

## Role Metric Counts

- nonland_ramp: `20` (minimum `11`)
- draw: `27` (minimum `14`)
- engine: `19` (minimum `14`)
- protection: `14` (minimum `10`)
- removal: `8` (minimum `8`)
- tutor: `9` (minimum `7`)
- wincon: `11` (minimum `7`)
- recursion: `7` (minimum `4`)
- board_wipe: `2` (minimum `2`)
- stax: `5` (minimum `3`)

## Deck List

1 Lorehold, the Historian
1 Ancient Den
1 Ancient Tomb
1 Arid Mesa
1 Battlefield Forge
1 Bloodstained Mire
1 City of Brass
1 Clifftop Retreat
1 Command Tower
1 Elegant Parlor
1 Exotic Orchard
1 Flooded Strand
1 Gemstone Caverns
1 Great Furnace
1 Inventors' Fair
1 Marsh Flats
1 Mountain // Mountain
1 Needleverge Pathway // Pillarverge Pathway
1 Plains // Plains
1 Plateau
1 Prismatic Vista
1 Rugged Prairie
1 Sacred Foundry
1 Scalding Tarn
1 Spectator Seating
1 Sunbaked Canyon
1 Sunbillow Verge
1 Sundown Pass
1 The Biblioplex
1 Urza's Saga
1 Verdant Catacombs
1 War Room
1 Windswept Heath
1 Wooded Foothills
1 Approach of the Second Sun
1 Arcane Signet
1 Austere Command
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Blasphemous Act
1 Boros Charm
1 Boros Signet
1 Brainstone
1 Chaos Warp
1 Deflecting Swat
1 Dualcaster Mage
1 Enlightened Tutor
1 Esper Sentinel
1 Faithless Looting
1 Fellwar Stone
1 Flawless Maneuver
1 Gamble
1 Get Lost
1 Ghostly Prison
1 Giver of Runes
1 Goblin Engineer
1 Grand Abolisher
1 Heat Shimmer
1 Imperial Recruiter
1 Improvisation Capstone
1 Increasing Vengeance
1 Jeska's Will
1 Land Tax
1 Library of Leng
1 Lightning Greaves
1 Lotus Petal
1 Mana Vault
1 Mizzix's Mastery
1 Molten Duplication
1 Monument to Endurance
1 Mother of Runes
1 Orim's Chant
1 Past in Flames
1 Path to Exile
1 Pinnacle Monk // Mystic Peak
1 Professional Face-Breaker
1 Pyroblast
1 Ranger-Captain of Eos
1 Recruiter of the Guard
1 Reforge the Soul
1 Reiterate
1 Restoration Seminar
1 Reverberate
1 Rite of Flame
1 Ruby Medallion
1 Scroll Rack
1 Seething Song
1 Sensei's Divining Top
1 Silence
1 Smothering Tithe
1 Sol Ring
1 Storm-Kiln Artist
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 The One Ring
1 Twinflame
1 Unexpected Windfall
1 Valakut Awakening // Valakut Stoneforge
1 Wheel of Fortune
1 Wheel of Misfortune

## Notes

- Generated from battle-ready matrix rows only.
- Cards with pending mapper/split/runtime promotion lanes were excluded.
- Color identity was checked against the local card_oracle_cache.
- The candidate SQLite DB is an isolated copy for battle smoke only.
- This report does not approve applying the deck to PostgreSQL or deck 6.


## Battle Smoke

- load_status: `completed`
- loaded_total: `100`
- construction_valid: `True`
- smoke_status: `completed`
- returncode: `0`
- games: `3` (`1` per opponent, `3` real learned opponents)
- overall_wr: `33.3%`
- record: `1W/2L/0S`
- stdout: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260625_pg217_v1/battle_smoke_stdout.txt`
- stderr: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260625_pg217_v1/battle_smoke_stderr.txt`
- log_path: `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260625_pg217_v1/knowledge_dir/decks/lorehold-the-historian/BATTLE_LOG.md`

### Smoke Tail

```text
============================================================
BATTLE ANALYST v9 — Interactive Commander (Priority + Stack + Miracle)
============================================================
Commander: Lorehold, the Historian
Deck: 1+99 | L=33 R=52 X=10 CMC=2.44 Instants=19
v9: Priority, Stack, Instant/Sorcery Timing, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste
Evaluation mode: target-deck-under-pressure
Evaluation target player: Lorehold
Loaded 3 real opponent decks from 12 valid candidates (seed=20260625)

Using 3 REAL learned opponent decks

1 games vs each of 3 real opponents (4-player)...

  loss vs Kinnan, Bonder Prodigy #120 (real) WR=  0.0% W=0 L=1 S=0 T=0.0 []
  win vs Najeela, the Blade-Blossom #111 (real) WR=100.0% W=1 L=0 S=0 T=17.0 [elimination=1]
  loss vs Rograkh, Son of Rohgahh #118 (real) WR=  0.0% W=0 L=1 S=0 T=0.0 []

  OVERALL v9: WR=33.3% (1W/2L/0S)

Log: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260625_pg217_v1/knowledge_dir/decks/lorehold-the-historian/BATTLE_LOG.md
```

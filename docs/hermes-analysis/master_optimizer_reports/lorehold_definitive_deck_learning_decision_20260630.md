# Lorehold Definitive Deck Learning Decision - 2026-06-30

## Decision

- Current definitive deck: deck `607`.
- Deck action taken: no swap, no live deck mutation, no PostgreSQL write.
- Reason: the current learning cycle found zero gate-ready packages. The only correct promotion rule is to keep the protected baseline until a challenger beats it with safe-cut, seed-anchor, natural-use, and battle evidence.
- Important boundary: the Squee evidence in this cycle is challenger evidence, not live deck-607 evidence. The active deck `607` does not contain `Squee, Goblin Nabob`.

## Evidence Summary

| Evidence | Result | Decision Impact |
| --- | --- | --- |
| Commander deckbuilding contract audit | `pass` | Project routing still treats deck `607` as protected baseline. |
| Operational surface alignment audit | `pass` | Battle/deckbuilder handoff is aligned after current runner fixes. |
| Learning evidence ledger | `current_leader=deck_607`; `actionable_confirmation_count=6`; invalid Olórin package removed from actionable queue | Old positive signal cannot be used blindly. |
| Old package preflight | `preflight_blocked`; all old actionable packages blocked by protected cut or prior negative evidence | No old signal is allowed into battle gate. |
| Safe-cut replanner | `manifest_ready_count=0` | No safe cut manifest exists for the next swap. |
| Runtime gap queue | `blocked_runtime_rule_gap_count=0` | Current blocker is not card-rule runtime coverage. |
| Squee graveyard-entry probe | `squee_route_modeled_but_access_gap_remains`; seed 42 is positive when accessed, weak seeds miss access/material events | Squee shell remains a challenger hypothesis, not a live-deck promotion. |
| Focus-access package generator | `package_candidate_count=52`; `gate_ready_package_count=0`; top work `squee_access_density_model` | Do not create a blind swap. Build a safe access/cut model first. |

## Active Deck 607 List

Commander:

1. Lorehold, the Historian

Main deck:

1. Approach of the Second Sun
1. Arcane Signet
1. Artist's Talent
1. Avatar's Wrath
1. Bender's Waterskin
1. Big Score
1. Blasphemous Act
1. Boros Signet
1. Call Forth the Tempest
1. Creative Technique
1. Dawn's Truce
1. Deflecting Swat
1. Emeria's Call // Emeria, Shattered Skyclave
1. Esper Sentinel
1. Everything Comes to Dust
1. Farewell
1. Fated Clash
1. Fellwar Stone
1. Flawless Maneuver
1. Furygale Flocking
1. Generous Gift
1. Giver of Runes
1. Hexing Squelcher
1. High Noon
1. Hit the Mother Lode
1. Improvisation Capstone
1. Insurrection
1. Jeska's Will
1. Land Tax
1. Library of Leng
1. Lightning Greaves
1. Mizzix's Mastery
1. Molecule Man
1. Monument to Endurance
1. Mother of Runes
1. Path to Exile
1. Pearl Medallion
1. Pinnacle Monk // Mystic Peak
1. Prismari Pianist
1. Promise of Loyalty
1. Redirect Lightning
1. Reforge the Soul
1. Rise of the Eldrazi
1. Ruby Medallion
1. Scroll Rack
1. Sensei's Divining Top
1. Smothering Tithe
1. Sol Ring
1. Starfall Invocation
1. Storm Herd
1. Stroke of Midnight
1. Surge to Victory
1. Swiftfoot Boots
1. Swords to Plowshares
1. Talisman of Conviction
1. Teferi's Protection
1. Tempt with Bunnies
1. The Mind Stone
1. The Scarlet Witch
1. Thor, God of Thunder
1. Tibalt's Trickery
1. Tragic Arrogance
1. Unexpected Windfall
1. Victory Chimes
1. Winds of Abandon
1. Ancient Tomb
1. Arid Mesa
1. Battlefield Forge
1. Bloodstained Mire
1. Command Beacon
1. Command Tower
1. Eiganjo, Seat of the Empire
1. Elegant Parlor
1. Exotic Orchard
1. Flooded Strand
1. Glittering Massif
1. Marsh Flats
4. Mountain // Mountain
4. Plains // Plains
1. Plaza of Heroes
1. Prismatic Vista
1. Radiant Summit
1. Reliquary Tower
1. Sacred Foundry
1. Scalding Tarn
1. Spectator Seating
1. Sunbaked Canyon
1. Sunbillow Verge
1. Turbulent Steppe
1. Urza's Saga
1. War Room
1. Windswept Heath
1. Wooded Foothills

Deck-size check from Hermes SQLite:

- Total cards: `100`
- Commander: `1`
- Main deck: `99`
- `Squee, Goblin Nabob` rows in active deck `607`: `0`

## Current Learning Plan

1. Keep deck `607` as the current definitive deck.
2. Do not rerun old positive signals that cut protected cards or already failed preflight.
3. Treat the Squee shell as a challenger lane only. It needs a safe add/cut/access package before it can challenge `607`.
4. Prioritize `squee_access_density_model`: find a non-protected package that improves access to Squee/Top/Rack/Library while preserving the seed-42 miracle/topdeck band.
5. If no safe Squee package exists, run `contextual_tutor_cut_model` for seed-7 engine access without cutting Land Tax, Thor, Creative Technique, or protected topdeck engines.
6. Leave `hand_filter_non_core_cut_search` blocked until there is a new non-core cut or runtime evidence; do not repeat exhausted hand-filter pairs.

## Commands Rebuilt In This Cycle

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_squee_graveyard_entry_probe.py --stem lorehold_squee_graveyard_entry_probe_20260630_definitive_learning_v2
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_focus_access_package_generator.py --stem lorehold_focus_access_package_generator_20260630_definitive_learning_v5
python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_focus_access_package_generator.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_squee_graveyard_entry_probe.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_learning_evidence_ledger.py
```

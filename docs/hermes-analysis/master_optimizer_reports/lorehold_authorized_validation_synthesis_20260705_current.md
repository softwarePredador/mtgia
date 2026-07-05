# Lorehold Authorized Validation Synthesis - 2026-07-05

- Status: `keep_607_protected_baseline_no_promotion`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Authorization used as: `isolated candidate DBs and read-only audits`

## Technical Validation

| Gate | Result |
| --- | --- |
| Deckbuilding contract surface | pass |
| Operational surface alignment | pass |
| Legacy contamination | pass |
| PG/Hermes/SQLite contract | pass, 51/51 |
| Focused Python unittest | pass, 35/35 |

## Cut And Brain Findings

- Brain status: `brain_safe_cut_gap_no_seed_safe_cut_keep_607`
- Brain active rule count: `1`
- Brain safe cut count: `0`
- Topdeck/DRC safe cut ready count: `None`
- Seed-safe cut ready count: `0`
- Same-lane-only, not seed-safe cuts: `Creative Technique, Bender's Waterskin`

## Candidate Battle Results

| Candidate | Matrix rank | Matrix score | Smoke 8 | Confirm 24 | Decision |
| --- | ---: | ---: | --- | --- | --- |
| `access_density_control` | 4 | 129.148 | candidate 4/8 vs 607 4/8 | candidate 4/24 vs 607 10/24 | reject; failed confirmation |
| `spell_volume_access_depressure` | 1 | 141.721 | candidate 4/8 vs 607 4/8 | candidate 5/24 vs 607 10/24 | reject; failed confirmation |
| `spell_pressure_mana_conversion_deoverfill` | 1 | 142.003 | candidate 3/8 vs 607 4/8 | not expanded; smoke lost | reject; smoke loss |

## Decision

Authorized isolated tests did not produce a candidate that ties or beats protected 607 under the required battle evidence. Two 8-game smoke ties collapsed in 24-game confirmation; the third smoke candidate lost immediately.

Recommended next action: Repair cut safety and failure diagnosis before more promotion gates: preserve 607 removal/protection density, treat high structural score as insufficient, and only reopen Brain/DRC when a real seed-safe same-lane cut exists.

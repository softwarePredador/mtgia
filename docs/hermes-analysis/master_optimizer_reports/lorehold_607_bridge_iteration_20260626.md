# Lorehold 607 Bridge Iteration 2026-06-26

- status: `bridge_rejected_keep_deck_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- source_deck: `deck_607`
- comparison_seed: `opponent_seed=20260626`, `simulation_seed=42`
- opponent_sample: `Vivi Ornitier #99 (real)`, `Sisay, Weatherlight Captain #61 (real)`, `Winota, Joiner of Forces #39 (real)`
- games_per_opponent: `3`

## Decision

Keep `deck_607` as the current best Lorehold base. Both bridge attempts that imported v7 engine pieces reduced battle output under the same gate. Do not promote either bridge candidate to PostgreSQL or Hermes as a learned final deck.

## Evidence

| Candidate | Change | Result | Winota | Decision |
| --- | --- | ---: | ---: | --- |
| `deck_607` | baseline | `5W/4L/0S`, WR `55.56%` | `2W/1L` | keep |
| `candidate_607_bridge_v1` | add `Aetherflux Reservoir`, `Birgi`, `Enlightened Tutor`, `Gamble`, `Past in Flames`, `Storm-Kiln Artist`; remove `Bender's Waterskin`, `Emeria's Call`, `Library of Leng`, `Molecule Man`, `The Scarlet Witch`, `Tragic Arrogance` | `1W/8L/0S`, WR `11.11%` | `0W/3L` | reject |
| `candidate_607_bridge_v2` | add `Aetherflux Reservoir`, `Storm-Kiln Artist`; remove `Molecule Man`, `The Scarlet Witch` | `2W/7L/0S`, WR `22.22%` | `0W/3L` | reject |

## Why v2 Still Failed

The minimal v2 improved over v1 but still lost the properties that made `deck_607` win the finalist gate:

| Metric | `deck_607` | `candidate_607_bridge_v2` |
| --- | ---: | ---: |
| Wins | `5/9` | `2/9` |
| Avg win turn | `13.60` | `19.00` |
| Lorehold cost-paid events | `100` | `82` |
| Lorehold spell-cast events | `81` | `71` |
| Miracle games | `7/9` | `5/9` |
| Topdeck-manipulation games | `4/9` | `3/9` |
| Winota matchup | `2W/1L` | `0W/3L` |

The imported cards looked structurally correct, but the runtime evidence says they did not convert into the actual 607 battle plan. `Aetherflux Reservoir` and `Storm-Kiln Artist` raised theoretical finisher/ramp density, yet the deck cast fewer Lorehold-discounted spells, used topdeck setup less often, won later, and failed the Winota pressure test.

## Operating Rule From This Iteration

Treat `deck_607` as the protected baseline. Future changes should be one-card ablations or tightly related family swaps, accepted only if they at least tie `deck_607` on the same real-opponent gate and do not regress the Winota matchup.

Generated artifacts:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_candidate_20260626_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_candidate_20260626_v2.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v2.json`

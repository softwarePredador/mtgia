# Lorehold Equal Battle Gate

- generated_at: `2026-06-26T20:42:38Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- game_timeout_seconds: `30.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_flashback_equal_gate_20260626_203511_flashback_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 5 | 4 | 0 | 55.56% | 17.60 | 8 | 3 | recursion_role, tutor_role |
| 2 |  | Lorehold 607 Flashback equal gate (`candidate_607_flashback_equal_gate`) | optimizer-equal-gate | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 4 | 1 | none |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `5W/4L/0S`, WR `55.56%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 1 | 0 | 66.67% | 15.50 | elimination=2 |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 21.50 | elimination=2 |

**Strategic event counts:** lorehold_cost_paid=122, lorehold_spell_cast=98, miracle_cast=25, topdeck_manipulation_activated=9

### 2. Lorehold 607 Flashback equal gate (`candidate_607_flashback_equal_gate`)

- objective: not available in structural matrix
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=72, lorehold_spell_cast=60, miracle_cast=8, topdeck_manipulation_activated=4


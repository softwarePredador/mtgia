# Global Commander Strategy Matrix

- Generated at: `2026-07-06T12:20:36.171777+00:00`
- Status: `pass`
- Contract: `docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`
- Deck rows considered: `17`
- Commanders considered: `6`
- Ready decks: `17`
- Product ready decks: `0`
- Blocked product decks: `0`

## Status Counts

| Status | Commanders |
| --- | ---: |
| `ready_for_strategy_matrix` | 2 |
| `structure_ready_source_missing` | 4 |

## Commander Matrix

| Commander | Status | Ready | Product Ready | Lab Ready | Source Lanes | Blocked Product | Next Gate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `Lorehold, the Historian` | `ready_for_strategy_matrix` | 12 | 0 | 12 | 1 | 0 | `run_commander_specific_strategy_matrix_before_battle_gate` |
| `Kaalia of the Vast` | `ready_for_strategy_matrix` | 1 | 0 | 1 | 1 | 0 | `run_commander_specific_strategy_matrix_before_battle_gate` |
| `Kefka, Court Mage // Kefka, Ruler of Ruin` | `structure_ready_source_missing` | 1 | 0 | 1 | 0 | 0 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |
| `Sauron, the Dark Lord` | `structure_ready_source_missing` | 1 | 0 | 1 | 0 | 0 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |
| `Valgavoth, Harrower of Souls` | `structure_ready_source_missing` | 1 | 0 | 1 | 0 | 0 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |
| `Y'shtola, Night's Blessed` | `structure_ready_source_missing` | 1 | 0 | 1 | 0 | 0 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |

## Blocked Product Decks

| Commander | Deck | Quantity | Commanders | Issues |
| --- | --- | ---: | ---: | --- |
| none | none | 0 | 0 | none |

## Method Notes

- PostgreSQL product decks and registered variants remain product truth.
- Hermes rows are included only as lab/cache candidates.
- This matrix does not run battles, generate cards, or promote any deck.
- A commander can move to battle only after a commander-specific strategy matrix and equal-gate evidence.

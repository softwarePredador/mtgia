# Global Commander Strategy Matrix

- Generated at: `2026-07-01T00:52:25.785210+00:00`
- Status: `pass`
- Contract: `docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`
- Deck rows considered: `46`
- Commanders considered: `10`
- Ready decks: `36`
- Product ready decks: `19`
- Blocked product decks: `8`

## Status Counts

| Status | Commanders |
| --- | ---: |
| `blocked_before_global_promotion` | 2 |
| `ready_for_strategy_matrix` | 4 |
| `structure_ready_source_missing` | 4 |

## Commander Matrix

| Commander | Status | Ready | Product Ready | Lab Ready | Source Lanes | Blocked Product | Next Gate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `Lorehold, the Historian` | `ready_for_strategy_matrix` | 23 | 11 | 12 | 6 | 1 | `run_commander_specific_strategy_matrix_before_battle_gate` |
| `Kaalia of the Vast` | `ready_for_strategy_matrix` | 3 | 2 | 1 | 1 | 0 | `run_commander_specific_strategy_matrix_before_battle_gate` |
| `Kefka, Court Mage // Kefka, Ruler of Ruin` | `ready_for_strategy_matrix` | 2 | 1 | 1 | 1 | 0 | `run_commander_specific_strategy_matrix_before_battle_gate` |
| `Y'shtola, Night's Blessed` | `ready_for_strategy_matrix` | 2 | 1 | 1 | 1 | 0 | `run_commander_specific_strategy_matrix_before_battle_gate` |
| `Sauron, the Dark Lord` | `structure_ready_source_missing` | 2 | 1 | 1 | 0 | 0 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |
| `Valgavoth, Harrower of Souls` | `structure_ready_source_missing` | 2 | 1 | 1 | 0 | 0 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |
| `Animar, Soul of Elements` | `structure_ready_source_missing` | 1 | 1 | 0 | 0 | 0 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |
| `Jin-Gitaxias // The Great Synthesis` | `structure_ready_source_missing` | 1 | 1 | 0 | 0 | 5 | `add_reference_profile_or_learned_source_lane_before_strategy_matrix` |
| `Auntie Ool, Cursewretch` | `blocked_before_global_promotion` | 0 | 0 | 0 | 0 | 1 | `repair_or_exclude_product_deck_before_strategy_matrix` |
| `Jin-Gitaxias, Core Augur` | `blocked_before_global_promotion` | 0 | 0 | 0 | 0 | 1 | `repair_or_exclude_product_deck_before_strategy_matrix` |

## Blocked Product Decks

| Commander | Deck | Quantity | Commanders | Issues |
| --- | --- | ---: | ---: | --- |
| `Lorehold, the Historian` | `lorehold` (`b17e9d71-8b51-48ad-833b-f17190a347a3`) | 2 | 1 | `quantity_not_100` |
| `Jin-Gitaxias // The Great Synthesis` | `hfgh` (`93e0e6e1-e351-4db8-9715-6c6d1fdf5672`) | 1 | 1 | `quantity_not_100` |
| `Jin-Gitaxias // The Great Synthesis` | `jin` (`8ff632c1-2499-436f-89a4-2802da1e605f`) | 1 | 1 | `quantity_not_100` |
| `Jin-Gitaxias // The Great Synthesis` | `Jin` (`0b163477-2e8a-488a-8883-774fcd05281f`) | 1 | 1 | `quantity_not_100` |
| `Jin-Gitaxias // The Great Synthesis` | `Jin` (`536b9e7d-69c3-4518-ab92-fe83352a0b4e`) | 1 | 1 | `quantity_not_100` |
| `Jin-Gitaxias // The Great Synthesis` | `jjjj` (`59bbcd4a-f8a4-46b2-944d-0896d83a6f7c`) | 1 | 1 | `quantity_not_100` |
| `Auntie Ool, Cursewretch` | `goblins` (`8c22deb9-80bd-489f-8e87-1344eabac698`) | 100 | 1 | `illegal_card_rows` |
| `Jin-Gitaxias, Core Augur` | `jin2` (`2fb14ec7-7a00-4ad7-a7e9-5a5a85d7f9b2`) | 1 | 1 | `quantity_not_100` |

## Method Notes

- PostgreSQL product decks and registered variants remain product truth.
- Hermes rows are included only as lab/cache candidates.
- This matrix does not run battles, generate cards, or promote any deck.
- A commander can move to battle only after a commander-specific strategy matrix and equal-gate evidence.

# Global Commander Core Repair Hypotheses

- Generated at: `2026-07-05T19:56:20.615205+00:00`
- Status: `pass`
- Hypotheses: `11`
- Mutation allowed: `false`
- Battle or optimization performed: `False`

## Status Counts

| Status | Count |
| --- | ---: |
| `needs_commander_win_plan_source_lane` | 1 |
| `needs_mana_base_profile_before_named_cards` | 9 |
| `review_candidate_pool_ready_color_identity_required` | 1 |

## Hypothesis Queue

| Deck | Commander | Role | Missing | Status | Repair Classes | Review Candidates | Cut Pressure |
| --- | --- | --- | ---: | --- | --- | --- | --- |
| `VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (612)` | `Lorehold, the Historian` | `land` | 7 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | engine=23, ramp=8, board_wipe=7, wincon=4 |
| `VARIANT Kaalia Variant 01 - Rafael Paste 2026-06-24 (619)` | `Kaalia of the Vast` | `removal` | 5 | `review_candidate_pool_ready_color_identity_required` | `cheap_targeted_interaction`, `flexible_permanent_answer` | Swords to Plowshares(W), Path to Exile(W), Bojuka Bog(B), Feed the Swarm(B), Deadly Rollick(B) | engine=11, tutor=8, ramp=7 |
| `VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (616)` | `Lorehold, the Historian` | `land` | 5 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | protection=7, engine=6, board_wipe=5, draw=3, removal=2 |
| `VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (609)` | `Lorehold, the Historian` | `land` | 4 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | draw=10, protection=4, board_wipe=3, engine=3, tutor=3 |
| `VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (610)` | `Lorehold, the Historian` | `land` | 4 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | recursion=9, engine=7, ramp=6, board_wipe=2 |
| `VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (608)` | `Lorehold, the Historian` | `land` | 3 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | draw=19, board_wipe=18, tutor=17, recursion=15, ramp=5 |
| `Runtime Lorehold Learned 19e93de3cca (6)` | `Lorehold, the Historian` | `wincon` | 2 | `needs_commander_win_plan_source_lane` | `commander_plan_finisher`, `deterministic_combo_or_closer` | - | ramp=35, protection=9, draw=6, engine=2, tutor=1 |
| `VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (613)` | `Lorehold, the Historian` | `land` | 2 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | engine=13, draw=12, protection=6, ramp=4, board_wipe=3 |
| `VARIANT Y'shtola Variant 01 - Rafael Paste 2026-06-24 (621)` | `Y'shtola, Night's Blessed` | `land` | 2 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | engine=7, board_wipe=1 |
| `Runtime Lorehold Learned 19e93de3cca (6)` | `Lorehold, the Historian` | `land` | 1 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | ramp=35, protection=9, draw=6, engine=2, tutor=1 |
| `VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (614)` | `Lorehold, the Historian` | `land` | 1 | `needs_mana_base_profile_before_named_cards` | `basic_or_color_source_floor`, `untapped_fixing_land`, `utility_land_only_after_color_floor` | - | engine=7, ramp=6, protection=5, draw=4, board_wipe=2 |

## Method Notes

- This report is read-only and never materializes deck changes.
- Format staples are review candidates only; color identity, legality, commander fit, same-lane cut, strategy matrix, and battle gates remain required.
- Land gaps require a mana-base profile before named cards.
- Wincon gaps require commander win-plan/source-lane proof before named cards.
- Deck 607 remains a regression benchmark, not the global objective.

# Global Commander Core Role Audit

- Generated at: `2026-07-06T12:20:29.670924+00:00`
- Status: `pass`
- Decks audited: `17`
- Commanders audited: `6`
- PostgreSQL skipped: `True`
- Battle or optimization performed: `False`

## Status Counts

| Status | Decks |
| --- | ---: |
| `core_review_ready` | 8 |
| `core_role_gap` | 9 |

## Core Repair Queue

| Deck | Commander | First Action | Missing Slots | Excess Review | Unknown |
| --- | --- | --- | --- | --- | ---: |
| `Runtime Lorehold Learned 19e93de3cca (6)` | `Lorehold, the Historian` | `fill_critical_role_floor` | land=1, wincon=2 | ramp=35, draw=6, protection=9, tutor=1, engine=2 | 0 |
| `VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (606)` | `Lorehold, the Historian` | `review_role_extremes` | - | ramp=4, draw=4, protection=2, engine=2 | 0 |
| `VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (607)` | `Lorehold, the Historian` | `review_role_extremes` | - | ramp=4, draw=5, removal=1, board_wipe=5, protection=8 | 0 |
| `VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (608)` | `Lorehold, the Historian` | `fill_critical_role_floor` | land=3 | ramp=5, draw=19, board_wipe=18, recursion=15, tutor=17, engine=1 | 0 |
| `VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (609)` | `Lorehold, the Historian` | `fill_critical_role_floor` | land=4 | draw=10, removal=1, board_wipe=3, protection=4, tutor=3, engine=3 | 0 |
| `VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (610)` | `Lorehold, the Historian` | `fill_critical_role_floor` | land=4 | ramp=6, board_wipe=2, recursion=9, engine=7 | 0 |
| `VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (611)` | `Lorehold, the Historian` | `review_role_extremes` | - | ramp=6, draw=13, board_wipe=4, recursion=1, engine=13 | 0 |
| `VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (612)` | `Lorehold, the Historian` | `review_role_extremes` | - | ramp=5, board_wipe=3, engine=16 | 0 |
| `VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (613)` | `Lorehold, the Historian` | `fill_critical_role_floor` | land=2 | ramp=4, draw=12, board_wipe=3, protection=6, engine=13 | 0 |
| `VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (614)` | `Lorehold, the Historian` | `fill_critical_role_floor` | land=1 | ramp=6, draw=4, board_wipe=2, protection=5, wincon=1, engine=7 | 0 |
| `VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (615)` | `Lorehold, the Historian` | `review_role_extremes` | - | draw=5, board_wipe=2, protection=6, engine=8 | 0 |
| `VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (616)` | `Lorehold, the Historian` | `fill_critical_role_floor` | land=5 | draw=3, removal=2, board_wipe=5, protection=7, wincon=2, engine=6 | 2 |
| `VARIANT Kefka Variant 01 - Rafael Paste 2026-06-24 (617)` | `Kefka, Court Mage // Kefka, Ruler of Ruin` | `review_role_extremes` | - | draw=9, board_wipe=3, wincon=1, engine=28 | 0 |
| `VARIANT Valgavoth Variant 01 - Rafael Paste 2026-06-24 (618)` | `Valgavoth, Harrower of Souls` | `review_role_extremes` | - | board_wipe=3, engine=17 | 1 |
| `VARIANT Kaalia Variant 01 - Rafael Paste 2026-06-24 (619)` | `Kaalia of the Vast` | `fill_critical_role_floor` | removal=5 | ramp=7, tutor=8, engine=11 | 0 |
| `VARIANT Sauron Variant 01 - Rafael Paste 2026-06-24 (620)` | `Sauron, the Dark Lord` | `review_role_extremes` | - | ramp=3, board_wipe=2, recursion=2, engine=7 | 0 |
| `VARIANT Y'shtola Variant 01 - Rafael Paste 2026-06-24 (621)` | `Y'shtola, Night's Blessed` | `fill_critical_role_floor` | land=2 | board_wipe=1, engine=7 | 0 |

## Deck Core Rows

| Deck | Commander | Scope | Core Status | Lands | Ramp | Draw | Removal | Wipes | Protection | Wincon | Unknown | Next Gate |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `Runtime Lorehold Learned 19e93de3cca (6)` | `Lorehold, the Historian` | `hermes_lorehold_baseline` | `core_role_gap` | 33 | 51 | 22 | 8 | 4 | 19 | 1 | 0 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (606)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_review_ready` | 39 | 20 | 20 | 10 | 5 | 12 | 8 | 0 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (607)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_review_ready` | 34 | 20 | 21 | 15 | 10 | 18 | 11 | 0 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (608)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_role_gap` | 31 | 21 | 35 | 7 | 23 | 7 | 5 | 0 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (609)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_role_gap` | 30 | 15 | 26 | 15 | 8 | 14 | 9 | 0 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (610)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_role_gap` | 30 | 22 | 13 | 9 | 7 | 8 | 6 | 0 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (611)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_review_ready` | 34 | 22 | 29 | 12 | 9 | 6 | 14 | 0 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (612)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_review_ready` | 34 | 21 | 11 | 10 | 8 | 10 | 14 | 0 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (613)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_role_gap` | 32 | 20 | 28 | 10 | 8 | 16 | 10 | 0 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (614)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_role_gap` | 33 | 22 | 20 | 7 | 7 | 15 | 15 | 0 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (615)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_review_ready` | 34 | 16 | 21 | 13 | 7 | 16 | 14 | 0 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (616)` | `Lorehold, the Historian` | `hermes_lorehold_variant` | `core_role_gap` | 29 | 9 | 19 | 16 | 10 | 17 | 16 | 2 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Kefka Variant 01 - Rafael Paste 2026-06-24 (617)` | `Kefka, Court Mage // Kefka, Ruler of Ruin` | `hermes_registered_variant` | `core_review_ready` | 36 | 9 | 25 | 11 | 8 | 6 | 15 | 0 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Valgavoth Variant 01 - Rafael Paste 2026-06-24 (618)` | `Valgavoth, Harrower of Souls` | `hermes_registered_variant` | `core_review_ready` | 37 | 9 | 10 | 11 | 8 | 7 | 13 | 1 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Kaalia Variant 01 - Rafael Paste 2026-06-24 (619)` | `Kaalia of the Vast` | `hermes_registered_variant` | `core_role_gap` | 34 | 23 | 13 | 1 | 2 | 9 | 6 | 0 | `repair_core_role_floor_before_strategy_matrix` |
| `VARIANT Sauron Variant 01 - Rafael Paste 2026-06-24 (620)` | `Sauron, the Dark Lord` | `hermes_registered_variant` | `core_review_ready` | 36 | 19 | 11 | 12 | 7 | 5 | 3 | 0 | `review_role_extremes_before_strategy_matrix` |
| `VARIANT Y'shtola Variant 01 - Rafael Paste 2026-06-24 (621)` | `Y'shtola, Night's Blessed` | `hermes_registered_variant` | `core_role_gap` | 32 | 16 | 16 | 9 | 6 | 9 | 11 | 0 | `repair_core_role_floor_before_strategy_matrix` |

## Method Notes

- This report is read-only and does not promote decks.
- Role bands are generic Commander floors; commander-specific profiles may adjust them later.
- Structured tags win; Oracle text inference is diagnostic fallback for untagged lab decks.
- Core repair plans are not mutation permits; missing critical floors come before source lanes, while excess roles are review signals.
- Deck 607 is treated as a benchmark/regression deck, not a global template.

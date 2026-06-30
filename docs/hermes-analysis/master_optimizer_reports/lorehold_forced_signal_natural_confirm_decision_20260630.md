# Lorehold Forced-Signal Natural Confirmation Decision - 2026-06-30

Status: `no_natural_promotion_keep_607`

Scope:

- Baseline: protected `deck_607`.
- Forced access mode: `none` natural confirmation.
- Tested packages: `storm_kiln_artist_cut_arcane_signet`, `valakut_hand_filter_cut_big_score`, and `enlightened_access_benchmark_cut_land_tax`.
- Opponents: `8` real opponent decks, `3` games each per package.
- Seeds: opponent `20260629`, simulation `20260630`.
- Source wrapper: `docs/hermes-analysis/master_optimizer_reports/lorehold_forced_signal_natural_confirm_20260630_after_607_fix_20260630_044907.json`.

## Summary

- Package status counts: `{"gated": 3}`
- Package decision counts: `{"reject_or_rework": 2, "tie_watch_strategy_regression": 1}`
- Deck change: `false`; `deck_607` remains protected.

## Results

| Package | Add | Cut | Baseline | Candidate | Delta | Added-card evidence | Decision |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| `storm_kiln_artist_cut_arcane_signet` | Storm-Kiln Artist | Arcane Signet | 11W/12L/1S | 9W/15L/0S | -8.33 pp | Storm-Kiln Artist use=3 accessed=6 near=5 used_record=1W/1L/0S | `reject_or_rework` |
| `valakut_hand_filter_cut_big_score` | Valakut Awakening // Valakut Stoneforge | Big Score | 11W/12L/1S | 9W/15L/0S | -8.33 pp | Valakut Awakening // Valakut Stoneforge use=12 accessed=4 near=5 used_record=3W/1L/0S | `reject_or_rework` |
| `enlightened_access_benchmark_cut_land_tax` | Enlightened Tutor | Land Tax | 11W/12L/1S | 11W/13L/0S | +0.00 pp | Enlightened Tutor use=18 accessed=7 near=11 used_record=3W/4L/0S | `tie_watch_strategy_regression` |

## Decision

- `storm_kiln_artist_cut_arcane_signet`: reject. Forced signal did not survive natural access; candidate lost `9W/15L/0S` vs baseline `11W/12L/1S`.
- `valakut_hand_filter_cut_big_score`: reject. Forced signal did not survive natural access; candidate lost `9W/15L/0S` vs baseline `11W/12L/1S`.
- `enlightened_access_benchmark_cut_land_tax`: do not promote. It tied total wins at `11W`, but loses the stall tie-break (`11W/13L/0S` vs `11W/12L/1S`) and carries strategy-regression watch.
- Keep `Land Tax`, `Arcane Signet`, and `Big Score` in protected `deck_607` until a different same-lane or package-level hypothesis beats the baseline naturally.

## Next Step

Return to failure-targeted synthesis instead of retesting these exact swaps. The next useful work is either a new access package that does not cut `Land Tax`, or a runtime/play-heuristic review for `Volcanic Vision` before any recursion retest.

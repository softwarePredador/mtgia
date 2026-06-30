# Lorehold Forced-Exposure Probe Decision - 2026-06-30

Status: `diagnostic_complete_no_deck_promotion`

Scope:

- Baseline: protected `deck_607`.
- Forced access mode: `opening_hand`.
- Opponents: `8` real opponent decks, `3` games each per package.
- Seeds: opponent `20260629`, simulation `20260630`.
- Purpose: prove whether low-exposure/prior-negative cards do anything when actually accessed. This is not a natural promotion gate.
- Source wrapper: `docs/hermes-analysis/master_optimizer_reports/lorehold_forced_exposure_probe_20260630_after_607_fix_20260630_043721.json`.

## Summary

- Package status counts: `{"gated": 11}`
- Package decision counts: `{"forced_access_inconclusive_low_exposure": 1, "forced_access_no_lift_reject_or_rework": 1, "forced_access_signal_requires_natural_confirmation": 6, "forced_access_tie_requires_natural_confirmation": 3}`
- Real deck change: `false`; forced-access signal requires natural confirmation before any deck replacement.

## Results

| Package | Add | Cut | Baseline | Candidate | Delta | Added-card evidence | Decision |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| `austere_command_wipe_over_emeria_tradeoff` | Austere Command | Emeria's Call // Emeria, Shattered Skyclave | 5W/19L/0S | 5W/19L/0S | +0.00 pp | Austere Command use=14 accessed=24 used_record=3W/2L/0S | `forced_access_tie_requires_natural_confirmation` |
| `boros_charm_pressure_cut_avatar_wrath` | Boros Charm | Avatar's Wrath | 5W/19L/0S | 6W/18L/0S | +4.17 pp | Boros Charm use=16 accessed=24 used_record=4W/4L/0S | `forced_access_signal_requires_natural_confirmation` |
| `enlightened_access_benchmark_cut_land_tax` | Enlightened Tutor | Land Tax | 9W/15L/0S | 11W/13L/0S | +8.33 pp | Enlightened Tutor use=70 accessed=24 used_record=11W/12L/0S | `forced_access_signal_requires_natural_confirmation` |
| `gamble_access_benchmark_cut_land_tax` | Gamble | Land Tax | 9W/15L/0S | 7W/17L/0S | -8.33 pp | Gamble use=68 accessed=24 used_record=7W/14L/0S | `forced_access_no_lift_reject_or_rework` |
| `plateau_timing_upgrade_cut_radiant_summit` | Plateau | Radiant Summit | 9W/14L/1S | 10W/14L/0S | +4.17 pp | Plateau use=24 accessed=24 used_record=10W/14L/0S | `forced_access_signal_requires_natural_confirmation` |
| `plateau_timing_upgrade_cut_turbulent_steppe` | Plateau | Turbulent Steppe | 11W/13L/0S | 11W/13L/0S | +0.00 pp | Plateau use=24 accessed=24 used_record=11W/13L/0S | `forced_access_tie_requires_natural_confirmation` |
| `seething_song_cut_fellwar_stone` | Seething Song | Fellwar Stone | 9W/15L/0S | 10W/14L/0S | +4.17 pp | Seething Song use=35 accessed=24 used_record=10W/10L/0S | `forced_access_signal_requires_natural_confirmation` |
| `storm_kiln_artist_cut_arcane_signet` | Storm-Kiln Artist | Arcane Signet | 7W/17L/0S | 11W/13L/0S | +16.66 pp | Storm-Kiln Artist use=12 accessed=24 used_record=7W/3L/0S | `forced_access_signal_requires_natural_confirmation` |
| `valakut_hand_filter_cut_big_score` | Valakut Awakening // Valakut Stoneforge | Big Score | 5W/19L/0S | 8W/16L/0S | +12.50 pp | Valakut Awakening // Valakut Stoneforge use=45 accessed=24 used_record=8W/9L/0S | `forced_access_signal_requires_natural_confirmation` |
| `volcanic_recursion_cut_pinnacle` | Volcanic Vision | Pinnacle Monk // Mystic Peak | 6W/18L/0S | 5W/19L/0S | -4.17 pp | Volcanic Vision use=0 accessed=24 used_record=0W/0L/0S | `forced_access_inconclusive_low_exposure` |
| `wheel_hand_filter_cut_big_score` | Wheel of Fortune | Big Score | 5W/19L/0S | 5W/19L/0S | +0.00 pp | Wheel of Fortune use=17 accessed=24 used_record=3W/3L/0S | `forced_access_tie_requires_natural_confirmation` |

## Decision

- Do not change `deck_607` from this diagnostic alone.
- Natural confirmation queue: `austere_command_wipe_over_emeria_tradeoff, boros_charm_pressure_cut_avatar_wrath, enlightened_access_benchmark_cut_land_tax, plateau_timing_upgrade_cut_radiant_summit, plateau_timing_upgrade_cut_turbulent_steppe, seething_song_cut_fellwar_stone, storm_kiln_artist_cut_arcane_signet, valakut_hand_filter_cut_big_score, wheel_hand_filter_cut_big_score`.
- Rejected from this diagnostic: `gamble_access_benchmark_cut_land_tax`.
- Inconclusive/runtime-play-heuristic review: `volcanic_recursion_cut_pinnacle`.
- Highest forced signals by delta were `storm_kiln_artist_cut_arcane_signet` (+16.66 pp), `valakut_hand_filter_cut_big_score` (+12.50 pp), and `enlightened_access_benchmark_cut_land_tax` (+8.33 pp). These still need natural gates because forced opening hand overstates access.
- `Volcanic Vision` was accessed but effectively not used; inspect play heuristic/runtime/cost timing before retesting it.

## Next Step

Run natural confirmation only for the forced-signal packages, starting with the largest signal and smallest strategic-regression risk. Keep `Gamble` and `Volcanic Vision` out of the next promotion path unless a separate model change explains the failure.

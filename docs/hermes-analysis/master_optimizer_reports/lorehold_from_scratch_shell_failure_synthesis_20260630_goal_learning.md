# Lorehold From-Scratch Shell Failure Synthesis

- Generated at: `2026-06-30T23:15:14Z`
- Protected baseline: `deck_607`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Recommended next action: `mine_closing_window_trace_before_next_shell`
- Can run next battle gate: `false`
- Tested shells: `challenger_lorehold_access_density_control_v1, challenger_lorehold_miracle_pressure_conversion_v1, challenger_lorehold_recursion_discard_engine_v1, challenger_lorehold_recursion_discard_pressure_repair_v1`
- Gate rows: `5`
- Status counts: `{"forced_access_rejected": 1, "natural_rejected": 4}`
- Failure mode counts: `{"forced_access_no_conversion": 1, "lorehold_spell_floor_regressed": 2, "losses_above_protected_607": 5, "miracle_floor_regressed": 3, "new_package_cards_not_observed": 1, "package_lanes_overfilled": 4, "positive_squee_telemetry_not_converting": 3, "squee_graveyard_entry_not_converting": 1, "topdeck_floor_regressed": 2, "upkeep_rummage_floor_regressed": 5, "wins_below_protected_607": 5}`

## Blockers

- all current from-scratch shells are below protected 607
- forced tutor/access evidence still failed to convert into wins
- broad shell changes overfill package lanes or regress miracle/topdeck cadence
- another battle gate without a predeclared trace target would repeat prior work

## Gate Rows

| Candidate | Gate | Forced | Record | 607 Record | Delta W | Failures |
| --- | --- | --- | --- | --- | ---: | --- |
| challenger_lorehold_access_density_control_v1 | forced_access_diagnostic | opening_hand | 0/4/0 | 1/3/0 | -1 | forced_access_no_conversion, lorehold_spell_floor_regressed, losses_above_protected_607, miracle_floor_regressed, package_lanes_overfilled, positive_squee_telemetry_not_converting, upkeep_rummage_floor_regressed, wins_below_protected_607 |
| challenger_lorehold_access_density_control_v1 | natural_smoke_gate | none | 0/4/0 | 1/3/0 | -1 | losses_above_protected_607, miracle_floor_regressed, package_lanes_overfilled, topdeck_floor_regressed, upkeep_rummage_floor_regressed, wins_below_protected_607 |
| challenger_lorehold_miracle_pressure_conversion_v1 | natural_smoke_gate | none | 0/4/0 | 1/3/0 | -1 | losses_above_protected_607, miracle_floor_regressed, new_package_cards_not_observed, squee_graveyard_entry_not_converting, upkeep_rummage_floor_regressed, wins_below_protected_607 |
| challenger_lorehold_recursion_discard_engine_v1 | natural_gate | none | 4/20/0 | 6/18/0 | -2 | losses_above_protected_607, package_lanes_overfilled, positive_squee_telemetry_not_converting, upkeep_rummage_floor_regressed, wins_below_protected_607 |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | natural_gate | none | 3/21/0 | 6/18/0 | -3 | lorehold_spell_floor_regressed, losses_above_protected_607, package_lanes_overfilled, positive_squee_telemetry_not_converting, topdeck_floor_regressed, upkeep_rummage_floor_regressed, wins_below_protected_607 |

## Learning Constraints

- `protected_607_remains_baseline`: Do not replace deck_607 unless a natural equal gate ties or beats it.
- `forced_access_is_diagnostic_only`: Forced access can prove a card was seen/used, but cannot promote a deck.
- `preserve_miracle_topdeck_floor`: Next shell must predeclare miracle/topdeck targets and avoid regressing the 607 cadence.
- `avoid_overfilled_access_recursion_shells`: Do not add tutors, recursion, hand filter, and conversion density at once without lane balance.
- `require_conversion_window_trace`: Next candidate must target a named closing-window failure and prove the added cards were naturally accessed or exercised by focused test.

## Required Before Next Shell

- mine 607 win traces versus candidate loss traces for closing-window sequence differences
- name the exact lane or pressure failure being repaired
- predeclare target metrics for miracle games, topdeck manipulation games, and conversion-card access
- keep forced-access diagnostics separate from natural promotion evidence
- block exact shell reruns unless the deck list or runtime model materially changes

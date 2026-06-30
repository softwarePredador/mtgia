# Lorehold Electro Over Waterskin Decision - 2026-06-30

Status: `rejected_smoke`

Scope:

- Candidate: `electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin`
- Add: `Electro, Assaulting Battery`
- Cut: `Bender's Waterskin`
- Baseline: protected `deck_607`
- Gate: natural, no forced access, 8 real opponents, 3 games per opponent
- Seeds: opponent `20260629`, simulation `20260630`

Operational correction before trusting this gate:

- `lorehold_profiled_cut_benchmark_generator.py` now uses deck `607` as the default current shell instead of historical deck `6`.
- `lorehold_synergy_package_gate.py` now applies package swaps to `--baseline-deck-id`, default `607`.
- `lorehold_variant_battle_gate.py` now accepts `--candidate-deck-id`; the package gate passes `607`, so the candidate battle loads the modified deck `607` from the copied candidate DB.
- The earlier `lorehold_electro_waterskin_gate_20260630_20260630_042012` run is not valid deck evidence because it loaded the candidate from deck `6`. It must not be used for promotion.

Corrected gate result:

| Deck | Wins | Losses | Stalls | Win rate | Winota |
| --- | ---: | ---: | ---: | ---: | --- |
| `deck_607` | 11 | 12 | 1 | 45.83% | 2W/1L/0S |
| `+Electro; -Bender's Waterskin` | 6 | 18 | 0 | 25.00% | 0W/3L/0S |

Card-use evidence:

- `Electro, Assaulting Battery`: 9 recorded use events; candidate added card status `candidate_added_cards_used`.
- `Bender's Waterskin`: 8 recorded baseline use events.

Strategic deltas versus `deck_607`:

- `lorehold_spell_cast`: -65
- `miracle_cast`: -23
- `lorehold_cost_paid`: -37
- `lorehold_upkeep_rummage`: -36
- `discard_to_top_replacement`: -4
- `topdeck_manipulation_activated`: -6
- `static_cost_reduction_total`: -13

Decision:

Reject this exact same-lane ramp benchmark. `Electro` is legal and battle-ready enough to test, but it does not improve the current Lorehold shell. The replacement reduced total wins, collapsed the Winota pressure slice, and lowered the key miracle/topdeck/spell-volume metrics. `Bender's Waterskin` remains protected until a same-function replacement beats `deck_607`.

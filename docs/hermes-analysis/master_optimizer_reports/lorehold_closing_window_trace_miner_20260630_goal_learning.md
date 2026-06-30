# Lorehold Closing Window Trace Miner

- Generated at: `2026-06-30T23:24:28Z`
- Protected baseline: `deck_607`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Recommended next action: `build_trace_targeted_micro_package_from_closing_window`
- Comparison count: `13`
- Ready micro-package hypotheses: `3`
- Average 607 turn advantage: `10.15`
- Gap counts: `{"607_mana_timing_anchor_deficit": 9, "approach_conversion_missing": 7, "candidate_died_before_closing_window": 13, "candidate_lost_multiple_turns_before_607_finish": 13, "lorehold_spell_volume_deficit": 13, "miracle_cast_deficit": 13, "static_cost_reduction_deficit": 9, "topdeck_activation_deficit": 9, "topdeck_engine_card_deficit": 11, "upkeep_rummage_deficit": 9}`

## Top Strategic Deficits

- `lorehold_cost_paid`: `153`
- `lorehold_spell_cast`: `134`
- `miracle_cast`: `71`
- `lorehold_upkeep_rummage`: `63`
- `topdeck_manipulation_activated`: `41`
- `static_cost_reduction_total`: `37`

## Top Anchor Card Deficits

- `topdeck_manipulation_activated:Sensei's Divining Top`: `29`
- `cost_paid:Lorehold, the Historian`: `17`
- `cost_paid:Sensei's Divining Top`: `15`
- `spell_cast:Sensei's Divining Top`: `15`
- `spell_resolved:Sensei's Divining Top`: `15`
- `topdeck_manipulation_activated:Scroll Rack`: `14`
- `spell_resolved:Approach of the Second Sun`: `13`
- `cost_paid:Victory Chimes`: `8`
- `spell_cast:Victory Chimes`: `7`
- `cost_paid:Approach of the Second Sun`: `7`
- `spell_cast:Approach of the Second Sun`: `7`
- `spell_resolved:Mizzix's Mastery`: `6`
- `miracle_cast:Approach of the Second Sun`: `5`
- `cost_paid:Bender's Waterskin`: `4`
- `cost_paid:Scroll Rack`: `4`
- `miracle_cast:Jeska's Will`: `4`

## Hypotheses

### preserve_topdeck_miracle_floor_micro_package

- Status: `ready_for_micro_package_model`
- Target gaps: `miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit`
- Requirement: do not cut Sensei's Divining Top, Scroll Rack, Bender's Waterskin, or Victory Chimes
- Requirement: predeclare miracle_cast and topdeck_manipulation_activated targets before gate
- Requirement: candidate must not overfill hand_filter plus graveyard_recursion plus conversion lanes together

### pressure_survival_without_engine_cuts

- Status: `ready_for_micro_package_model`
- Target gaps: `candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish`
- Requirement: repair early pressure only with cards that preserve the 607 topdeck/miracle floor
- Requirement: Winota/Sisay/Vivi losses must be evaluated by same opponent slot before confirmation

### approach_big_spell_conversion_preservation

- Status: `ready_for_micro_package_model`
- Target gaps: `approach_conversion_missing, lorehold_spell_volume_deficit`
- Requirement: protect Approach of the Second Sun, Mizzix's Mastery, and high-impact spell volume
- Requirement: do not treat tutor access as sufficient unless it restores spell volume and finish conversion

## Comparisons

| Candidate | Opponent | Game | 607 | Candidate | Turn delta | Gaps |
| --- | --- | ---: | --- | --- | ---: | --- |
| challenger_lorehold_access_density_control_v1 | Sisay, Weatherlight Captain #61 (real) | 0 | elimination T15 | life_zero|found=False|countered=0 T6 | 9 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Sisay, Weatherlight Captain #61 (real) | 0 | elimination T15 | life_zero|found=False|countered=0 T10 | 5 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Aang, at the Crossroads #106 (real) | 1 | approach T15 | life_zero|found=False|countered=0 T8 | 7 | approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Aang, at the Crossroads #106 (real) | 2 | approach T12 | life_zero|found=False|countered=0 T9 | 3 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Rograkh, Son of Rohgahh #62 (real) | 0 | elimination T11 | life_zero|found=False|countered=0 T7 | 4 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Vivi Ornitier #99 (real) | 0 | approach T34 | life_zero|found=False|countered=0 T6 | 28 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T7 | 12 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Winota, Joiner of Forces #39 (real) | 1 | elimination T18 | life_zero|found=False|countered=0 T12 | 6 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Aang, at the Crossroads #106 (real) | 1 | approach T15 | life_zero|found=False|countered=0 T9 | 6 | approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Aang, at the Crossroads #106 (real) | 2 | approach T12 | life_zero|found=False|countered=0 T6 | 6 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Vivi Ornitier #99 (real) | 0 | approach T34 | life_zero|found=False|countered=0 T8 | 26 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T8 | 11 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Winota, Joiner of Forces #39 (real) | 1 | elimination T18 | life_zero|found=False|countered=0 T9 | 9 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |

## Next Steps

- Use the hypothesis queue to build only a micro-package, not another broad shell.
- Protect 607 anchors observed in winning close windows.
- Predeclare target metrics before any battle gate.
- Reject any package that improves access but loses miracle/topdeck/spell-volume deltas.

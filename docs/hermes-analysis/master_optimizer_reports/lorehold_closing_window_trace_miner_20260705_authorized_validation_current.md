# Lorehold Closing Window Trace Miner

- Generated at: `2026-07-05T13:45:25Z`
- Protected baseline: `deck_607`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Recommended next action: `build_trace_targeted_micro_package_from_closing_window`
- Comparison count: `48`
- Ready micro-package hypotheses: `3`
- Average 607 turn advantage: `7.79`
- Gap counts: `{"607_mana_timing_anchor_deficit": 21, "approach_conversion_missing": 11, "candidate_died_before_closing_window": 48, "candidate_lost_multiple_turns_before_607_finish": 43, "lorehold_spell_volume_deficit": 47, "miracle_cast_deficit": 44, "static_cost_reduction_deficit": 25, "topdeck_activation_deficit": 19, "topdeck_engine_card_deficit": 21, "upkeep_rummage_deficit": 28}`

## Top Strategic Deficits

- `lorehold_cost_paid`: `417`
- `lorehold_spell_cast`: `391`
- `static_cost_reduction_total`: `235`
- `miracle_cast`: `185`
- `lorehold_upkeep_rummage`: `161`
- `topdeck_manipulation_activated`: `77`

## Top Anchor Card Deficits

- `topdeck_manipulation_activated:Sensei's Divining Top`: `54`
- `cost_paid:Lorehold, the Historian`: `53`
- `topdeck_manipulation_activated:Scroll Rack`: `27`
- `trigger_resolved:Surge to Victory`: `18`
- `cost_paid:The Scarlet Witch`: `17`
- `spell_resolved:Surge to Victory`: `16`
- `cost_paid:Sensei's Divining Top`: `16`
- `miracle_cast:Surge to Victory`: `16`
- `spell_cast:Sensei's Divining Top`: `16`
- `spell_cast:The Scarlet Witch`: `15`
- `spell_resolved:Sensei's Divining Top`: `15`
- `spell_resolved:Jeska's Will`: `14`
- `spell_resolved:Big Score`: `14`
- `spell_resolved:Creative Technique`: `13`
- `cost_paid:Bender's Waterskin`: `13`
- `spell_cast:Bender's Waterskin`: `13`

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
| challenger_lorehold_access_density_control_v1 | Aang, at the Crossroads #106 (real) | 0 | elimination T17 | life_zero|found=False|countered=0 T7 | 10 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Aang, at the Crossroads #106 (real) | 1 | approach T10 | life_zero|found=False|countered=0 T6 | 4 | approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Kenrith, the Returned King #113 (real) | 2 | elimination T18 | life_zero|found=False|countered=0 T7 | 11 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_access_density_control_v1 | Rograkh, Son of Rohgahh #62 (real) | 1 | elimination T23 | life_zero|found=False|countered=0 T9 | 14 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Sisay, Weatherlight Captain #61 (real) | 0 | approach T8 | life_zero|found=False|countered=0 T8 | 0 | approach_conversion_missing, candidate_died_before_closing_window, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Umbris, Fear Manifest #114 (real) | 1 | elimination T21 | life_zero|found=False|countered=0 T8 | 13 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_access_density_control_v1 | Umbris, Fear Manifest #114 (real) | 2 | elimination T12 | life_zero|found=False|countered=0 T11 | 1 | candidate_died_before_closing_window, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Vivi Ornitier #99 (real) | 0 | elimination T24 | life_zero|found=False|countered=0 T11 | 13 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T7 | 12 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_access_density_control_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T7 | 12 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_access_density_control_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T17 | life_zero|found=False|countered=0 T9 | 8 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_access_density_control_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T6 | 7 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_access_density_control_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T6 | 7 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_miracle_pressure_conversion_v1 | Kenrith, the Returned King #113 (real) | 0 | elimination T14 | life_zero|found=False|countered=0 T8 | 6 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_miracle_pressure_conversion_v1 | Rograkh, Son of Rohgahh #62 (real) | 0 | elimination T11 | life_zero|found=False|countered=0 T7 | 4 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_miracle_pressure_conversion_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T7 | 12 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_miracle_pressure_conversion_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T12 | 1 | candidate_died_before_closing_window, lorehold_spell_volume_deficit, upkeep_rummage_deficit |
| challenger_lorehold_miracle_topdeck_control_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T8 | 11 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_miracle_topdeck_control_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T6 | 7 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Kenrith, the Returned King #113 (real) | 0 | elimination T14 | life_zero|found=False|countered=0 T11 | 3 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Rograkh, Son of Rohgahh #62 (real) | 0 | elimination T11 | life_zero|found=False|countered=0 T7 | 4 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_engine_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T8 | 11 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Kenrith, the Returned King #113 (real) | 0 | elimination T14 | life_zero|found=False|countered=0 T8 | 6 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Rograkh, Son of Rohgahh #62 (real) | 0 | elimination T11 | life_zero|found=False|countered=0 T6 | 5 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T6 | 13 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_recursion_discard_pressure_repair_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T7 | 6 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T10 | 9 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T10 | 9 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T8 | 5 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T8 | 5 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_pressure_mana_conversion_v1 | Kenrith, the Returned King #113 (real) | 0 | elimination T14 | life_zero|found=False|countered=0 T8 | 6 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_pressure_mana_conversion_v1 | Rograkh, Son of Rohgahh #62 (real) | 0 | elimination T11 | life_zero|found=False|countered=0 T11 | 0 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_pressure_topdeck_v1 | Rograkh, Son of Rohgahh #62 (real) | 0 | elimination T11 | life_zero|found=False|countered=0 T8 | 3 | approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish |
| challenger_lorehold_spell_pressure_topdeck_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T8 | 11 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_spell_pressure_topdeck_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T10 | 3 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Aang, at the Crossroads #106 (real) | 1 | approach T10 | life_zero|found=False|countered=0 T6 | 4 | approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Kenrith, the Returned King #113 (real) | 1 | elimination T35 | life_zero|found=False|countered=0 T9 | 26 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Rograkh, Son of Rohgahh #62 (real) | 1 | elimination T23 | life_zero|found=False|countered=0 T9 | 14 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Sisay, Weatherlight Captain #61 (real) | 0 | approach T8 | life_zero|found=False|countered=0 T7 | 1 | candidate_died_before_closing_window, lorehold_spell_volume_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Umbris, Fear Manifest #114 (real) | 1 | elimination T21 | life_zero|found=False|countered=0 T9 | 12 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Umbris, Fear Manifest #114 (real) | 2 | elimination T12 | life_zero|found=False|countered=0 T9 | 3 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Vivi Ornitier #99 (real) | 0 | elimination T24 | life_zero|found=False|countered=0 T6 | 18 | 607_mana_timing_anchor_deficit, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, topdeck_activation_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T17 | life_zero|found=False|countered=0 T8 | 9 | approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit, topdeck_engine_card_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T6 | 7 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spell_volume_access_depressure_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T6 | 7 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spellchain_big_sorcery_v1 | Rograkh, Son of Rohgahh #62 (real) | 0 | elimination T11 | life_zero|found=False|countered=0 T8 | 3 | 607_mana_timing_anchor_deficit, approach_conversion_missing, candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |
| challenger_lorehold_spellchain_big_sorcery_v1 | Vivi Ornitier #99 (real) | 0 | elimination T19 | life_zero|found=False|countered=0 T7 | 12 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, static_cost_reduction_deficit |
| challenger_lorehold_spellchain_big_sorcery_v1 | Winota, Joiner of Forces #39 (real) | 0 | elimination T13 | life_zero|found=False|countered=0 T7 | 6 | candidate_died_before_closing_window, candidate_lost_multiple_turns_before_607_finish, lorehold_spell_volume_deficit, miracle_cast_deficit, upkeep_rummage_deficit |

## Next Steps

- Use the hypothesis queue to build only a micro-package, not another broad shell.
- Protect 607 anchors observed in winning close windows.
- Predeclare target metrics before any battle gate.
- Reject any package that improves access but loses miracle/topdeck/spell-volume deltas.

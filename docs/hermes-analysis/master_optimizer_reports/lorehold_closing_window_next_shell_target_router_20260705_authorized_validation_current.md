# Lorehold Closing-Window Next Shell Target Router

- Generated at: `2026-07-05T13:46:20Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `closing_window_shell_target_selected_no_battle`
- Selected hypothesis: `preserve_topdeck_miracle_floor_micro_package`
- Selected status: `primary_shell_contract_target_blocked_but_actionable_as_design`
- Closing-window comparisons: `48`
- Average 607 turn advantage: `7.79`
- Named seed-safe cuts: `0`
- Natural battle gate allowed now: `false`
- Recommended next action: `write_miracle_access_first_shell_contract_no_battle`

## Hypothesis Routes

| Hypothesis | Status | Score | Target Gap Total | Blockers |
| --- | --- | ---: | ---: | --- |
| preserve_topdeck_miracle_floor_micro_package | `primary_shell_contract_target_blocked_but_actionable_as_design` | 463 | 84 | from_scratch_shell_gate_not_allowed, miracle_trace_missing, no_named_seed_safe_cuts_in_current_607, topdeck_activation_missing, topdeck_anchor_access_regressed |
| approach_big_spell_conversion_preservation | `secondary_shell_contract_target_after_miracle_floor` | 341 | 58 | from_scratch_shell_gate_not_allowed, miracle_trace_missing, no_named_seed_safe_cuts_in_current_607, pressure_conversion_unproven, topdeck_anchor_access_regressed |
| pressure_survival_without_engine_cuts | `diagnostic_only_after_engine_floor` | 451 | 91 | fast_pressure_slice_not_protected, from_scratch_shell_gate_not_allowed, no_named_seed_safe_cuts_in_current_607, pressure_causality_unproven, pressure_route_must_follow_engine_floor_repair |

## Selected Shell Contract

- Contract key: `miracle_access_first_shell_contract`
- Shell type: `micro_shell_before_full_generation`
- Must preserve:
  - `Sensei's Divining Top`
  - `Scroll Rack`
  - `Bender's Waterskin`
  - `Victory Chimes`
  - `Approach of the Second Sun`
- Target metrics:
  - `miracle_cast`
  - `topdeck_manipulation_activated`
  - `lorehold_spell_cast`
  - `lorehold_upkeep_rummage`
  - `static_cost_reduction_total`
- Forbidden shortcut: Do not add tutors/recursion/hand-filter density unless the shell first preserves the topdeck and miracle cadence.

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

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: Closing-window evidence identifies a miracle/topdeck floor repair target, but failed shells and zero seed-safe cuts block battle or mutation now.
- next_actions:
  - write_miracle_access_first_shell_contract_no_battle
  - do_not_start_from_broad_from_scratch_shell
  - do_not_test_pressure_conversion_until miracle/topdeck floor contract exists
  - predeclare target metrics before any structure matrix
  - keep deck_607 protected until same-seed equal battle gate proves replacement

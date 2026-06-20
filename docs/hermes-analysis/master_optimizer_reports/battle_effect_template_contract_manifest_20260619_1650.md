# Battle Effect Template Contract Manifest - 2026-06-19T16:50Z

## Scope

Artifact-only validation slice for `effect_json.effect` coverage in the current
battle corpus. This manifest crosschecks observed effect families against:

- latest effect coverage counts;
- runtime effect literals in `battle_analyst_v9.py`;
- primary `apply_effect_immediate` / composite handler detection;
- forensic `SUPPORTED_EFFECTS`;
- focused evidence `supports_*_template` surface.

No PostgreSQL changes, swaps, commits, product-code edits, or automation edits
were made.

## Inputs

- Coverage:
  `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.json`
- Generated JSON:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/effect_template_contract_1650/effect_template_contract.json`
- Runtime:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Forensic:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- Focused evidence:
  `server/bin/manaloom_battle_rule_focused_evidence.py`

## Summary

- Observed effect families in latest coverage: `40`.
- Latest total card instances: `1288`.
- Runtime effect literals detected statically: `64`.
- Primary apply/composite effect literals detected statically: `52`.
- Forensic supported effects: `52`.
- Focused evidence template functions: `21`.
- Effects with no runtime literal detected: `0/40`.
- Effects not in forensic supported set: `2/40` (`unknown`, `worldfire_reset`).
- Effects without focused template mapping: `30/40`.
- Effects with current coverage flags: `27/40`.
- Status counts:
  - `mapped_no_current_flags`: `2`.
  - `mapped_but_incomplete_contract`: `36`.
  - `gap`: `2`.

Important limitation: static detection of the primary apply handler is not proof
that an effect has no behavior. Some effects, such as `counter`, are handled by
stack/cast paths rather than by `apply_effect_immediate`. This manifest treats
that as an incomplete contract annotation, not as a runtime bug by itself.

## Effect Matrix

| Effect | Count | Status | Forensic | Runtime literal | Primary handler | Focused template | Flags | Missing contract reasons |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| `land` | 377 | `mapped_but_incomplete_contract` | true | true | true | `-` | `copy_effect_mismatch=1, land_utility_ability_not_modeled=21` | `no_focused_template_mapping, coverage_flags_present` |
| `creature` | 223 | `mapped_but_incomplete_contract` | true | true | true | `-` | `cast_permission_not_explicit=8, heuristic_effect=70, needs_review_rule=3, oracle_silence_mismatch=1, oracle_target_removal_mismatch=5, temporary_effect_not_explicit=15, trigger_not_explicit=33` | `no_focused_template_mapping, coverage_flags_present` |
| `ramp_permanent` | 129 | `mapped_but_incomplete_contract` | true | true | true | `-` | `heuristic_effect=11, needs_review_rule=8, temporary_effect_not_explicit=3, trigger_not_explicit=5` | `no_focused_template_mapping, coverage_flags_present` |
| `counter` | 99 | `mapped_but_incomplete_contract` | true | true | false | `supports_counterspell_template` | `cast_permission_not_explicit=2, heuristic_effect=2, needs_review_rule=3, oracle_silence_mismatch=1, oracle_target_removal_mismatch=2, trigger_not_explicit=1` | `no_primary_apply_effect_handler_detected_or_handled_elsewhere, coverage_flags_present` |
| `tutor` | 82 | `mapped_but_incomplete_contract` | true | true | true | `supports_attack_artifact_tutor_template` | `cast_permission_not_explicit=1, heuristic_effect=3, needs_review_rule=2, temporary_effect_not_explicit=3, trigger_not_explicit=1` | `coverage_flags_present` |
| `ramp_ritual` | 55 | `mapped_but_incomplete_contract` | true | true | true | `-` | `temporary_effect_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `unknown` | 41 | `gap` | false | true | false | `-` | `cast_permission_not_explicit=3, needs_review_rule=5, temporary_effect_not_explicit=3, trigger_not_explicit=2, unknown_effect=28` | `effect_is_unknown, no_primary_apply_effect_handler_detected_or_handled_elsewhere, not_in_forensic_supported_effects, no_focused_template_mapping, coverage_flags_present` |
| `draw_engine` | 39 | `mapped_but_incomplete_contract` | true | true | true | `-` | `trigger_not_explicit=6` | `no_focused_template_mapping, coverage_flags_present` |
| `passive` | 33 | `mapped_but_incomplete_contract` | true | true | true | `-` | `cast_permission_not_explicit=4, oracle_silence_mismatch=1, oracle_target_removal_mismatch=1, trigger_not_explicit=3` | `no_focused_template_mapping, coverage_flags_present` |
| `remove_permanent` | 33 | `mapped_but_incomplete_contract` | true | true | true | `supports_destroy_target_nonland_permanent_template, supports_exile_target_nonland_permanent_template, supports_destroy_target_artifact_template, supports_exile_target_artifact_template, supports_destroy_target_enchantment_template, supports_exile_target_enchantment_template, supports_exile_target_artifact_or_enchantment_template` | `cast_permission_not_explicit=1, heuristic_effect=1, needs_review_rule=3, temporary_effect_not_explicit=4, unknown_effect=1` | `coverage_flags_present` |
| `draw_cards` | 30 | `mapped_but_incomplete_contract` | true | true | true | `supports_simple_draw_card_template` | `cast_permission_not_explicit=4, heuristic_effect=3, needs_review_rule=3, temporary_effect_not_explicit=1, trigger_not_explicit=1` | `coverage_flags_present` |
| `ramp_engine` | 24 | `mapped_but_incomplete_contract` | true | true | true | `-` | `temporary_effect_not_explicit=2, trigger_not_explicit=5` | `no_focused_template_mapping, coverage_flags_present` |
| `recursion` | 16 | `mapped_but_incomplete_contract` | true | true | true | `supports_return_target_creature_from_graveyard_template, supports_return_target_artifact_from_graveyard_template, supports_return_target_enchantment_from_graveyard_template, supports_return_target_artifact_or_enchantment_from_graveyard_template` | `cast_permission_not_explicit=4, temporary_effect_not_explicit=2` | `coverage_flags_present` |
| `silence_spell` | 12 | `mapped_but_incomplete_contract` | true | true | true | `-` | `oracle_silence_mismatch=1` | `no_focused_template_mapping, coverage_flags_present` |
| `finisher` | 11 | `mapped_but_incomplete_contract` | true | true | true | `-` | `trigger_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `remove_creature` | 11 | `mapped_but_incomplete_contract` | true | true | true | `supports_destroy_target_creature_template, supports_exile_target_creature_template` | `cast_permission_not_explicit=2, needs_review_rule=2` | `coverage_flags_present` |
| `redirect_removal` | 10 | `mapped_but_incomplete_contract` | true | true | true | `-` | `cast_permission_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `token_maker` | 10 | `mapped_but_incomplete_contract` | true | true | true | `-` | `temporary_effect_not_explicit=1, trigger_not_explicit=2` | `no_focused_template_mapping, coverage_flags_present` |
| `copy_spell` | 8 | `mapped_but_incomplete_contract` | true | true | true | `-` | `cast_permission_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `silence_opponents` | 6 | `mapped_but_incomplete_contract` | true | true | true | `-` | `trigger_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `topdeck_manipulation` | 5 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `land_ramp` | 4 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `deal_damage` | 3 | `mapped_no_current_flags` | true | true | true | `supports_sacrifice_damage_template` | `-` | `-` |
| `extra_turn` | 3 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `hate_artifact` | 3 | `mapped_but_incomplete_contract` | true | true | true | `-` | `oracle_target_removal_mismatch=1, trigger_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `indestructible` | 3 | `mapped_but_incomplete_contract` | true | true | true | `supports_creatures_indestructible_template` | `cast_permission_not_explicit=1, heuristic_effect=2, temporary_effect_not_explicit=1` | `coverage_flags_present` |
| `treasure_maker` | 3 | `mapped_but_incomplete_contract` | true | true | true | `supports_simple_treasure_template, supports_attack_artifact_tutor_template` | `cast_permission_not_explicit=1` | `coverage_flags_present` |
| `copy_creature_token` | 2 | `mapped_but_incomplete_contract` | true | true | true | `-` | `cast_permission_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `equipment_haste_shroud` | 2 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `approach` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `board_wipe` | 1 | `mapped_no_current_flags` | true | true | true | `supports_destroy_all_creatures_template` | `-` | `-` |
| `hand_filter` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `life_artifact` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `modal_boros_charm` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `temporary_effect_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `overload_recursion` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `cast_permission_not_explicit=1, oracle_target_removal_mismatch=1` | `no_focused_template_mapping, coverage_flags_present` |
| `phase_creatures` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `phase_out` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `protect_creature` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `temporary_effect_not_explicit=1, trigger_not_explicit=1` | `no_focused_template_mapping, coverage_flags_present` |
| `remove_artifact_or_3dmg` | 1 | `mapped_but_incomplete_contract` | true | true | true | `-` | `-` | `no_focused_template_mapping` |
| `worldfire_reset` | 1 | `gap` | false | true | true | `-` | `-` | `not_in_forensic_supported_effects, no_focused_template_mapping` |

## Operational Reading

This is stronger than the previous broad statement that a contract is missing:
all currently observed effect names are at least mentioned in runtime logic, but
only `deal_damage` and `board_wipe` currently look mapped without active
coverage flags in this manifest.

The remaining risk is contract completeness, not necessarily immediate runtime
failure:

- `unknown` is still a real gap and accounts for `41` coverage instances.
- `worldfire_reset` is observed once and has runtime handling, but it is not in
  forensic `SUPPORTED_EFFECTS` and has no focused template mapping.
- `30/40` observed effects have no focused template mapping.
- `27/40` observed effects still have coverage flags.
- Several effects are valid broad categories (`creature`, `land`, `passive`)
  and need explicit waived/subcontracted handling rather than one broad hard
  template.

## Required Follow-Up

- Promote this manifest into the recurring battle audit summary, or generate an
  equivalent `effect_template_contract.json` each run.
- Add accepted waiver categories for broad container effects such as `creature`,
  `land`, and `passive`, or split their flagged subfamilies into narrower
  contracts.
- Add forensic support or explicit waiver for `worldfire_reset`.
- Keep `unknown` as blocking/review-required until each current card has a
  family/template/waiver.
- Use `mapped_no_current_flags` as evidence only for the current corpus, not as
  proof that the effect is globally complete.

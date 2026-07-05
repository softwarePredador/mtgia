# Lorehold Post-Identity Queue Split

- Generated at: `2026-07-05T02:02:02Z`
- Status: `post_identity_queue_split_no_battle_ready_keep_607`
- Current baseline: `deck_607`
- Source DB mutated: `False`
- Deck 607 mutated: `False`

## Summary

| Metric | Value |
| --- | ---: |
| `queue_card_count` | `14` |
| `identity_import_remaining_count` | `0` |
| `temporary_identity_ready_count` | `6` |
| `source_identity_ready_count` | `8` |
| `runtime_or_manual_review_count` | `4` |
| `combo_runtime_contract_count` | `1` |
| `full_shell_contract_count` | `9` |
| `verified_auto_rule_ready_count` | `1` |
| `battle_ready_now_count` | `0` |

## Card Priorities

| Card | Route | Lane | Contract | Rule Count | Blockers |
| --- | --- | --- | --- | ---: | --- |
| Brain in a Jar | `runtime_or_manual_review` | `topdeck_miracle_access` | `single_card_runtime_contract_then_cut_safety` | `0` | verified_battle_rule_missing, named_safe_cut_missing |
| Entreat the Angels | `runtime_or_manual_review` | `miracle_finisher` | `miracle_token_runtime_contract_then_cut_safety` | `0` | verified_battle_rule_missing, named_safe_cut_missing |
| Haze of Rage | `combo_runtime_contract` | `storm_combo_pressure` | `combo_runtime_contract_with_storm_kiln_artist` | `0` | verified_battle_rule_missing, combo_runtime_required, named_safe_cut_missing |
| Burning Prophet | `runtime_or_manual_review` | `spell_scry_pressure` | `spell_trigger_runtime_review_then_diagnostic_cut_check` | `0` | verified_battle_rule_missing, named_safe_cut_missing |
| Inti, Seneschal of the Sun | `runtime_or_manual_review` | `rummage_pressure_access` | `discard_access_runtime_review_then_shell_or_cut_check` | `0` | verified_battle_rule_missing, named_safe_cut_missing |
| Anointed Procession | `full_shell_contract` | `token_multiplier` | `token_multiplier_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |
| Cathars' Crusade | `full_shell_contract` | `token_multiplier` | `token_multiplier_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |
| Karmic Guide | `full_shell_contract` | `white_reanimator` | `white_reanimator_shell_contract` | `1` | full_shell_contract_required, named_safe_cut_missing |
| Late to Dinner | `full_shell_contract` | `white_reanimator` | `white_reanimator_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |
| Miraculous Recovery | `full_shell_contract` | `white_reanimator` | `white_reanimator_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |
| Storm of Souls | `full_shell_contract` | `white_reanimator` | `white_reanimator_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |
| Blackblade Reforged | `full_shell_contract` | `voltron_equipment` | `voltron_equipment_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |
| Excalibur, Sword of Eden | `full_shell_contract` | `voltron_equipment` | `voltron_equipment_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |
| Strata Scythe | `full_shell_contract` | `voltron_equipment` | `voltron_equipment_shell_contract` | `0` | verified_battle_rule_missing, full_shell_contract_required, named_safe_cut_missing |

## Shell And Combo Contracts

| Contract | Cards | Next Step |
| --- | --- | --- |
| `token_multiplier_shell` | Anointed Procession, Cathars' Crusade | `define_token_density_engine_and_cuts_before_any_battle` |
| `voltron_equipment_shell` | Blackblade Reforged, Excalibur, Sword of Eden, Strata Scythe | `define_equipment_commander_damage_shell_before_any_battle` |
| `white_reanimator_shell` | Karmic Guide, Late to Dinner, Miraculous Recovery, Storm of Souls | `define_creature_graveyard_density_shell_before_any_battle` |
| `storm_kiln_haze_combo` | Storm-Kiln Artist, Haze of Rage | `define_combo_runtime_and_cut_safety_before_any_battle` |

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Reason: Post-identity queues are now clear enough to plan, but every path still requires runtime, combo, shell, or named safe-cut work before a battle gate.

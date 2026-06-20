# Battle Unknown Template Backlog Audit

- Generated at: `2026-06-19T17:02:49Z`
- Coverage JSON: `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.json`
- Status: `backlog_manifest_ready`
- Unknown cards: `29`
- With current inferred family: `29`
- Without current inferred family: `0`
- With reviewed family: `29`
- Without reviewed family: `0`
- With focused template match: `0`
- Without focused template match: `29`
- With plan or waiver: `29`
- Without plan or waiver: `0`
- Plan status counts: `{"template_required": 29}`
- Reviewed family counts: `{"additional_cost_discard_multi_target_damage": 1, "alternative_cost_library_bounce": 1, "alternative_cost_sacrifice_mountain_damage": 1, "convoke_damage": 1, "copy_artifact_static_as_enters": 1, "copy_permanent_with_flash_or_flashback": 1, "copy_token_with_delayed_sacrifice": 1, "cost_reduction_static_aura": 1, "counter_manipulation_and_type_change": 1, "graveyard_recast_replacement": 1, "impulse_topdeck_or_library_zone": 2, "manifest_cloak_equipment": 3, "manifest_from_hand_activated_ability": 1, "mill_and_graveyard_return": 1, "modal_mass_sacrifice_selection": 1, "phase_out_mass_removal_counters": 1, "planeswalker_static_and_activated_graveyard_ability": 1, "split_second_damage": 1, "static_named_card_cast_restriction": 1, "static_noncreature_tax": 1, "static_tax_and_opponent_life_loss": 1, "tap_untap_bounce_granted_ability": 1, "tap_untap_cipher_trigger": 1, "type_change_continuous_effect": 1, "utility_artifact_untap_x_lands": 1, "vanishing_sacrifice_trigger_removal": 1, "x_cost_counters_vehicle_token": 1}`

## Per-Card Contract

| Card | Current inferred families | Reviewed families | Focused template match | Plan | Owner | Next fixture | Risk flags |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Ashnod's Transmogrant` | `counter_manipulation, counter_manipulation_and_type_change, type_change_continuous_effect` | `counter_manipulation_and_type_change` | `-` | `template_required` | `battle-template-backlog` | `counter_and_artifact_type_change_replay` | `missing_focused_template` |
| `Banishing Knack` | `tap_untap_bounce_granted_ability` | `tap_untap_bounce_granted_ability` | `-` | `template_required` | `battle-template-backlog` | `grant_activated_bounce_ability_replay` | `missing_focused_template` |
| `Candelabra of Tawnos` | `utility_artifact_untap_x_lands` | `utility_artifact_untap_x_lands` | `-` | `template_required` | `battle-template-backlog` | `x_land_untap_activated_ability_replay` | `missing_focused_template` |
| `Clown Car` | `counter_manipulation, counter_manipulation_and_type_change` | `x_cost_counters_vehicle_token` | `-` | `template_required` | `battle-template-backlog` | `x_cost_vehicle_counters_and_token_replay` | `missing_focused_template` |
| `Codex Shredder` | `mill_and_graveyard_return` | `mill_and_graveyard_return` | `-` | `template_required` | `battle-template-backlog` | `mill_then_graveyard_return_activated_ability_replay` | `missing_focused_template` |
| `Copy Artifact` | `copy_artifact_static_as_enters` | `copy_artifact_static_as_enters` | `-` | `template_required` | `battle-template-backlog` | `copy_artifact_as_enters_replay` | `missing_focused_template` |
| `Cryptic Coat` | `manifest_cloak_equipment` | `manifest_cloak_equipment` | `-` | `template_required` | `battle-template-backlog` | `cloak_equipment_etb_attach_replay` | `missing_focused_template` |
| `Cursed Windbreaker` | `manifest_cloak_equipment` | `manifest_cloak_equipment` | `-` | `template_required` | `battle-template-backlog` | `manifest_cloak_equipment_static_grant_replay` | `missing_focused_template` |
| `Dissection Tools` | `manifest_cloak_equipment` | `manifest_cloak_equipment` | `-` | `template_required` | `battle-template-backlog` | `manifest_cloak_equipment_lifelink_replay` | `missing_focused_template` |
| `Firestorm` | `additional_cost_discard_multi_target_damage` | `additional_cost_discard_multi_target_damage` | `-` | `template_required` | `battle-template-backlog` | `discard_x_multi_target_damage_replay` | `missing_focused_template` |
| `Flash Photography` | `copy_permanent_with_flash_or_flashback, copy_spell_or_permanent, graveyard_recast_replacement` | `copy_permanent_with_flash_or_flashback` | `-` | `template_required` | `battle-template-backlog` | `copy_permanent_flash_timing_and_flashback_replay` | `missing_focused_template` |
| `God-Pharaoh's Statue` | `static_tax_and_opponent_life_loss` | `static_tax_and_opponent_life_loss` | `-` | `template_required` | `battle-template-backlog` | `static_opponent_tax_and_end_step_life_loss_replay` | `missing_focused_template` |
| `Heroes' Hangout` | `impulse_topdeck_or_library_zone` | `impulse_topdeck_or_library_zone` | `-` | `template_required` | `battle-template-backlog` | `modal_impulse_play_until_next_turn_replay` | `missing_focused_template` |
| `Hidden Strings` | `tap_untap_cipher_trigger` | `tap_untap_cipher_trigger` | `-` | `template_required` | `battle-template-backlog` | `tap_untap_cipher_trigger_replay` | `missing_focused_template` |
| `Kindle the Inner Flame` | `copy_spell_or_permanent, copy_token_with_delayed_sacrifice, graveyard_recast_replacement` | `copy_token_with_delayed_sacrifice, graveyard_recast_replacement` | `-` | `template_required` | `battle-template-backlog` | `copy_token_delayed_sacrifice_flashback_replay` | `missing_focused_template` |
| `Liquimetal Coating` | `type_change_continuous_effect` | `type_change_continuous_effect` | `-` | `template_required` | `battle-template-backlog` | `temporary_artifact_type_change_replay` | `missing_focused_template` |
| `Mine Collapse` | `alternative_cost_sacrifice_mountain_damage, targeted_interaction` | `alternative_cost_sacrifice_mountain_damage` | `-` | `template_required` | `battle-template-backlog` | `sacrifice_mountain_alternative_cost_damage_replay` | `missing_focused_template` |
| `Nevermore` | `static_named_card_cast_restriction` | `static_named_card_cast_restriction` | `-` | `template_required` | `battle-template-backlog` | `named_card_cast_restriction_replay` | `missing_focused_template` |
| `Opera Love Song` | `impulse_topdeck_or_library_zone` | `impulse_topdeck_or_library_zone` | `-` | `template_required` | `battle-template-backlog` | `instant_impulse_play_until_next_turn_replay` | `missing_focused_template` |
| `Out of Time` | `phase_out_mass_removal_counters` | `phase_out_mass_removal_counters` | `-` | `template_required` | `battle-template-backlog` | `mass_phase_out_duration_counters_replay` | `missing_focused_template` |
| `Power Artifact` | `cost_reduction_static_aura` | `cost_reduction_static_aura` | `-` | `template_required` | `battle-template-backlog` | `enchanted_artifact_activation_cost_reduction_replay` | `missing_focused_template` |
| `Reality Acid` | `vanishing_sacrifice_trigger_removal` | `vanishing_sacrifice_trigger_removal` | `-` | `template_required` | `battle-template-backlog` | `vanishing_sacrifice_enchanted_permanent_replay` | `missing_focused_template` |
| `Scroll of Fate` | `manifest_from_hand_activated_ability` | `manifest_from_hand_activated_ability` | `-` | `template_required` | `battle-template-backlog` | `manifest_card_from_hand_replay` | `missing_focused_template` |
| `Stoke the Flames` | `convoke_damage` | `convoke_damage` | `-` | `template_required` | `battle-template-backlog` | `convoke_damage_payment_replay` | `missing_focused_template` |
| `Submerge` | `alternative_cost_library_bounce` | `alternative_cost_library_bounce` | `-` | `template_required` | `battle-template-backlog` | `alternative_cost_top_of_library_bounce_replay` | `missing_focused_template` |
| `Sudden Shock` | `split_second_damage` | `split_second_damage` | `-` | `template_required` | `battle-template-backlog` | `split_second_damage_priority_lock_replay` | `missing_focused_template` |
| `Thorn of Amethyst` | `static_noncreature_tax` | `static_noncreature_tax` | `-` | `template_required` | `battle-template-backlog` | `static_noncreature_spell_tax_replay` | `missing_focused_template` |
| `Tragic Arrogance` | `modal_mass_sacrifice_selection` | `modal_mass_sacrifice_selection` | `-` | `template_required` | `battle-template-backlog` | `per_player_permanent_type_choice_sacrifice_replay` | `missing_focused_template` |
| `Tyvar, Jubilant Brawler` | `planeswalker_static_and_activated_graveyard_ability` | `planeswalker_static_and_activated_graveyard_ability` | `-` | `template_required` | `battle-template-backlog` | `planeswalker_static_haste_and_graveyard_activation_replay` | `missing_focused_template` |

## Interpretation

- `missing_focused_template` means the card still needs a narrow template, fixture, or waiver before promotion.
- `backlog_manifest_ready` means every unknown card has a reviewed family and an explicit plan or waiver; it does not mean runtime support is complete.

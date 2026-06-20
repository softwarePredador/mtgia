# Battle Template Dispatch Gap Audit - 2026-06-19 17:28Z

## Scope

This report checks whether the current unknown-template backlog is only matched
by `supports_*_template` predicates or is also dispatchable through the focused
evidence runner that generates replay artifacts.

No PostgreSQL changes, no swaps, no code edits, and no commits were performed.

Source artifacts:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172842/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172842/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172842/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/template_dispatch_gap_172842/template_dispatch_gap.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

## Current Gate Snapshot

| Metric | Value |
| --- | ---: |
| `battle_replay_final_status` | `review_required` |
| `mandatory_gate_divergences` | `["effect_coverage=review_required"]` |
| `effect_coverage_unknowns` | `33` |
| `unknown_template_without_focused_template_match` | `0` |
| `unknown_template_backlog.status` | `focused_template_backlog_ready` |
| `unknown_template_plan_status_counts` | `{"focused_template_ready": 29}` |

The latest recurring summary correctly shows that every current unknown card has
a `supports_*_template` predicate match. It does not prove that the focused
evidence runner can execute those templates.

## Dispatch Surface

| Surface | Count |
| --- | ---: |
| `supports_*_template` functions in `manaloom_battle_rule_focused_evidence.py` | `47` |
| `supports_*_template` functions called by `evaluate_draft(...)` | `21` |
| `build_*_evidence` functions | `21` |
| `supports_*_template` functions not dispatched by `evaluate_draft(...)` | `26` |

Current unknown backlog:

| Metric | Value |
| --- | ---: |
| Unknown cards | `29` |
| Cards with `focused_template_matches` | `29` |
| Cards with dispatchable template match | `0` |
| Cards without dispatchable template match | `29` |
| `evaluate_draft(...)` statuses for those 29 cards | `{"unsupported": 29}` |

## Per-Card Dispatch Check

| Card | Match reported | Dispatchable | Evidence runner | Next fixture |
| --- | --- | ---: | --- | --- |
| `Ashnod's Transmogrant` | `supports_counter_type_change_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `counter_and_artifact_type_change_replay` |
| `Banishing Knack` | `supports_granted_bounce_ability_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `grant_activated_bounce_ability_replay` |
| `Candelabra of Tawnos` | `supports_utility_artifact_untap_x_lands_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `x_land_untap_activated_ability_replay` |
| `Clown Car` | `supports_x_vehicle_counters_token_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `x_cost_vehicle_counters_and_token_replay` |
| `Codex Shredder` | `supports_mill_graveyard_return_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `mill_then_graveyard_return_activated_ability_replay` |
| `Copy Artifact` | `supports_copy_artifact_as_enters_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `copy_artifact_as_enters_replay` |
| `Cryptic Coat` | `supports_manifest_cloak_equipment_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `cloak_equipment_etb_attach_replay` |
| `Cursed Windbreaker` | `supports_manifest_cloak_equipment_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `manifest_cloak_equipment_static_grant_replay` |
| `Dissection Tools` | `supports_manifest_cloak_equipment_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `manifest_cloak_equipment_lifelink_replay` |
| `Firestorm` | `supports_additional_cost_discard_multi_target_damage_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `discard_x_multi_target_damage_replay` |
| `Flash Photography` | `supports_copy_permanent_flash_or_flashback_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `copy_permanent_flash_timing_and_flashback_replay` |
| `God-Pharaoh's Statue` | `supports_static_tax_opponent_life_loss_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `static_opponent_tax_and_end_step_life_loss_replay` |
| `Heroes' Hangout` | `supports_impulse_topdeck_or_library_zone_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `modal_impulse_play_until_next_turn_replay` |
| `Hidden Strings` | `supports_tap_untap_cipher_trigger_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `tap_untap_cipher_trigger_replay` |
| `Kindle the Inner Flame` | `supports_copy_token_delayed_sacrifice_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `copy_token_delayed_sacrifice_flashback_replay` |
| `Liquimetal Coating` | `supports_type_change_continuous_effect_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `temporary_artifact_type_change_replay` |
| `Mine Collapse` | `supports_alternative_cost_sacrifice_mountain_damage_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `sacrifice_mountain_alternative_cost_damage_replay` |
| `Nevermore` | `supports_named_card_cast_restriction_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `named_card_cast_restriction_replay` |
| `Opera Love Song` | `supports_impulse_topdeck_or_library_zone_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `instant_impulse_play_until_next_turn_replay` |
| `Out of Time` | `supports_phase_out_mass_removal_counters_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `mass_phase_out_duration_counters_replay` |
| `Power Artifact` | `supports_cost_reduction_static_aura_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `enchanted_artifact_activation_cost_reduction_replay` |
| `Reality Acid` | `supports_vanishing_sacrifice_trigger_removal_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `vanishing_sacrifice_enchanted_permanent_replay` |
| `Scroll of Fate` | `supports_manifest_from_hand_activated_ability_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `manifest_card_from_hand_replay` |
| `Stoke the Flames` | `supports_convoke_damage_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `convoke_damage_payment_replay` |
| `Submerge` | `supports_alternative_cost_library_bounce_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `alternative_cost_top_of_library_bounce_replay` |
| `Sudden Shock` | `supports_split_second_damage_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `split_second_damage_priority_lock_replay` |
| `Thorn of Amethyst` | `supports_static_noncreature_tax_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `static_noncreature_spell_tax_replay` |
| `Tragic Arrogance` | `supports_modal_mass_sacrifice_selection_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `per_player_permanent_type_choice_sacrifice_replay` |
| `Tyvar, Jubilant Brawler` | `supports_planeswalker_static_activated_graveyard_template` | `0` | `unsupported` / `no_focused_evidence_template_for_effect_family` | `planeswalker_static_haste_and_graveyard_activation_replay` |

## Interpretation

`unknown_template_without_focused_template_match=0` is a template-detection
milestone, not proof of executable focused evidence. The current backlog still
cannot be promoted through `manaloom_battle_rule_focused_evidence.py` because
the matching predicates for the 29 current unknown cards are not dispatched by
`evaluate_draft(...)` and have no `build_*_evidence` path.

This also explains why `effect_coverage` still blocks the run with
`effect_coverage_unknowns=33`: the backlog knows which narrow template should
exist, but the runtime/evidence pipeline has not yet produced executable replay
evidence for those templates.

## Required Adjustment

The recurring gate should distinguish at least three states:

- `template_predicate_match`: a `supports_*_template` predicate matched.
- `evidence_dispatch_ready`: `evaluate_draft(...)` can route the matched
  template to a `build_*_evidence` function.
- `focused_evidence_ready`: the builder generated focused artifacts and passed
  replay/action/decision checks.

Until then, the current `focused_template_backlog_ready` status can overstate
readiness for the current unknown backlog.

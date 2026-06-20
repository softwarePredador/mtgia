# Battle Latest Focused Dispatch And Forensic Audit - 2026-06-19 17:44Z

## Scope

This report records the latest recurring battle audit state after the wrapper
started publishing `focused_template_dispatch` as a mandatory final-status gate.
It is documentation-only: no PostgreSQL changes, no swaps, no code changes and
no commit.

Primary source:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

Resolved run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/`

Supporting sources:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/focused_template_dispatch.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/seed_63201744/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/effect_coverage_residual.json`

## Latest Status

| Field | Value |
| --- | --- |
| `timestamp_utc` | `2026-06-19T17:44:52Z` |
| `battle_replay_final_status` | `blocked` |
| `battle_replay_final_status_reason` | `one_or_more_mandatory_gates_blocked` |
| `mandatory_gate_divergences` | `focused_template_dispatch=review_required`, `forensic_audit=blocked` |
| high/critical action seeds | none |
| strategy blocker seeds | none |
| high/critical forensic seeds | `63201744` |

Current mandatory gates in `summary.json`:

- `action_critic`
- `strategy_audit`
- `replay_decision_audit`
- `forensic_audit`
- `effect_coverage`
- `focused_template_dispatch`
- `unknown_template_backlog`
- `decision_trace_taxonomy`
- `event_contract_static`

## Focused Template Dispatch

The current focused template gate proves that the backlog has predicates, but
does not yet prove executable focused evidence.

| Metric | Value |
| --- | ---: |
| `focused_template_cards` | 29 |
| `template_predicate_match` | 29 |
| `without_template_predicate_match` | 0 |
| `supports_template_count` | 47 |
| `evaluate_dispatch_template_count` | 21 |
| `build_evidence_function_count` | 21 |
| `evidence_dispatch_ready` | 0 |
| `without_evidence_dispatch` | 29 |
| `focused_evidence_ready` | 0 |
| `focused_evidence_not_ready_unwaived` | 29 |
| `accepted_waivers` | 0 |
| `evidence_runner_status_counts` | `{"unsupported": 29}` |

The 26 support predicates that exist but are not dispatched by
`evaluate_draft(...)` are:

- `supports_additional_cost_discard_multi_target_damage_template`
- `supports_alternative_cost_library_bounce_template`
- `supports_alternative_cost_sacrifice_mountain_damage_template`
- `supports_convoke_damage_template`
- `supports_copy_artifact_as_enters_template`
- `supports_copy_permanent_flash_or_flashback_template`
- `supports_copy_token_delayed_sacrifice_template`
- `supports_cost_reduction_static_aura_template`
- `supports_counter_type_change_template`
- `supports_granted_bounce_ability_template`
- `supports_impulse_topdeck_or_library_zone_template`
- `supports_manifest_cloak_equipment_template`
- `supports_manifest_from_hand_activated_ability_template`
- `supports_mill_graveyard_return_template`
- `supports_modal_mass_sacrifice_selection_template`
- `supports_named_card_cast_restriction_template`
- `supports_phase_out_mass_removal_counters_template`
- `supports_planeswalker_static_activated_graveyard_template`
- `supports_split_second_damage_template`
- `supports_static_noncreature_tax_template`
- `supports_static_tax_opponent_life_loss_template`
- `supports_tap_untap_cipher_trigger_template`
- `supports_type_change_continuous_effect_template`
- `supports_utility_artifact_untap_x_lands_template`
- `supports_vanishing_sacrifice_trigger_removal_template`
- `supports_x_vehicle_counters_token_template`

All 29 current focused-template cards are not ready and unwaived:

| Card | Predicate | Required next fixture |
| --- | --- | --- |
| `Ashnod's Transmogrant` | `supports_counter_type_change_template` | `counter_and_artifact_type_change_replay` |
| `Banishing Knack` | `supports_granted_bounce_ability_template` | `grant_activated_bounce_ability_replay` |
| `Candelabra of Tawnos` | `supports_utility_artifact_untap_x_lands_template` | `x_land_untap_activated_ability_replay` |
| `Clown Car` | `supports_x_vehicle_counters_token_template` | `x_cost_vehicle_counters_and_token_replay` |
| `Codex Shredder` | `supports_mill_graveyard_return_template` | `mill_then_graveyard_return_activated_ability_replay` |
| `Copy Artifact` | `supports_copy_artifact_as_enters_template` | `copy_artifact_as_enters_replay` |
| `Cryptic Coat` | `supports_manifest_cloak_equipment_template` | `cloak_equipment_etb_attach_replay` |
| `Cursed Windbreaker` | `supports_manifest_cloak_equipment_template` | `manifest_cloak_equipment_static_grant_replay` |
| `Dissection Tools` | `supports_manifest_cloak_equipment_template` | `manifest_cloak_equipment_lifelink_replay` |
| `Firestorm` | `supports_additional_cost_discard_multi_target_damage_template` | `discard_x_multi_target_damage_replay` |
| `Flash Photography` | `supports_copy_permanent_flash_or_flashback_template` | `copy_permanent_flash_timing_and_flashback_replay` |
| `God-Pharaoh's Statue` | `supports_static_tax_opponent_life_loss_template` | `static_opponent_tax_and_end_step_life_loss_replay` |
| `Heroes' Hangout` | `supports_impulse_topdeck_or_library_zone_template` | `modal_impulse_play_until_next_turn_replay` |
| `Hidden Strings` | `supports_tap_untap_cipher_trigger_template` | `tap_untap_cipher_trigger_replay` |
| `Kindle the Inner Flame` | `supports_copy_token_delayed_sacrifice_template` | `copy_token_delayed_sacrifice_flashback_replay` |
| `Liquimetal Coating` | `supports_type_change_continuous_effect_template` | `temporary_artifact_type_change_replay` |
| `Mine Collapse` | `supports_alternative_cost_sacrifice_mountain_damage_template` | `sacrifice_mountain_alternative_cost_damage_replay` |
| `Nevermore` | `supports_named_card_cast_restriction_template` | `named_card_cast_restriction_replay` |
| `Opera Love Song` | `supports_impulse_topdeck_or_library_zone_template` | `instant_impulse_play_until_next_turn_replay` |
| `Out of Time` | `supports_phase_out_mass_removal_counters_template` | `mass_phase_out_duration_counters_replay` |
| `Power Artifact` | `supports_cost_reduction_static_aura_template` | `enchanted_artifact_activation_cost_reduction_replay` |
| `Reality Acid` | `supports_vanishing_sacrifice_trigger_removal_template` | `vanishing_sacrifice_enchanted_permanent_replay` |
| `Scroll of Fate` | `supports_manifest_from_hand_activated_ability_template` | `manifest_card_from_hand_replay` |
| `Stoke the Flames` | `supports_convoke_damage_template` | `convoke_damage_payment_replay` |
| `Submerge` | `supports_alternative_cost_library_bounce_template` | `alternative_cost_top_of_library_bounce_replay` |
| `Sudden Shock` | `supports_split_second_damage_template` | `split_second_damage_priority_lock_replay` |
| `Thorn of Amethyst` | `supports_static_noncreature_tax_template` | `static_noncreature_spell_tax_replay` |
| `Tragic Arrogance` | `supports_modal_mass_sacrifice_selection_template` | `per_player_permanent_type_choice_sacrifice_replay` |
| `Tyvar, Jubilant Brawler` | `supports_planeswalker_static_activated_graveyard_template` | `planeswalker_static_haste_and_graveyard_activation_replay` |

## Forensic Blocker

The run contains one high forensic finding and incomplete lineage counters:

- `forensic_rule_findings=5`
- `forensic_severity_counts={"high":1,"medium":2,"low":2}`
- `forensic_card_event_count=164`
- `forensic_lineage_status=incomplete`
- `forensic_card_id_present/missing=118/46`
- `forensic_semantic_hash_present/missing=118/46`
- `forensic_rule_logical_key_present/missing=160/4`

High finding:

| Seed | Turn | Event | Card | Finding | Required adjustment |
| --- | ---: | --- | --- | --- | --- |
| `63201744` | 1 | `spell_resolved` | `Veil of Summer` | Game event depended on heuristic source `functional_tags_json`. | Move the card/effect path into verified or active `card_battle_rules`, or block high-confidence learning with an explicit waiver. |

Medium related findings:

- `Veil of Summer` `spell_cast` also depended on `functional_tags_json`.
- `Reckless Barbarian` `spell_cast` also depended on `functional_tags_json`.

## Effect Coverage Residual Reading

The coverage gate is now `pass` because the residual audit accepted the
remaining residuals:

- `effect_coverage_residual_status=effect_coverage_residual_accepted`
- `raw_flag_total=539`
- `card_flag_rows=293`
- `raw_unaccepted_flags=[]`
- `unaccepted_card_flag_rows=0`

Accepted owner totals:

- `battle-effect-contract=151`
- `battle-heuristic-fallback=92`
- `battle-land-utility-contract=21`
- `battle-rule-review-queue=29`

Operational reading: accepted residual ownership is not the same thing as
runtime implementation. It only means these flags no longer block the coverage
gate while they have an owner/contract/waiver path.

## Documentation Drift

`docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md` is marked current in
`BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`, but its gate list still only
documents:

- `action_critic`
- `strategy_audit`
- `replay_decision_audit`
- `forensic_audit`
- `effect_coverage`

It does not document the current mandatory gates observed in the latest
`summary.json`: `focused_template_dispatch`, `unknown_template_backlog`,
`decision_trace_taxonomy` and `event_contract_static`. This can mislead future
agents into using an incomplete final-status contract.

## Register Updates

Open findings refreshed or added in
`docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`:

- `BV-011`: coverage residual is accepted but not runtime-complete proof.
- `BV-048`: focused template dispatch is now an official mandatory gate and
  still has 29 unready/unwaived cards.
- `BV-050`: forensic source lineage remains blocked on `Veil of Summer`.
- `BV-052`: gate matrix/status documentation is stale relative to current
  mandatory gates.

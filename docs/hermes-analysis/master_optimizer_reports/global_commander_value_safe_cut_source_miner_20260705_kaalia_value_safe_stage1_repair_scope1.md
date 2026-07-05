# Global Commander Value-Safe Cut Source Miner

- generated_at: `2026-07-05T22:25:39.686155+00:00`
- status: `value_safe_cut_source_hypotheses_ready_for_trace`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- hypothesis_count: `8`
- blocked_hypothesis_count: `80`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_usage_trace_for_new_cut_source_hypotheses`

## Target Cut Roles

- `haste_protection_silence`: `4`
- `mana_acceleration`: `1`
- `tutors_access`: `8`

## Fresh Cut-Source Hypotheses

| Card | Score | Roles | Reasons | Next Gate |
| --- | ---: | --- | --- | --- |
| `Biotransference` | 60 | `` | off_profile_or_unclassified_slot, no_runtime_cut_risk_flag, higher_curve_cut_pressure | `collect_usage_trace_for_new_cut_source_hypothesis` |
| `Maskwood Nexus` | 60 | `` | off_profile_or_unclassified_slot, no_runtime_cut_risk_flag, higher_curve_cut_pressure | `collect_usage_trace_for_new_cut_source_hypothesis` |
| `Sigarda's Aid` | 54 | `` | off_profile_or_unclassified_slot, no_runtime_cut_risk_flag | `collect_usage_trace_for_new_cut_source_hypothesis` |
| `Necromancy` | 38 | `reanimation_plan_b` | no_runtime_cut_risk_flag | `collect_usage_trace_for_new_cut_source_hypothesis` |
| `Necropotence` | 30 | `card_draw_selection, reanimation_plan_b` |  | `collect_usage_trace_for_new_cut_source_hypothesis` |
| `Trouble in Pairs` | 30 | `card_draw_selection, dedicated_win_conditions` | higher_curve_cut_pressure, format_staple_reviewable_needs_extra_trace | `collect_usage_trace_for_new_cut_source_hypothesis` |
| `Puresteel Paladin` | 24 | `card_draw_selection` | format_staple_reviewable_needs_extra_trace | `collect_usage_trace_for_new_cut_source_hypothesis` |
| `Sram, Senior Edificer` | 24 | `card_draw_selection` | format_staple_reviewable_needs_extra_trace | `collect_usage_trace_for_new_cut_source_hypothesis` |

## Blockers

- `hypotheses_require_trace_before_value_safe_reclassification`
- `candidate_copy_closed_until_value_safe_cut_pair_exists`

## Blocked Hypothesis Sample

- `Alicia Masters, Skilled Sculptor`: `already_stage_only_cut_source_requires_proof, forced_access_used_cut_blocks_reclassification, attack_window_cut_requires_same_lane_stage_proof`
- `Ancient Copper Dragon`: `protected_profile_role_angels_demons_dragons_payoffs`
- `Ancient Tomb`: `protected_profile_role_lands`
- `Angel of the Ruins`: `protected_profile_role_angels_demons_dragons_payoffs`
- `Anguished Unmaking`: `protected_profile_role_spot_interaction, contextual_staple_requires_stage_review`
- `Arcane Signet`: `already_stage_only_cut_source_requires_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Ardenn, Intrepid Archaeologist`: `attack_window_cut_requires_same_lane_stage_proof`
- `Arena of Glory`: `protected_profile_role_haste_protection_silence,lands`
- `Arid Mesa`: `protected_profile_role_lands, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Aurelia, the Law Above`: `protected_profile_role_angels_demons_dragons_payoffs,haste_protection_silence`
- `Avacyn, Angel of Hope`: `protected_profile_role_angels_demons_dragons_payoffs,haste_protection_silence`
- `Balefire Dragon`: `protected_profile_role_angels_demons_dragons_payoffs`

## Policy

- miner_boundary: Fresh hypotheses are not value-safe cuts until trace or same-lane proof is collected.
- protected_role_boundary: Protected commander lanes, lands, structural staples, contextual staples, and stage-only cuts remain blocked.
- battle_boundary: This miner does not run battle or open promotion.

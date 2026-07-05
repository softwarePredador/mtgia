# Lorehold Topdeck Sidecar Probe Evidence Miner

- Generated at: `2026-07-05T06:49:48Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_sidecar_probe_evidence_no_safe_cut_keep_607`
- Probe rows: `48`
- Safe-cut ready: `0`
- Matrix candidate rows eligible: `0`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Mana model ready pairs: `2`
- Mana model exact rejected pairs: `2`
- Mana model eligible pairs: `0`
- Mana route status: `mana_route_closed_by_exact_decisions`
- Recommended next action: `collect_new_mana_evidence_or_topdeck_floor_traces_before_any_matrix_row`

## Source Reports

- `cut_model_planner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json`
- `exposure_profile`: `docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260704_role_tag_repair_deck607.json`
- `mana_base_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_safe_cut_model_20260705_current.json`
- `mana_decision_integrator`: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json`

## Status Summary

- status_counts: `{"blocked_exposed_topdeck_role_probe": 20, "blocked_generic_mana_probe_not_pair_safe": 28}`
- blocker_counts: `{"basic_land_floor_not_safe_from_probe": 14, "colored_source_floor_requires_pair_model": 7, "fast_mana_utility_land_not_safe_from_probe": 7, "mana_source_floor_equivalence_required": 28, "miracle_topdeck_floor_equivalence_required": 20, "probe_cut_has_material_exposure": 20, "probe_cut_role_not_low_impact:draw_filter_value": 15, "probe_cut_role_not_low_impact:recursion_engine": 5, "requires_exposure_trace_before_safe_cut": 48, "safe_cut_miner_zero_current_ready": 48, "structural_floor_equivalence_required": 28, "use_dedicated_mana_base_model_before_generic_probe": 28}`

## Probe Evidence Rows

| Add | Probe cut | Status | Exposure | Role | Next action |
| --- | --- | --- | ---: | --- | --- |
| Boros Garrison | `Ancient Tomb` | `blocked_generic_mana_probe_not_pair_safe` | 39 | `tutor_access` | `mine mana source equivalence or use dedicated ready pair instead` |
| Boros Garrison | `Battlefield Forge` | `blocked_generic_mana_probe_not_pair_safe` | 15 | `ramp_engine` | `mine mana source equivalence or use dedicated ready pair instead` |
| Boros Garrison | `Mountain // Mountain` | `blocked_generic_mana_probe_not_pair_safe` | 402 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Boros Garrison | `Plains // Plains` | `blocked_generic_mana_probe_not_pair_safe` | 244 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Boseiju, Who Shelters All | `Ancient Tomb` | `blocked_generic_mana_probe_not_pair_safe` | 39 | `tutor_access` | `mine mana source equivalence or use dedicated ready pair instead` |
| Boseiju, Who Shelters All | `Battlefield Forge` | `blocked_generic_mana_probe_not_pair_safe` | 15 | `ramp_engine` | `mine mana source equivalence or use dedicated ready pair instead` |
| Boseiju, Who Shelters All | `Mountain // Mountain` | `blocked_generic_mana_probe_not_pair_safe` | 402 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Boseiju, Who Shelters All | `Plains // Plains` | `blocked_generic_mana_probe_not_pair_safe` | 244 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Cavern of Souls | `Ancient Tomb` | `blocked_generic_mana_probe_not_pair_safe` | 39 | `tutor_access` | `mine mana source equivalence or use dedicated ready pair instead` |
| Cavern of Souls | `Battlefield Forge` | `blocked_generic_mana_probe_not_pair_safe` | 15 | `ramp_engine` | `mine mana source equivalence or use dedicated ready pair instead` |
| Cavern of Souls | `Mountain // Mountain` | `blocked_generic_mana_probe_not_pair_safe` | 402 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Cavern of Souls | `Plains // Plains` | `blocked_generic_mana_probe_not_pair_safe` | 244 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Clifftop Retreat | `Ancient Tomb` | `blocked_generic_mana_probe_not_pair_safe` | 39 | `tutor_access` | `mine mana source equivalence or use dedicated ready pair instead` |
| Clifftop Retreat | `Battlefield Forge` | `blocked_generic_mana_probe_not_pair_safe` | 15 | `ramp_engine` | `mine mana source equivalence or use dedicated ready pair instead` |
| Clifftop Retreat | `Mountain // Mountain` | `blocked_generic_mana_probe_not_pair_safe` | 402 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Clifftop Retreat | `Plains // Plains` | `blocked_generic_mana_probe_not_pair_safe` | 244 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Plateau | `Ancient Tomb` | `blocked_generic_mana_probe_not_pair_safe` | 39 | `tutor_access` | `mine mana source equivalence or use dedicated ready pair instead` |
| Plateau | `Battlefield Forge` | `blocked_generic_mana_probe_not_pair_safe` | 15 | `ramp_engine` | `mine mana source equivalence or use dedicated ready pair instead` |
| Plateau | `Mountain // Mountain` | `blocked_generic_mana_probe_not_pair_safe` | 402 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Plateau | `Plains // Plains` | `blocked_generic_mana_probe_not_pair_safe` | 244 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Rugged Prairie | `Ancient Tomb` | `blocked_generic_mana_probe_not_pair_safe` | 39 | `tutor_access` | `mine mana source equivalence or use dedicated ready pair instead` |
| Rugged Prairie | `Battlefield Forge` | `blocked_generic_mana_probe_not_pair_safe` | 15 | `ramp_engine` | `mine mana source equivalence or use dedicated ready pair instead` |
| Rugged Prairie | `Mountain // Mountain` | `blocked_generic_mana_probe_not_pair_safe` | 402 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Rugged Prairie | `Plains // Plains` | `blocked_generic_mana_probe_not_pair_safe` | 244 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Sundown Pass | `Ancient Tomb` | `blocked_generic_mana_probe_not_pair_safe` | 39 | `tutor_access` | `mine mana source equivalence or use dedicated ready pair instead` |
| Sundown Pass | `Battlefield Forge` | `blocked_generic_mana_probe_not_pair_safe` | 15 | `ramp_engine` | `mine mana source equivalence or use dedicated ready pair instead` |
| Sundown Pass | `Mountain // Mountain` | `blocked_generic_mana_probe_not_pair_safe` | 402 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Sundown Pass | `Plains // Plains` | `blocked_generic_mana_probe_not_pair_safe` | 244 | `runtime_ready_unexposed` | `mine mana source equivalence or use dedicated ready pair instead` |
| Dragon's Rage Channeler | `Artist's Talent` | `blocked_exposed_topdeck_role_probe` | 535 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Dragon's Rage Channeler | `Improvisation Capstone` | `blocked_exposed_topdeck_role_probe` | 59 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Dragon's Rage Channeler | `Pinnacle Monk // Mystic Peak` | `blocked_exposed_topdeck_role_probe` | 8 | `recursion_engine` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Dragon's Rage Channeler | `Reforge the Soul` | `blocked_exposed_topdeck_role_probe` | 23 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Galvanoth | `Artist's Talent` | `blocked_exposed_topdeck_role_probe` | 535 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Galvanoth | `Improvisation Capstone` | `blocked_exposed_topdeck_role_probe` | 59 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Galvanoth | `Pinnacle Monk // Mystic Peak` | `blocked_exposed_topdeck_role_probe` | 8 | `recursion_engine` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Galvanoth | `Reforge the Soul` | `blocked_exposed_topdeck_role_probe` | 23 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Penance | `Artist's Talent` | `blocked_exposed_topdeck_role_probe` | 535 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Penance | `Improvisation Capstone` | `blocked_exposed_topdeck_role_probe` | 59 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Penance | `Pinnacle Monk // Mystic Peak` | `blocked_exposed_topdeck_role_probe` | 8 | `recursion_engine` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Penance | `Reforge the Soul` | `blocked_exposed_topdeck_role_probe` | 23 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Valakut Awakening // Valakut Stoneforge | `Artist's Talent` | `blocked_exposed_topdeck_role_probe` | 535 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Valakut Awakening // Valakut Stoneforge | `Improvisation Capstone` | `blocked_exposed_topdeck_role_probe` | 59 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Valakut Awakening // Valakut Stoneforge | `Pinnacle Monk // Mystic Peak` | `blocked_exposed_topdeck_role_probe` | 8 | `recursion_engine` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Valakut Awakening // Valakut Stoneforge | `Reforge the Soul` | `blocked_exposed_topdeck_role_probe` | 23 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Wheel of Fortune | `Artist's Talent` | `blocked_exposed_topdeck_role_probe` | 535 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Wheel of Fortune | `Improvisation Capstone` | `blocked_exposed_topdeck_role_probe` | 59 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Wheel of Fortune | `Pinnacle Monk // Mystic Peak` | `blocked_exposed_topdeck_role_probe` | 8 | `recursion_engine` | `do not turn this probe into a cut without proving redundant low-impact exposure` |
| Wheel of Fortune | `Reforge the Soul` | `blocked_exposed_topdeck_role_probe` | 23 | `draw_filter_value` | `do not turn this probe into a cut without proving redundant low-impact exposure` |

## Dedicated Mana Model Ready Pairs

| Add | Cut | Score | Status | Reasons |
| --- | --- | ---: | --- | --- |
| `Plateau` | `Radiant Summit` | 52 | `model_ready_for_candidate_materialization` | tempo_upgrade_preserves_color_and_fetch_target_type |
| `Plateau` | `Turbulent Steppe` | 52 | `model_ready_for_candidate_materialization` | tempo_upgrade_preserves_color_and_fetch_target_type |

## Dedicated Mana Decision Integrator

| Add | Cut | Learning Status | Decision | Next Action |
| --- | --- | --- | --- | --- |
| `Plateau` | `Radiant Summit` | `blocked_exact_tested_decision` | `reject_promotion_keep_607_current_baseline` | `do_not_retest_exact_pair_without_new_mana_trace_evidence` |
| `Plateau` | `Turbulent Steppe` | `blocked_exact_tested_decision` | `reject_promotion_keep_607_current_baseline` | `do_not_retest_exact_pair_without_new_mana_trace_evidence` |

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- safe_cut_ready_now: `false`
- matrix_candidate_rows_ready: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: Current probe cuts have real exposure or structural mana-floor risk. The dedicated Plateau mana pairs were already decision-filtered and are not currently eligible for another materialization route.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_convert exposed topdeck probes into cuts
  - do_not_retest exact Plateau pairs without new mana trace evidence
  - require matrix, trace, and equal battle gates before any deck change

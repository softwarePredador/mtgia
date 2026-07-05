# Lorehold Named Same-Lane Cut Frontier

- Generated at: `2026-07-05T07:45:31Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `named_same_lane_cut_frontier_closed_no_safe_cut_keep_607`
- Probe rows: `48`
- Topdeck frontier targets: `5`
- Topdeck matrix-ready probes: `0`
- Mana generic probes: `28`
- Mana eligible pairs: `0`
- Mana exact rejected pairs: `2`
- Structure matrix contract allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `collect_new_topdeck_floor_or_mana_trace_evidence_before_structure_matrix`

## Source Reports

- `mana_decision_integrator`: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json`
- `nonanchor_cut_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json`
- `probe_evidence`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json`
- `sidecar_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_access_first_sidecar_shell_contract_20260705_current.json`

## Structure Matrix Requirements

- `named_add_and_named_cut_pair`
- `safe_cut_ready_now_or_eligible_mana_pair_after_decision_filter`
- `no_exact_prior_reject_for_the_add_cut_signature`
- `protected_607_anchor_not_cut_without_same_lane_battle_proof`
- `topdeck_miracle_or_mana_floor_equivalence_declared`
- `direct_trace_plan_for_added_card_and_cut_floor`
- `same_seed_equal_gate_stays_closed_until_structure_matrix_passes`

## Topdeck Frontier

| Add | Status | Non-anchor status | Ready | Lowest-exposure probe cuts |
| --- | --- | --- | ---: | --- |
| Dragon's Rage Channeler | `blocked_exposed_or_floor_sensitive_topdeck_cuts` | `clean_prior_target_blocked_no_nonanchor_cut` | `0` | Pinnacle Monk // Mystic Peak (8), Reforge the Soul (23), Improvisation Capstone (59) |
| Galvanoth | `blocked_exposed_or_floor_sensitive_topdeck_cuts` | `prior_reject_target_blocked_no_nonanchor_cut` | `0` | Pinnacle Monk // Mystic Peak (8), Reforge the Soul (23), Improvisation Capstone (59) |
| Penance | `blocked_exposed_or_floor_sensitive_topdeck_cuts` | `prior_reject_target_blocked_no_nonanchor_cut` | `0` | Pinnacle Monk // Mystic Peak (8), Reforge the Soul (23), Improvisation Capstone (59) |
| Valakut Awakening // Valakut Stoneforge | `blocked_exposed_or_floor_sensitive_topdeck_cuts` | `prior_reject_target_blocked_no_nonanchor_cut` | `0` | Pinnacle Monk // Mystic Peak (8), Reforge the Soul (23), Improvisation Capstone (59) |
| Wheel of Fortune | `blocked_exposed_or_floor_sensitive_topdeck_cuts` | `prior_reject_target_blocked_no_nonanchor_cut` | `0` | Pinnacle Monk // Mystic Peak (8), Reforge the Soul (23), Improvisation Capstone (59) |

## Mana Frontier

- frontier_status: `mana_route_closed_by_exact_decisions`
- generic_probe_count: `28`
- eligible_pair_count: `0`
- exact_rejected_pair_count: `2`
- exact_rejected_pairs:
  - `Plateau` over `Radiant Summit`: `reject_promotion_keep_607_current_baseline`
  - `Plateau` over `Turbulent Steppe`: `reject_promotion_keep_607_current_baseline`

## Blocked Staples

- `Mana Vault` in `early_mana_and_spell_chain_conversion`: `learning_only_not_607_change`
- `The One Ring` in `draw_and_resource_density`: `learning_only_not_607_change`

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- structure_matrix_contract_allowed_now: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: All current named same-lane topdeck and mana cut probes are blocked by material exposure, mana-floor risk, non-anchor cut absence, or exact rejected Plateau pair evidence.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_decks_from_review_only_cut_probes
  - do_not_retest_exact_plateau_pairs_without_new_mana_trace_evidence
  - collect new low-exposure topdeck cut evidence or a distinct mana trace before structure matrix

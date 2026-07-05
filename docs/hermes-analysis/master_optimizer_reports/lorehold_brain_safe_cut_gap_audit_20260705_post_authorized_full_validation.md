# Lorehold Brain in a Jar Safe-Cut Gap Audit

- Generated at: `2026-07-05T11:40:41Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `brain_safe_cut_gap_no_seed_safe_cut_keep_607`
- Brain PG package status: `prepared_read_only_pending_apply_approval`
- Apply ready for manual review: `true`
- Apply executed by this script: `false`
- PostgreSQL rule active confirmed now: `true`
- Apply confirmed outside package script: `true`
- Brain PG package route governed: `true`
- Runtime preflight status: `brain_in_a_jar_runtime_cut_preflight_blocked_no_safe_cut_keep_607`
- Runtime route gate valid: `true`
- Runtime route planner status: `miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607`
- Runtime candidate queue governed: `true`
- Runtime candidate queue next-shell status: `next_shell_cut_path_closed_route_miracle_access_first_keep_607`
- Runtime candidate queue matrix-route governed: `true`
- Active Brain rule count: `1`
- Safe same-lane cuts: `0`
- Blocked same-lane cuts: `9`
- External signal classification: `low_context_signal_not_staple`
- Brain EDHREC global inclusion: `0.03%`
- Brain EDHREC Lorehold inclusion: `0.4%`
- Lowest-risk diagnostic cut candidate: `Molecule Man`
- Diagnostic cut allowed now: `false`
- Matrix scoring allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `mine_named_topdeck_engine_seed_safe_cut_before_matrix_scoring`

## Source Reports

- `brain_pg_package`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_post_authorized_full_validation.json`
- `brain_preflight`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_post_authorized_full_validation.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## External Research Snapshot

- Brain card page: https://edhrec.com/cards/brain-in-a-jar
- Brain adoption: `0.03%` global (`2490` / `9280000` decks), `0.4%` in Lorehold (`35` / `9030` decks).
- Lorehold article: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
- Lorehold topdeck anchors: `Library of Leng, Scroll Rack, Sensei's Divining Top`
- Spellslinger guide: https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander
- Imported package rule: A streamlined primary plan can add one or two packages only when they still synergize with Plan A.

## Gap Categories

- `never_cut_commander`: `1`
- `never_cut_mana_base`: `1`
- `prior_rejected_protected_slot`: `2`
- `protected_core_topdeck_engine`: `3`
- `protected_structural_floor`: `2`

## Same-Lane Cut Rows

| Cut | Category | Exposure | Status | Unlock requirements |
| --- | --- | ---: | --- | --- |
| Lorehold, the Historian | `never_cut_commander` | 5768 | `blocked_current_607_hard_stop` | cannot_unlock_under_current_607_contract |
| Urza's Saga | `never_cut_mana_base` | 2656 | `blocked_current_607_hard_stop` | cannot_unlock_under_current_607_contract |
| Molecule Man | `prior_rejected_protected_slot` | 102 | `blocked_current_607_hard_stop` | named_same_lane_seed_safe_cut_evidence, new_trace_evidence_reverses_prior_rejected_cut, refresh_candidate_queue_and_strategy_matrix, only_after_matrix_run_materialize_candidate_for_equal_battle_gate |
| Land Tax | `prior_rejected_protected_slot` | 3449 | `blocked_current_607_hard_stop` | named_same_lane_seed_safe_cut_evidence, new_trace_evidence_reverses_prior_rejected_cut, refresh_candidate_queue_and_strategy_matrix, only_after_matrix_run_materialize_candidate_for_equal_battle_gate |
| Library of Leng | `protected_core_topdeck_engine` | 855 | `blocked_current_607_hard_stop` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_topdeck_miracle_anchor_role, refresh_candidate_queue_and_strategy_matrix, only_after_matrix_run_materialize_candidate_for_equal_battle_gate |
| Scroll Rack | `protected_core_topdeck_engine` | 2957 | `blocked_current_607_hard_stop` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_topdeck_miracle_anchor_role, refresh_candidate_queue_and_strategy_matrix, only_after_matrix_run_materialize_candidate_for_equal_battle_gate |
| Sensei's Divining Top | `protected_core_topdeck_engine` | 3816 | `blocked_current_607_hard_stop` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_topdeck_miracle_anchor_role, refresh_candidate_queue_and_strategy_matrix, only_after_matrix_run_materialize_candidate_for_equal_battle_gate |
| The Scarlet Witch | `protected_structural_floor` | 362 | `blocked_current_607_hard_stop` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_mana_or_curve_floor, refresh_candidate_queue_and_strategy_matrix, only_after_matrix_run_materialize_candidate_for_equal_battle_gate |
| The Mind Stone | `protected_structural_floor` | 2312 | `blocked_current_607_hard_stop` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_mana_or_curve_floor, refresh_candidate_queue_and_strategy_matrix, only_after_matrix_run_materialize_candidate_for_equal_battle_gate |

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- external_signal_is_staple_proof: `false`
- named_safe_cut_required_before_scoring: `true`
- active_rule_required_before_battle: `false`
- pg_apply_requires_explicit_approval: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: Brain in a Jar now has an active PostgreSQL-backed runtime rule, but its current external adoption is low-context and every protected-607 same-lane slot remains blocked. Deck 607 therefore remains the Lorehold champion until a named seed-safe cut and matrix score exist.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_brain_candidate_deck
  - do_not_run_natural_battle_for_brain_from_this_audit
  - mine_named_topdeck_engine_seed_safe_cut_before_matrix_scoring
  - find_or_generate_named_same_lane_cut_evidence_before_matrix_scoring
  - after_rule_and_cut_exist_rerun_brain_preflight_then_candidate_queue

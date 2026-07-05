# Lorehold Pressure-Safe Cut-Pool Resolver

- Generated at: `2026-07-05T03:33:27Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Contract report: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json`
- Seed-safe cut report: `docs/hermes-analysis/master_optimizer_reports/lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json`
- Decision status: `no_seed_safe_cut_plan_no_diagnostic_tradeoff_current_607`
- Gate-ready cut count: `0`
- Gate-ready plan complete: `false`
- Diagnostic tradeoff plan available: `false`
- Natural battle gate allowed now: `false`
- Contract natural gate-ready from hypothesis queue: `0`
- Contract blocks natural gate: `true`
- Recommended next action: `build_smaller_pressure_package_or_new_cut_safety_model_before_any_battle`

## Primary Adds

- Monastery Mentor
- Young Pyromancer
- Guttersnipe
- Storm-Kiln Artist

## Gate-Ready Cut Plan

- None.

## Diagnostic-Only Tradeoff Plan

- None.

## Diagnostic Blocker Counts

`{"commander_never_cut": 1, "cut_is_early_mana_floor_support": 14, "cut_is_miracle_core_big_spell": 25, "cut_is_protection_shell": 14, "diagnostic_lane_excluded:big_spell_value": 2, "diagnostic_lane_excluded:commander": 1, "diagnostic_lane_excluded:draw": 6, "diagnostic_lane_excluded:early_mana": 18, "diagnostic_lane_excluded:graveyard_recursion": 1, "diagnostic_lane_excluded:hand_filter": 1, "diagnostic_lane_excluded:mana_base": 28, "diagnostic_lane_excluded:protection": 13, "diagnostic_status_excluded:blocked_by_cut_safety": 8, "diagnostic_status_excluded:blocked_by_prior_rejection": 24, "diagnostic_status_excluded:measured_high_cut_exposure": 7, "diagnostic_status_excluded:never_cut": 29, "diagnostic_status_excluded:same_lane_only": 2, "diagnostic_status_excluded:structural_dependency": 24, "early_mana_floor_support": 18, "mana_base_never_cut": 28, "manual_review_cut_safety_block": 8, "measured_high_cut_exposure": 34, "miracle_or_finisher_core": 24, "never_cut_lane": 29, "never_cut_or_mana_base": 29, "prior_rejected_cut": 37, "prior_rejected_cut_slot": 24, "prior_rejected_signature": 4, "protected_cut": 22, "protection_shell": 14, "same_lane_only_requires_concrete_same_lane_add": 2, "structural_dependency": 24}`

## Contract Gate Context

`{"contract_blocks_natural_gate": true, "contract_decision_status": "preflight_pass_cut_pool_required", "contract_diagnostic_only": true, "contract_diagnostic_status": "pressure_safe_diagnostic_contract_ready_no_battle", "contract_natural_gate_ready_from_hypothesis_queue": 0, "primary_package_matched_in_hypothesis_queue": 1, "primary_package_missing_from_hypothesis_queue": 3}`

## Hard Stop Rules

- `no_natural_gate_when_queue_has_zero_ready_candidates`: if natural_gate_ready_from_hypothesis_queue == 0, diagnostic_only_keep_607_protected.
- `protected_anchor_generic_cuts_forbidden`: if cut plan contains Molecule Man, Bender's Waterskin, Creative Technique, or another protected anchor, reject_cut_plan_before_variant_generation.
- `do_not_repeat_storm_kiln_generic_mana_swap`: if Storm-Kiln Artist is tested as a generic Arcane Signet or Bender's Waterskin replacement without a new trace hypothesis, reject_as_prior_reject_retest.
- `winota_fast_pressure_floor_required`: if test plan omits Winota or fast-pressure regression checks, reject_battle_gate_plan.
- `card_level_claims_need_direct_events`: if pressure cards lack draw, cast, trigger, or use events in the candidate traces, allow_learning_only_no_promotion_claim.

## Method Notes

- Gate-ready cuts require the seed-safe report to provide four unblocked cut slots.
- Diagnostic tradeoff cuts are not promotion evidence; they require reviewable noncore cut status and cannot use structural dependencies or protected anchors.
- Deck 607 remains unchanged. Any diagnostic deck must be a separate copy and must not be promoted from forced or diagnostic evidence alone.
- If the pressure contract reports zero natural gate-ready hypotheses, this resolver cannot open a natural battle gate.

# Lorehold Guttersnipe + Storm-Kiln Hypothesis Contract

- Generated at: `2026-07-05T04:07:42Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `hypothesis_contract_written_blocked_no_named_safe_cuts`
- Target route: `guttersnipe_storm_kiln_engine_preserving_pair`
- Target adds: `Guttersnipe, Storm-Kiln Artist`
- Required cuts: `2`
- Available named seed-safe cuts: `0`
- Cut shortage: `2`
- Natural battle gate allowed now: `false`
- Recommended next action: `mine_or_create_cut_evidence_for_two_named_same_lane_nonanchor_slots`

## Source Reports

- `closing_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_trace_miner_20260704_role_tag_repair.json`
- `engine_router`: `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_pressure_conversion_router_20260705_current_relearn.json`
- `miracle_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_trace_failure_miner_20260704_current.json`
- `package_router`: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_package_size_router_20260705_current_relearn.json`
- `seed_safe_cut_report`: `docs/hermes-analysis/master_optimizer_reports/lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json`
- `trace_cut_evidence_expander`: `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json`

## Cut Status

### Named Seed-Safe Cuts

- None.

### Same-Lane Only Slots Not Seed-Safe

- `Bender's Waterskin` lane `early_mana` blockers `cut_is_early_mana_floor_support, cut_not_flex_decision, cut_safety_not_seed_safe, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.
- `Creative Technique` lane `big_spell_value` blockers `cut_is_miracle_core_big_spell, cut_safety_not_seed_safe, manual_status_not_seed_safe, miracle_or_finisher_core, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.

## Event Requirements

- `guttersnipe_direct_spell_damage`: At least one candidate win or protected equal-gate game must show Guttersnipe converting instant/sorcery casts into direct opponent damage.
- `storm_kiln_treasure_conversion`: Storm-Kiln must create Treasures from instant/sorcery casts or copies, and those Treasures must connect to spell-chain or survival value.
- `no_proxy_win_without_new_cards`: A win carried only by existing 607 topdeck/miracle cards is not proof for Guttersnipe or Storm-Kiln.

## Engine Floor Requirements

- `same_seed_same_opponent_matrix_against_protected_deck_607`
- `no_regression_in_winota_fast_pressure_slice`
- `no_regression_in_miracle_cast_and_topdeck_manipulation_counts`
- `no_regression_in_lorehold_spell_cast_and_upkeep_rummage_counts`
- `preserve_early_mana_floor_and_protection_shell`
- `preserve_approach_conversion_or_explain_replacement_win_path`

## Hard Stop Cut Classes

- `commander`
- `mana_base`
- `early_mana`
- `protection`
- `topdeck_miracle_setup`
- `miracle_or_finisher_core`
- `measured_high_cut_exposure`
- `prior_rejected_cut`
- `structural_dependency`
- `protected_cut`

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: Guttersnipe plus Storm-Kiln is the best next learning route, but it requires two named seed-safe cuts and the current evidence has zero.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_run_natural_battle_until_two_named_safe_cuts_exist
  - mine low-exposure non-anchor cut evidence before any package build
  - require direct Guttersnipe damage and Storm-Kiln Treasure events in future tests
  - preserve topdeck, miracle, mana, protection, and Winota fast-pressure floors

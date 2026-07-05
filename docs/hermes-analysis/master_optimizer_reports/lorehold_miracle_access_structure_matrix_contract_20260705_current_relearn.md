# Lorehold Miracle Access Structure Matrix Contract

- Generated at: `2026-07-05T04:33:06Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `miracle_access_structure_matrix_template_ready_no_candidate_no_battle`
- Selected contract: `miracle_access_first_shell_contract`
- Matrix cells: `6`
- Candidate rows: `0`
- Matrix scoring allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Named seed-safe cuts: `0`
- Blocking hard gates: `3`
- Recommended next action: `declare_candidate_rows_with_named_same_lane_cuts_before_scoring`

## Source Reports

- `closing_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_trace_miner_20260704_role_tag_repair.json`
- `contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_first_shell_contract_20260705_current_relearn.json`
- `cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## Matrix Cells

| Cell | Lane | Weight | Metrics | Rule |
| --- | --- | ---: | --- | --- |
| topdeck_miracle_access | `topdeck_miracle_setup` | 30 | `miracle_cast, topdeck_manipulation_activated` | candidate_must_meet_or_exceed_607_floor |
| turn_cycle_miracle_mana | `early_mana_and_opponent_turn_mana` | 20 | `static_cost_reduction_total, lorehold_cost_paid` | candidate_must_not_reduce_opponent_turn_miracle_mana |
| spell_volume_density | `instant_sorcery_density` | 15 | `lorehold_spell_cast` | candidate_must_preserve_spell_volume_and_non_dud_first_draws |
| approach_finisher_conversion | `deterministic_finisher` | 15 | `approach_conversion, miracle_cast:Approach of the Second Sun` | candidate_must_not_make_approach_conversion_disappear |
| pressure_survival_floor | `protection_window_and_pressure_absorber` | 10 | `Winota fast-pressure slice, candidate_died_before_closing_window` | candidate_must_not_regress_fast_pressure_slice |
| same_lane_cut_safety | `same_lane_cuts` | 25 | `named_seed_safe_cut_count, cut_shortage` | each_add_must_have_same_lane_named_cut_or_documented_shell_fork |

## Hard Gates

| Gate | Passed | Blocks Scoring |
| --- | ---: | ---: |
| `contract_written` | `true` | `false` |
| `no_deck_607_mutation` | `true` | `false` |
| `no_database_writes` | `true` | `false` |
| `candidate_rows_declared` | `false` | `true` |
| `named_same_lane_cuts_exist` | `false` | `true` |
| `aggregate_blockers_cleared_or_explained` | `false` | `true` |

## Candidate Row Schema

- `candidate_key`
- `add_card`
- `cut_card`
- `lane`
- `same_lane_cut_reason`
- `protected_anchor_impact`
- `expected_metric_lift`
- `rule_runtime_status`
- `source_provenance`
- `floor_risk`

## Materialization Policy

- `do_not_materialize_a_deck_from_template_only`
- `candidate_rows_must_name_adds_and_cuts_first`
- `any generated list stays lab-only until equal gate beats 607`
- `battle remains closed until matrix score and trace floors pass`

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- matrix_scoring_allowed_now: `false`
- candidate_deck_materialization_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: The matrix is defined, but scoring/materialization needs named candidate rows and hard-gate clearance first.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_generate_a_deck_from_template_only
  - declare candidate add/cut rows before scoring
  - require named same-lane cuts and miracle/topdeck floor preservation
  - keep battle closed until matrix and trace gates pass

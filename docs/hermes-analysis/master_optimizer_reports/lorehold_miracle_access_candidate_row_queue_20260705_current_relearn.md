# Lorehold Miracle Access Candidate Row Queue

- Generated at: `2026-07-05T04:37:27Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607`
- Source candidates: `5`
- Scoreable candidate rows: `0`
- Blocked candidate rows: `5`
- Named seed-safe cuts: `0`
- Matrix scoring allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `resolve_runtime_and_named_same_lane_cut_before_matrix_scoring`

## Source Reports

- `cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json`
- `matrix`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.json`
- `post_identity`: `docs/hermes-analysis/master_optimizer_reports/lorehold_post_identity_queue_split_20260705_current.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## Scoreable Candidate Rows

- None.

## Blocked Candidate Rows

| Add | Lane | Matrix Cells | Blockers |
| --- | --- | --- | --- |
| Brain in a Jar | `topdeck_miracle_access` | `topdeck_miracle_access, turn_cycle_miracle_mana` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Entreat the Angels | `miracle_finisher` | `approach_finisher_conversion, topdeck_miracle_access` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Haze of Rage | `storm_combo_pressure` | `pressure_survival_floor` | `combo_runtime_required, matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Burning Prophet | `spell_scry_pressure` | `spell_volume_density, pressure_survival_floor` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |
| Inti, Seneschal of the Sun | `rummage_pressure_access` | `topdeck_miracle_access, pressure_survival_floor` | `matrix_contract_blockers_not_cleared, named_safe_cut_missing, verified_battle_rule_missing` |

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- matrix_scoring_allowed_now: `false`
- candidate_deck_materialization_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: Post-identity candidates exist, but each current miracle-access row is blocked by runtime, named cut, or uncleared matrix-contract gates.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_candidate_deck_from_blocked_rows
  - resolve verified runtime for top-priority rows
  - find named same-lane non-anchor cuts before scoring
  - keep battle closed until matrix scoring and trace floors pass

# Lorehold Topdeck Floor Trace Target Contract

- Generated at: `2026-07-05T07:00:57Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_floor_trace_contract_written_no_deck_action_keep_607`
- Trace contract ready: `true`
- Target card count: `5`
- Safe-cut ready: `0`
- Matrix-eligible rows: `0`
- Forced access allowed: `false`
- Structure matrix allowed: `false`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Recommended next action: `collect_trace_floor_evidence_for_targets_before_matrix_or_sidecar`

## Source Reports

- `candidate_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_candidate_queue_20260705_current.json`
- `frontier`: `docs/hermes-analysis/master_optimizer_reports/lorehold_learning_frontier_after_probe_closure_20260705_current.json`
- `probe_evidence`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json`

## Protected Anchors

- `Lorehold, the Historian`
- `Sensei's Divining Top`
- `Scroll Rack`
- `Library of Leng`
- `Land Tax`
- `Bender's Waterskin`
- `Victory Chimes`
- `The Mind Stone`
- `Approach of the Second Sun`

## Floor Metrics

| Metric | Floor Rule | Why |
| --- | --- | --- |
| `miracle_cast` | `meet_or_exceed_current_607_same_seed_floor` | The candidate cannot reduce Lorehold's primary miracle window. |
| `topdeck_manipulation_activated` | `meet_or_exceed_current_607_same_seed_floor` | The candidate must preserve active top-library control. |
| `lorehold_upkeep_rummage` | `meet_or_exceed_current_607_same_seed_floor` | Lorehold's opponent-turn discard/draw setup is the engine timing. |
| `lorehold_spell_cast` | `no_material_regression_against_607` | Topdeck access is only useful if it keeps spell-chain volume intact. |
| `static_cost_reduction_total` | `no_material_regression_against_607` | Cost reduction is part of converting the miracle window into action. |
| `Winota_fast_pressure_slice` | `tie_or_improve_current_607_before_promotion` | Prior positive-looking packages failed because fast pressure regressed. |

## Target Cards

| Card | Contract Status | Trace Allowed | Matrix Allowed | Materialization Allowed | Expected Lift |
| --- | --- | --- | --- | --- | --- |
| `Penance` | `trace_target_only_not_matrix_row` | `true` | `false` | `false` | miracle_cast_and_topdeck_manipulation_floor_lift |
| `Galvanoth` | `trace_target_only_not_matrix_row` | `true` | `false` | `false` | miracle_cast_and_topdeck_manipulation_floor_lift |
| `Dragon's Rage Channeler` | `trace_target_only_not_matrix_row` | `true` | `false` | `false` | miracle_cast_and_topdeck_manipulation_floor_lift |
| `Valakut Awakening // Valakut Stoneforge` | `trace_target_only_not_matrix_row` | `true` | `false` | `false` | miracle_cast_and_topdeck_manipulation_floor_lift |
| `Wheel of Fortune` | `trace_target_only_not_matrix_row` | `true` | `false` | `false` | miracle_cast_and_topdeck_manipulation_floor_lift |

## Staple Policy

- `Mana Vault`: `blocked_until_same_lane_nonanchor_cut_and_no_topdeck_floor_regression`
- `The One Ring`: `blocked_until_same_lane_draw_value_cut_and_fast_pressure_guard`

## Decision

- keep_607_as_protected_baseline: `true`
- allow_deck_mutation_now: `false`
- allow_candidate_materialization_now: `false`
- allow_forced_access_now: `false`
- allow_structure_matrix_now: `false`
- allow_natural_battle_gate_now: `false`
- promotion_allowed: `false`
- reason: The current queue has topdeck target cards but no safe cut or matrix row. The only allowed progress is to collect trace-floor evidence as learning.
- next_actions:
  - `collect_trace_floor_evidence_for_targets_before_matrix_or_sidecar`
  - `do_not_convert_trace_targets_into_deck_changes`
  - `do_not_route pressure or spell-chain followups until topdeck floors pass`

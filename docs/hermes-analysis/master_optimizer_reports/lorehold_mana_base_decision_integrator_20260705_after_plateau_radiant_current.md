# Lorehold Mana Base Decision Integrator

- generated_at: `2026-07-05T00:41:35Z`
- status: `mana_base_next_diagnostic_pair_available`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- safe_model_ready_pair_count: `2`
- exact_rejected_pair_count: `1`
- eligible_model_ready_pair_count: `1`
- promotion_allowed: `false`
- allow_natural_gate_now: `false`

## Annotated Model-Ready Pairs

| Status | Score | Add | Cut | Decision | Next Action |
| --- | ---: | --- | --- | --- | --- |
| `blocked_exact_tested_decision` | `52` | `Plateau` | `Radiant Summit` | `reject_promotion_keep_607_current_baseline` | `do_not_retest_exact_pair_without_new_mana_trace_evidence` |
| `eligible_for_materialization_after_prior_decision_filter` | `52` | `Plateau` | `Turbulent Steppe` | `-` | `materialize_only_if_cut_condition_is_materially_different_from_rejected_pair` |

## Best Next Pair

- pair: `+Plateau / -Turbulent Steppe`
- next_action: `materialize_only_if_cut_condition_is_materially_different_from_rejected_pair`
- same_added_card_prior_rejects: `[{"blockers": ["forced_opening_hand_diagnostic_lost_to_607", "natural_smoke_did_not_access_plateau", "natural_smoke_lost_to_607"], "cut": "Radiant Summit", "report": "docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_radiant_decision_20260705_current.json", "status": "reject_promotion_keep_607_current_baseline"}]`
- cut_oracle_text: `({T}: Add {R} or {W}.)
This land enters tapped unless your opponents control eight or more lands.`

## Decision

- current_best_baseline: `deck_607`
- promotion_allowed: `false`
- reason: Tested mana-base pairs must be fed back into the safe-cut model. An exact rejected pair is blocked, but a different land with a different ETB condition is not inferred as accepted or rejected until it gets its own materialization and gate.
- next_action: `materialize_best_next_mana_base_pair_as_diagnostic`

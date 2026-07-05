# Lorehold Mana Base Decision Integrator

- generated_at: `2026-07-05T00:52:57Z`
- status: `mana_base_model_ready_queue_exhausted_by_decisions`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- safe_model_ready_pair_count: `2`
- exact_rejected_pair_count: `2`
- eligible_model_ready_pair_count: `0`
- promotion_allowed: `false`
- allow_natural_gate_now: `false`

## Annotated Model-Ready Pairs

| Status | Score | Add | Cut | Decision | Next Action |
| --- | ---: | --- | --- | --- | --- |
| `blocked_exact_tested_decision` | `52` | `Plateau` | `Radiant Summit` | `reject_promotion_keep_607_current_baseline` | `do_not_retest_exact_pair_without_new_mana_trace_evidence` |
| `blocked_exact_tested_decision` | `52` | `Plateau` | `Turbulent Steppe` | `reject_promotion_keep_607_current_baseline` | `do_not_retest_exact_pair_without_new_mana_trace_evidence` |

## Best Next Pair

- none

## Decision

- current_best_baseline: `deck_607`
- promotion_allowed: `false`
- reason: Tested mana-base pairs must be fed back into the safe-cut model. An exact rejected pair is blocked, but a different land with a different ETB condition is not inferred as accepted or rejected until it gets its own materialization and gate.
- next_action: `leave_mana_base_queue_closed_until_new_evidence`

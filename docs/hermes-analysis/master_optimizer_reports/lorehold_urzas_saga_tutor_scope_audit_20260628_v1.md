# Lorehold Urza's Saga Tutor Scope Audit - 2026-06-28

## Scope

- Hypothesis reviewed: `audit_urzas_saga_artifact_tutor_scope`.
- Question: whether `Urza's Saga` is under-modeled or choosing the wrong chapter III artifact target before we test another deck swap.
- PostgreSQL writes: none.
- Source DB mutated: no.

## Evidence From Existing Focus Traces

The focus-access traces show that `Urza's Saga` can resolve chapter III in the weak seeds, but older trace evidence selected generic value too often:

| Seed | Game | Legal/Candidate Targets | Selected | Selected Reason |
| ---: | --- | --- | --- | --- |
| 7 | Sisay #61 game 0 | Esper Sentinel, Sol Ring, Sensei's Divining Top, Library of Leng | Esper Sentinel | establish_value_engine |
| 7 | Vivi #99 game 1 | Esper Sentinel, Sensei's Divining Top, Library of Leng | Esper Sentinel | establish_value_engine |
| 20260625 | Winota #39 game 1 | Library of Leng, Sol Ring, Sensei's Divining Top, Esper Sentinel | Esper Sentinel | highest_contextual_value |
| 20260625 | Winota #39 game 2 | Sol Ring, Esper Sentinel, Sensei's Divining Top, Library of Leng | Esper Sentinel | establish_value_engine |
| 42 | Sisay #61 game 0 | Sol Ring, Sensei's Divining Top | Sensei's Divining Top | highest_contextual_value |
| 42 | Vivi #99 game 1 | Sol Ring, Sensei's Divining Top, Library of Leng | Library of Leng | highest_contextual_value |

This supports the planner's concern: the weak-seed line was not consistently converting Saga into the Top/Library engine.

## Current Runtime Check

A current-state micro-scenario with `Lorehold, the Historian`, `Urza's Saga` on chapter III setup, and legal targets `Esper Sentinel`, `Sol Ring`, `Sensei's Divining Top`, and `Library of Leng` now selects:

- found: `Sensei's Divining Top`
- selected_reason: `find_lorehold_topdeck_miracle_engine`
- candidate order: `Sensei's Divining Top`, `Library of Leng`, `Sol Ring`, `Esper Sentinel`

Regression test added:

- `docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_saga_tutor_priority.py`

## Current Gate Rerun

Small current-executor reruns were generated with deck `6`, the Squee candidate DB, one game per opponent, real opponent seed `20260626`, and deck-process isolation.

| Simulation Seed | Deck Key | Record | Saga Finding |
| ---: | --- | ---: | --- |
| 7 | `candidate_607_squee_current_saga_priority_v1` | 0-3 | Saga resolved once and selected `Sensei's Divining Top` over `Library of Leng` and `Esper Sentinel`; selected_reason=`find_lorehold_topdeck_miracle_engine`. |
| 20260625 | `deck_6` | 1-2 | Saga selected `Sensei's Divining Top` when Top was legal; selected `Sol Ring` when Top/Library were not available. |
| 20260625 | `candidate_607_squee_current_saga_priority_v1` | 1-2 | No natural Saga chapter III resolution observed in this small recut. |

Current rerun artifacts:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_saga_priority_current_gate_20260628_summary.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_saga_priority_current_gate_20260628_summary.md`

## Decision

Do not create a new card-swap package for this hypothesis yet.

The current runtime already contains the intended Lorehold-specific Saga target priority when the commander plan is known. The current seed-7 rerun proves the natural gate can select `Sensei's Divining Top` correctly. The older trace remains useful as failure evidence, but it is not proof of an active Saga target-selection bug.

## Next Action

- Keep `Urza's Saga`, `Sensei's Divining Top`, and `Library of Leng` protected as existing engine pieces.
- Do not add a card to solve Saga targeting.
- Continue with weak-seed access/conversion work: seed 7 still went 0-3 even after correct Saga target selection, and seed 20260625 still depends on whether the engine appears naturally.

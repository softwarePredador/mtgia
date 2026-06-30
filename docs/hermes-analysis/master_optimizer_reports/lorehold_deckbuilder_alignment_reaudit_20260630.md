# Lorehold Deckbuilder Alignment Reaudit - 2026-06-30

## Decision

- Status: `aligned_existing_flow_use_trace_runtime_before_new_swap`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Main correction: do not create a new flex-cut/registry flow. The project already has the required surfaces: cut models, manual cut review, profiled cut benchmark generator, next hypothesis queue, failure-targeted synthesis, trace audit, focus-access package generator, exposure-aware gate queue, and package gate.
- Previous ambiguity: using `lorehold_registry_candidate_runner.py` alone was the wrong continuation for this phase. That registry is empty, but the current deckbuilder handoff is not empty; it is the 2026-06-30 planner/trace/focus-access chain. The runner is now blocked by default and only available with an explicit legacy flag.

## Current Evidence

| Surface | Current artifact | Result |
| --- | --- | --- |
| Hypothesis queue | `lorehold_next_hypothesis_queue_20260630_after_profiled_gate.json` | `13` packages, all `tested_negative_do_not_promote` |
| Planner | `lorehold_next_action_planner_20260630_after_profiled_gate.json` | recommended action: `review_focus_access_trace_then_define_next_deck_or_runtime_package` |
| Failure-targeted synthesis | `lorehold_failure_targeted_synergy_hypotheses_20260630_after_profiled_gate.json` | `4` hypotheses; next action `run_failure_targeted_trace_audit` |
| Failure-targeted trace audit | `lorehold_failure_targeted_trace_audit_20260630_after_profiled_gate.json` | focus access/conversion trace is available; review sequence before package |
| Focus-access generator | `lorehold_focus_access_package_generator_20260630_after_profiled_gate.json` | `52` package candidates, `0` gate-ready, top work `runtime_rule_gap_batch`; `8` filtered runtime gaps remain |
| Exposure-aware queue | `lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate.json` | `11` forced-exposure diagnostics ready, `0` natural gate-ready |

## Interpretation

1. The missing piece is not a new `flex cut pool`.
2. The current safe-cut and profiled-cut models already evaluated the deck-607 cut surface and found `0` promotion-ready swaps.
3. The current hypothesis queue is exhausted because every listed package is prior-negative.
4. The next productive route is trace/runtime review of the existing engine:
   - seed `7`: missing or low engine access;
   - seed `20260625`: engine appears but does not convert;
   - `Urza's Saga`: active scope is partial and needs utilization review;
   - `Squee, Goblin Nabob`: graveyard-entry route needs sequencing review.
5. The exposure-aware queue can run forced diagnostics for `11` low/inconclusive packages, but this is diagnostic only. It is not a natural benchmark and cannot promote the deck.
6. The current runtime queue filters `53` verified/auto rules out of `61` raw runtime gaps; the remaining `8` cards are the real runtime/scope work before deck gates can trust those candidates.

## Aligned Default Flow

Run these in order when restarting Lorehold deckbuilder work:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_failure_targeted_synergy_hypotheses.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_failure_targeted_trace_audit.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_focus_access_package_generator.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_exposure_aware_gate_queue.py
```

Only run `lorehold_synergy_package_gate.py` after the previous reports produce either:

- a natural gate-ready package; or
- a forced-exposure diagnostic that is explicitly being used to collect card-access evidence, followed by natural confirmation before any deck claim.

## Script Alignment Applied

- `lorehold_failure_targeted_synergy_hypotheses.py` now defaults to:
  - `lorehold_next_hypothesis_queue_20260630_after_profiled_gate.json`
  - `lorehold_next_action_planner_20260630_after_profiled_gate.json`
- `lorehold_failure_targeted_trace_audit.py` now defaults to:
  - `lorehold_failure_targeted_synergy_hypotheses_20260630_after_profiled_gate.json`
- `lorehold_focus_access_package_generator.py` now defaults to:
  - `lorehold_failure_targeted_trace_audit_20260630_after_profiled_gate.json`
- `lorehold_exposure_aware_gate_queue.py` now defaults to:
  - `lorehold_runtime_candidate_readiness_20260630_post_pg280_kayla_music_box.json`
  - `lorehold_next_hypothesis_queue_20260630_after_profiled_gate.json`
  - `lorehold_next_action_planner_20260630_after_profiled_gate.json`
- The current route scripts now use a valid `knowledge.db` fallback instead of silently creating/using an empty worktree SQLite file.

## Current Stop Rule

Do not attempt to mount/promote a new deck list from this state. The correct next work is to inspect the available focus traces and decide whether the next implementation is:

- runtime/sequencing correction for an existing engine; or
- a diagnostic forced-exposure probe for one of the `11` ready diagnostic packages, only after the focus/runtime review is intentionally choosing diagnostic sampling; or
- a new failure-targeted package only after trace evidence identifies a missing route and preserves seed-42 miracle/topdeck telemetry.

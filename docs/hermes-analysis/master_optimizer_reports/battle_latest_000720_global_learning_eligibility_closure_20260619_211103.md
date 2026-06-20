# Battle Latest 000720 Global Learning Eligibility Closure

Status: BV-072 can be closed.

Scope: read-only recheck of cross-gate learning eligibility against the current
official battle audit artifact and the producers of the `summary.json` fields.
No code, database, deck swap, commit, or push was performed.

## Primary Evidence

- Latest artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720`.
- `summary.json` timestamp: `2026-06-20T00:07:20Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- Mandatory gates required for final status:
  `["action_critic","strategy_audit","replay_decision_audit","forensic_audit","effect_coverage","focused_template_dispatch","unknown_template_backlog","decision_trace_taxonomy","event_contract_static"]`.
- `strategy_learning_confidence_counts={"high_confidence_replay":12,"low_confidence_replay":4}`.
- `strategy_findings=5`, `strategy_low_confidence_findings=5`,
  `strategy_review_required_findings=0`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.
- `seeds_with_high_or_critical_decision_audit_findings=[]`.
- `test_results_total=16`, `test_results_status_counts={"pass":16}`.

## Global Eligibility Output

The current `summary.json` publishes the global post-gate fields that were
missing in the previous latest:

- `global_learning_eligibility_policy=requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`.
- `global_learning_eligible_seeds=["63210007","63210009","63210010","63210011","63210012","63210013","63210014","63210015","63210016","63210018","63210019","63210022"]`.
- `global_not_learning_eligible_seeds=["63210008","63210017","63210020","63210021"]`.
- `global_learning_eligibility_reasons` is present for every seed in the run.
  High-confidence seeds have `[]`; low-confidence seeds are excluded with
  `["strategy_audit:low_confidence_replay"]`.

This is no longer an inference from `strategy_*` fields. It is a first-class
global output after final gate aggregation.

## Producer Evidence

The local recurring wrapper initializes the global fields before aggregation:

- `global_learning_eligibility_policy`, `global_learning_eligible_seeds`,
  `global_not_learning_eligible_seeds`, and
  `global_learning_eligibility_reasons` are initialized in
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:436-439`.

The same wrapper computes final gate status before computing global learning
eligibility:

- It builds `mandatory_gate_statuses` and `mandatory_gate_divergences`, then
  sets `battle_replay_final_status` and
  `battle_replay_final_status_reason`
  (`manaloom-battle-strategy-audit.sh:1173-1188`).
- It calls `compute_global_learning_eligibility(...)` with
  `final_status=summary["battle_replay_final_status"]` and
  `mandatory_gate_divergences=summary["mandatory_gate_divergences"]`
  (`manaloom-battle-strategy-audit.sh:1190-1194`).
- The markdown summary renders the global policy, eligible seeds,
  not-eligible seeds, and reasons (`manaloom-battle-strategy-audit.sh:1284-1287`).

The implementation used by the wrapper is explicit:

- `compute_global_learning_eligibility(...)` treats any final status other than
  `trusted_for_strategy_learning` as learning-blocking, appends mandatory gate
  divergences as seed reasons, excludes non-`high_confidence_replay` strategy
  seeds, and records action, strategy, decision, and forensic blocker reasons
  (`battle_decision_strategy_auditor.py:545-612`).

## Test Evidence

`test_battle_decision_strategy_auditor.py` now covers both core cases:

- `test_global_learning_eligibility_blocks_high_strategy_seed_when_other_gates_review_required`
  verifies that a high-confidence strategy seed is excluded when action,
  decision, forensic, final status, or mandatory gate divergences require
  review/blocking (`test_battle_decision_strategy_auditor.py:460-488`).
- `test_global_learning_eligibility_allows_clean_high_seed_and_excludes_low_confidence_seed`
  verifies that a clean high-confidence seed is globally eligible and a
  low-confidence seed is not (`test_battle_decision_strategy_auditor.py:490-510`).

The official latest run log
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/test_battle_decision_strategy_auditor.log`
shows both tests passing.

## Register Decision

BV-072 can be removed from open findings.

Closure reason: the primary result now publishes global post-gate learning
eligibility lists and per-seed reasons, and the producer computes them only
after final mandatory gate status is known.

Residual note: low-confidence strategy seeds still exist in this trusted run,
but they are now explicitly listed under `global_not_learning_eligible_seeds`
with `strategy_audit:low_confidence_replay` reasons.

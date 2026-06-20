# Hermes Replay Decision Audit

- deck_id: 6
- baseline_id: 6
- status: turn_invariants_clean
- status_scope: turn_and_decision_trace_invariants
- structured_trace_usable: True
- human_replay_complete: not_evaluated_by_replay_decision_auditor
- rules_interaction_trusted: not_evaluated_by_replay_decision_auditor
- structured_events: 541
- decision_traces: 92
- turn_findings: 0
- decision_findings: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Files

- external events file was used.

## Turn-By-Turn Findings

| Severity | Replay | Turn | Player | Event | Finding |
| --- | --- | ---: | --- | --- | --- |
| info | all | - | all | all | No turn-by-turn red flags found. |

## Decision Trace Findings

- critical/high: 0
- medium: 0
- low: 0

| Severity | Replay | Turn | Player | Event | Finding |
| --- | --- | ---: | --- | --- | --- |
| info | all | - | all | all | No decision-trace red flags found. |

## Aggregate Baseline Findings

| Severity | Opponent | Finding |
| --- | --- | --- |
| medium | The Gitrog Monster #78 (real) | Slow average turn 18.0; inspect sequencing and finisher timing. |
| medium | Kraum, Ludevic's Opus #83 (real) | Slow average turn 16.0; inspect sequencing and finisher timing. |
| medium | Aang, at the Crossroads #106 (real) | Slow average turn 20.0; inspect sequencing and finisher timing. |
| medium | Kenrith, the Returned King #113 (real) | Slow average turn 20.0; inspect sequencing and finisher timing. |
| medium | Rograkh, Son of Rohgahh #119 (real) | Slow average turn 17.0; inspect sequencing and finisher timing. |

## Gate Interpretation

- `critical` or `high` turn findings block optimizer trust until battle logic is fixed.
- `critical` or `high` decision findings block optimizer trust until trace quality is fixed.
- This auditor only validates turn and decision-trace invariants; it does not prove human replay completeness or full rules-interaction trust.
- `medium` findings require review before product-facing deck mutation.
- `low` findings are polish/heuristic notes and do not block a Hermes-local experiment.
- Turn finding counts: {'critical': 0, 'high': 0, 'medium': 0, 'low': 0}.

Report written: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/master_optimizer_replay_audit_20260620_194539.md

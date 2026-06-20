# Hermes Replay Decision Audit

- deck_id: 6
- baseline_id: 0
- status: turn_by_turn_clean
- structured_events: 1071
- decision_traces: 152
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
| info | all | No aggregate red flags found. |

## Gate Interpretation

- `critical` or `high` turn findings block optimizer trust until battle logic is fixed.
- `critical` or `high` decision findings block optimizer trust until trace quality is fixed.
- `medium` findings require review before product-facing deck mutation.
- `low` findings are polish/heuristic notes and do not block a Hermes-local experiment.
- Turn finding counts: {'critical': 0, 'high': 0, 'medium': 0, 'low': 0}.

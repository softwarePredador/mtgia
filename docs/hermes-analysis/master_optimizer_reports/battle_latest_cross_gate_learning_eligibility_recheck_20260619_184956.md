# Battle latest cross-gate learning eligibility recheck 2026-06-19

Scope: recheck `BV-072` against the current `latest` battle audit artifact and
the current strategy aggregation code. This is documentation-only and read-only.

Guardrails:

- PostgreSQL was not modified.
- No swaps were applied.
- No code was changed.
- No commit was created.
- Only artifacts, logs, tests and documentation were inspected or written.

## Latest artifact

- Latest path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539`
- Primary summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `timestamp_utc=2026-06-19T21:45:39Z`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=review_required"]`
- `action_findings=1`
- `forensic_rule_findings=2`
- `forensic_lineage_status=incomplete`
- `strategy_audit.status=pass`
- `strategy_audit.findings=8`
- `strategy_audit.low_confidence_findings=8`
- `strategy_audit.review_required_findings=0`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

No high/critical action finding or strategy blocker was present, but the final
run status is not trusted because action and forensic mandatory gates require
review.

## Strategy confidence versus mandatory gates

Current strategy confidence fields:

```text
strategy_learning_confidence_counts={"high_confidence_replay":11,"low_confidence_replay":5}
strategy_high_confidence_learning_seeds=[
  63202145, 63202146, 63202148, 63202149, 63202151, 63202152,
  63202153, 63202154, 63202156, 63202158, 63202159
]
strategy_low_confidence_seeds=[
  63202147, 63202150, 63202155, 63202157, 63202160
]
strategy_not_learning_eligible_seeds=[]
```

Per-seed gate sample:

```text
63202145 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202146 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202147 strategy=low_confidence_replay  action_findings=0 forensic_findings=0
63202148 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202149 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202150 strategy=low_confidence_replay  action_findings=1 forensic_findings=2
63202151 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202152 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202153 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202154 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202155 strategy=low_confidence_replay  action_findings=0 forensic_findings=0
63202156 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202157 strategy=low_confidence_replay  action_findings=0 forensic_findings=0
63202158 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202159 strategy=high_confidence_replay action_findings=0 forensic_findings=0
63202160 strategy=low_confidence_replay  action_findings=0 forensic_findings=0
```

Important nuance:

- Unlike the older `BV-072` evidence from `2026-06-19T20:03:24Z`, the current
  latest does not put the action/forensic problematic seed `63202150` into
  `strategy_high_confidence_learning_seeds`.
- Seed `63202150` is strategy-low-confidence and also has the current action and
  forensic review findings.
- However, `strategy_not_learning_eligible_seeds=[]` is still a strategy-audit
  field only. It is not a global post-gate eligibility field.
- The primary summary does not publish `global_learning_eligible_seeds`,
  `global_not_learning_eligible_seeds` or per-seed global ineligibility reasons.

## Current finding sources

Action critic:

```text
seed=63202150
severity=low
code=missing_decision_trace
event=spell_cast
turn=6
phase=precombat_main
player=Lorehold
label=Silence
detail=Action has no matching decision trace.
```

Forensic audit:

```text
seed=63202150
severity=medium
event=spell_cast
turn=7
phase=precombat_main
player=Tayam, Luminous Enigma #25 (real)
card=Faeburrow Elder
effect=ramp_permanent
finding=Game event depended on heuristic source functional_tags_json.
```

```text
seed=63202150
severity=low
event=spell_cast
turn=7
phase=precombat_main
player=Tayam, Luminous Enigma #25 (real)
card=Faeburrow Elder
effect=ramp_permanent
finding=Runtime effect ramp_permanent differs from registry effect ramp_ritual.
```

Seed `63202150` strategy summary:

```text
learning_confidence=low_confidence_replay
high_confidence_learning_eligible=false
high_confidence_learning_weight=0.0
findings=2
code_counts={"forced_keep_after_bad_mulligan":2}
review_required_findings=0
```

This confirms the strategy auditor correctly downgrades the seed for strategy
reasons, but it does not incorporate action/forensic gate status into a global
eligibility decision.

## Source evidence

- `battle_decision_strategy_auditor.py:478-502` sets
  `learning_confidence`, `high_confidence_learning_eligible` and
  `high_confidence_learning_weight` from strategy findings only.
- `battle_decision_research_review.py:211-239` aggregates
  `strategy_high_confidence_learning_seeds`, `strategy_low_confidence_seeds` and
  `strategy_not_learning_eligible_seeds` from each seed's strategy summary only.
- `battle_decision_research_review.py:297-299` publishes those strategy lists.
- `master_optimizer_common.py:596-602` shows both mandatory gate status and
  strategy seed samples, but it still reports `strategy_*` fields rather than
  global post-gate seed eligibility fields.
- Search found no `global_learning_eligible` or `global_not_learning` field in
  the strategy research review or optimizer summary helpers.

## Tests run

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py
PASS test_research_review_classifies_categories_from_replay_artifacts
PASS test_research_review_renders_sources
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py
PASS 15 tests
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539
BATTLE_DECISION_RESEARCH_REVIEW ... strategy_learning_confidence_counts={"high_confidence_replay":11,"low_confidence_replay":5}
```

The tests confirm the strategy-only behavior is intentional in current code, but
they do not prove global learning eligibility after action and forensic gates.

## Operational reading

- `BV-072` remains open.
- Current latest improves over the older blocked sample because the problematic
  seed is not in `strategy_high_confidence_learning_seeds`.
- The semantic gap remains: downstream consumers need a global post-gate field
  or a hard naming separation so `strategy_not_learning_eligible_seeds=[]` is
  never read as "no seed is globally ineligible".
- The cleanest contract is to publish:
  - `global_learning_eligible_seeds`
  - `global_not_learning_eligible_seeds`
  - per-seed global ineligibility reasons such as `action_critic_review`,
    `forensic_audit_review`, `strategy_low_confidence`
  - a label that keeps current fields under `strategy_audit_*` semantics.

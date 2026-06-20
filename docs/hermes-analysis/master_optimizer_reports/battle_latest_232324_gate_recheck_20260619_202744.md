# Battle latest 232324 gate recheck - 2026-06-19T23:27:44Z

Scope: read-only validation. No code was changed for this report, PostgreSQL was
not touched, and no deck swaps were applied.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_63202325/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_63202328/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_63202335/replay.events.jsonl`
- all `seed_*/forensic_audit.json`
- all `seed_*/replay_decision_audit.json`
- all `seed_*/replay.events.jsonl`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Current aggregate gate

Latest official run:

- `timestamp_utc=2026-06-19T23:23:24Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `action_critic.status=pass`, `findings=0`
- `forensic_audit.status=pass`, `rule_findings=0`, `turn_findings=0`
- `replay_decision_audit.status=pass`, `decision_findings=0`,
  `turn_findings=0`
- `strategy_audit.status=pass`, `findings=4`,
  `review_required_findings=0`, `low_confidence_findings=4`
- `decision_trace_taxonomy.status=pass`, `rows=2394`, observed `12/15`
- `event_contract_static.status=pass`, observed event types `54`, accepted
  static fixture waivers `47`
- tests: `test_results_total=16`, `test_results_status_counts={"pass":16}`,
  `test_log_empty_successes=[]`, `test_log_empty_failures=[]`

No high/critical action, replay-decision, or forensic findings were present in
the summary. No strategy blocker was present.

## BV-079 and BV-080 current status

The current latest supersedes the previous `20260619_230829` and
`20260619_231827` transitions:

- `BV-079`: closed as stale latest regression. The current final status is
  trusted and both `forensic_audit` and `replay_decision_audit` pass with zero
  findings.
- `BV-080`: closed as stale lineage follow-up. Current lineage counters are
  `forensic_lineage_status=complete`,
  `forensic_card_id_missing_unaccepted=0`,
  `forensic_semantic_hash_missing_unaccepted=0`,
  `forensic_rule_logical_key_missing_unaccepted=0`, and
  `forensic_lineage_unaccepted_missing_samples=[]`.

`Bridgeworks Battle` still appears in seed `63202328`, and `Into the Flood Maw`
appears in seed `63202335`, but neither produces current forensic findings or
unaccepted lineage samples in the latest summary.

## Target-choice provenance check

24 `removal_resolved` events were scanned. Only one had multiple targets:

- seed `63202325`
- turn `7`
- card `Rise of the Eldrazi`
- target `Etali, Primal Conqueror`
- `available_targets=2`
- `target_score=[1,1,4,4,4]`
- `target_options_len=2`

Multi-target removals missing target provenance: `0`.

## Residual follow-ups still not closed by final trusted status

- `effect_coverage_effect_totals_unknown=41`
- `focused_template_ready_unknown_effect_count=28`
- `needs_review_rule_names=1457`
- `non_runtime_safe_rule_names=1457`

These remain separate from the now-clean mandatory replay/forensic/decision
gates.

## Status

No new battle replay gate blocker was opened from this recheck. `BV-079` and
`BV-080` should not remain in `Achados abertos` for the current latest.

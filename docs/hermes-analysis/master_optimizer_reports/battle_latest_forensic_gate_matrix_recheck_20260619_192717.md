# Battle latest forensic/gate matrix recheck - 2026-06-19T22:27Z

Scope: read-only validation of the current recurring battle audit state against
the live register and gate matrix. No code, PostgreSQL, deck swaps, commits or
pushes were changed.

Sources checked:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/replay.events.jsonl`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Latest aggregate state

- `latest` resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228`.
- `summary.json.timestamp_utc=2026-06-19T21:52:28Z`.
- `seeds_completed=16`.
- `battle_replay_final_status=review_required`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `mandatory_gate_statuses.action_critic.status=pass`, with `findings=0`.
- `mandatory_gate_statuses.replay_decision_audit.status=pass`, with
  `decision_findings=0` and `turn_findings=0`.
- `mandatory_gate_statuses.strategy_audit.status=pass`, with `findings=5`,
  `low_confidence_findings=5`, and `review_required_findings=0`.
- `mandatory_gate_statuses.forensic_audit.status=review_required`, with
  `rule_findings=1` and `turn_findings=0`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.

Operational reading: this run is not blocked by high/critical findings, but it
is also not trusted for strategy learning because the aggregate final status is
`review_required`.

## Current forensic review sample

The current forensic review is reproducible in seed `63202164`.

Evidence from
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/forensic_audit.json`:

- `findings_total=1`.
- Severity counts: `medium=1`, `high=0`, `critical=0`.
- Rule source counts include `functional_tags_json=1`.
- Review status counts include `heuristic=1`.
- `lineage_unaccepted_missing_samples` has three entries for `Infernal Plunge`,
  all on `event=spell_cast`, `effect=ramp_permanent`,
  `source=functional_tags_json`, missing `rule_logical_key`, `card_id`, and
  `semantic_hash`.
- The finding is:
  - replay: `seed_63202164`
  - turn: `3`
  - phase: `precombat_main`
  - player: `Dargo, the Shipwrecker #74 (real)`
  - event: `spell_cast`
  - card: `Infernal Plunge`
  - effect: `ramp_permanent`
  - finding: `Game event depended on heuristic source functional_tags_json.`
  - recommendation: move this card into `card_battle_rules` with
    `verified`/`active` status.

Evidence from `replay.events.jsonl` for the same seed:

- `Infernal Plunge` emitted `cast_announced`, `cost_paid`, and `spell_cast`.
- The events carry `rule_source=functional_tags_json`,
  `rule_review_status=heuristic`, `rule_confidence=0.35`, and
  `effect=ramp_permanent`.
- The audited `spell_cast` has `cmc=1.0`, `phase=precombat_main`, and
  `cast_pipeline=601.2_minimal`.

Cross-checks for the same seed:

- `action_critic.json`: `findings=0`, `total_actions=267`,
  `verdict_counts={"ok":267}`.
- `replay_decision_audit.json`: `decision_findings=0`, `turn_findings=0`,
  `structured_trace_usable=true`.
- `strategy_audit.json`: `findings=0`,
  `high_confidence_learning_eligible=true`,
  `high_confidence_learning_weight=1.0`,
  `learning_confidence=high_confidence_replay`, and
  `verdict=usable_for_strategy_learning`.

Operational reading: the local strategy/action/decision views for this seed are
clean, but the aggregate run is still `review_required` because forensic lineage
found an unaccepted heuristic functional-tag execution. This is the current
concrete instance of the `functional_tags_json` battle fallback problem.

## Cross-gate learning eligibility

Evidence from latest `summary.json`:

- `strategy_high_confidence_learning_seeds` includes `63202164`.
- `strategy_low_confidence_seeds=["63202155","63202157","63202160","63202163"]`.
- `strategy_not_learning_eligible_seeds=[]`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- No `global_learning_eligible_seeds`, `global_not_learning_eligible_seeds`, or
  per-seed global gate reasons are published in the summary.

Operational reading: `63202164` is high-confidence only inside the strategy
auditor. It should not be treated as globally learning-grade while the final
run status is `review_required` and the same seed carries the forensic
functional-tag lineage finding.

## Gate matrix drift

`docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md` currently says:

- `Status: current as of 2026-06-19T21:40Z`.
- Current gate reading points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/summary.json`.
- It reports `battle_replay_final_status=trusted_for_strategy_learning`.
- It reports `mandatory_gate_divergences=[]`.

The live `latest` summary checked in this pass points to `20260619_215228` and
reports `battle_replay_final_status=review_required` with
`mandatory_gate_divergences=["forensic_audit=review_required"]`.

Operational reading: the matrix contract is still useful, but its `Current Gate
Reading` block is stale and currently contradicts the live summary. A reader
must use register + latest summary for readiness, not the matrix snapshot
alone.

## Tasks for Ajustar battle

1. Promote `Infernal Plunge` out of `functional_tags_json` execution into a
   `card_battle_rules` rule with `verified`/`active` status, or add a formal
   temporary waiver that keeps the event non-learning-grade until promoted.
2. Publish current `functional_tags_json` event/card counts and affected cards
   in the aggregate `summary.json`, not only in per-seed forensic samples.
3. Add global post-gate learning eligibility fields after all mandatory gates:
   `global_learning_eligible_seeds`, `global_not_learning_eligible_seeds`, and
   reasons per seed. Strategy-local high confidence must not imply global
   eligibility.
4. Generate the `Current Gate Reading` block of
   `BATTLE_REPLAY_GATE_MATRIX.md` from the live latest summary, or label it as a
   historical snapshot and add a freshness check that fails when it diverges
   from `latest`.

## Validation commands run

- `git status --short`
- `realpath /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`
- `jq` reads against the latest aggregate `summary.json`
- `jq` reads against seed `63202164` action critic, forensic audit, replay
  decision audit, strategy audit, and replay events
- Read of `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- Read of `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`


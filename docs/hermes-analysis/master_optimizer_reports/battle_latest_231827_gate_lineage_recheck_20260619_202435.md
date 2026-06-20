# Battle latest 231827 gate and lineage recheck - 2026-06-19T23:24:35Z

Scope: read-only validation. No code was changed for this report, PostgreSQL was
not touched, and no deck swaps were applied.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_231827/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_231827/seed_63202325/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_231827/seed_63202328/forensic_audit.json`
- all `seed_*/forensic_audit.json`
- all `seed_*/replay_decision_audit.json`
- all `seed_*/replay.events.jsonl`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Current aggregate gate

Latest official run:

- `timestamp_utc=2026-06-19T23:18:27Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `action_critic.status=pass`, `findings=0`
- `forensic_audit.status=pass`, `rule_findings=0`, `turn_findings=0`
- `replay_decision_audit.status=pass`, `decision_findings=0`,
  `turn_findings=0`
- `strategy_audit.status=pass`, `findings=4`,
  `review_required_findings=0`, `low_confidence_findings=4`
- `decision_trace_taxonomy.status=pass`, `rows=2187`, observed `12/15`
- `event_contract_static.status=pass`, observed event types `54`, accepted
  static fixture waivers `47`
- tests: `test_results_total=16`, `test_results_status_counts={"pass":16}`,
  `test_log_empty_successes=[]`, `test_log_empty_failures=[]`

No high/critical action, replay-decision, or forensic findings were present in
the summary. No strategy blocker was present.

## BV-079 current status

The previous official run `20260619_230829` had two current review causes:

- `Into the Flood Maw` oracle/runtime normalization findings in seed `63202310`.
- `Rise of the Eldrazi` target-choice finding in seed `63202308`.

Those findings do not reproduce in current latest `20260619_231827`:

- `rg "Into the Flood Maw" .../20260619_231827/seed_*/replay.events.jsonl`
  returned no matches.
- 16 forensic audit files were scanned: total `rule_findings=0` and
  `turn_findings=0`.
- 16 replay-decision audit files were scanned: total `decision_findings=0` and
  `turn_findings=0`.
- 16 `removal_resolved` events were scanned. Only one had multiple targets:
  seed `63202325`, turn `7`, `Rise of the Eldrazi`, selected
  `Etali, Primal Conqueror`, `available_targets=2`,
  `target_score=[1,1,4,4,4]`, `target_options_len=2`.
- Multi-target removals missing target provenance: `0`.

Therefore `BV-079` is no longer a current latest blocker. The old run remains
useful historical evidence, but it should not remain in `Achados abertos` as the
current latest state.

## New lineage follow-up

The same latest has a separate lineage gap that does not currently move the
mandatory forensic gate to review:

- `forensic_lineage_status=incomplete`
- `forensic_card_id_missing=567`
- `forensic_card_id_missing_unaccepted=2`
- `forensic_semantic_hash_missing=567`
- `forensic_semantic_hash_missing_unaccepted=2`
- `forensic_rule_logical_key_missing=29`
- `forensic_rule_logical_key_missing_unaccepted=0`

The unaccepted samples are all seed `63202328`, card `Bridgeworks Battle`, effect
`draw_cards`:

- `spell_cast` missing `card_id`
- `spell_cast` missing `semantic_hash`
- `spell_resolved` missing `card_id`
- `spell_resolved` missing `semantic_hash`

Seed `63202328/forensic_audit.json` still has `rule_findings=[]` and
`turn_findings=[]`.

## Task for "Ajustar battle"

1. Decide whether unaccepted `card_id`/`semantic_hash` lineage gaps should make
   `forensic_audit.status` or `battle_replay_final_status` non-pass.
2. Fix or formally waive `Bridgeworks Battle` lineage for `spell_cast` and
   `spell_resolved`.
3. Keep the gate matrix explicit: final status can be trusted for the current
   mandatory gates, but lineage incompleteness remains a follow-up until
   `forensic_*_missing_unaccepted=0` or a clear waiver/gate rule exists.

## Status

`BV-079` should be closed as stale latest regression. Open new lineage follow-up
`BV-080` for `Bridgeworks Battle` unaccepted missing `card_id`/`semantic_hash`.

## Superseded by newer latest

After this report was written, the official `latest` symlink moved to
`20260619_232324`. That newer run keeps
`battle_replay_final_status=trusted_for_strategy_learning` and
`mandatory_gate_divergences=[]`, and also clears the lineage follow-up:
`forensic_lineage_status=complete`,
`forensic_card_id_missing_unaccepted=0`,
`forensic_semantic_hash_missing_unaccepted=0`, and
`forensic_lineage_unaccepted_missing_samples=[]`.

This report remains historical evidence for run `20260619_231827`; do not use it
as the current latest status without also reading
`battle_latest_232324_gate_recheck_20260619_202744.md`.

# Battle Replay Gate Matrix

Status: current as of `2026-06-20T21:21Z`.

This matrix defines the mandatory gates that must run before a battle replay is
interpreted as final evidence. A green result in one auditor is not a global
pass unless the aggregate final status also says so.

## Mandatory Gates

| Gate | Purpose | Blocking condition | Review condition |
| --- | --- | --- | --- |
| `action_critic` | Validates replay action/event integrity. | Any high/critical action seed. | Non-blocking findings remain. |
| `strategy_audit` | Validates strategy-learning usability. | Any strategy blocker seed. | Non-low-confidence strategy findings remain in `strategy_review_required_findings`. Low-confidence findings remain visible but do not keep this gate in review by themselves. |
| `replay_decision_audit` | Validates turn and decision trace invariants. | Any high/critical replay-decision seed. | Low/medium decision findings remain. |
| `forensic_audit` | Validates supported card/rule forensic behavior and source lineage. | Any high/critical forensic seed. | Low/medium forensic findings remain, including heuristic source review and non-blocking registry/runtime drift. Current wrapper gap: unaccepted lineage counters are visible but are not yet direct gate inputs when findings are zero; see `BV-088`. |
| `target_pressure` | Validates that opponent combat in Lorehold deck-evaluation runs pressures the evaluation target instead of letting other opponents eliminate each other. | Any opponent combat against a non-target defender while the target is alive, any multi-defender split against the target, or any per-seed target-pressure finding. | No opponent combat occurred in a seed, requiring manual review before using that seed as pressure evidence. |
| `effect_coverage` | Validates template/runtime-safe coverage for the corpus. | Any source-unknown `unknown_effect` flag or unaccepted residual flag. | `effect_totals.unknown` can remain visible for focused-template-ready, needs-review, or waived curated effect families. Accepted residuals are owner/waiver evidence, not proof that runtime behavior is implemented. |
| `focused_template_dispatch` | Validates that focused-template predicate matches are dispatchable through `evaluate_draft(...)` and produce focused evidence or accepted waivers. | Reserved for future thresholded dispatch blockers. | Any focused-template card without dispatch/evidence/waiver keeps this gate in review. |
| `unknown_template_backlog` | Validates that current unknown cards have inferred/reviewed families, plans or waivers, and focused-template predicate coverage. | Missing required backlog plan/waiver can block when configured. | Unknown-template backlog status other than `focused_template_backlog_ready`. |
| `decision_trace_taxonomy` | Validates observed/static decision trace kinds, required fields, and accepted waivers. | Contract findings or missing static/observed contracts. | Missing specific kind contracts or required fields that are not waived. |
| `event_contract_static` | Validates observed/static event kinds against action/forensic/strategy/renderer/technical classes and required fields. | Unclassified observed/static events or missing required fields. | Static fixture-depth waivers can remain even when the static contract itself passes. |

The latest wrapper publishes these exact gates under
`mandatory_gates_required_for_final_status`. If this table disagrees with that
field, trust the latest `summary.json` and update this document before drawing a
readiness conclusion.

## Final Status Rules

The recurring wrapper writes a single aggregate `battle_replay_final_status`:

- `blocked`: at least one mandatory gate has a blocking status.
- `review_required`: no blocking gate, but one or more mandatory gates has
  status `review_required`.
- `trusted_for_strategy_learning`: all mandatory gates are pass.

The wrapper also writes:

- `mandatory_gate_statuses`
- `mandatory_gate_divergences`
- `mandatory_gates_required_for_final_status`
- `battle_replay_final_status_reason`
- `effect_coverage_residual_status`
- `effect_coverage_residual_raw_flag_total`
- `effect_coverage_residual_accepted_card_flag_rows` / `effect_coverage_residual_unaccepted_card_flag_rows`
- `effect_coverage_effect_totals_unknown`
- `effect_coverage_unknown_effect_source_counts`
- `effect_coverage_unknown_effect_status_counts`
- `needs_review_unknown_effect_count`
- `focused_template_dispatch_status`
- `review_only_rule_names`
- `needs_review_rule_names`
- `non_runtime_safe_rule_names`
- `runtime_safe_rule_names`
- `review_status_counts`
- `decision_trace_taxonomy_rows`
- `decision_trace_kinds_total`
- `decision_trace_kinds_observed`
- `decision_trace_kinds_uncovered`
- `decision_trace_static_uncovered_types`
- `forensic_lineage_status`
- `forensic_card_id_missing_accepted` / `forensic_card_id_missing_unaccepted`
- `forensic_semantic_hash_missing_accepted` / `forensic_semantic_hash_missing_unaccepted`
- `forensic_rule_logical_key_missing_accepted` / `forensic_rule_logical_key_missing_unaccepted`
- `target_pressure_statuses`
- `target_pressure_findings`
- `target_pressure_opponent_combat_total`
- `target_pressure_opponent_combat_to_target`
- `target_pressure_opponent_combat_to_other`
- `target_pressure_opponent_multi_defender_attack`
- `seeds_with_target_pressure_violations`
- `event_contract_static_fixture_or_waiver_counts`
- `event_contract_static_waiver_until_forced_fixture`
- `event_contract_static_fixture_unaccepted_types`
- `strategy_learning_confidence_counts`
- `strategy_low_confidence_seeds`
- `global_learning_eligibility_policy`
- `global_learning_eligible_seeds`
- `global_not_learning_eligible_seeds`
- `global_learning_eligibility_reasons`
- `runtime_surface_manifest_automation_coverage_counts`
- `runtime_surface_manifest_gate_expected_counts`
- `runtime_surface_manifest_status`

## Current Latest Reading - 2026-06-20T21:21Z

- Latest artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`
- Run scope: `recurring_full`
- Invocation kind: `manual_cli`
- Seeds: `16/16`
- Start seed: `63212120`
- Final status: `trusted_for_strategy_learning`
- Final status reason: `all_mandatory_gates_pass`
- Mandatory gate divergences: `[]`
- Forensic findings: `rule=0`, `turn=0`
- Replay decision findings: `turn=0`, `decision=0`
- Action findings: `0`
- Target-pressure gate: `pass` for `16/16` seeds,
  `target_pressure_findings=0`, `opponent_combat_to_target=214`,
  `opponent_combat_to_other=3`, and `opponent_multi_defender_attack=2`.
- Table-intent gate: `pass` for `16/16` seeds.
- Event-contract gate: `pass`, including
  `observed_unclassified_total=0` and `static_unclassified_total=0`.
- Replay-decision gate: `pass`.
- Test gate: `18/18` pass.
- Strategy audit has only low-confidence findings:
  `strategy_findings=2`, `strategy_low_confidence_findings=2`,
  `strategy_review_required_findings=0`.

Wrapper correction:

- The local wrapper now includes `target_pressure` in
  `mandatory_gates_required_for_final_status`.
- Before this correction, target-pressure counters could be blocked while
  `mandatory_gate_divergences` omitted `target_pressure`.
- `bash -n` and wrapper `--dry-run --seeds 16` exited `0`; full rerun
  `20260620_204002` confirmed `mandatory_gate_divergences` could include
  `target_pressure=blocked` when the target-pressure gate blocks.
- `20260620_205821` briefly confirmed target-pressure pass with only low
  forensic review.
- `20260620_210513` superseded `205821`; target-pressure still passed `16/16`,
  but forensic high/medium lineage blockers returned in that seed window.
- `20260620_211217` supersedes `210513` after the externally generated round7
  artifacts and still blocks only on `forensic_audit=blocked`. The prior
  `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`,
  `The Unagi of Kyoshi Island`, and `Apex of Power` blocker set is superseded;
  current high/medium lineage blockers are `Tellah, Great Sage` and
  `Practical Research`.
- `20260620_211648` supersedes `211217`; target-pressure still passes `16/16`
  and the only current divergence is `forensic_audit=review_required` from low
  `Breena, the Demagogue` registry/runtime drift.
- `20260620_212035` supersedes `211648` after externally detected round8/round9
  artifacts and now has `mandatory_gate_divergences=[]`.

Focused proof retained:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200322/summary.json`
  is a focused seed `63213000` rerun after the `table_intent_*` metadata
  target-pressure fix. It is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`, `target_pressure_statuses={"pass":1}`,
  `forensic_rule_findings=0`, `decision_audit_turn_findings=0`,
  `action_findings=0`, and tests `18/18` pass. This closes that seed-specific
  metadata false positive, but it does not replace the full recurring gate.

Superseded blocker closure:

- `20260620_191248` blocked on `Goblin Bombardment` executing a
  `needs_review` / `review_only` canonical snapshot rule as `remove_creature`.
- `battle_analyst_v9.py` now suppresses non-runtime-safe canonical snapshot
  rules into passive provenance.
- `battle_card_specific_tests.py` adds
  `test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast`.
- The current `20260620_200409` run has `action_findings=0`; the Goblin
  blocker is not present.

Target-pressure closure:

- `20260620_194456` temporarily blocked target-pressure on seed `63211952`.
  The violating combat happened after `Lorehold` had already been eliminated.
- `battle_target_pressure_audit.py` now ignores opponent combat after target
  elimination and records
  `post_target_elimination_opponent_combat_ignored`.
- `test_battle_target_pressure_audit.py` covers this with
  `test_ignores_opponent_combat_after_lorehold_is_eliminated`.
- Focused seed `63211952` validation returned
  `target_player_eliminated=true`,
  `post_target_elimination_opponent_combat_ignored=1`,
  `opponent_combat_to_target=10`, `opponent_combat_to_other=0`, and
  `status=pass`.
- Full run `20260620_195007` confirmed target-pressure pass `16/16` for that
  seed window. The newer full run `20260620_200409` has one real
  target-pressure violation on seed `63212012`: opponent
  `Kinnan, Bonder Prodigy #104 (real)` split combat between Lorehold and
  `Tayam, Luminous Enigma #25 (real)` on turn `9`.

Target-pressure metadata closure:

- `20260620_200056` focused seed `63213000` temporarily blocked
  target-pressure because attacks into Lorehold used `target_reason` values
  such as `table_intent_table_threat` and `table_intent_low_life_opportunism`
  instead of only `evaluation_target_pressure` or `lethal`.
- `battle_target_pressure_audit.py` now accepts `table_intent_*` reasons when
  `evaluation_target_active=true` and the defender is Lorehold.
- `test_battle_target_pressure_audit.py` covers
  `test_accepts_table_intent_target_reason_when_evaluation_target_is_active`.
- Focused rerun `20260620_200322` confirms seed `63213000` now passes
  target-pressure.

Current residual:

- Current forensic findings: `0`.
- Target-pressure is currently pass `16/16` with no findings.
- Replay-decision is currently clean.
- Strategy has only low-confidence findings, not review-required findings.

Operational conclusion: the active full recurring run is trusted for strategy
learning. There is no current battle gate blocker or review-required gate for
Lorehold deck composition, target-pressure, forensic lineage, action integrity,
replay-decision, event-contract classification, or table-intent metadata.

Historical target-pressure run details retained below:

<!--
  `runtime_surface_manifest_category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":16,"optimizer/scorecard":15,"recurring audit gate":26,"renderer":4,"review queue":1,"rule registry/sync":15}`,
  `runtime_surface_manifest_automation_coverage_counts={"covered_by_recurring_run":31,"imported_by_core_runtime":6,"outside_recurring_run":75}`,
  and
  `runtime_surface_manifest_gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":31,"targeted_manual_gate_required_before_change":32,"targeted_test_required_before_change":43}`.
-->

Operational reading: if `mandatory_gate_divergences` is non-empty, the replay
has mixed gate signals and must be read by the aggregate final status, not by
the cleanest individual auditor.

Scope reading: `battle_replay_final_status` applies only to the exact run
scope published in that `summary.json`. Always read `run_dir`,
`seeds_requested`, `seeds_completed`, and `start_seed` before using `latest` as
readiness evidence. A focused run with `seeds_requested=1` can close a
seed-specific blocker, but it is not proof that the recurring 16-seed audit is
currently green.

For strategy outputs, `strategy_low_confidence_seeds` are not high-confidence
learning samples. In the current contract, forced mulligan-cap keeps get
`high_confidence_learning_weight=0.0` inside per-seed `strategy_audit.json` and
are counted separately in the aggregate summary. When those are the only
strategy findings, `strategy_audit.status` can still be `pass`; use
`strategy_review_required_findings` to identify strategy findings that keep the
gate in review.

For runtime-surface claims, the recurring wrapper is not global coverage for
all Python battle files. Use `runtime_surface_manifest.json` to decide whether a
changed area is covered by the recurring run, imported by core runtime, or needs
a targeted gate before claiming readiness.

## Historical Gate Reading - superseded by 20260620_125745

Previously checked run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005/summary.json`
- This is a recurring run: `run_profile=manual_post_pg006_sqlite_sync`,
  `run_scope=recurring_full`,
  `invocation_kind=manual_auditor_post_sqlite_sync`,
  `seeds_requested=16`, `seeds_completed=16`, and `start_seed=61620904`.
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `global_learning_eligible_seeds` is no longer globally blocked by final
  status.
- `action_critic`: pass with `findings=0`; `action_findings=0`.
- `strategy_audit`: pass; low-confidence strategy findings remain visible but
  do not force aggregate review by themselves.
- `replay_decision_audit`: pass with no high/critical decision audit findings.
- `forensic_audit`: pass with `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_rule_logical_key_missing_unaccepted=0`,
  `forensic_card_id_missing_unaccepted=0`, and
  `forensic_semantic_hash_missing_unaccepted=0`.
- `effect_coverage`, `focused_template_dispatch`,
  `unknown_template_backlog`, `decision_trace_taxonomy`, and
  `event_contract_static` all pass under the wrapper aggregate.
- `runtime_surface_manifest`: ready with
  `runtime_surface_manifest_total_files=110`,
  `runtime_surface_manifest_category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":16,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}`,
  `runtime_surface_manifest_automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":75}`,
  and
  `runtime_surface_manifest_gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":32,"targeted_test_required_before_change":43}`.
- The manifest denominator changed from `108` to `110` because
  `server/bin/plan_learned_deck_partner_identity_backfill.py` and
  `server/test/plan_learned_deck_partner_identity_backfill_test.py` are now
  classified as `learned-deck source`.
- Test provenance: `test_results_total=16`,
  `test_results_status_counts={"pass":16}`, `test_result_failures=[]`, and
  `test_results_jsonl=/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005/test_results.jsonl`.

Open-source-scope caveats:

- The PG-006 source-scope caveat was reconciled after the local Hermes SQLite
  cache was refreshed from PostgreSQL with
  `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`.
  The latest runtime summary now reports
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, and `review_only_rule_names=1457`.
- `review_only_rule_instances=0` is a corpus label counter, not the global
  rule-name backlog. The latest effect audit still exposes the `34` corpus
  uses as `battle_rule_needs_review_generated` / `needs_review_rule`.
- The superseded `090636` forensic blocker must not be used to justify a new
  PG-004/Leyline write unless a future latest artifact reproduces it.
- Learned-opponent/source-coherence caveats remain reportable separately when
  the task is source lineage, but they no longer block the current aggregate
  battle final status.

## Historical Gate Reading - 2026-06-20 10:18 -0300 - Pre-PG-007

Latest official run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/summary.json`
- This is a recurring run: `run_profile=recurring_16_seed`,
  `run_scope=recurring_full`, `invocation_kind=manual_cli`,
  `seeds_requested=16`, `seeds_completed=16`, and `start_seed=63211257`.
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `forensic_lineage_status=incomplete`
- `forensic_rule_findings=1`
- `forensic_turn_findings=0`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `execution_status_counts={"auto":1702,"review_only":1457}`
- `needs_review_rule_names=1457`
- `review_only_rule_names=1457`

Blocking finding:

- Seed artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/seed_63211258/forensic_audit.json`
- Card: `Leyline of Abundance`
- Event: `spell_cast`
- Effect: `ramp_permanent`
- Source: `functional_tags_json`
- Severity: `medium`
- Recommendation from forensic auditor: move this card into
  `card_battle_rules` with verified/active status.

Gate reading:

- At this historical point, battle was not trusted for strategy learning until
  the Leyline forensic blocker was handled and a new latest run proved the gate
  clean.
- This state was superseded by PG-007 apply/postcheck, PG -> Hermes SQLite sync,
  PG-007 closure battle `20260620_132812`, and current latest battle
  `20260620_151437`.

## Targeted Focused-Evidence Closure - 2026-06-20 10:09 -0300

Latest recurring gate at that time:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`

Additional targeted evidence after the latest recurring run:

- `server/bin/manaloom_battle_rule_focused_evidence.py` now preserves original
  spell effect data when validating extra-combat flashback evidence.
- Targeted test:
  `python3 -m unittest server.test.manaloom_review_queue_consumers_test.ManaloomReviewQueueConsumersTest.test_focused_evidence_unblocks_supported_low_risk_templates -v`
  passed with `evaluated_count=14` and `evidence_count=14`.
- Full Python discover passed `96/96`.

Gate reading:

- This targeted closure validates the focused-evidence/promotion harness slice.
- It does not replace the recurring `16`-seed latest summary and does not
  authorize PostgreSQL rule promotion by itself.
- No new PG-004 package is ready from this targeted evidence.

## Historical Gate Reading - 2026-06-20 11:19 -0300

Latest official run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_140016/summary.json`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `execution_status_counts={"auto":1703,"review_only":1457}`
- `strategy_review_required_findings=0`
- `unknown_template_backlog_cards=0`
- `focused_template_dispatch_status=focused_template_dispatch_ready`
- `focused_template_evidence_ready=29`
- `focused_template_evidence_not_ready_unwaived=0`

Runtime surface evidence:

- `python3 test_battle_runtime_surface_manifest.py` passed.
- Manifest scan reports `total_files=110` and `unclassified_files=[]`.

Gate reading:

- At that time, battle was trusted for strategy learning.
- The historical `20260620_125745` Leyline blocker is superseded by PG-007.
- The `20260620_132812` run remains PG-007 closure evidence, but the active
  latest is now `20260620_160459`.
- The later `20260620_150241` Machine God's Effigy blocker is superseded by
  PG-008, closure battle `20260620_151437`, and current latest
  `20260620_160459`.

## Current Gate Reading - 2026-06-20 18:27 -0300

Latest official run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `target_pressure_statuses={"pass":16}`
- `target_pressure_findings=0`
- `table_intent_statuses={"pass":16}`
- `table_intent_findings=0`
- `table_intent_missing_scores=0`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_trace_contract_findings=0`
- `test_results_status_counts={"pass":18}`
- `unknown_template_backlog_cards=0`
- `effect_coverage_residual_unaccepted_cards=[]`

Gate reading:

- Current battle is trusted for strategy learning.
- The target-pressure-only methodology is superseded by table-intent-realistic
  evaluation for Lorehold deck review.
- The latest real-battle result should be treated as a baseline for deck
  optimization, not as proof that Lorehold is already the best list.

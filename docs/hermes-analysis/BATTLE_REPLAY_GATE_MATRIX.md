# Battle Replay Gate Matrix

Status: current as of `2026-06-23T07:32Z`.

This matrix defines the mandatory gates that must run before a battle replay is
interpreted as final evidence. A green result in one auditor is not a global
pass unless the aggregate final status also says so.

Latest accepted run:
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_072754/summary.json`.
It ran deck `6`, `start_seed=64270200`, `seeds_requested=16`,
`seeds_completed=16`, with
`run_profile=deck6_pg078_learning_gate_fix_16_seed`.
Final status is `trusted_for_strategy_learning`; all mandatory gates passed.

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

## Current Latest Reading - 2026-06-21T00:08Z

- Latest artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_000827/summary.json`
- Run scope: `recurring_full`
- Invocation kind: `codex_real_deck_after_wrath_variants`
- Seeds: `16/16`
- Start seed: `63212310`
- Final status: `trusted_for_strategy_learning`
- Final status reason: `all_mandatory_gates_pass`
- Mandatory gate divergences: `[]`
- Forensic findings: `rule=0`, `turn=0`, severity `{}`
- Replay decision findings: `turn=0`, `decision=0`
- Action findings: `0`
- Target-pressure gate: `pass` for `16/16` seeds,
  `target_pressure_findings=0`.
- Table-intent gate: `pass` for `16/16` seeds.
- Event-contract gate: `pass`, including
  `observed_unclassified_total=0` and `static_unclassified_total=0`.
- Replay-decision gate: `pass`.
- Test gate: `test_results_status_counts={"pass":18}`; compatibility fields
  `tests_passed` and `tests_total` are `null`.
- Strategy audit has only low-confidence findings:
  `strategy_findings=5`, `strategy_low_confidence_findings=5`,
  `strategy_review_required_findings=0`.

Superseded blocker note:

- `Arcane Epiphany`, seed `63212310`, turn `10`, player
  `The Emperor of Palamecia #42 (real)`, effect `draw_cards`, source
  `functional_tags_json`, appeared in superseded latest `235914`.
- `spell_cast` is medium and `spell_resolved` is high.
- SELECT-only evidence shows PostgreSQL has the `cards` row but
  `card_battle_rules` has `0` rows for `Arcane Epiphany`.
- This blocker is not present in current latest `000827`. It is separate from
  PG-015/Wrath, which is externally applied/postchecked/synced and now
  battle-validated by a trusted latest.

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
- `20260620_221652` supersedes `212035`; all mandatory gates still pass, and
  the only strategy findings remain low-confidence.
- `20260620_224455` supersedes `221652` after externally detected PG-011
  apply/sync evidence and a fresh full rerun. It is `review_required` only
  because forensic audit has six low `Flame Wave` passive-vs-remove findings;
  all other mandatory gates pass.
- `20260620_232534` supersedes `224455` after externally detected
  PG-012/PG-013/PG-014 apply/sync evidence and a fresh full rerun. It is
  `trusted_for_strategy_learning` with all mandatory gates passing; the
  `Flame Wave` residual is historical.
- `20260620_233350` supersedes `232534` after an external variant runner and is
  blocked only by `Arcane Epiphany` lacking a PG-backed battle rule. This does
  not reopen PG-012/PG-013/PG-014.
- `20260620_234004` supersedes `233350` after later external variant reruns and
  returns to `trusted_for_strategy_learning` with all mandatory gates passing.
- `20260620_234900` supersedes `234004` after the external variant sweep
  continued and is again blocked by `Arcane Epiphany` lineage. A new runner was
  active after this read, so future cycles must refresh `latest`.
- `20260620_235219` supersedes `234900` after that runner completed and returns
  to `trusted_for_strategy_learning` with all mandatory gates passing. The
  Arcane Epiphany blocker is no longer active in that latest.
- `20260620_235914` supersedes `235219` after externally detected
  PG-015/Wrath artifacts and a variant run. PG-015/Wrath is present in PG/cache,
  but the run blocks on `Arcane Epiphany` heuristic lineage.
- `20260621_000245`, `20260621_000525`, and then `20260621_000827` supersede
  `235914`; latest `000827` is `trusted_for_strategy_learning` with all
  mandatory gates passing.
  The Arcane Epiphany finding is historical unless a future latest reproduces it.

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

## Current Gate Reading - 2026-06-20 19:31 -0300

Latest official run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221652/summary.json`
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
- `target_pressure_opponent_combat_to_target=190`
- `target_pressure_opponent_combat_to_other=2`
- `target_pressure_opponent_multi_defender_attack=0`
- `table_intent_statuses={"pass":16}`
- `table_intent_findings=0`
- `table_intent_missing_scores=0`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`
- `unknown_template_backlog_cards=0`
- `effect_coverage_residual_unaccepted_card_flag_rows=0`

Gate reading:

- Current battle remains trusted for strategy learning.
- This heartbeat introduced no PostgreSQL write, deck swap, cleanup, stage,
  commit, or push.
- The local source/test worktree now includes attack-limit, attack-tax, and
  self-preservation combat regressions. This `221652` artifact was the live
  baseline until `224455` superseded it.

## Historical Gate Reading - 2026-06-20 19:48 -0300

Latest official run checked by this matrix at that checkpoint:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `forensic_rule_findings=6`
- `forensic_turn_findings=0`
- `forensic_severity_counts={"low":6}`
- `target_pressure_statuses={"pass":16}`
- `target_pressure_findings=0`
- `target_pressure_opponent_combat_to_target=284`
- `target_pressure_opponent_combat_to_other=4`
- `target_pressure_opponent_multi_defender_attack=2`
- `table_intent_statuses={"pass":16}`
- `table_intent_findings=0`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`

Gate reading:

- At that checkpoint, the battle was not blocked, but it was not fully trusted because forensic
  has low review residuals.
- The residual is `Flame Wave` runtime `passive` vs registry
  `remove_creature` on `spell_cast` and `spell_resolved` in seeds `63212248`,
  `63212253`, and `63212256`.
- PG-011 did not introduce a target-pressure, table-intent, action, or replay
  decision blocker in this rerun.

## Current Gate Reading - 2026-06-20 22:14 -0300

Latest completed run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_010452/summary.json`
- `run_scope=custom_multi_seed`
- `invocation_kind=codex_pg017_full64_real_deck_baseline`
- `seeds_requested=64`
- `seeds_completed=64`
- `start_seed=63212310`
- `battle_replay_final_status=blocked`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`
- `forensic_rule_findings=2`
- `forensic_turn_findings=0`
- `forensic_severity_counts={"high":1,"medium":1}`
- `target_pressure_statuses={"pass":64}`
- `target_pressure_findings=0`
- `table_intent_statuses={"pass":64}`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`

Gate reading:

- Current latest completed battle is blocked only by forensic lineage.
- The blocker was `Jin-Gitaxias, Core Augur` using
  `functional_tags_json` for `draw_cards` in seed `63212362`, turn `8`.
- PG-018 appeared after this completed run and was verified by read-only
  PostgreSQL postcheck plus Hermes SQLite sync evidence for `Jin-Gitaxias, Core
  Augur` and `Chandra, Flameshaper`.
- A post-PG018 64-seed runner was active at the checkpoint, so this matrix must
  be re-read after the next completed `latest` summary before calling PG-018
  battle-closed.

## Current Gate Reading - 2026-06-20 22:44 -0300

Latest completed run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_012833/summary.json`
- `run_scope=custom_multi_seed`
- `invocation_kind=codex_pg018_full64_real_deck_baseline`
- `seeds_requested=64`
- `seeds_completed=64`
- `start_seed=63212310`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["strategy_audit=review_required"]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `forensic_severity_counts={}`
- `target_pressure_statuses={"pass":64}`
- `target_pressure_findings=0`
- `table_intent_statuses={"pass":64}`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`
- `strategy_findings=17`
- `strategy_low_confidence_findings=16`
- `strategy_review_required_findings=1`

Gate reading:

- PG-018 is battle-forensic closed by this run: forensic rule and turn findings
  are zero.
- Current latest is not fully trusted because strategy audit has one
  review-required finding: `wheel_opponent_refill_risk` for
  `Jin-Gitaxias, Core Augur`, seed `63212362`, decision `decision-000141`.
- PG-019 appeared after this completed run and was verified by read-only
  PostgreSQL postcheck plus Hermes SQLite sync with `wheel_like=false`.
- A post-PG019 64-seed runner was active at the checkpoint, so PG-019 battle
  closure depends on the next completed `latest` summary.

## Current Gate Reading - 2026-06-20 23:14 -0300

Latest completed run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020427/summary.json`
- `run_scope=recurring_full`
- `invocation_kind=codex_pg019_post_apply_windborn_16`
- `seeds_requested=16`
- `seeds_completed=16`
- `start_seed=63212310`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `forensic_severity_counts={}`
- `target_pressure_statuses={"pass":16}`
- `target_pressure_findings=0`
- `table_intent_statuses={"pass":16}`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`
- `strategy_findings=5`
- `strategy_low_confidence_findings=5`
- `strategy_review_required_findings=0`

## Current Gate Reading - 2026-06-20 23:45 -0300

Latest completed run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024220/summary.json`
- `run_scope=recurring_full`
- `invocation_kind=codex_pg020_candidate_ensnaring_bridge_for_monument_16`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`
- `strategy_findings=7`
- `strategy_low_confidence_findings=7`
- `strategy_review_required_findings=0`

Gate reading:

- Completed latest is trusted for strategy learning.
- This is an Ensnaring Bridge over Monument to Endurance candidate run, not a
  PostgreSQL package/apply result.
- A newer run directory `20260621_024527` had no `summary.json` and should be
  checked next.

Final candidate reading:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024527/summary.json`
- `invocation_kind=codex_pg020_candidate_silent_arbiter_for_monument_16`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`
- No PG package/apply result was found for this candidate.

Gate reading:

- Completed latest is trusted for strategy learning.
- This trusted run is on Hermes local runtime deck state after the local
  Windborn-over-Guttersnipe optimizer apply.
- PostgreSQL materialized Lorehold deck still has `Guttersnipe`, not
  `Windborn Muse`, so this gate result is not proof of a canonical
  PostgreSQL/learned-deck swap.
- A newer 64-seed run directory `20260621_020729` was active without summary at
  this checkpoint.

Final 64-seed reading:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/summary.json`
- `invocation_kind=codex_pg019_post_apply_windborn_64`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

## PG-020 Canonical Deck Gate Reading - 2026-06-20 23:40 -0300

Latest completed run after PostgreSQL promotion and PG -> Hermes sync:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022700/summary.json`
- `invocation_kind=codex_pg020_post_pg_sync_windborn_64`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `action_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`
- `strategy_findings=15`
- `strategy_low_confidence_findings=15`
- `strategy_review_required_findings=0`

Gate reading:

- PG-020 is gate-clean after canonical PostgreSQL apply and PG -> Hermes sync.
- The remaining strategy signal is low-confidence mulligan/keep instability,
  not a mandatory replay blocker.
- The deck is still strategically underperforming at `4/64 = 6.25%`.

## Candidate Gate Reading - 2026-06-20 23:49 -0300

Latest completed candidate run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024906/summary.json`
- `invocation_kind=codex_pg020_candidate_norns_annex_for_monument_16`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- Norn's Annex candidate replay is gate-clean in the 16-seed candidate window.
- This is not a promotion record: no PG package was found for the candidate.

## Review-Required Candidate Gate Reading - 2026-06-20 23:52 -0300

Latest completed candidate run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_025233/summary.json`
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_16`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["forensic_audit=review_required", "replay_decision_audit=review_required"]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=1`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=1`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- The candidate is blocked by a low-severity board-wipe/protection turn finding
  in seed `63212318`, turn `12`.
- Do not mark this run trusted for strategy learning unless a review or clean
  rerun clears the mandatory gate.

## Review-Required Candidate Gate Reading - 2026-06-21 00:17 -0300

Latest completed candidate run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_030022/summary.json`
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_64`
- `run_scope=custom_multi_seed`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required", "replay_decision_audit=review_required"]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=1`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=1`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- The 64-seed Magus candidate confirms the same low-severity
  board-wipe/protection finding from seed `63212318`, turn `12`.
- Mandatory gates remain review-required, so this run is not trusted for
  strategy learning or PostgreSQL promotion.

## Corrected Candidate Gate Reading - 2026-06-21 00:18 -0300

Latest completed corrected candidate run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_031617/summary.json`
- `invocation_kind=codex_pg021_corrected_candidate_magus_moat_for_monument_16`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- The corrected Magus candidate clears the board-wipe/protection replay blocker
  seen in `025233` and `030022`.
- This remains candidate-only because no PG021 package exists.

## Corrected Candidate Gate Reading - 2026-06-21 00:52 -0300

Latest completed corrected candidate run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json`
- `invocation_kind=codex_pg021_corrected_candidate_silent_arbiter_for_monument_64`
- `run_scope=custom_multi_seed`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- The corrected Silent Arbiter 64-seed candidate is gate-clean.
- This remains candidate-only because no PG021 package exists.

## PG022 Post-Sync Gate Reading - 2026-06-21 01:55 -0300

Latest completed post-sync run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`
- `invocation_kind=codex_pg022_post_pg_sync_silent_arbiter_16`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- PG022 post-sync smoke is gate-clean and trusted for strategy learning.
- Full post-sync confirmation is now available in
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`.

## PG022 Full Post-Sync Gate Reading - 2026-06-21 01:58 -0300

Latest completed post-sync run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`
- `invocation_kind=codex_pg022_post_pg_sync_silent_arbiter_64`
- `run_scope=custom_multi_seed`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- PG022 full post-sync run is gate-clean and trusted for strategy learning.

## Post-PG022 Candidate Gate Reading - 2026-06-21 02:27 -0300

Latest completed candidate run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_052416/summary.json`
- `run_profile=candidate_reprieve_for_generous_gift_16`
- `invocation_kind=codex_candidate_scan`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["strategy_audit=review_required"]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=1`

Gate reading:

- The Reprieve over Generous Gift candidate is not learning-eligible because
  strategy audit requires review.
- The blocker is strategy-level, not forensic, replay-decision,
  target-pressure, table-intent, or test-suite failure.
- Intermediate `20260621_051800` Brainstone and `20260621_052117`
  Artist's Talent candidate scans were gate-clean, but remain candidate-only
  without PostgreSQL packages or approved apply commands.

## Post-Engine-Fix Candidate Gate Reading - 2026-06-21 03:06 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_054803/summary.json`
- `run_profile=recurring_16_seed`
- `invocation_kind=codex_candidate_combo_scan`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- The latest combo scan is gate-clean and trusted for strategy learning.
- It is still poor deck evidence: Lorehold wins only `1/16`, and
  `forced_keep_after_bad_mulligan=7`.
- It does not create a PostgreSQL deployment signal without a package and
  explicit approval.

## Aborted Runner Gate Reading - 2026-06-21 04:48 -0300

Newer incomplete run directory:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_060733/`
- No `summary.json`.
- `py_compile=pass`.
- `test_battle_analyst_v10_3=failed` after `963s`.
- Failure:
  `psycopg2.OperationalError: server closed the connection unexpectedly` during
  PG setup for `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`.

Gate reading:

- `060733` has no battle gate status because the wrapper did not publish a
  summary.
- Follow-up read-only PG `select 1` succeeded, so this is classified as an
  aborted/transient runner artifact rather than current PG unavailability.
- Keep `054803` as the latest completed gate reading.

## Latest Manual 64-Seed Gate Reading - 2026-06-21 05:17 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json`
- `run_profile=custom_64_seed`
- `invocation_kind=manual_cli`
- `run_scope=custom_multi_seed`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- `080706` supersedes `054803` as the latest completed gate reading.
- The replay is fully gate-clean and trusted for strategy learning.
- Strategy remains low-confidence in 10 seeds and reports
  `forced_keep_after_bad_mulligan=13`.

## PG023 Post-Sync Full Gate Reading - 2026-06-21 10:07 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`
- `run_profile=custom_64_seed`
- `invocation_kind=manual_cli`
- `run_scope=custom_multi_seed`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- `122732` supersedes `080706` as the latest completed gate reading after
  PG023 was applied externally and synced into Hermes SQLite.
- The replay is fully gate-clean and trusted for strategy learning.
- Strategy remains low-confidence in 10 seeds and reports
  `forced_keep_after_bad_mulligan=13`.
- This is not a battle-gate blocker; it is remaining strategy quality work.

## Temporary Expedition Map Candidate Gate Reading - 2026-06-21 10:15 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131126/summary.json`
- `run_profile=recurring_16_seed`
- `invocation_kind=manual_cli`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- `131126` supersedes `122732` as the latest symlink target.
- Gates are clean, but the observed temporary candidate produced only
  `1/16` Lorehold wins and is not promotion evidence.
- No battle-gate repair is needed from this artifact.

## Latest PG023 Recurring Smoke Gate Reading - 2026-06-21 10:20 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131606/summary.json`
- `run_profile=recurring_16_seed`
- `invocation_kind=manual_cli`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- `131606` supersedes `131126` as the latest symlink target.
- Gates are clean; strategy remains weak at `3/16` Lorehold wins and
  `forced_keep_after_bad_mulligan=5`.

## Temporary Thrill Candidate Gate Reading - 2026-06-21 10:25 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132027/summary.json`
- `run_profile=recurring_16_seed`
- `invocation_kind=manual_cli`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`

Gate reading:

- `132027` supersedes `131606` as the latest symlink target.
- Gates are clean; strategy remains weak at `2/16` Lorehold wins and
  `forced_keep_after_bad_mulligan=4`.
- No gate repair follows from this artifact.

## Temporary Reprieve Candidate Gate Reading - 2026-06-21 10:30 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`
- `run_profile=recurring_16_seed`
- `invocation_kind=manual_cli`
- `run_scope=recurring_full`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`

Gate reading:

- `132537` supersedes `132027` as the latest symlink target.
- Gates are clean; strategy remains weak at `4/16` Lorehold wins and
  `forced_keep_after_bad_mulligan=5`.
- No gate repair follows from this artifact.

## PG023 Candidate Scan Gate Classification - 2026-06-21 10:30 -0300

- New artifact:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_pg023_candidate_scan_20260621_132537.md`.
- All four candidate runs were trusted/clean at the gate level:
  `131126`, `131606`, `132027`, and `132537`.
- Artifact status is `no_promotion`; these are strategy-quality failures, not
  battle-gate failures.
- Correction: `131606` is classified as temporary `Reforge the Soul` over
  `Boros Charm`, not canonical PG023 smoke.

## PG023 Post-Sync Gate Reading - 2026-06-21 10:06 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`
- `run_profile=custom_64_seed`
- `invocation_kind=manual_cli`
- `run_scope=custom_multi_seed`
- `seeds_requested=64`
- `seeds_completed=64`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `target_pressure_statuses={"pass":64}`
- `table_intent_statuses={"pass":64}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- `122732` supersedes `080706` as the latest completed gate reading because it
  ran after PostgreSQL apply and PG -> Hermes sync.
- The post-sync replay is fully gate-clean and trusted for strategy learning.
- Strategy remains low-confidence in 10 seeds and reports
  `forced_keep_after_bad_mulligan=13`; this is a deck consistency backlog, not
  a gate blocker.

## PG023 Candidate Gate Reading - 2026-06-21 10:06 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`
- Candidate: `Reprieve` over `Boros Charm`.
- `seeds_completed=16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`

Gate reading:

- The run is technically trusted, but it is a rejected candidate because it
  does not improve PG023 smoke. It ties win count (`4/16`) while worsening
  pressure to Lorehold (`267` versus `222`) and low-confidence strategy count
  (`5` versus `2`).
- Do not treat `latest` as canonical runtime state just because the symlink now
  points to this rejected candidate. Canonical runtime validation remains
  `20260621_122732` until another post-apply/post-sync full run supersedes it.

## Focused Zone Transition Gate Reading - 2026-06-21 11:03 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_140346/summary.json`
- `run_profile=focused_zone_transition_fix_v3`
- `run_scope=focused_seed`
- `invocation_kind=codex_focused_zone_transition_fix_63212310_v3`
- `seeds_completed=1/1`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":1}`
- `table_intent_statuses={"pass":1}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`

Gate reading:

- `latest` now points to `140346`; this supersedes the older `132537` pointer
  as symlink state only.
- The run validates the focused zone-transition runtime path and is trusted at
  the gate level.
- It is not a full deck validation, not a candidate promotion signal, and not a
  PostgreSQL deploy signal.
- Canonical Lorehold deck validation remains PG023 full run `20260621_122732`
  until another post-sync/post-apply full run supersedes it.

## PG023 Combat-Survival Rebaseline Gate Reading - 2026-06-21 11:30 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_142400/summary.json`
- `run_profile=pg023_rebaseline_after_combat_survival_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=codex_pg023_rebaseline_after_combat_survival_response`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":2}`
- `strategy_severity_counts={"medium":2}`

Gate reading:

- The rebaseline is trusted and gate-clean.
- It supersedes `140346` as latest symlink state, but it is a poor strategy
  outcome: Lorehold won `1/16` and opponents won `15/16`.
- This is not a battle-gate blocker and not a PostgreSQL deploy signal.
- Use it as deck-strategy pressure evidence for the next Lorehold iteration.

## PG023 Priority-Fix And Angel's Grace Gate Reading - 2026-06-21 12:04 -0300

Recent completed runs:

- `20260621_140846`: `pg023_rebaseline_after_zone_fix_16_seed`, trusted,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`, table-intent
  `pass=16`, tests `pass=18`, Lorehold `2/16`.
- `20260621_141620`: `pg023_rebaseline_after_reactive_hold_16_seed`, trusted,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`, table-intent
  `pass=16`, tests `pass=18`, Lorehold `1/16`.
- `20260621_144336`: `candidate_angels_grace_for_boros_16_seed`, blocked,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `20260621_145423`:
  `pg023_rebaseline_after_cannot_lose_priority_fix_16_seed`, trusted,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`, table-intent
  `pass=16`, tests `pass=18`, Lorehold `1/16`.
- `20260621_145948`:
  `candidate_angels_grace_for_boros_after_priority_fix_16_seed`, trusted,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`, table-intent
  `pass=16`, tests `pass=18`, Lorehold `2/16`, opponents `13/16`.

Gate reading:

- `145948` supersedes `142400` as latest symlink state.
- `144336` is blocked and cannot be treated as valid strategy evidence.
- `145948` is technically trusted but is a rejected candidate: clean gates do
  not overcome the poor `2/16` result.
- No battle-gate issue requires PostgreSQL rollback; the issue remains deck
  strategy under pressure.

## Latest Manual 16-Seed Review Gate Reading - 2026-06-21 12:35 -0300

Latest completed summary at read time:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_151645/summary.json`
- `run_profile=recurring_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=manual_cli`
- `seeds_completed=16/16`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required","replay_decision_audit=review_required","strategy_audit=review_required"]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=4`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":4,"resource_cost_without_selection_context":1,"spending_unique_color_land":1,"tutor_no_target":2}`
- `strategy_severity_counts={"low":1,"medium":7}`

Gate reading:

- `151645` supersedes `145948` as latest symlink state.
- It is not blocked, but it is not trusted; three mandatory gates require
  review.
- Target-pressure/table-intent/tests are green, so the open issue is
  forensic/replay-decision/strategy review rather than a PostgreSQL deployment
  issue.
- An external runner was still active during the read, so treat this as a
  checkpoint until a later heartbeat confirms final state.

## PG023 Oracle-Specific Finisher Contract Gate Reading - 2026-06-21 12:37 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_152154/summary.json`
- `run_profile=pg023_rebaseline_after_oracle_specific_finisher_contract_fix_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=codex_pg023_rebaseline_after_oracle_specific_finisher_contract_fix`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":2}`
- `strategy_severity_counts={"medium":2}`

Gate reading:

- `152154` supersedes `151645` as latest symlink state and clears its review
  gates.
- The battle pipeline is trusted again, but Lorehold still only wins `1/16`.
- This is not a PostgreSQL deploy or rollback signal.

## Magus Candidate Gate Reading - 2026-06-21 13:03 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_153944/summary.json`
- `run_profile=candidate_magus_of_the_moat_for_electroduplicate_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=codex_candidate_magus_of_the_moat_for_electroduplicate_16_seed`
- `seeds_completed=16/16`
- `battle_replay_final_status=blocked`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`
- `mandatory_gate_divergences=["strategy_audit=blocked"]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=2`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":2,"spending_last_land":1,"spending_unique_color_land":1}`
- `strategy_severity_counts={"high":1,"medium":3}`

Gate reading:

- `153944` supersedes `152154` as latest symlink state, but it is blocked.
- The candidate cannot be used as trusted strategy evidence or promotion
  evidence while `strategy_audit=blocked`.
- This is not a PostgreSQL deploy or rollback signal.

## Magus Candidate After Mox Trace Fix Gate Reading - 2026-06-21 13:19 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_160405/summary.json`
- `run_profile=candidate_magus_of_the_moat_for_electroduplicate_after_mox_trace_fix_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=codex_candidate_magus_of_the_moat_for_electroduplicate_after_mox_trace_fix_16_seed`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":2}`
- `strategy_severity_counts={"medium":2}`

Gate reading:

- `160405` supersedes `153944` as latest symlink state and clears its strategy
  blocker.
- It is trusted evidence, but still not a promotion signal: Lorehold won
  `3/16`.
- This is not a PostgreSQL deploy or rollback signal.

## Victory Chimes Rule Fix Gate Reading - 2026-06-21 13:52 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_164710/summary.json`
- `run_profile=recurring_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=manual_cli`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":2}`
- `strategy_severity_counts={"medium":2}`

Gate reading:

- `164710` supersedes `164101` as latest symlink state and remains
  gate-clean.
- The Victory Chimes draw/ramp modeling pending item is closed by reviewed-rule
  source, SQLite sync evidence, focused tests, and battle rebaseline.
- It is not a promotion signal: Lorehold won only `2/16`.
- This is not a PostgreSQL deploy or rollback signal.

## Magus Same-Seed Candidate After Victory Fix Gate Reading - 2026-06-21 14:38 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_173334/summary.json`
- `run_profile=candidate_magus_after_victory_chimes_fix_same_seed_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=codex_candidate_magus_after_victory_chimes_fix_same_seed_16_seed`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=0`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":2}`
- `strategy_severity_counts={"medium":2}`

Gate reading:

- `173334` supersedes `164710` as latest symlink state and remains gate-clean.
- It is trusted candidate evidence, but not a promotion signal: Lorehold won
  `3/16`.
- This is not a PostgreSQL deploy or rollback signal.

## Runtime Cache Drift After Latest Battle - 2026-06-21 14:42 -0300

Current gate reading:

- Battle `latest` still points to `20260621_173334`; no newer completed battle
  artifact exists.
- Current local SQLite deck `6` has changed after latest battle to focused
  `Magus of the Moat` plus `Sphere of Safety`.
- Backup
  `knowledge_db_backup_candidate_magus_sphere_after_victory_fix_20260621_174200.sqlite`
  preserves the prior focused `Electroduplicate` plus `Victory Chimes` shape.

Gate interpretation:

- There is no battle gate verdict yet for the current Magus+Sphere runtime
  state.
- Treat this as active runtime-cache drift/candidate state, not as trusted
  strategy evidence and not as PostgreSQL deploy or rollback evidence.

## Magus+Sphere Candidate Review Required Gate Reading - 2026-06-21 14:46 -0300

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_174142/summary.json`
- `run_profile=candidate_magus_sphere_after_victory_fix_same_seed_16_seed`
- `run_scope=recurring_full`
- `invocation_kind=codex_candidate_magus_sphere_after_victory_fix_same_seed_16_seed`
- `seeds_completed=16/16`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required","replay_decision_audit=review_required","strategy_audit=review_required"]`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_review_required_findings=1`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":3,"tutor_no_target":1}`
- `strategy_severity_counts={"medium":4}`

Gate reading:

- `174142` supersedes `173334` as latest symlink state.
- It is not trusted strategy-learning evidence because mandatory gates require
  review.
- The higher `5/16` candidate outcome is not promotable until those gates are
  closed with concrete evidence.
- This is not a PostgreSQL deploy or rollback signal.

## Quantity Guard Candidate Gate Readings - 2026-06-21 15:32 -0300

Loader correction:

- A battle-source contamination bug was fixed in `load_deck_cards()`: local
  candidate cuts stored as `quantity=0` are no longer loaded as one copy.
- The fix is covered by `test_load_deck_ignores_zero_quantity_rows` and the
  full `test_battle_analyst_v10_3.py` suite passed.

Gate readings:

- `20260621_175408` is superseded as promotion evidence because its mandatory
  battle gates were green while Lorehold deck provenance still had a deck-source
  error caused by zero-quantity loading.
- `20260621_180442` is the first clean Magus+Sphere candidate after the guard:
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  `deck_source_blocker_domains={"none":64}`, tests `pass=18`,
  target-pressure/table-intent `pass=16/16`, Lorehold `5/16`.
- `20260621_181316` Magus+Sphere+Wrath is gate-clean but lower at Lorehold
  `4/16`.
- `20260621_181905` Magus+Sphere+Norn's Annex is gate-clean at Lorehold
  `5/16`, opponents `10/16`, one stall; it does not improve the clean
  Magus+Sphere result and has five low-confidence mulligan findings.

Gate interpretation:

- Current latest `20260621_181905` is valid battle evidence but not promotion
  evidence.
- A green aggregate final status still requires deck-source provenance review
  before deck-swap interpretation.
- No PostgreSQL apply/rollback or official deck swap is authorized by these
  candidate results.

## HandCards Replay And Survival-Reserve Gate Reading - 2026-06-22 12:10 -0300

Replay/gate change:

- `replay.txt` now exposes `HandCards=[...]` in mulligan, turn-start, and
  turn-end output. The replay artifact can now be audited against the actual
  cards held by each player.
- Low-life main-phase play now reserves mana for survival response effects so
  Lorehold does not spend below the mana needed to hold cards such as
  `Teferi's Protection` when already near lethal pressure.
- Stack cast-ledger recovery was added and tested to prevent action critic
  drift where a non-triggered spell can resolve without a visible cast ledger.

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_121049/summary.json`
- `run_profile=survival_reserve_full_gate_clean_16_seed`
- `invocation_kind=codex_survival_reserve_full_gate_clean_16_seed`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`
- `table_intent_statuses={"pass":16}`
- `target_pressure_statuses={"pass":16}`
- `strategy_review_required_findings=0`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":7}`
- `strategy_low_confidence_seeds=["63231111","63231114","63231116","63231121","63231124"]`

Outcome reading:

- Lorehold wins `2/16`; opponents win `13/16`; one seed has no winner/stall.
- Target pressure remains extreme: opponent combat to Lorehold `303`, to other
  players `11`.
- Seed `63231123` is the positive proof case: the replay shows the hand,
  preserves the survival response line, casts `Windborn Muse` only with enough
  mana left, and Lorehold ends alive.

Gate interpretation:

- This supersedes the previous `review_required` survival-reserve run
  `20260622_115553`; the focused seed cleanup `20260622_120747` and full
  rerun `20260622_121049` are gate-clean.
- The battle/replay gates are green for this implementation change.
- This is not PostgreSQL deploy evidence and not a deck-swap promotion signal;
  the remaining work is deck/mulligan consistency under focused table pressure.

## Opening Fetch Mulligan Gate Reading - 2026-06-22 12:25 -0300

Gate change:

- Opening-hand evaluation now treats fetchlands as flexible color fixing for
  mulligan decisions. This is scoped to mulligan/opening-hand analysis and does
  not change PostgreSQL data, deck rows, or global land `source_colors()`.
- The fix addresses a concrete false negative from seed `63231121`, where a
  Lorehold hand with `Bloodstained Mire`, `Urza's Saga`, `Esper Sentinel`,
  `Land Tax`, and `Ghostly Prison` was marked off-color even though the fetch
  should support early white access in deck-context evaluation.

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_122526/summary.json`
- `run_profile=opening_fetch_fix_full_16_seed`
- `invocation_kind=codex_opening_fetch_fix_full_16_seed`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`
- `table_intent_statuses={"pass":16}`
- `target_pressure_statuses={"pass":16}`
- `strategy_review_required_findings=0`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":1}`
- `strategy_low_confidence_seeds=["63231124"]`

Delta versus previous full gate-clean run `20260622_121049`:

- Lorehold outcome remains `2/16`; opponents remain `13/16`.
- Target pressure remains extreme but slightly lower in aggregate:
  opponent combat to Lorehold `296` vs previous `303`; to other players `10`
  vs previous `11`.
- Low-confidence mulligan findings improved from `7` across five seeds to `1`
  in one seed.
- The remaining low-confidence seed `63231124` is opponent-owned: the forced
  keep belongs to Sisay, not Lorehold.

Gate interpretation:

- The current replay/battle evidence is cleaner and high-confidence for
  Lorehold-specific learning.
- The deck itself remains unresolved because the win rate did not improve.
- Next gate work should analyze the current high-confidence Lorehold losses
  directly; do not keep using the superseded five-seed low-confidence set as the
  main deck-quality evidence.

## Survival Defense And Counter-Legality Gate Matrix - 2026-06-22 12:48 UTC

Artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_124815/summary.json`

Statuses:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16/16`
- `test_results_status_counts={"pass":18}`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":1}`
- `strategy_low_confidence_seeds=["63231124"]`

Gate rows:

- Replay hand visibility: pass. `replay.txt` includes `HandCards=[...]` in
  mulligan, turn-start, and turn-end records.
- Survival response reservation: pass for observed seed `63231114`. Lorehold
  holds and casts `Teferi's Protection` before lethal combat damage.
- Proactive combat defense priority: pass for observed seed `63231114`.
  Lorehold casts/resolves `Windborn Muse` before non-defense lines at life `1`.
- Counter target legality: pass for observed seed `63231114`. Thrasios keeps
  `Mental Misstep` in hand instead of countering mana-value-four `Windborn
  Muse`.
- Strategy result: fail as deck-quality evidence. Lorehold remains `2/16` and
  receives `316` opponent combat pressure versus `13` pressure to other
  players.

Reading:

- The gate matrix is clean enough to trust the loss data.
- The current failure is deck/strategy quality under table focus, not a replay
  rendering defect or known counter-legality defect.

## PG024 Mental Misstep Registry Gate Matrix - 2026-06-22 13:07 UTC

Artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130732/summary.json`

Statuses:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16/16`
- `test_results_status_counts={"pass":18}`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":1}`
- `strategy_low_confidence_seeds=["63231124"]`

Gate rows:

- PostgreSQL source rule: pass. `Mental Misstep` has a curated verified/auto
  rule with `counter_target_cmc=1`.
- SQLite/Hermes sync: pass. Sync report shows `pg_rows_loaded=3` and
  `sqlite_inserted_or_updated=3`.
- Runtime waiver removal: pass. `Mental Misstep` is absent from
  `MANUAL_RULE_RUNTIME_WAIVERS` and resolves from SQLite/PG registry.
- Focused replay: pass. Seed `63231114` still shows `Windborn Muse` resolving
  while Thrasios keeps `Mental Misstep` in hand.
- Full replay gate: pass. Latest `130732` remains trusted and gate-clean.
- Deck strategy: fail/unresolved. Lorehold remains `2/16` under the same
  16-seed window.

## PG025 The One Ring / Orim's Chant Registry Gate Matrix - 2026-06-22 15:29 UTC

Artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_152901/summary.json`

Statuses:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16/16`
- `test_results_status_counts={"pass":18}`
- `strategy_low_confidence_seeds=["63231318","63231327"]`

Gate rows:

- PostgreSQL source rules: pass. `The One Ring` has exact curated verified/auto
  rule `battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1`; `Orim's Chant` has
  exact curated verified/auto rule
  `battle_rule_v1:2332a82b6395a065b6516702d3e326c7`.
- SQLite/Hermes sync: pass. Sync report shows `pg_rows_loaded=6`,
  `sqlite_inserted_or_updated=6`, and `canonical_snapshot_rows_exported=3193`.
- Runtime selection: pass. `get_card_effect` resolves both cards from the new
  SQLite/PG logical keys.
- Replay event contract: pass. `seed_63231322/replay.events.jsonl` lines
  `453-461` show `The One Ring` granting protection from everything with the
  PG025 logical key; `seed_63231314/replay.events.jsonl` lines `533-537` show
  kicked `Orim's Chant` preventing attack declaration with the PG025 logical
  key.
- Replay text observability: pass. `replay.txt` includes `HandCards=[...]` in
  opening/turn/final summaries and renders `PREVENT ATTACK` for kicked
  `Orim's Chant`.
- Deck strategy: fail/unresolved. The controlled comparable matrix remains
  Lorehold `0/16`, opponents `16/16`, pressure to Lorehold `296`, pressure to
  other players `4`.

Reading:

- The gate matrix is clean for learning from the current failures.
- The next work is deck construction/strategy, not another replay gate fix for
  these two cards.

## PG026 Magus+Sphere Official Deck Gate Matrix - 2026-06-22 17:09 UTC

Artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_170304/summary.json`

Statuses:

- `run_profile=pg026_magus_sphere_post_deploy_16_seed`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16`
- `test_results_status_counts={"pass":18}`
- `table_intent_statuses={"pass":16}`
- `target_pressure_statuses={"pass":16}`

Gate rows:

- PostgreSQL deck deploy: pass. PG026 postcheck confirms
  `Magus of the Moat=1`, `Sphere of Safety=1`, `Electroduplicate=0`,
  `Victory Chimes=0`, deck quantity `100`.
- SQLite/Hermes deck sync: pass. Deck `6` has rows/quantity `100/100`,
  `sync_run_id=20260622T170115Z`, and direct rows for Magus/Sphere.
- Replay text hand visibility: pass. `replay.txt` includes `HandCards=[...]`
  in mulligan/opening, turn-start, turn-end, cleanup, and final summaries.
- Table intent: pass. `table_intent_statuses={"pass":16}` with no blocking
  table-intent findings.
- Target pressure: pass. `target_pressure_statuses={"pass":16}` with no
  blocking target-pressure findings.
- Deck strategy: improved but unresolved. Lorehold won `6/16`; opponents won
  `10/16`.

Reading:

- This matrix is the current official deck baseline after PG026.
- The replay is trusted for strategy learning and for loss-pattern analysis.
- The next gate is not observability or PG sync; it is classifying the ten
  remaining losses and testing the next deck change against this baseline.

## Lorehold Variant 01 Deck 606 Gate Matrix - 2026-06-22 18:17 UTC

Artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_181727/summary.json`

Statuses:

- `run_profile=lorehold_variant01_deck606_16_seed_trusted_final`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16/16`
- `test_results_status_counts={"pass":18}`
- `target_pressure_statuses={"pass":16}`
- `table_intent_statuses={"pass":16}`
- `action_findings=0`
- `forensic_severity_counts={}`
- `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`
- `lorehold_deck_source_ref=deck_id:606`

Gate rows:

- Candidate intake: pass. Stager report
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260622_175032.json`
  validates the pasted list as `100/99/1` with zero issues and zero warnings.
- Candidate isolation: pass. The list was materialized to isolated
  `deck_cards.deck_id=606`; official deck `6` was not swapped.
- Deck provenance: pass. `seed_64270208/deck_provenance.json` confirms
  `source_ref=deck_id:606`, `target_deck_id=606`, valid construction, no
  off-color cards, and no singleton violations.
- Replay text observability: pass. `replay.txt` includes `HandCards=[...]` in
  turn and final summaries.
- Action critic: pass. No action findings; cleanup hand-size checks now account
  for no-maximum-hand-size permanents.
- Forensic audit: pass. Variant-specific modeled effects are recognized by the
  forensic support matrix.
- Decision audit: pass. No critical, high, medium, or low findings; land-tutor
  artifact traces include rejected options where relevant.
- Strategy result: fail as a promotion candidate. Variant 01 won `1/16`
  (`6.25%`) versus the PG026 official baseline of `6/16` (`37.5%`).

Reading:

- This matrix is clean enough for strategy learning.
- Variant 01 should be retained as a rejected candidate and should not be
  promoted to official deck `6`.
- The approved workflow for future pasted Lorehold decklists is candidate
  staging, isolated deck id materialization, trusted battle matrix, and only
  then a PostgreSQL deck swap if the candidate beats the current baseline.

## PG028 Austere Command Focused Event Gate - 2026-06-22 19:10 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_replay_summary_20260622_190701.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_events_20260622_190701.jsonl`.
- Decision trace:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_decision_trace_20260622_190701.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted rule key is
  `battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime selection: pass. The executor selected two modes from
  `modal_destroy_modes`.
- Event contract: pass. `board_wipe_resolved` includes the logical rule key,
  oracle hash, selected modes, destroyed cards, and separated permanent versus
  creature counters.

Reading:

- This closes card-level event proof for `Austere Command`.
- It proves modal destroy resolution for the card rule; it is not evidence for
  broader deck promotion or strategy win-rate changes.

## PG029 Blasphemous Act Focused Event Gate - 2026-06-22 19:29 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_replay_summary_20260622_192517.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_events_20260622_192517.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted rule key is
  `battle_rule_v1:56271789d639ef390213dbc90059e4d2`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime resolution: pass. `damage_wipe_resolved` destroyed creatures with
  toughness `<=13`, preserved an indestructible creature, and preserved a
  toughness-14 creature.
- Event contract: pass. `spell_resolved` and `damage_wipe_resolved` both
  include the PG029 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Blasphemous Act` damage resolution.
- The card's cost reduction is represented as `annotation_only` metadata in
  the PG rule; this focused event does not prove dynamic cost reduction.

## PG030 Boros Charm Focused Event Gate - 2026-06-22 19:42 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_replay_summary_20260622_193818.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_events_20260622_193818.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted rule key is
  `battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime protection mode: pass. `modal_boros_charm_resolved` selected
  `permanents_you_control_gain_indestructible_until_eot` and affected a
  creature, artifact, enchantment, and land until cleanup.
- Runtime combat mode: pass. `modal_boros_charm_resolved` selected
  `target_creature_gains_double_strike_until_eot` and affected exactly one
  creature until cleanup.
- Event contract: pass. `spell_resolved` and `modal_boros_charm_resolved`
  both include the PG030 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Boros Charm` protection/combat
  modal resolution.
- The card's 4 damage player/planeswalker mode is represented as
  `annotation_only` metadata in the PG rule; this focused event does not prove
  direct modal damage target selection.

## PG031 Deflecting Swat Focused Event Gate - 2026-06-22 19:56 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_replay_summary_20260622_195126.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_events_20260622_195126.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted rule key is
  `battle_rule_v1:bac48343654a53205d790a8268bd2631`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime free-cast condition: pass. `spell_cast` for `Deflecting Swat`
  includes `alternative_cost={0}` and
  `alternative_cost_kind=control_commander` with zero available mana.
- Runtime redirect resolution: pass. `redirect_removal_resolved` changed the
  target from `Protected Creature` to `Opponent Threat`; the protected
  creature survived and the opponent threat was removed.
- Event contract: pass. `spell_cast` and `redirect_removal_resolved` both
  include the PG031 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Deflecting Swat` free-cast
  redirection of a single-target removal spell.
- The card's broader spell-or-ability target class is represented as
  `annotation_only` metadata for activated/triggered abilities; this focused
  event does not prove ability target redirection.

## PG032 Flawless Maneuver Focused Event Gate - 2026-06-22 20:10 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_replay_summary_20260622_200215.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted rule key is
  `battle_rule_v1:73622071c1ad89267708f914a0729bf2`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime free-cast condition: pass. `spell_cast` for `Flawless Maneuver`
  includes `alternative_cost={0}` and
  `alternative_cost_kind=control_commander` with zero available mana.
- Runtime protection resolution: pass. `protection_resolved` granted
  indestructible to `Lorehold, the Historian` and `Protected Creature`; both
  survived `Blasphemous Act`.
- Event contract: pass. `spell_cast`, `spell_resolved`, and
  `protection_resolved` include the PG032 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Flawless Maneuver` free-cast
  protection of creatures controlled by the player.
- `Blasphemous Act` appears in this focused event as the incoming wipe, but its
  PG029 cost reduction remains `annotation_only`; this gate proves Flawless
  protection, not dynamic Blasphemous Act cost reduction.

## PG033 Land Tax Focused Event Gate - 2026-06-22 20:25 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_replay_summary_20260622_201417.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_events_20260622_201417.jsonl`.
- Decision trace:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_decision_trace_20260622_201417.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted rule key is
  `battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime condition: pass. `land_tax_trigger_resolved` fired only because the
  live opponent controlled 3 lands while the controller controlled 1.
- Runtime tutor resolution: pass. The executor moved exactly three basic land
  cards from library to hand and left nonbasic `Command Tower` in library.
- Event contract: pass. `spell_resolved`, `land_tax_trigger_resolved`, and
  `land_tax_upkeep_tutor` include the PG033 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Land Tax` beginning-of-upkeep basic
  land tutoring when an opponent controls more lands.
- Reveal and shuffle are represented as structured metadata in this focused
  deterministic replay; this gate does not prove randomized library order after
  the search.

## PG034 Lightning Greaves Focused Event Gate - 2026-06-22 20:36 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_replay_summary_20260622_202908.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_events_20260622_202908.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted rule key is
  `battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac`.
- SQLite/Hermes sync: pass after corrected local reviewed-runtime cache sync.
  The first post-PG034 selective sync exposed stale local cache filtering; the
  retry report selected the new active PostgreSQL rule.
- Runtime attach resolution: pass. `equipment_attached` granted haste and
  shroud to `Target Creature`.
- Negative shadow proof: pass. The target did not gain indestructible.
- Event contract: pass. `spell_resolved` and `equipment_attached` both include
  the PG034 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Lightning Greaves` haste/shroud
  equipment behavior under the current battle model.
- The current runtime model is the documented approximation
  `auto_attach_best_creature_on_resolution`; this gate does not prove full
  Equipment attach/retarget timing.

## PG035 Lorehold, the Historian Focused Event Gate - 2026-06-22 20:52 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_replay_summary_20260622_204549.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_events_20260622_204549.jsonl`.
- Decision trace:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_decision_trace_20260622_204549.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Lorehold rule key is
  `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db` and aligning the local
  reviewed-runtime cache.
- Runtime upkeep rummage: pass. `lorehold_upkeep_rummage` discarded
  `Nine Mana Spell`, drew `Reforge the Soul`, and emitted the PG035 rule
  provenance.
- Event contract: pass. `lorehold_upkeep_rummage` includes the PG035 logical
  rule key and oracle hash.

Reading:

- This closes card-level event proof for `Lorehold, the Historian` as a
  miracle/rummage commander under the current battle model.
- The runtime model covers opponent-upkeep rummage and first-draw miracle
  windows; this gate does not claim every Magic policy edge for miracle,
  replacement effects, or timing choices.

## PG036 Past in Flames Focused Event Gate - 2026-06-22 21:11 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_replay_summary_20260622_210425.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_events_20260622_210425.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Past in Flames rule key is
  `battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime flashback grant: pass. `graveyard_flashback_granted` granted
  flashback to `Battle Cantrip` and `Reforge the Soul`, and did not grant it to
  `Monastery Mentor`.
- Runtime flashback cast provenance: pass. `flashback_cast` for
  `Battle Cantrip` includes
  `flashback_granted_rule_key=battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be`.
- Event contract: pass. `spell_resolved` and
  `graveyard_flashback_granted` both include the PG036 logical rule key and
  oracle hash.

Reading:

- This closes card-level event proof for `Past in Flames` as a temporary
  graveyard flashback grant under the current battle model.
- The runtime model does not claim full priority/timing policy for every
  possible flashback spell. The base flashback exile-on-resolution path is
  covered by `test_flashback_cast_from_graveyard_exiles_after_resolution`.

## PG037 Path to Exile Focused Event Gate - 2026-06-22 21:25 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_pg037_focused_replay_summary_20260622_212057.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_pg037_focused_events_20260622_212057.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Path to Exile rule key is
  `battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime target zone: pass. The opponent `Siege Rhino` left battlefield and
  was placed in exile, not graveyard.
- Runtime spell zone: pass. The `Path to Exile` instant itself resolved to
  graveyard.
- Compensation caveat: pass. The target-controller basic-land rider is
  emitted as `basic_land_compensation_status=annotation_only`; no dynamic
  search/shuffle/ramp executor is claimed.
- Event contract: pass. `spell_resolved` and `removal_resolved` both include
  the PG037 logical rule key and oracle hash.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG047 Archaeomancer's Map Focused Event Gate - 2026-06-23 00:17 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_events_20260623_001244.jsonl`.
- Focused summary:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_replay_summary_20260623_001244.md`.
- Focused decision trace:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_decision_trace_20260623_001244.jsonl`
  (empty; no runtime decision was needed).
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_apply_20260623_001244.sql`.

Gate:

- Event `spell_resolved` includes:
  `rule_logical_key=battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e`.
- Event `spell_resolved` includes:
  `rule_oracle_hash=22b82ca6bbef42371227bc38a9a546b5`.
- Event `tutor_resolved` uses the same PG047 rule, finds two basic Plains,
  and puts them into hand while the artifact remains on the battlefield.
- Successful `trigger_resolved` uses the same PG047 rule and records land
  counts proving the Map controller is behind before putting a land from hand
  onto the battlefield.
- Equal-land `trigger_skipped` uses the same PG047 rule, records
  `reason=opponent_does_not_control_more_lands`, and preserves the land in
  hand.

Status:

- `Archaeomancer's Map` is closed for the current battle-rule coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_001717.json`
  reports `Archaeomancer's Map` as `pass`.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG048 Blind Obedience Focused Event Gate - 2026-06-23 00:35 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_pg048_focused_events_20260623_003029.jsonl`.
- Focused summary:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_pg048_focused_replay_summary_20260623_003029.md`.
- Focused decision trace:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_pg048_focused_decision_trace_20260623_003029.jsonl`
  (empty; no runtime decision was needed).
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_apply_20260623_003029.sql`.

Gate:

- Event `static_enter_tapped_applied` includes:
  `rule_logical_key=battle_rule_v1:40f23fcea3b7955bacd550a9090c6872`.
- Event `static_enter_tapped_applied` includes:
  `rule_oracle_hash=4e62bff316f784c1b468b9e53146d2aa`.
- The focused replay proves an opponent creature enters tapped from the Blind
  Obedience static source.
- The focused replay proves an opponent artifact enters tapped from the same
  source.
- The controller's own artifact does not enter tapped from its own Blind
  Obedience source.

Status:

- `Blind Obedience` is closed for the current battle-rule coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_003552.json`
  reports `Blind Obedience` as `pass`.

Caveats:

- Extort remains `annotation_only`; this gate does not claim a dynamic optional
  `{W/B}` payment trigger executor.
- This gate proves normal permanent entry paths covered by the current runtime
  hook. It does not claim unrelated alternate-entry code paths that bypass
  `prepare_entering_permanent`.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG038 Reverberate Focused Event Gate - 2026-06-22 21:43 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_replay_summary_20260622_213615.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_events_20260622_213615.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Reverberate rule key is
  `battle_rule_v1:0269136edf067f696c8576740b720e14`.
- SQLite/Hermes sync: pass. The event was generated after syncing the card
  rule from PostgreSQL into `knowledge.db`.
- Runtime stack response: pass. `Reverberate` was cast by the responder while
  `Targeted Insight` was on the stack.
- Runtime copy semantics: pass. The copied spell was not cast, resolved for
  the responder, and emitted `spell_copy_ceased_to_exist` instead of entering a
  graveyard.
- Runtime original semantics: pass. The original `Targeted Insight` remained
  on stack after the copy and then resolved for the original controller.
- Event contract: pass. `spell_cast` and `spell_copied` both include the PG038
  logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Reverberate` as a stack-copy
  response under the current battle model.
- `may_choose_new_targets` is retained as
  `choose_new_targets_status=annotation_only`; this gate does not claim
  dynamic target reassignment.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG039 Sensei's Divining Top Focused Event Gate - 2026-06-22 22:01 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_replay_summary_20260622_215306.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_events_20260622_215306.jsonl`.
- Decision trace:
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_decision_trace_20260622_215306.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Top rule key is
  `battle_rule_v1:70c8478871f352b46cee1af296117951`.
- SQLite/Hermes sync: pass after aligning the reviewed runtime cache with the
  active PostgreSQL key.
- Runtime topdeck reorder: pass. `topdeck_manipulation_activated` moved
  `Approach of the Second Sun` above `Small Creature` for Lorehold's first
  draw.
- Runtime win-line chain: pass. Lorehold rummage drew `Approach`, miracle-cast
  it, and the game ended with `reason=approach`.
- Event contract: pass. `topdeck_manipulation_activated` includes the PG039
  logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Sensei's Divining Top` as a
  top-three reorder tool under the current Lorehold battle model.
- Generic activated draw policy remains `annotation_only`; this gate only
  proves the restricted first-draw miracle draw-put-self line.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG040 Swords to Plowshares Focused Event Gate - 2026-06-22 22:22 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_pg040_focused_replay_summary_20260622_221254.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_pg040_focused_events_20260622_221254.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Swords rule key is
  `battle_rule_v1:379008f3f03f94258292123453e3041c`.
- SQLite/Hermes sync: pass after aligning the reviewed runtime cache with the
  active PostgreSQL key.
- Runtime exile resolution: pass. `removal_resolved` moved `Siege Rhino` from
  battlefield to exile.
- Runtime life gain: pass. `removal_resolved` recorded
  `life_gain_requested=4` and `life_gained=4`, equal to the target creature's
  power.
- Event contract: pass. `removal_resolved` includes the PG040 logical rule key
  and oracle hash.

Reading:

- This closes card-level event proof for `Swords to Plowshares` as an exile
  removal spell with target-controller life gain equal to target power under
  the current battle model.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG041 Teferi's Protection Focused Event Gate - 2026-06-22 22:41 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_replay_summary_20260622_223850.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_events_20260622_223850.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Teferi rule key is
  `battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a`.
- SQLite/Hermes sync: pass after aligning the reviewed runtime cache with the
  active PostgreSQL key.
- Runtime phase-out: pass. `phase_out_resolved` moved `Monastery Mentor`,
  `Sol Ring`, and `Plateau` from battlefield to phased-out state.
- Runtime life/protection: pass. Replacement events prevented a 20-damage
  attempt and a 5-life gain attempt while life stayed at `8`.
- Runtime self-exile: pass. `spell_resolved.destination=exile` and
  `self_exiled_on_resolution` prove Teferi's Protection did not go to
  graveyard.
- Event contract: pass. `spell_resolved` and `phase_out_resolved` both include
  the PG041 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Teferi's Protection` as a protection
  instant with life-total lock, protection from everything, all-permanent
  phase-out including lands, and self-exile under the current battle model.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG042 Valakut Awakening Focused Event Gate - 2026-06-22 23:01 UTC

Artifacts:

- Summary:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_replay_summary_20260622_225355.md`.
- Events:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_events_20260622_225355.jsonl`.

Statuses:

- Focused event proof only. This is not a full 16-seed deck battle matrix and
  does not change the PG026 official Lorehold deck baseline.
- PG source rule: pass. The emitted Valakut split-name rule key is
  `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`.
- SQLite/Hermes sync: pass after syncing PG042 and aligning the reviewed
  runtime cache with the active PostgreSQL hash.
- Runtime hand filter: pass. `hand_filter_resolved` bottomed `Nine Drop B` and
  `Eight Drop A`, drew three cards, and preserved
  `Approach of the Second Sun` in hand.
- Runtime spell zone: pass for the focused cast object. `spell_resolved`
  recorded `destination=graveyard` using PostgreSQL's `Instant` type line.
- Event contract: pass. `spell_resolved` and `hand_filter_resolved` both
  include the PG042 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Valakut Awakening // Valakut
  Stoneforge` as a bottom-then-draw-plus-one instant under the current battle
  model.
- The MDFC land-face metadata remains available on the split-name rule for
  lookup coherence, but this focused gate does not claim land-play or tapped
  red-mana execution for `Valakut Stoneforge`.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG043 Wheel of Fortune Focused Event Gate - 2026-06-22 23:26 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_events_20260622_231859.jsonl`.
- Focused summary:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_replay_summary_20260622_231859.md`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_apply_20260622_231859.sql`.

Gate:

- Event `wheel_resolved` includes:
  `rule_logical_key=battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3`.
- Event `wheel_resolved` includes:
  `rule_oracle_hash=c37cd579d8132efac0c2118608f6f001`.
- Event proves multiplayer wheel resolution: controller discarded `2`, drew
  `7`; opponent discarded `1`, drew `7`.
- Event proves payoff propagation for the modeled battlefield: Smothering
  Tithe created `7` Treasure tokens from opponent draws.
- Decision trace uses `model_scope=multiplayer_discard_draw_v1` and records
  `wheel_payoffs=['Smothering Tithe']`.

Status:

- `Wheel of Fortune` is closed for the current battle-rule coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_232608.json`
  reports `Wheel of Fortune` as `pass`.

Caveats:

- This gate proves the modeled `Wheel of Fortune` discard-hand/draw-seven
  executor and replay provenance. It does not claim every possible replacement
  effect or opponent denial policy beyond the currently modeled
  `multiplayer_discard_draw_v1` path.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG044 Valakut Awakening Metadata Refresh Gate Note - 2026-06-22 23:26 UTC

Artifacts:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_apply_20260622_232411.sql`.
- Existing PG042 focused events remain the behavior proof:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_events_20260622_225355.jsonl`.

Gate:

- PG044 did not add a new executor and did not require a new replay. It
  restored PostgreSQL metadata so the existing PG042 replay evidence points to
  oracle-hashed active rules in the source of truth.
- Postcheck shows full-name and alias Valakut rows with
  `oracle_hash=22b42fcc181b7aed71f78b2e1e51e887`, and no trusted executable
  Valakut rows without hash.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_232608.json`
  reports `Valakut Awakening // Valakut Stoneforge` as `pass`.

Caveat:

- The MDFC land face remains metadata for split-name lookup; PG044 does not
  claim land-play or tapped-red-mana execution for `Valakut Stoneforge`.

## PG045 Aetherflux Reservoir Focused Event Gate - 2026-06-22 23:40 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_pg045_focused_events_20260622_233656.jsonl`.
- Focused summary:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_pg045_focused_replay_summary_20260622_233656.md`.
- Focused decision trace:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_pg045_focused_decision_trace_20260622_233656.jsonl`
  (empty; no runtime decision was needed).
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_apply_20260622_233656.sql`.

Gate:

- Event `aetherflux_reservoir_resolved` includes:
  `rule_logical_key=battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5`.
- Event `aetherflux_reservoir_resolved` includes:
  `rule_oracle_hash=ea5327899fb66a2d583e80e8ca12d9b2`.
- Two `trigger_resolved` events for future spell casts include the same
  logical rule key and oracle hash.
- Lifegain sequence is `[1, 2]`, matching the current turn spell-count model.
- No `damage_resolved` event is emitted for Aetherflux Reservoir in this
  focused gate.

Status:

- `Aetherflux Reservoir` is closed for the current battle-rule coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_234015.json`
  reports `Aetherflux Reservoir` as `pass`.

Caveats:

- This gate proves the modeled spell-cast lifegain trigger and replay
  provenance. It does not claim the activated `Pay 50 life: deal 50 damage`
  ability as executable; that remains `annotation_only`.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG046 Approach of the Second Sun Focused Event Gate - 2026-06-23 00:02 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl`.
- Focused summary:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_replay_summary_20260622_235039.md`.
- Focused decision trace:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_decision_trace_20260622_235039.jsonl`
  (empty; no runtime decision was needed).
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_apply_20260622_235039.sql`.

Gate:

- Events `approach_cast_tracked` include:
  `rule_logical_key=battle_rule_v1:ed74fb069b6c1d635392d907804a1d98`.
- Events `approach_cast_tracked` include:
  `rule_oracle_hash=0838960b80a282fb4508532f7bae8c2b`.
- The focused replay proves copied Approach did not increment the cast ledger:
  count stayed `0 -> 0`.
- The first cast from hand was countered through `Stack.resolve_top()` and
  still left Approach count at `1`.
- The second cast from hand emitted `approach_cast_tracked` with
  `approach_count=2`, emitted `spell_resolved` with `destination=graveyard`,
  did not emit the `approach_first_resolution` life-gain/library branch, and
  emitted `game_won` with `reason=approach`.

Status:

- `Approach of the Second Sun` is closed for the current battle-rule coherence
  gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_000228.json`
  reports `Approach of the Second Sun` as `pass`.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG051 Deck 6 L1B Non-Fetch Land Mana Focused Event Gate - 2026-06-23 01:25 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_focused_events_20260623_012230.jsonl`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_apply_20260623_011438.sql`.

Gate:

- `11` `rule_resolution` rows prove the included non-fetch lands resolve to
  trusted curated rules with `rule_logical_key` and `rule_oracle_hash`.
- `3` runtime `land_played` samples prove the battle runtime emits the active
  PostgreSQL-backed rule provenance for:
  `City of Brass`, `Battlefield Forge`, and `Sacred Foundry`.
- All runtime samples used
  `rule_logical_key=battle_rule_v1:603c776839827f2f21cef8b62e22a1be`.
- Sample oracle hashes:
  `City of Brass=969b41c45b968319b44f77454c6ac55b`,
  `Battlefield Forge=39d45b03e1a8226fd02925e44ee7692c`, and
  `Sacred Foundry=33b9a82ff9bf4322c280434b47fb3436`.

Status:

- The included `11` non-fetch lands are closed for the current
  battle-rule coherence gate.
- Final auditor after PG052:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_012130.json`
  reports deck `6` at `high=41`, `medium=8`, `pass=51`.

Caveats:

- This gate proves mana-source runtime provenance. Life-loss, conditional ETB,
  surveil, filter, and related clauses remain annotation-only or abstracted as
  stated in each `battle_model_scope`.
- Fetchlands were excluded and remain open for a separate waiver/model package.

## PG052 Valakut Awakening Hash-Only Gate - 2026-06-23 01:25 UTC

Artifacts:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg052_hash_only_apply_20260623_012000.sql`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg052_valakut_hash_only_20260623_012000.json`.

Gate:

- PG052 did not add a new executor and did not require a new replay.
- It restored the active PG042 rule oracle hash:
  `rule_logical_key=battle_rule_v1:6e1f3b876822abafe1de47610f46858d`,
  `rule_oracle_hash=22b42fcc181b7aed71f78b2e1e51e887`.
- Full battle regression suite passed after the PG-to-SQLite sync:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.

Status:

- `Valakut Awakening // Valakut Stoneforge` is closed for the hash-only
  provenance gate.

## PG054 Deck 6 L6 Silence-Lock Focused Event Gate - 2026-06-23 01:36 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_focused_events_20260623_013520.jsonl`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_apply_20260623_013119.sql`.

Gate:

- `Silence` rule resolution includes:
  `rule_logical_key=battle_rule_v1:74b210b77b004a677906e0216d44e445` and
  `rule_oracle_hash=a0ca3c09a7db091c435ab31adb9c1780`.
- The focused `Silence` runtime check emits `spell_resolved` for Silence with
  that same key/hash and then proves the responder keeps `Real Counter` while
  `silenced_opponents_until_eot=true`.
- `Grand Abolisher` rule resolution includes:
  `rule_logical_key=battle_rule_v1:4df98360e4467568504b19219c8ba5d0` and
  `rule_oracle_hash=57c98b7e49853c5e0afff526da052e3c`.
- The focused Grand Abolisher runtime check emits `cast_announced`,
  `cost_paid`, `spell_cast`, and `spell_resolved` with that same key/hash, and
  verifies `silenced_opponents=true`.

Status:

- `Silence` and `Grand Abolisher` are closed for the current battle-rule
  coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_013430.json`
  reports deck `6` at `high=39`, `medium=8`, `pass=53`.

Caveat:

- Grand Abolisher's activated-ability lock remains `annotation_only`; this
  gate proves the current opponent spell-cast lock runtime path.

## PG057 Deck 6 L3A Artifact Mana-Rock Focused Event Gate - 2026-06-23 01:50 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3a_artifact_mana_rocks_pg055_focused_events_20260623_014032.jsonl`.
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3a_artifact_mana_rocks_pg055_apply_20260623_014032.sql`.

Gate:

- The `rule_resolution_batch` row proves all seven target cards resolve to
  trusted `ramp_permanent` rules with `rule_logical_key`, `rule_oracle_hash`,
  `battle_model_scope`, `produces`, and `mana_produced`.
- Runtime sample without a legendary permanent reports `sources=6`,
  `available_mana=9`, `colorless=5`, and `wildcard=4`; `Mox Amber` is not
  counted.
- Runtime sample after adding `Lorehold, the Historian` reports `sources=7`,
  `available_mana=10`, `colorless=5`, and `wildcard=5`; `Mox Amber` is counted
  only with a live legendary permanent.

Status:

- `Arcane Signet`, `Boros Signet`, `Fellwar Stone`, `Mana Vault`,
  `Mox Amber`, `Sol Ring`, and `Talisman of Conviction` are closed for the
  current battle-rule coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_015020.json`
  reports deck `6` at `high=32`, `medium=8`, `pass=60`.

Caveats:

- This gate proves mana-source runtime provenance and current refresh behavior.
  It does not claim full Magic-equivalent tap/cost sequencing for Boros Signet,
  exact color production for Fellwar Stone/Mox Amber, Mana Vault's untap/damage
  clauses, or Talisman life-loss resolution.
- Numbering note: the focused event artifact keeps the physical `pg055` prefix;
  this gate is tracked logically as `PG057` because `PG055` is used by the
  parallel Lorehold Variant 03 metadata deploy and separate `PG056` deck 608
  package artifacts exist in this worktree.

## PG056 Deck 608 Dragon Package Focused Runtime Gate - 2026-06-23 01:58 UTC

Artifacts:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_apply_20260623_015223.sql`.
- PG postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_postcheck_20260623_015223.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg056_deck608_dragons_approach_thrumming_20260623_015223.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_focused_events_20260623_015223.jsonl`.

Gate:

- `Dragon's Approach` resolves with fixed `damage_each_opponent=3`; graveyard
  copies are counted only for the optional five-copy Dragon tutor cost.
- The focused Dragon's Approach test proves five graveyard copies move to exile
  and `Goldspan Dragon` moves from library to battlefield.
- `Thrumming Stone` resolves as `ripple_engine` with same-name `ripple 4`
  support; the focused ripple test proves two additional Dragon's Approach
  copies are cast from the top four without increasing per-copy damage.

Status:

- `Dragon's Approach` and `Thrumming Stone` are closed for the current deck
  `608` battle-rule coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_015223.json`
  reports deck `608` at `high=38`, `medium=11`, `pass=19`.

Caveats:

- This gate proves the focused runtime paths needed by the deck `608` Dragon's
  Approach package. It does not claim full Magic-equivalent stack, search,
  replacement, or shuffle behavior.

## PG058 Deck 6 L3B Simple Red Ritual Focused Event Gate - 2026-06-23 02:11 UTC

Artifacts:

- PG postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_postcheck_20260623_020031.out`.
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_apply_20260623_020031.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg058_deck6_l3b_simple_red_rituals_20260623_020031.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_focused_events_20260623_020031.jsonl`.

Gate:

- `Rite of Flame` resolves with
  `rule_logical_key=battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518`,
  `rule_oracle_hash=35a034ee45b092bc443cd5992d8793f4`, and adds `2` mana in
  the current singleton-baseline runtime.
- `Seething Song` resolves with
  `rule_logical_key=battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7`,
  `rule_oracle_hash=ccd492289c6f1c14c8fb7a248d7bbf32`, and adds `5` mana.
- Both spells resolve to graveyard and keep
  `mana_color_status=abstracted_to_generic_pool_runtime`.

Status:

- `Rite of Flame` and `Seething Song` are closed for the current deck `6`
  battle-rule coherence gate.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_021017.json`
  reports deck `6` at `high=30`, `medium=8`, `pass=62`.

Caveats:

- This gate proves the current one-shot ritual abstraction. It does not model
  Rite of Flame named-copy graveyard scaling across all graveyards.

## PG059 Deck 6 Hash/Sync Metadata Restore Gate - 2026-06-23 02:29 UTC

Artifacts:

- Hash-only package postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_postcheck_20260623_021840.out`.
- Sync metadata restore postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg059_sync_metadata_restore_postcheck_20260623_022328.out`.
- SQLite sync after metadata restore:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg059_sync_metadata_restore_20260623_022328.json`.
- Current deck audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_023130.json`.

Gate:

- The hash-only package reports `target_runtime_missing_hash_rows=0`,
  `target_runtime_hash_mismatch_rows=0`, and
  `target_runtime_live_hash_mismatch_rows=0` for the eight trusted deck-6 L2
  runtime rows.
- The sync metadata restore reports `target_missing_hash_rows=0`,
  `target_hash_mismatch_rows=0`, `target_missing_effect_patch_rows=0`, and
  `backup_rows=7`.
- The PG-to-Hermes sync exported `3201` canonical snapshot rows after the
  metadata restore.

Status:

- The sync/upsert path now has a regression guard that preserves existing
  `oracle_hash` and curated/manual PG-only metadata on same-key conflicts.
- Deck `6` remains at `high=30`, `medium=8`, `pass=62` after the repair.
- Deck `606` remains at `high=38`, `medium=8`, `pass=35`; deck `607` is
  `high=50`, `medium=16`, `pass=28`; deck `608` is `high=38`, `medium=11`,
  `pass=19`.

Caveats:

- This gate repairs provenance/annotation drift. It does not promote any new
  card model and does not change deck contents.
- The external `PG060` ritual metadata artifact with timestamp
  `20260623_022418` is not a trusted gate: its apply output has no `UPDATE` or
  `COMMIT`, its postcheck output is empty, and no matching backup table exists
  in PostgreSQL.
- The follow-up `PG061` ritual metadata confirmation is trusted: its apply
  output reports `UPDATE 2` and `COMMIT`, its postcheck reports
  `target_missing_runtime_scope_rows=0`,
  `target_missing_mana_color_status_rows=0`, and `backup_rows=5`, and its
  SQLite sync is
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg061_deck6_l3b_simple_red_rituals_metadata_20260623_023130.json`.

Final audit after PG061:

- Required global auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_023224.json`
  reports `high=116`, `medium=23`, `pass=66`.
- Deck `6`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_023130.json`
  reports `high=30`, `medium=8`, `pass=62`.
- Deck `606`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_023130.json`
  reports `high=38`, `medium=8`, `pass=35`.
- No new replay artifact was generated for PG061 because it did not change
  executor behavior; the applicable runtime proof remains the PG058 simple-red
  ritual focused event gate.

## PG062 Deck 6 L1 Fetchland Focused Event Gate - 2026-06-23 02:46 UTC

Artifacts:

- PG postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_postcheck_20260623_024200.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg062_deck6_l1_fetchlands_20260623_024200.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_focused_events_20260623_024200.jsonl`.
- Current deck audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_024200.json`.

Gate:

- The rule-resolution event proves `8` trusted curated fetchland rows with
  `battle_model_scope=fetchland_land_play_with_activation_annotation_v1`,
  live `oracle_hash`, and `8` generated shadows disabled.
- The runtime sample proves current name-based opening-hand fetchland color
  fixing using `Bloodstained Mire`; the hand is kept with
  `off_color_early_count=0`.
- Dynamic pay-life/sacrifice/search/shuffle activation remains
  `annotation_only`, not a newly promoted executor.

Status:

- `Arid Mesa`, `Bloodstained Mire`, `Flooded Strand`, `Marsh Flats`,
  `Prismatic Vista`, `Scalding Tarn`, `Windswept Heath`, and
  `Wooded Foothills` are closed for the current deck `6` L1 fetchland
  coherence gate.
- Deck `6` now reports `high=30`, `pass=70`; the medium land/mana-base queue
  is empty in the current auditor cut.
- Deck `606` also benefits for shared `Arid Mesa`, moving to `high=38`,
  `medium=7`, `pass=36`.

Caveat:

- This gate does not claim full Magic-equivalent fetchland activation
  sequencing. It only proves the runtime-safe land model and current
  opening-hand fixing behavior.

## PG063 Deck 608 Tutor/Search Runtime Gate - 2026-06-23 02:54 UTC

Artifacts:

- PG postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck608_tutor_search_pg063_postcheck_20260623_024856.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg063_deck608_tutor_search_20260623_024856.json`.
- Current deck 608 audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_025416.json`.

Gate:

- `test_enlightened_tutor_puts_artifact_or_enchantment_on_library_top` proves
  library-top movement for artifact/enchantment tutors.
- `test_idyllic_tutor_finds_enchantment_to_hand_only` proves enchantment-only
  filtering to hand.
- `test_goblin_engineer_etb_tutors_artifact_to_graveyard` proves creature ETB
  artifact-to-graveyard tutor movement.
- `test_imperial_recruiter_etb_tutors_power_two_creature_to_hand` proves
  creature ETB power <= 2 filtering to hand.

Status:

- `Enlightened Tutor`, `Idyllic Tutor`, `Goblin Engineer`, and
  `Imperial Recruiter` are closed for the current deck `608` tutor/search
  coherence gate.
- Deck `608` now reports `high=34`, `medium=6`, `pass=28`; all four target
  cards report `pass/coherent_for_current_gate`.

Caveat:

- Goblin Engineer's activated artifact reanimation ability remains
  `annotation_only`; PG063 only promotes the ETB artifact-to-graveyard tutor
  executor.

## PG064 Deck 6 Recruiter of the Guard Focused Event Gate - 2026-06-23 03:04 UTC

Artifacts:

- PG postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_postcheck_20260623_025848.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg064_deck6_recruiter_guard_20260623_025848.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_focused_events_20260623_025848.jsonl`.
- Current deck 6 audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_030307.json`.

Gate:

- `test_recruiter_of_the_guard_etb_tutors_toughness_two_creature_to_hand`
  proves the new `creature_toughness_lte_2` selector.
- The focused runtime event proves `Recruiter of the Guard` resolves from the
  synced rule and emits `tutor_resolved` with
  `rule_logical_key=battle_rule_v1:423a8aa67b5cf450f4c4fb47ca50ae46`.
- The sample moves `Esper Sentinel` to hand and leaves `Craterhoof Behemoth`
  in library, proving toughness-filtered selection.

Status:

- `Recruiter of the Guard` is closed for the current deck `6` tutor/ETB gate.
- Deck `6` now reports `high=27`, `pass=73`.

Caveat:

- This gate models the ETB search/reveal/put-into-hand behavior. It does not
  claim a full shuffle-order simulator beyond the current tutor abstraction.

## PG064 Deck 6 Recruiter of the Guard Runtime Gate - 2026-06-23 03:03 UTC

Artifacts:

- PG postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_postcheck_20260623_025848.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg064_deck6_recruiter_guard_20260623_025848.json`.
- Current deck 6 audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_030307.json`.

Gate:

- `test_recruiter_of_the_guard_etb_tutors_toughness_two_creature_to_hand`
  proves creature ETB toughness <= 2 filtering to hand.
- The gate is intentionally separate from `Imperial Recruiter`, which filters
  by power <= 2.

Status:

- `Recruiter of the Guard` is closed for the current deck `6` tutor/search
  coherence gate.
- Deck `6` now reports `high=27`, `pass=73`; `Recruiter of the Guard` reports
  `pass/coherent_for_current_gate`.

Caveat:

- Historical note: this duplicate runtime-gate entry is superseded by the
  focused event gate above. PG064 apply output is now present in the worktree;
  postcheck, backup table, sync, audit, and battle tests remain the accepted
  evidence.

## PG065/PG066 Deck 6 Resource Engine Focused Event Gate - 2026-06-23 03:24 UTC

Artifacts:

- PG065 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/shared_engine_rules_pg065_postcheck_20260623_031553.out`.
- PG066 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_birgi_spellcast_resource_engine_pg066_postcheck_20260623_032200.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg066_birgi_20260623_032200.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg066_birgi_smothering_focused_events_20260623_032200.jsonl`.
- Current deck 6 audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg066_20260623_032200.json`.

Gate:

- `Smothering Tithe` emits `trigger_resolved` for `opponent_draw` with
  `effect=create_treasure`, `treasures_created=2`, and
  `rule_logical_key=battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6`.
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty` emits
  `trigger_resolved` for `spell_cast` with `effect=add_mana`,
  `mana_color=red`, and
  `rule_logical_key=battle_rule_v1:05576012d8fca56910da7ea072abe15e`.
- `Scroll Rack` is covered by PG065 as a topdeck runtime slice and by the
  existing `test_scroll_rack_sets_up_lorehold_approach_second_cast_on_opponent_upkeep`.

Status:

- `Scroll Rack`, `Smothering Tithe`, and `Birgi` are closed for the current
  deck `6` resource/topdeck engine gate.
- Deck `6` now reports `high=24`, `pass=76`.

Caveat:

- `Smothering Tithe` tax payment is still modeled as
  `compact_assume_unpaid_v1`, not dynamic opponent payment.
- `Birgi` PG066 models the front face spell-cast mana trigger only; `Harnfel`
  and boast text remain `annotation_only`.
- `Blasphemous Act` was only rechecked as a pass card in this cycle; its cost
  reduction remains the prior `annotation_only` caveat.

## PG068 Deck 6 Copy Spell Stack Gate - 2026-06-23 03:45 UTC

Artifacts:

- PG068 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l5a_copy_spell_stack_pg068_postcheck_20260623_004158.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg068_copy_spell_stack_20260623_004158.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg068_copy_spell_stack_focused_events_20260623_004158.jsonl`.
- Current deck `6` audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg068_20260623_004158.json`.

Gate:

- `Reiterate` casts in response to a target instant/sorcery stack object and
  emits `spell_copied` with
  `rule_logical_key=battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405`.
- `Dualcaster Mage` casts as a flash creature in response, resolves to the
  battlefield, then its ETB emits `spell_copied` with
  `trigger=enters_battlefield` and
  `rule_logical_key=battle_rule_v1:e176019b87d68d22e2388e08a4efbf55`.

Status:

- `Reiterate` and `Dualcaster Mage` are closed for the current deck `6`
  copy-spell stack gate.
- Deck `6` now reports `high=22`, `pass=78`.

Caveat:

- The "you may choose new targets" text remains `annotation_only`; the runtime
  proves stack-copy creation and provenance, not dynamic target reassignment.

## PG068 Deck 6 Copy Token Gate - 2026-06-23 03:50 UTC

Artifacts:

- PG068 copy-token postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_copy_token_stack_rules_pg068_postcheck_20260623_034443.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg068_deck6_copy_token_stack_rules_20260623_034443.json`.
- Current deck `6` audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_035001.json`.

Gate:

- `Heat Shimmer` emits `copy_creature_token_created` for the best legal
  creature target from any controller and marks the token with
  `exile_at_end_step=true`.
- `Twinflame` emits `copy_creature_token_created` for a controller-owned
  creature and marks the token with `exile_at_end_step=true`.
- `Molten Duplication` emits `copy_creature_token_created` for a
  controller-owned artifact or creature, marks `artifact_in_addition=true`, and
  marks the token with `sacrifice_at_end_step=true`.

Status:

- `Heat Shimmer`, `Twinflame`, and `Molten Duplication` are closed for the
  current copy-token gate.
- The previously proven `Reiterate` and `Dualcaster Mage` PG068 copy-spell
  gates remain closed.
- Deck `6` now reports `high=7`, `medium=11`, `pass=82`.

Caveat:

- `Twinflame` strive is modeled as
  `annotation_only_single_best_own_creature`; the runtime proves the single
  best legal target path, not multi-target strive expansion.
- `Molten Duplication` proves temporary artifact-copy creation and end-step
  sacrifice, not downstream activated abilities of copied artifacts beyond the
  copied permanent metadata.

## PG069 Deck 6 L2 Specific Runtime Cleanup Gate - 2026-06-23 04:02 UTC

Artifacts:

- PG069 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_specific_runtime_cleanup_pg069_postcheck_20260623_005736.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg069_l2_specific_runtime_cleanup_20260623_040215.json`.
- Current deck `6` audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg069_20260623_040215.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg069_specific_runtime_cleanup_focused_events_20260623_011015.jsonl`.

Gate:

- `The One Ring` remains covered by the existing runtime tests for ETB/cast
  protection and burden-counter draw; PG069 refreshed the persisted
  `oracle_hash` and added an explicit `oracle_runtime_scope`.
- `Unexpected Windfall` remains covered by the existing
  discard/draw/Treasure executor; PG069 persisted the current oracle hash and
  explicit additional-cost runtime scope, and `treasure_created` now emits the
  rule key/hash provenance.

Status:

- `The One Ring` and `Unexpected Windfall` are closed for the current
  hash/scope cleanup gate.
- Deck `6` now reports `high=7`, `medium=10`, `pass=83`.

Caveat:

- PG069 did not change game semantics. It preserved already-tested executors,
  corrected persisted metadata/shadow rows, and added replay provenance to the
  final Treasure event.

## PG070 Deck 6 L2 Hash Cleanup + Red Discard Runtime Gate - 2026-06-23 04:30 UTC

Artifacts:

- L2 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_runtime_rules_pg070_postcheck_20260623_011859.out`.
- L2 Seething metadata postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_runtime_rules_pg070_seething_metadata_postcheck_20260623_011859.out`.
- Red-discard postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_postcheck_20260623_042617.out`.
- Accepted SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg070_deck6_red_discard_runtime_20260623_042617.json`.
- Accepted deck `6` audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg070_20260623_042617.json`.
- Accepted deck `606` audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg070_20260623_042617.json`.
- Accepted deck `607` audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg070_20260623_042617.json`.
- Accepted deck `608` audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_pg070_20260623_042617.json`.
- Accepted global audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg070_20260623_042617.json`.
- L2 focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl`.
- Red-discard focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl`.

Gate:

- L2 hash-only cards now expose stable `rule_oracle_hash` provenance in
  focused runtime events without changing their existing executors.
- `Seething Song` keeps `battle_model_scope=single_shot_red_ritual_v1`; the
  addendum only restored the persisted generic-pool red-mana annotation
  metadata expected by the ritual family tests.
- `Faithless Looting` emits `loot_resolved` with
  `rule_logical_key=battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa` and
  `rule_oracle_hash=2e734d8bae3f331866abf1b030c92781`.
- `Gamble` emits `tutor_resolved` and `random_discard_after_tutor` with
  `rule_logical_key=battle_rule_v1:2861739f22e978549e28d2339288df2a` and
  `rule_oracle_hash=9b3fc8ab7f664f6c084e0bda0ccf9a7c`.

Status:

- `Fellwar Stone`, `Mana Vault`, `Mox Amber`, `Scroll Rack`,
  `Seething Song`, `Silence`, `Talisman of Conviction`,
  `Unexpected Windfall`, and
  `Valakut Awakening // Valakut Stoneforge` are closed for the current
  L2 hash-only cleanup gate.
- `Faithless Looting` and `Gamble` are closed for the current red card-flow
  runtime gate.
- Accepted gate counts are deck `6` `high=5`, `medium=10`, `pass=85`;
  deck `606` `high=7`, `medium=30`, `pass=44`; deck `607` `high=30`,
  `medium=17`, `pass=47`; deck `608` `high=21`, `medium=9`, `pass=38`;
  global `high=55`, `medium=44`, `pass=106`.
- The rejected review-rule sync is not a replay gate source and must not be
  used to reopen cards that only appear because untrusted review rows were
  imported.

Caveat:

- `Faithless Looting` flashback is annotation-only; the runtime proves the
  cast-from-hand draw-two/discard-two path.
- `Gamble` library shuffle is annotation-only because hidden-zone ordering is
  not modeled; the runtime proves the tutor-to-hand plus random discard path.
- `Blasphemous Act` was not a PG070 target. Its cost-reduction note remains a
  caveat only, not a rule source or blocker.

## PG070 Deck 6 Red Discard Runtime Gate - 2026-06-23 04:29 UTC

Artifacts:

- PG070 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_postcheck_20260623_042617.out`.
- SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg070_deck6_red_discard_runtime_20260623_042617.json`.
- Current deck `6` audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg070_20260623_042617.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl`.

Gate:

- `Faithless Looting` emits `loot_resolved` with two drawn cards, two
  discarded cards, and PG070 rule key/hash provenance.
- `Gamble` emits `tutor_resolved` for the selected card, then
  `random_discard_after_tutor` with PG070 rule key/hash provenance.

Status:

- `Faithless Looting` and `Gamble` are closed for the current red discard
  runtime gate.
- Deck `6` now reports `high=5`, `medium=10`, `pass=85`.

Caveat:

- `Faithless Looting` flashback and `Gamble` library shuffle are explicit
  annotation-only metadata in this runtime slice; the proved runtime behavior
  is draw/discard and tutor/random-discard.

## PG071 Deck 6 L3 Fast Mana/Cost Reduction Gate - 2026-06-23 04:45 UTC

Artifacts:

- PG071 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_postcheck_20260623_043623.out`.
- Trusted SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg071_l3_fast_mana_cost_reduction_trusted_sync_report_20260623_043623.json`.
- Current deck `6` audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg071_l3_fast_mana_cost_reduction_trusted_20260623_043623.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg071_l3_fast_mana_runtime_focused_events_20260623_043623.jsonl`.

Gate:

- `Lotus Petal` emits `spell_resolved` with
  `rule_logical_key=battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d`,
  `rule_oracle_hash=a5b9069217908acfd75c5704b414b035`, resolves to
  graveyard, and focused state proves `mana_pool_total=1`.
- `Ruby Medallion` emits `spell_resolved` with
  `rule_logical_key=battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a`,
  `rule_oracle_hash=52bc55846d69bacf3afba1ffa734b81e`, resolves to
  battlefield as `passive`, and focused state proves `is_mana_source=false`.

Status:

- `Lotus Petal` and `Ruby Medallion` are closed for the current L3
  fast-mana/cost-reduction gate.
- Deck `6` accepted cut reports `high=5`, `medium=8`, `pass=87`; global
  accepted cut reports `high=55`, `medium=42`, `pass=108`.
- The broad review-rule sync generated during the batch is rejected as a
  replay gate source.

Caveat:

- `Ruby Medallion` cost reduction is annotation-only until a dynamic cost
  reducer executor exists; the current runtime proof is that it no longer
  behaves as a mana source.

## PG072 Deck 6 L6 Interaction/Removal/Counter Gate - 2026-06-23 05:04 UTC

Artifacts:

- PG072 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_postcheck_20260623_045642.out`.
- Trusted SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg072_l6_interaction_removal_counter_sync_report_20260623_045642.json`.
- Final snapshot resync after the oracle-normalizer fix:
  `docs/hermes-analysis/master_optimizer_reports/pg072_l6_interaction_removal_counter_resync_report_20260623_050816.json`.
- Current deck `6` audit cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg072_l6_interaction_removal_counter_20260623_045642.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg072_l6_interaction_removal_counter_focused_events_20260623_045642.jsonl`.

Gate:

- `Pyroblast` emits `spell_countered` with
  `rule_logical_key=battle_rule_v1:141ff57f44bc4c229393f05f7daf667c`,
  `rule_oracle_hash=ecf9ad1f393a664f16867aab8a6edf77`, allows a blue stack
  spell target, and rejects a red stack spell target.
- `Get Lost` emits `removal_resolved` with
  `rule_logical_key=battle_rule_v1:8e7da3df51386d58c857a596433f73ea`,
  `rule_oracle_hash=6b6517e1b5b60db5cf6bbcd991dbc1ec`,
  `target_type=creature_enchantment_or_planeswalker`, then emits
  `compensation_tokens_created` for two Map tokens.

Status:

- `Get Lost` and `Pyroblast` are closed for the current L6 interaction gate.
- Deck `6` accepted cut reports `high=3`, `medium=8`, `pass=89`; global
  accepted cut reports `high=53`, `medium=42`, `pass=110`.

Caveat:

- `Pyroblast` destroy-blue-permanent mode is annotation-only in PG072; the
  proved executor path is countering blue spells on the stack.
- `Get Lost` Map-token activation/explore is annotation-only; the proved
  executor path is target destruction plus token creation.

## PG073 Deck 6 L4 Card-Flow Gate - 2026-06-23 05:24 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_card_flow_focused_events_20260623_051141.jsonl`.
- Reconciled focused events after preserving PG `rule_version` in SQLite:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl`.
- PG073 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l4_card_flow_pg073_postcheck_20260623_051141.out`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/pg073_l4_card_flow_sync_report_20260623_051141.json`.
- Final accepted deck `6` cut after PG075:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg075_final_20260623_053046.json`.

Gate:

- `Esper Sentinel` emits `trigger_resolved` with
  `rule_logical_key=battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d`,
  `rule_oracle_hash=d8e8e60e34140942af13aa1be250a961`,
  `trigger=opponent_noncreature_spell`, `noncreature_spell_number=1`,
  `tax_amount=1`, `tax_amount_equals_source_power=true`, and
  `tax_paid=false`; the reconciled event also carries `rule_version=2`.
- `Wheel of Misfortune` emits `spell_resolved` and `wheel_resolved` with
  `rule_logical_key=battle_rule_v1:402155f35799993b812ca441586017cd`,
  `rule_oracle_hash=fa744c33b4bc56c05977ec9c378e5b7d`,
  `secret_number_choice_model=compact_controller_draw_count_opponents_zero_v1`,
  active number `7`, opponent number `0`, active damage `7`, and
  non-lowest discard/draw seven.

Status:

- `Esper Sentinel` and `Wheel of Misfortune` are closed for the current L4
  card-flow gate.
- PG074 and PG075 were provenance/metadata restore gates, not separate runtime
  replay gates.
- Deck `6` final accepted cut reports `high=1`, `medium=8`, `pass=91`;
  remaining high is `Chaos Warp`.
- Deck `607` accepted cut reports `high=29`, `medium=16`, `pass=49`;
  deck `608` accepted cut reports `high=21`, `medium=7`, `pass=40`.

Caveat:

- `Wheel of Misfortune` hidden-number equilibrium is compact deterministic
  runtime, not a full strategic hidden-choice solver.
- `Blasphemous Act` was not a PG073-PG075 target. Its cost-reduction note is
  a caveat/pista only and does not reopen the card without proven mismatch.

## PG076 Deck 6 Chaos Warp Runtime Gate - 2026-06-23 05:55 UTC

Artifacts:

- PostgreSQL postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_chaos_warp_runtime_pg076_postcheck_20260623_055230.out`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/pg076_chaos_warp_runtime_sync_report_20260623_055230.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_chaos_warp_focused_events_20260623_055230.jsonl`.
- Final deck `6` cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg076_chaos_warp_20260623_055230.json`.

Gate:

- `Chaos Warp` emits `removal_resolved` with
  `rule_logical_key=battle_rule_v1:0b547d7209a38ac2d23a1cca07917680`,
  `rule_oracle_hash=7db2bc44526b855fd22302e9569746b5`,
  `target_type=permanent`, and `destination=library`.
- It then emits `chaos_warp_reveal_resolved`; the focused event proves a token
  target vanishes after the zone-change replacement and a revealed permanent
  is put onto the battlefield.

Status:

- `Chaos Warp` is closed for the current L8 unique shuffle/reveal gate.
- Deck `6` now reports `high=0`, `medium=2`, `pass=98`; remaining deck `6`
  medium cards are `Jeska's Will` and `Mizzix's Mastery`.
- Deck `607` now reports `high=29`, `medium=14`, `pass=51`; deck `608`
  reports `high=21`, `medium=6`, `pass=41`.

Caveat:

- Commander replacement for a commander targeted by `Chaos Warp` remains
  covered by the general replacement suite, not by this focused token-target
  event.

## PG076 Deck 6 Support/Passive Annotation Gate - 2026-06-23 06:01 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_support_passive_annotation_focused_events_20260623_054358.jsonl`.
- Final deck `6` cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg076_final_20260623_060105.json`.

Gate:

- `Drannith Magistrate`, `Giver of Runes`, `Mother of Runes`,
  `Professional Face-Breaker`, `Ranger-Captain of Eos`, and
  `Storm-Kiln Artist` each emit `spell_resolved` with curated rule key/hash
  provenance.
- `Ranger-Captain of Eos` additionally emits `tutor_resolved` with
  `rule_logical_key=battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495`,
  `target_type=creature_mana_value_1_or_less`, `found=Esper Sentinel`, and
  `destination=hand`.

Status:

- The former deck `6` medium support/passive queue is closed for the current
  coherence gate.
- The only deck `6` remaining cards in queue are `Jeska's Will` and
  `Mizzix's Mastery`.

Caveat:

- The protection, treasure/impulse, magecraft, static nonhand-cast
  restriction, sacrifice silence, and shuffle text captured in these rows
  remain annotation/provenance unless explicitly named as runtime above.

## PG077 Deck 6 Runtime Event Gate - 2026-06-23 06:25 UTC

Artifacts:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl`.
- Final deck `6` audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg077_final_20260623_062156.json`.

Gate:

- `Jeska's Will` emits `spell_resolved` and `jeskas_will_resolved` with
  `rule_logical_key=battle_rule_v1:c8621a807cc65adc820a8b8189979f70` and
  `rule_oracle_hash=e323893e6c38ee2d618b4f9c737fadee`; the event proves red
  mana equals selected opponent hand size and commander choose-both exiles the
  top three cards with play permission tracked.
- `Mizzix's Mastery` emits `spell_resolved`, `mizzix_mastery_copy_cast`, and
  `mizzix_mastery_resolved` with
  `rule_logical_key=battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f` and
  `rule_oracle_hash=8b822f0c58e4ab4e91f9e4946e8c04e9`.
- The same JSONL records hash-only provenance gates for `Scroll Rack`,
  `Unexpected Windfall`, and
  `Valakut Awakening // Valakut Stoneforge`; those were not semantic runtime
  changes in PG077, but prove the executor still reads the restored
  `logical_rule_key` and `oracle_hash`.

Status:

- Deck `6` is closed for the current battle-rule coherence gate:
  `pass=100`.
- Continue with deck `606` high battle-critical queue.

## PG077 Final Metadata Recheck Gate - 2026-06-23 06:28 UTC

Artifacts:

- Metadata addendum postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_seething_song_metadata_restore_postcheck_20260623_062422.out`.
- Final sync:
  `docs/hermes-analysis/master_optimizer_reports/pg077_l4_battle_support_final_sync_report_20260623_062422.json`.
- Final focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl`.
- Final deck `6` cut:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg077_final_20260623_062422.json`.

Gate:

- The recheck closed the `Seething Song` provenance harness regression caused
  by missing `mana_color_status`.
- `Jeska's Will` and `Mizzix's Mastery` focused events were regenerated after
  the final sync and still show the same rule key/hash runtime behavior.

Status:

- Current accepted deck `6` gate: `high=0`, `medium=0`, `pass=100`.
- Use PG078 for the next PostgreSQL package.

## PG077 L4 Focused Runtime Evidence Addendum - 2026-06-23 06:26 UTC

- `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl`
  is the high-water Jeska's Will and Mizzix's Mastery focused event artifact
  after the final PG077 sync.
- It records scenario summaries plus `spell_resolved`,
  `jeskas_will_resolved`, `mizzix_mastery_copy_cast`, and
  `mizzix_mastery_resolved` events with rule key/hash provenance.

## PG078 Card-Rule Provenance Gate - 2026-06-23 06:42 UTC

Artifacts:

- PostgreSQL postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck606_l2_hash_scope_restore_pg078_postcheck_20260623_063535.out`.
- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg078_l2_hash_scope_restore_sync_report_20260623_063535.json`.
- Focused runtime events:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg078_l2_hash_scope_restore_focused_events_20260623_063535.jsonl`.
- Deck `6` card-gate audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg078_l2_hash_scope_restore_20260623_063535.json`.
- Deck `606` card-gate audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg078_l2_hash_scope_restore_20260623_063535.json`.

Gate:

- PG078 is a provenance/hash gate only. It restored PostgreSQL `oracle_hash`
  values for 23 already scoped trusted rules and disabled 44 superseded shadow
  rows.
- The focused event file proves representative restored rules still resolve
  with the expected `rule_logical_key` and `rule_oracle_hash`; it is not a
  full 16-seed battle rebaseline.
- It does not add new battle replay evidence, does not alter target-pressure or
  table-intent behavior, and does not change deck composition.

Status:

- Card gate is closed for deck `6` at `high=0`, `medium=0`, `pass=100`.
- Deck `606` remains open at `high=7`, `medium=7`, `pass=67`.
- A fresh 16-seed deck `6` battle rebaseline is still required before drawing
  strategic conclusions from the post-PG078 state.

## PG078 Battle Rebaseline Preflight Gate - 2026-06-23 06:50 UTC

Artifacts:

- Failed preflight run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065035/test_battle_runtime_surface_manifest.log`.

Gate:

- The battle wrapper correctly stopped before replay because the runtime
  surface manifest had two unclassified files:
  `deck_card_battle_rule_coherence_audit.py` and
  `test_deck_card_battle_rule_coherence_audit.py`.
- The manifest classification was corrected to `rule registry/sync`.

Status:

- `test_battle_runtime_surface_manifest.py` now passes.
- `battle_runtime_surface_manifest.py --fail-on-unclassified` now exits cleanly.
- The 16-seed deck `6` battle rebaseline still needs to be rerun after this
  harness fix is committed.

## PG078 Deck 6 Battle Rebaseline - 2026-06-23 07:32 UTC

Artifacts:

- Accepted run summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_072754/summary.json`.
- Event contract:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_072754/event_contract_static.json`.
- Decision taxonomy:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_072754/decision_trace_taxonomy.json`.

Gate:

- `action_critic`: pass, `findings=0`, `action_verdict_counts.ok=8229`.
- `forensic_audit`: pass, `rule_findings=0`, `turn_findings=0`.
- `replay_decision_audit`: pass, `decision_findings=0`, `turn_findings=0`.
- `event_contract_static`: pass,
  `observed_unclassified_total=0`, `observed_missing_required_fields=0`,
  `static_unclassified_total=0`.
- `decision_trace_taxonomy`: pass,
  `decision_trace_contract_findings=0`, `missing_required_fields=0`,
  `observed_without_contract=0`.
- `table_intent` and `target_pressure`: pass for all 16 seeds.
- `strategy_audit`: pass, `findings=2`, both medium low-confidence:
  `forced_keep_after_bad_mulligan=2`; `review_required_findings=0`.

Status:

- Final aggregate status: `trusted_for_strategy_learning` with reason
  `all_mandatory_gates_pass`.
- There are no high/critical action, forensic, or replay-decision blockers.
- Strategy learning eligibility is seed-scoped: 14 seeds are high-confidence
  eligible, while seeds `64270204` and `64270207` remain low-confidence.

## PG079 Deck 606 Focused Card-Rule Gate - 2026-06-23 08:01 UTC

Artifacts:

- PostgreSQL postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck606_high_battle_critical_pg079_postcheck_20260623_074912.out`.
- PG -> SQLite/canonical sync:
  `docs/hermes-analysis/master_optimizer_reports/pg079_deck606_high_battle_critical_sync_report_20260623_075404.json`.
- Focused event evidence:
  `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl`.
- Post-test deck `606` card-gate audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg079_post_tests_20260623_080107.json`.

Gate:

- The focused event artifact has 19 rows and proves runtime propagation of all
  seven PG079 `rule_logical_key` values.
- Covered cards: `Flare of Duplication`, `Powerbalance`, `Reforge the Soul`,
  `Rise of the Eldrazi`, `Rite of the Dragoncaller`, `Storm Herd`, and
  `Witch Enchanter // Witch-Blessed Meadow`.
- This is card-rule execution/provenance evidence only. It is not a 16-seed
  battle rebaseline and is not strategy-learning evidence.
- The runtime wrapper passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.

Status:

- Deck `606` high battle-critical queue is closed for this PG079 batch:
  post-test audit reports `high=0`, `medium=7`, `pass=74`.
- Deck `6` remains closed at `pass=100`.
- Global queue after PG079 is `high=43`, `medium=11`, `pass=151`.
- Next card-rule gate should start with deck `606` `medium/battle_support`:
  `Monologue Tax`, `Mox Opal`, and `Simian Spirit Guide`.

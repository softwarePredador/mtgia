# Battle Replay Gate Matrix

Status: current as of `2026-06-21T00:08Z`.

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

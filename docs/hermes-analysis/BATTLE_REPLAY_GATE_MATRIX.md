# Battle Replay Gate Matrix

Status: current as of `2026-06-20T03:11Z`.

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

## Current Gate Reading

Latest official run checked by this matrix:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/summary.json`
- Run scope: recurring 16-seed audit with `seeds_requested=16`,
  `seeds_completed=16`, and `start_seed=63210311`.
- `battle_replay_final_status=blocked`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked","strategy_audit=review_required"]`
- `global_learning_eligible_seeds=[]`; all `16` seeds are globally
  ineligible because the final status is blocked.
- `action_critic`: pass with `findings=0`,
  `seeds_with_high_or_critical_action_findings=[]`,
  `action_events_total=14788`, `action_verdict_counts={"ok":5820}`,
  `action_event_contract_class_counts={"action_audited":5820,"forensic_card_event":2,"ignored_with_reason":345,"renderer_only":26,"strategy_signal":226,"technical":8369}`,
  and `action_events_unclassified=0`.
- Action event type denominator caveat remains open: `action_event_types_total=535`
  and `action_event_type_class_counts` are seed-summed counts, while the global
  distinct observed event type count is
  `event_contract_static_observed_event_types_total=55`. See `BV-083`.
- `strategy_audit`: `review_required` with `findings=3`,
  `low_confidence_findings=2`, `review_required_findings=1`, no strategy
  blocker seeds, and `strategy_code_counts={"board_wipe_without_timing_justification":1,"forced_keep_after_bad_mulligan":2}`.
- `replay_decision_audit`: pass with `turn_findings=0` and
  `decision_findings=0`.
- `forensic_audit`: blocked with `blocking_seeds=["63210319"]`,
  `forensic_rule_findings=4`, `forensic_turn_findings=0`, and
  `forensic_severity_counts={"high":1,"medium":1,"low":2}`.
  The blocker is `Breena, the Demagogue` in seed `63210319`, turn `10`:
  `spell_cast` and `spell_resolved` used `rule_source=functional_tags_json`,
  `rule_review_status=heuristic`, `effect=draw_cards`, no `card_id`, and no
  `semantic_hash`. See `BV-086`.
- Forensic lineage is incomplete in this run:
  `forensic_card_id_missing_unaccepted=2`,
  `forensic_semantic_hash_missing_unaccepted=2`, and
  `forensic_rule_logical_key_missing_unaccepted=0`. This run is already
  blocked by high forensic finding; `BV-088` remains open for the latent case
  where lineage is unaccepted but no forensic findings are emitted.
- `effect_coverage`: pass with source-unknown `unknown_effects=0`,
  `residual_status=effect_coverage_residual_accepted`,
  `residual_unaccepted_card_flag_rows=0`,
  `needs_review_rule_names=1457`, `heuristic_effects=114`,
  `cast_permission_not_explicit=89`, `trigger_not_explicit=147`, and
  `land_utility_ability_not_modeled=48`.
- Residual effect denominator remains visible and must not be read as runtime
  completeness: `effect_coverage_effect_totals_unknown=41`,
  `effect_coverage_unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`,
  and `needs_review_unknown_effect_count=5`. See `BV-087`.
- `focused_template_dispatch`: pass; `29/29` focused-template cards have
  focused evidence ready and `evidence_runner_status_counts={"evidence_ready":29}`.
- `unknown_template_backlog`: pass with
  `status_detail=focused_template_backlog_ready` and all missing-plan counters
  at `0`. This status is source-unknown scoped; `effect_unknown_cards=34`
  remains a separate denominator without per-card contract in this artifact.
  See `BV-087`.
- `decision_trace_taxonomy`: pass with `rows=2241`,
  `kinds_observed=12/15`, `contract_findings=0`, and
  `missing_required_fields=0`. The three static kinds not observed in this
  run are `activated_sacrifice_damage`, `attack_trigger_artifact_tutor`, and
  `worldfire_reset`.
- Decision trace waiver caveat: `164` observed decision rows are
  `accepted_field_contract_waiver`/`generic_strategy_fields_only`, not
  strategy-audited branches: `lorehold_upkeep_rummage=104`,
  `saga_chapter_resolution=4`, `utility_artifact_activation=36`, and
  `utility_land_activation=20`. A direct scan found `parent_link_rows=0`.
  See `BV-085`.
- `event_contract_static`: pass; `events_observed_total=14788`,
  `observed_event_types_total=55`, `static_event_types_total=101`,
  `observed_missing_required_fields=0`, and `waiver_until_forced_fixture=0`.
- Human replay renderer status changed in the current worktree/run:
  the official `summary.json` publishes
  `human_replay_resolve_ability_kind_unknown_lines=0`,
  `human_replay_damage_cause_unknown_lines=0`,
  `human_replay_unknown_lines=0`, `human_replay_placeholder_lines=0`, and
  `human_replay_placeholder_samples=[]`. A direct scan of the `16` current
  `replay.txt` files found `kind=?=0`, `cause=?=0`, `UNKNOWN=0`, and
  `PLACEHOLDER=0`; `test_battle_replay_v10_3_renderer` passed in
  `test_results.jsonl`, including trigger-kind fallback and noncombat damage.
  The old placeholder issue is closed for current evidence; do not reopen it
  unless a later recurring run reintroduces placeholders.
- `runtime_surface_manifest`: ready with
  `runtime_surface_manifest_gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`.
- Runtime-surface scope for this run: `total_files=108`,
  `unclassified_files=[]`,
  `automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`.
  The recurring run covers the main replay/audit pipeline; the `73` files
  outside it still require targeted gates before changes.
- Learned-opponent aggregate is present for the recurring run:
  `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`,
  `learned_opponent_appearance_count=48`,
  `learned_opponent_unique_count=12`,
  `learned_opponent_source_counts={"pg_meta_decks":48}`, and
  `opponent_deck_provenance.source_url_missing_count=0`.
- Learned-opponent source coherence is explicitly outside the final engine
  status for this run: `construction_report_missing_count=48` and
  `deck_coherence_report_missing_count=48` are covered by the shape waiver.
  Current cross-check still found `0/12` matches by
  `summary.learned_deck_opponents[].source_url` versus coherence `row_id`, and
  per-seed `deck_provenance.json` still omits `source_url` for all `48`
  learned opponent appearances. `source_ref=learned_deck:<id>` can name
  different commanders across artifacts; source-ref cross-check found `5/12`
  matches. See `BV-082`.
- Follow-ups not closed by the current aggregate status: `BV-081` remains open
  for `latest` scope observability; `BV-082` remains open for learned-deck
  source lineage/coherence joins across artifacts; `BV-083` remains open for
  action-event type denominator naming; `BV-084` remains open for
  research-review finding samples; `BV-085` remains open for learning-grade
  counts on field-contract waivers; `BV-086` is a current blocker for
  `functional_tags_json`; `BV-087` remains open for source-unknown versus
  effect-unknown backlog contract; `BV-088` remains open for direct
  lineage/gate coupling. The previous human-replay placeholder follow-up
  `BV-089` is closed by current artifact/code/test evidence.
- Test provenance: `test_results_total=16`,
  `test_results_status_counts={"pass":16}`, `test_result_failures=[]`, and
  `test_results_jsonl=/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/test_results.jsonl`.

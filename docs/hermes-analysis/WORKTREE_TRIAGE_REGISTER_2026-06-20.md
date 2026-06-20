# Worktree Triage Register - 2026-06-20

Owner: Auditor Central / single operator
Status: active inventory, PG deploys and PG-006/PG-007 runtime sync reconciled, no cleanup authorized
Last updated: 2026-06-20 11:35 -0300

## Purpose

Track the dirty ManaLoom worktree without deleting, reverting, stashing, or
overwriting work from other fronts. This file separates required evidence,
candidate source changes, generated artifacts, and possible cleanup candidates.

## Current Snapshot

Evidence commands:

- `git status --short`
- `git diff --stat`
- `git diff --name-only | wc -l`
- `git ls-files --others --exclude-standard | wc -l`
- `git diff --shortstat`

Observed state:

- branch: `master...origin/master`
- tracked modified files: `72`
- untracked status entries after PG-007 package/runtime evidence and register
  reconciliation: `78 ??`
- individual untracked files from `git ls-files --others --exclude-standard`:
  `79`
- tracked diff size before this register update:
  `72 files changed, 24631 insertions(+), 2029 deletions(-)`
- tracked modified prefix split:
  - `app`: `17`
  - `server`: `47`
  - `docs`: `8`

## App Deck Provider/UI Ownership Audit - 2026-06-20 11:05 -0300

Scope:

- `10` changed app deck source files under `app/lib/features/decks/**`.
- `7` changed focused app tests under `app/test/features/decks/**`.
- Current app deck tracked diff for this slice after the auditor patch:
  `17 files changed, 1264 insertions(+), 90 deletions(-)`.

Audited behavior:

- Create-deck now forwards learned/generated `archetype` and `bracket` to the
  backend and keeps the optimistic local deck normalized to the same trimmed
  `archetype` sent over the API.
- Optimization apply now preserves physical `condition` in payloads and uses
  condition-aware signatures so a condition-only deck change invalidates stale
  optimization output before PUT.
- Strict post-save validation failure now returns `false`, refreshes details,
  and prevents optimize success/strategy persistence after the backend rejects
  the saved deck shape.
- Deck details overview hydrates functional diagnostics through
  `GET /decks/:id/analysis`. This is read-only functional analysis, not the
  generative `POST /decks/:id/ai-analysis`.
- Diagnostic panels prefer backend `functional_tags` / legacy composition
  counts when present and fall back to local oracle heuristics only when backend
  analysis has no bucket for that role.
- Import-to-deck review now keeps visible evidence for warnings, missing cards,
  missing commander, and preserved commander instead of closing the dialog
  without review.
- Learned-deck preview hides raw Hermes `source_ref` from normal app users and
  labels it as `Deck aprendido Hermes`.

Auditor patch in this cycle:

- `app/lib/features/decks/providers/deck_provider.dart`: normalized
  `archetype` once in `createDeck` and reused the same value for the request and
  optimistic local deck cache.
- `app/test/features/decks/providers/deck_provider_test.dart`: the create-deck
  fixture now returns a complete deck payload and asserts local optimistic
  `archetype == spellslinger` plus `bracket == 3`.

Validation evidence:

- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  returned `65/65` tests passed.
- `cd app && flutter test test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart`
  returned `40/40` tests passed.

Operational result:

- Preserve the App Deck provider/UI slice.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, or push
  was performed.
- Remaining limitation: these local tests do not prove live backend deploy,
  live OpenAI success, or real-device Flutter behavior.

## Backend Deck Routes/Helpers Ownership Audit - 2026-06-20 11:09 -0300

Scope:

- Tracked route refactor under `server/routes/decks/**`,
  `server/routes/import/to-deck`, and `server/routes/cards/resolve/batch`:
  `9 files changed, 274 insertions(+), 798 deletions(-)`.
- New untracked backend helpers/tests in this ownership slice total `3379`
  lines by `wc -l`.

Audited behavior:

- Deck card name resolution now uses shared bridge-backed lookup through
  `deck_card_name_resolution_support.dart`, with fallback to `cards` if
  `card_identity_bridge` is unavailable.
- Manual deck create/update and batch resolve use the shared resolver instead
  of independent exact-name SQL.
- Bulk and import-to-deck paths preserve existing `condition` while merging
  quantities and rebuild `deck_cards` only after rule validation.
- Import-to-deck response now exposes final commander status, preserved
  commander status, localized match counts, warnings, and missing commander
  flags through `import_to_deck_merge_support.dart`.
- Recommendations route was reduced to an adapter; fallback/advisory/OpenAI
  shape now lives in typed helpers.
- Recommendations SQL still avoids unsafe deck-row fanout: product deck reads
  use `card_intelligence_snapshot` when present, otherwise aggregate
  `card_function_tags` and `card_semantic_tags_v2` through per-card JSON
  subqueries / `EXISTS`.

Auditor patch in this cycle:

- `server/lib/deck_recommendations_route_support.dart`: OpenAI prompt now
  includes backend-computed `candidate_color_identity` as
  `Identidade de cor para recomendacoes`, instead of exposing only observed
  `colors` from card rows.
- `server/test/deck_recommendations_route_support_test.dart`: added no-network
  assertion that the OpenAI prompt contains `Identidade de cor para
  recomendacoes: R, W`.

Validation evidence:

- `cd server && dart test test/deck_recommendations_route_support_test.dart test/deck_recommendations_advisory_support_test.dart test/deck_recommendations_fallback_support_test.dart test/deck_recommendations_power_level_support_test.dart test/deck_recommendations_route_adapter_test.dart`
  returned `16/16` tests passed.
- `cd server && dart test test/deck_cards_bulk_support_test.dart test/import_to_deck_merge_support_test.dart test/deck_validation_route_support_test.dart test/deck_fetch_hydration_contract_test.dart test/deck_manual_mutation_route_contract_test.dart test/deck_pricing_export_community_contract_test.dart test/cards_route_test.dart test/card_resolution_support_test.dart`
  returned `33/33` tests passed.
- `cd server && dart analyze ...` over the backend helpers, routes, and focused
  tests returned `No issues found!`.

Operational result:

- Preserve the Backend Deck routes/helpers slice.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, or push
  was performed.
- Remaining limitation: local adapter/helper tests do not prove live backend
  deploy or live OpenAI behavior.

## Backend AI/Import/Simulate Ownership Audit - 2026-06-20 11:12 -0300

Scope:

- `33` tracked files across backend AI routes, learned-deck support, optimize
  support, import lookup, validation services, battle/simulation helpers, and
  focused tests.
- Tracked diff for this ownership slice:
  `33 files changed, 1987 insertions(+), 500 deletions(-)`.
- Related untracked PostgreSQL planner scripts/tests total `1443` lines by
  `wc -l`; these are planner/audit artifacts, not applied DB writes.

Audited behavior:

- Learned-deck support now canonicalizes role summaries from card lists when
  possible and records fallback reason when persisted metadata is used.
- Learned-deck response decklists include safe app-facing card IDs/canonical
  names/legal status, while normal app pathways still avoid exposing raw Hermes
  internals as primary UI labels.
- Import lookup now handles split/DFC front-face and back-face aliases and
  carries `oracle_id` through resolved card metadata.
- Generated deck validation exposes quality evidence for repairs, removed
  invalid cards, warnings, and CMC-integrity warnings.
- Optimize cache/signature and route filtering include physical `condition` and
  block additions whose color identity cannot be proven.
- Simulate-matchup now uses deterministic seeds, `card_intelligence_snapshot`
  when present, aggregated functional/semantic tag subqueries otherwise, and
  commander color identity for response colors.
- Weakness-analysis and recommendations continue to avoid fixed staple lists in
  the guarded paths and prefer DB-backed semantic/functional lookup.

Validation evidence:

- `cd server && dart test test/ai_generate_learning_boundary_test.dart test/commander_learned_deck_support_test.dart test/deck_rules_service_test.dart test/experimental_deck_ai_authorization_source_test.dart test/generated_deck_validation_service_test.dart test/import_list_service_test.dart test/import_parser_test.dart test/optimize_cache_support_test.dart test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_warnings_support_test.dart test/unsupported_deck_sections_route_contract_test.dart`
  returned `83/83` tests passed.
- `python3 -m unittest server.test.card_impact_analyzer_test server.test.learned_deck_coherence_audit_test server.test.manaloom_ops_daemon_test server.test.plan_learned_deck_partner_identity_backfill_test server.test.plan_lorehold_critical_role_backfill_test server.test.plan_oracle_text_backfill_test`
  returned `39/39` tests passed.
- `cd server && dart analyze ...` over AI/import/simulate source and focused
  tests returned `No issues found!`.

Operational result:

- Preserve the Backend AI/import/simulate slice.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, or push
  was performed.
- Remaining limitation: local tests do not prove live backend deploy, live
  OpenAI behavior, or real battle runtime outside the generated artifacts.

## Auditor Central Source Patch Validation - 2026-06-20 10:09 -0300

Scope:

- Backend recommendation advisory response authority.
- Backend battle focused-evidence harness for extra-combat flashback.
- Backend ops-daemon `.env` test isolation.
- App deck provider/UI slice after the backend/source audit.

Changes recorded:

- `server/lib/deck_recommendations_advisory_support.dart` now keeps
  backend-owned fallback context authoritative after OpenAI text is parsed.
  The protected fields are `power_level`, `statistics`, `colors`,
  `candidate_color_identity`, `color_identity_source`, `trending`, and
  `message`.
- `server/test/deck_recommendations_advisory_support_test.dart` adds a
  regression for a conflicting model response trying to override those fields.
- `server/bin/manaloom_battle_rule_focused_evidence.py` now validates
  extra-combat flashback evidence with the original spell effect data rather
  than only the reclassified stack item data.
- `server/test/manaloom_ops_daemon_test.py` isolates `DB_HOST` and `DB_NAME`
  while checking `.env` loading so the test is not affected by the operator
  shell environment.

Evidence:

- `dart format server/lib/deck_recommendations_advisory_support.dart server/test/deck_recommendations_advisory_support_test.dart`
  completed with no remaining changes.
- Focused recommendations `dart analyze`: no issues.
- Focused recommendations `dart test`: `16/16` passed.
- Focused app deck `flutter analyze`: no issues.
- Focused app deck `flutter test`: `105/105` passed.
- Focused backend deck/API `dart test`: `143/143` passed.
- `python3 -m unittest server.test.manaloom_review_queue_consumers_test.ManaloomReviewQueueConsumersTest.test_focused_evidence_unblocks_supported_low_risk_templates -v`
  passed and emitted `MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE` with
  `evaluated_count=14` and `evidence_count=14`.
- `python3 -m unittest server.test.manaloom_ops_daemon_test.ManaLoomOpsDaemonTest.test_base_env_loads_database_values_from_env_file -v`
  passed.
- `python3 -m py_compile server/bin/manaloom_battle_rule_focused_evidence.py server/test/manaloom_ops_daemon_test.py`
  passed.
- `python3 -m unittest discover -s server/test -p '*_test.py' -v` passed
  `96/96`; it printed one `ResourceWarning` for an unclosed sqlite connection
  in a learned-deck audit test, but exit status was `0`.
- `git diff --check` returned no output.
- After this register/API-contract update, `git diff --check` still returned no
  output and
  `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
  passed `6/6`.
- Final tracked diff size after this documentation update:
  `72 files changed, 24134 insertions(+), 2026 deletions(-)`.

Database/deploy conclusion:

- This source patch did not write PostgreSQL and does not create a new
  PostgreSQL package.
- PG-001, PG-002, PG-006, and PG-007 remain closed; PG-003 remains
  policy-blocked; PG-005 remains no-apply-needed. PG-004's historical closure
  and the `20260620_125745` Leyline blocker were superseded by latest
  `20260620_132812`.
- No deck swap, cleanup, stash, revert, commit, push, or deletion was
  performed.

## PG-007 Prepared Package - Not Applied - 2026-06-20 10:22 -0300

Historical status: superseded by the `2026-06-20 10:31 -0300` PG-007 apply,
runtime sync, and latest battle closure below.

Scope:

- Latest battle `20260620_125745` returned to `review_required` by one
  `forensic_audit` blocker.
- Prepared a PostgreSQL package for `Leyline of Abundance` battle-rule lineage.

Evidence:

- Latest summary path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/summary.json`.
- Status: `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_rule_findings=1`, tests `16/16` passing.
- PostgreSQL precheck passed after correction:
  target card `1`, existing target rule `0`, existing Leyline rules `0`,
  snapshot `battle_rules=[]`, `function_tags={engine}`.
- Package files:
  `leyline_abundance_battle_rule_pg007_package_20260620_1018.md`,
  `leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql`,
  `leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql`,
  `leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql`,
  `leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`.

Conclusion:

- At this historical point, PG-007 was still in prepared/pre-apply state.
- No PostgreSQL write, Hermes SQLite sync, battle rerun, cleanup, commit, push,
  revert, stash, or deletion had been performed for PG-007 yet.

## PG-007 Applied And Validated - 2026-06-20 10:31 -0300

Evidence:

- PostgreSQL apply result: `INSERT 0 1`, `COMMIT`.
- PostgreSQL postcheck: `pg007_target_rule_count=1`; Leyline is present in
  `card_intelligence_snapshot.battle_rules`.
- SQLite backup:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg007-runtime-sync.20260620_102701.bak`.
- Runtime sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`
  with `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107`, and
  `canonical_snapshot_rows_exported=3160`.
- Latest battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`
  with `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  `forensic_lineage_status=complete`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, and tests `16/16` pass.

Conclusion:

- PG-007 is closed.
- No cleanup, commit, push, revert, stash, or deletion was performed.

## Required Evidence - Keep

These files are evidence or current control state. Do not remove them during
cleanup unless their contents are superseded and consolidated elsewhere.

- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_ORDERS.md`
- `docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md`
- `docs/hermes-analysis/WORKTREE_TRIAGE_REGISTER_2026-06-20.md`
- `docs/hermes-analysis/WORKTREE_FILE_OWNERSHIP_INDEX_2026-06-20.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_apply_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_precheck_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_postcheck_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_rollback_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_005219.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_095139_post_pg001_audit_fix.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md`
- `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg006-runtime-sync.20260620_120904.bak`
- `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Source/Test Candidates - Keep Pending Validation

These appear to be active implementation or validation work. They are not
cleanup candidates until audited slice by slice.

- `app/lib/features/decks/**`
- `app/test/features/decks/**`
- `server/lib/**`
- `server/routes/**`
- `server/test/**`
- `server/bin/card_impact_analyzer.py`
- `server/bin/learned_deck_coherence_audit.py`
- `server/bin/canonicalize_learned_deck_metadata.dart`
- `server/test/canonicalize_learned_deck_metadata_cli_test.dart`
- `server/bin/plan_learned_deck_partner_identity_backfill.py`
- `server/bin/plan_lorehold_critical_role_backfill.py`
- `server/bin/plan_oracle_text_backfill.py`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/doc/COMMANDER_LEARNING_API_2026-06-03.md`

## Current Single-Operator Heartbeat - 2026-06-20 10:50 -0300

Evidence:

- `git status --short --branch`: `master...origin/master`, `72 M`, `78 ??`.
- `git ls-files --others --exclude-standard | wc -l`: `79`.
- `git diff --shortstat`:
  `72 files changed, 24397 insertions(+), 2028 deletions(-)`.
- `git diff --check`: clean.
- Latest battle summary resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`,
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, and tests
  `16/16` pass.
- `cd server && dart run bin/migrate.dart --status`: `29/29` migrations
  executed, `0` pending.
- PG-007 postcheck read-only:
  `pg007_target_rule_count=1`, snapshot exposes `Leyline of Abundance`
  `battle_rules`, and rollback backup rows remain `0`.
- PostgreSQL queue read-only planners:
  - PG-001 partner identity: `planned_row_count=0`, `db_mutations=false`;
  - PG-002 metadata canonicalization postcheck:
    `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
    `still_before_rows=0`, `all_post_apply_checks_ok=true`;
  - PG-003 oracle/card text/type planner:
    `missing_any=363`, `planned_items=6`, `backfill_ready=0`,
    `db_mutations=false`;
  - PG-005 Lorehold critical-role dry-run:
    `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`,
    `counts_before` equals `counts_after`, `db_mutations=false`.
- Aggregate source validation:
  - app changed/untracked Dart analyze: no issues;
  - app changed/untracked Dart tests: `105/105` passed;
  - backend changed/untracked Dart analyze: no issues;
  - backend changed/untracked Dart tests: `146/146` passed;
  - backend changed/untracked Python `py_compile` plus focused unittests:
    `39/39` passed.

Conclusion:

- No new PostgreSQL apply is ready at this heartbeat.
- No PostgreSQL write, deck swap, cleanup, file deletion, stash, revert, commit,
  push, or staging was performed in this heartbeat.

## Validated In This Cycle

Single-operator heartbeat after Rafael paused other chats:

- Current worktree remains `72 M` and `78 ??` on `master...origin/master`.
- `git diff --check` returned no output.
- Added-line risk scan found no new `TODO`, `FIXME`, `debugPrint`, `print`,
  `console.log`, or skipped-test marker in the current app/server diff.
- PostgreSQL read-only queue recheck:
  - migrations: `29/29` executed, `0` pending;
  - PG-001 planner: `planned_row_count=0`, `db_mutations=false`;
  - PG-002 postcheck: `all_post_apply_checks_ok=true`;
  - PG-003 oracle planner: `backfill_ready=0`, `db_mutations=false`;
  - PG-005 Lorehold dry-run: `applied_counts=0`, `db_mutations=false`;
  - PG-006 postcheck: migration `029`, constraint present, `auto=1751`,
    `review_only=3437`, `remaining_needs_review_not_review_only=0`.
- Latest battle summary remains
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, and `test_results_total=16` with
  `test_results_status_counts={"pass":16}`.
- Current validation:
  - app aggregate analyze: no issues;
  - app focused tests: `105/105` passed;
  - backend aggregate Dart analyze: no issues;
  - backend changed/untracked Dart tests: `146/146` passed;
  - backend changed/untracked Python tests: `39` passed.
- No PostgreSQL write, deck swap, cleanup, file deletion, stash, revert, commit,
  push, or staging was performed.

Partner identity audit-code drift closure:

- code diff:
  `server/bin/learned_deck_coherence_audit.py` now suppresses
  `partner_identity_not_modeled` when persisted
  `metadata.commander_identity_model` matches the derived model.
- tests:
  `python3 -m unittest server/test/learned_deck_coherence_audit_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py`
  returned `21` tests passed.
- read-only planner:
  `plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`
  returned `status=PASS`, `planned_row_count=0`, `db_mutations=false`.
- read-only audit:
  `learned_deck_coherence_audit.py --stdout` returned no
  `partner_identity_not_modeled` in the compact summary and kept the real
  global metadata backlog visible.

Conclusion: PG-001 is closed. No new partner-identity PostgreSQL apply is
pending.

PG-002 metadata canonicalization package:

- `server/bin/canonicalize_learned_deck_metadata.dart` now supports chunked,
  parseable dry-runs via `--offset`, `--progress`, and
  `--include-full-metadata`; default mode remains no-write dry-run.
- `cd server && dart analyze bin/canonicalize_learned_deck_metadata.dart test/canonicalize_learned_deck_metadata_cli_test.dart`
  returned no issues.
- `cd server && dart test test/canonicalize_learned_deck_metadata_cli_test.dart -r expanded`
  returned `3/3` tests passed.
- Full dry-run artifact reports `checked=60`, `reported=60`, `changed=59`,
  `applied=0`, and `db_mutations=false`.
- SELECT-only precheck returned `expected_rows=59`, `matched_rows=59`,
  `before_matches=59`, `already_after_rows=0`, `would_change_rows=59`, and
  `active_matches=59`.
- Auditor Central package reconciliation at `2026-06-20 08:26 -0300` verified
  that precheck/apply/rollback/postcheck SQL each contain the same `59` unique
  `(row_id, source_ref)` pairs and that those pairs exactly match the dry-run
  `changed=true` rows.
- PG-002 was applied at `2026-06-20 08:32 -0300`.
- Apply result: `UPDATE 59`, `COMMIT`.
- Postcheck returned `after_matches=59`, `still_before_rows=0`, and
  `all_post_apply_checks_ok=true`.
- Canonicalizer post-apply dry-run returned `status=PASS`,
  `db_mutations=false`, `checked=60`, `changed=0`, and `applied=0`.

PG-006 card_battle_rules execution_status package:

- Read-only migration status:
  `dart run bin/migrate.dart --status` reports migration `029
  add_card_battle_rules_execution_status` pending.
- Read-only PostgreSQL inspection shows `card_battle_rules.execution_status`
  already exists as `NOT NULL` with default `'auto'::text`, while
  `chk_card_battle_rules_execution_status` is missing.
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`
  returned `pg006_rows_to_normalize=1970` and showed the current live
  `card_intelligence_snapshot` view definition does not mention
  `execution_status`.
- Package artifacts were created:
  `card_battle_rules_execution_status_pg006_package_20260620_0808.md`,
  `card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`,
  `card_battle_rules_execution_status_pg006_apply_20260620_0808.sql`,
  `card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql`, and
  `card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql`.
- PG-006 was applied at `2026-06-20 08:30 -0300`.
- Apply result: `COMMIT`, `normalized_rows=1970`, rollback backup rows `1970`.
- Postcheck returned `remaining_needs_review_not_review_only=0`,
  `generated / needs_review / review_only = 3437`,
  `chk_card_battle_rules_execution_status` present, and migration `029`
  present.
- `dart run bin/migrate.dart --status` now reports `29/29` migrations
  executed.
- No deck swap, commit, push, revert, stash, or cleanup was performed.

Backend deck/route extraction slice:

- Read and checked the new helper boundaries:
  `deck_card_name_resolution_support.dart`,
  `deck_cards_bulk_support.dart`,
  `deck_validation_route_support.dart`,
  `import_to_deck_merge_support.dart`, and
  `deck_recommendations_route_support.dart`.
- Current helper scope observed:
  - card-name resolution centralizes bridge-first candidate lookup and fallback;
  - bulk-card merge preserves existing `condition`;
  - validation helper only builds owner-scope SQL/body shapes;
  - import merge preserves commander state and response status fields;
  - recommendations route core separates not-found, no-key fallback, and OpenAI
    advisory/error envelopes.
- `cd server && dart analyze lib/deck_card_name_resolution_support.dart lib/deck_cards_bulk_support.dart lib/deck_validation_route_support.dart lib/import_to_deck_merge_support.dart lib/deck_recommendations_advisory_support.dart lib/deck_recommendations_fallback_support.dart lib/deck_recommendations_power_level_support.dart lib/deck_recommendations_route_support.dart routes/cards/resolve/batch/index.dart 'routes/decks/[id]/cards/bulk/index.dart' 'routes/decks/[id]/index.dart' 'routes/decks/[id]/recommendations/index.dart' 'routes/decks/[id]/validate/index.dart' routes/decks/index.dart routes/import/to-deck/index.dart test/card_resolution_support_test.dart test/deck_cards_bulk_support_test.dart test/deck_validation_route_support_test.dart test/import_to_deck_merge_support_test.dart test/deck_recommendations_advisory_support_test.dart test/deck_recommendations_fallback_support_test.dart test/deck_recommendations_power_level_support_test.dart test/deck_recommendations_route_support_test.dart test/deck_recommendations_route_adapter_test.dart test/api_contracts_data_map_guard_test.dart test/experimental_deck_ai_authorization_source_test.dart`
  returned no issues.
- `cd server && dart test test/card_resolution_support_test.dart test/deck_cards_bulk_support_test.dart test/deck_validation_route_support_test.dart test/import_to_deck_merge_support_test.dart test/deck_recommendations_advisory_support_test.dart test/deck_recommendations_fallback_support_test.dart test/deck_recommendations_power_level_support_test.dart test/deck_recommendations_route_support_test.dart test/deck_recommendations_route_adapter_test.dart test/api_contracts_data_map_guard_test.dart test/experimental_deck_ai_authorization_source_test.dart -r expanded`
  returned `52/52` tests passed.
- No PostgreSQL write, deck swap, live OpenAI call, commit, push, revert, stash,
  or cleanup was performed.

Flutter Deck provider/UI slice:

- Read the modified app diff for provider request/payload changes, generated
  deck strategy metadata, diagnostic analysis hydration, diagnostic panel
  backend-analysis preference, import dialog behavior, and optimize-flow
  support.
- Current app-side scope observed:
  - create-deck requests can preserve generated/learned `archetype` and
    `bracket`;
  - optimize/apply payload signatures include physical condition codes;
  - strict validation failure after optimize apply refreshes deck state and
    returns failure instead of claiming success;
  - Deck details fetches diagnostic analysis once for meaningful deck states;
  - diagnostic panel prefers backend functional-tag analysis when available;
  - import dialog tests cover review/refresh behavior.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_common.dart lib/features/decks/providers/deck_provider_support_fetch.dart lib/features/decks/providers/deck_provider_support_mutation.dart lib/features/decks/screens/deck_details_screen.dart lib/features/decks/screens/deck_generate_screen.dart lib/features/decks/widgets/deck_details_overview_tab.dart lib/features/decks/widgets/deck_diagnostic_panel.dart lib/features/decks/widgets/deck_import_list_dialog.dart lib/features/decks/widgets/deck_optimize_flow_support.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`
  returned no issues.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`
  returned `105/105` tests passed.
- No PostgreSQL write, deck swap, commit, push, revert, stash, or cleanup was
  performed.

Battle registers/latest artifact consistency and PG-006 runtime cache sync
(historical, superseded by PG-007 and latest `20260620_132812`):

- Read latest recurring artifact
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`.
- At that time, latest resolved to run `20260620_121005`,
  `run_scope=recurring_full`, `run_profile=manual_post_pg006_sqlite_sync`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  returned PASS.
- `test_results.jsonl` has `16` entries and all have `status=pass`.
- Battle status at that time was `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, and `forensic_turn_findings=0`.
- Runtime surface manifest was fixed during this cycle to classify
  `server/bin/plan_learned_deck_partner_identity_backfill.py` and
  `server/test/plan_learned_deck_partner_identity_backfill_test.py` as
  `learned-deck source`; the manifest now reports total files `110` and no
  unclassified files.
- PG-006 source-scope follow-up was closed for the local Hermes cache:
  `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
  reported `apply_pg=false`, `pg_rows_loaded=5188`,
  `sqlite_inserted_or_updated=5106`, and
  `canonical_snapshot_rows_exported=3159`.
- Post-sync effect audit reports
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, and `review_only_rule_names=1457`.
- No battle-rule PostgreSQL write, battle rule promotion, deck swap, commit,
  push, revert, stash, or cleanup was performed for this cache sync and battle
  rerun.

Backend AI/import/simulate slice:

- Read the modified diff across `server/lib/ai/**`, `server/routes/ai/**`,
  `server/routes/import/validate/index.dart`,
  `server/routes/decks/[id]/ai-analysis/index.dart`,
  `server/routes/decks/[id]/simulate/index.dart`,
  `server/lib/import_card_lookup_service.dart`,
  `server/lib/generated_deck_validation_service.dart`,
  `server/lib/deck_rules_service.dart`, and
  `server/bin/card_impact_analyzer.py`.
- Current behavior observed:
  - learned-deck route now recomputes role summary from canonicalized card-list
    metadata and exposes `role_summary_source`/fallback reason instead of raw
    persisted metadata;
  - `/ai/generate` publishes deterministic reference-deck diagnostics and
    preserves original validation quality evidence when fallback repairs a
    response;
  - `/ai/optimize` includes physical `condition` in context/cache signatures
    and blocks additions whose color identity cannot be proven;
  - import validation resolves split-card front/back faces, carries
    `oracle_id`, and groups physical-copy warnings by `oracle_id` when present;
  - simulate/matchup and weakness-analysis prefer commander color identity over
    observed card colors and clamp simulation counts to bounded ranges;
  - `card_impact_analyzer.py` accepts generated replay `won=true` markers and
    blocks mixed baseline hashes.
- `cd server && dart analyze ...` over the focused AI/import/simulate files
  returned no issues.
- `cd server && dart test test/ai_generate_learning_boundary_test.dart test/commander_learned_deck_support_test.dart test/deck_rules_service_test.dart test/generated_deck_validation_service_test.dart test/import_list_service_test.dart test/import_parser_test.dart test/optimize_cache_support_test.dart test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_warnings_support_test.dart test/cards_route_test.dart test/deck_simulate_route_adapter_test.dart -r expanded`
  returned `76/76` tests passed.
- `python3 -m unittest server/test/card_impact_analyzer_test.py`
  returned `5` tests passed.
- No PostgreSQL write, deck swap, commit, push, revert, stash, or cleanup was
  performed.

PostgreSQL planner scripts:

- `python3 -m py_compile server/bin/plan_lorehold_critical_role_backfill.py server/bin/plan_oracle_text_backfill.py server/bin/plan_learned_deck_partner_identity_backfill.py`
  returned PASS.
- `python3 -m unittest server/test/plan_lorehold_critical_role_backfill_test.py server/test/plan_oracle_text_backfill_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py`
  returned `7` tests passed.
- `python3 server/bin/plan_lorehold_critical_role_backfill.py --dry-run`
  returned `status=PASS`, `mode=dry_run`, `db_mutations=false`,
  `planned_counts={"commander_synergy_rows":5,"function_tag_rows":11,"semantic_v2_rows":4}`,
  `counts_before` equal to `counts_after`, and `applied_counts=0`.
- `python3 server/bin/plan_oracle_text_backfill.py --no-scryfall --limit 10`
  returned `status=PASS`, `mode=read_only`, `db_mutations=false`,
  `base_oracle_summary={"total_cards":34329,"missing_any":363,"missing_oracle_id":4,"missing_oracle_text":360}`,
  `planned_items=6`, `deck_card_gap_items=6`, `active_learned_gap_items=0`,
  and `backfill_ready=0`.
- Conclusion: no new PostgreSQL package is ready from these planners. Lorehold
  critical role rows already appear present under the planner's source, and the
  oracle backlog remains policy-blocked.

PostgreSQL queue heartbeat:

- `plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`
  returned `planned_row_count=0`, `db_mutations=false`.
- `learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`
  returned `all_post_apply_checks_ok=true`.
- `plan_oracle_text_backfill.py --no-scryfall --limit 10` returned
  `backfill_ready=0`, `planned_items=6`, `db_mutations=false`.
- `plan_lorehold_critical_role_backfill.py --dry-run` returned
  `applied_counts=0`, `counts_before` equal to `counts_after`, and
  `db_mutations=false`.
- Direct PG-006 SELECTs returned `execution_status auto=1751`,
  `review_only=3437`, `generated_needs_review_not_review_only=0`, and
  migration `029=1`.
- A full canonicalizer dry-run was started but interrupted after it did not
  finish in a useful window; it is not counted as evidence.
- No PostgreSQL write, deck swap, cleanup, commit, push, revert, or stash was
  performed.

Backend changed/untracked Dart aggregate validation:

- Scope: every changed or untracked Dart file under `server/` from
  `git diff --name-only -- server` plus
  `git ls-files --others --exclude-standard server`.
- Command:
  `(git diff --name-only -- server && git ls-files --others --exclude-standard server) | rg '\.dart$' | sed 's#^server/##' | sort -u | (cd server && xargs dart analyze)`
  returned no issues.
- Scope: every changed or untracked Dart test under `server/test`.
- Command:
  `(git diff --name-only -- server/test && git ls-files --others --exclude-standard server/test) | rg '_test\.dart$' | sed 's#^server/##' | sort -u | (cd server && xargs dart test -r expanded)`
  returned `146/146` tests passed.
- Python aggregate validation:
  `python3 -m unittest server/test/card_impact_analyzer_test.py server/test/learned_deck_coherence_audit_test.py server/test/manaloom_ops_daemon_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py server/test/plan_lorehold_critical_role_backfill_test.py server/test/plan_oracle_text_backfill_test.py -v`
  returned `39` tests passed.
- Note: an earlier attempt to aggregate Dart tests from inside `server/` used
  the wrong `server/test` prefix and emitted a path warning; that run is not
  counted as evidence. The root-run commands above are the valid evidence.
- No PostgreSQL write, deck swap, commit, push, revert, stash, or cleanup was
  performed.

Backend data-contract anti-fanout audit:

- Scope: changed/untracked backend server files plus current route/support
  sources that reference `card_battle_rules`, `card_function_tags`,
  `card_semantic_tags_v2`, `card_intelligence_snapshot`, and
  `card_identity_bridge`.
- Search commands:
  `rg -n "JOIN\\s+card_battle_rules|JOIN\\s+card_function_tags|JOIN\\s+card_semantic_tags_v2|FROM\\s+card_battle_rules|FROM\\s+card_function_tags|FROM\\s+card_semantic_tags_v2|card_intelligence_snapshot|card_identity_bridge" server docs/hermes-analysis/master_optimizer_reports -g '*.dart' -g '*.py' -g '*.sql' -g '*.md'`
  and
  `rg -n "deck_cards.*card_battle_rules|card_battle_rules.*deck_cards|deck_cards.*card_function_tags|card_function_tags.*deck_cards|deck_cards.*card_semantic_tags_v2|card_semantic_tags_v2.*deck_cards" server docs/hermes-analysis/master_optimizer_reports -g '*.dart' -g '*.py' -g '*.sql' -g '*.md'`.
- Source inspection found current deck-reading routes prefer
  `card_intelligence_snapshot` when present:
  `server/routes/decks/[id]/recommendations/index.dart`,
  `server/routes/ai/simulate-matchup/index.dart`,
  `server/routes/decks/[id]/ai-analysis/index.dart`,
  `server/routes/ai/weakness-analysis/index.dart`, and
  `server/lib/ai/optimize_request_support.dart`.
- Fallback paths read `card_function_tags` and `card_semantic_tags_v2` through
  per-card `jsonb_agg(...)` subqueries or `EXISTS` predicates, not direct
  `deck_cards -> multi-row table` joins.
- The expected direct `deck_cards -> card_battle_rules` reference remains inside
  `server/bin/audit_data_model_links.dart` as a diagnostic fanout detector, not
  product-route loading logic.
- `cd server && dart test test/api_contracts_data_map_guard_test.dart test/cards_route_test.dart test/deck_rules_service_test.dart test/deck_validation_route_support_test.dart -r expanded`
  returned `19/19` tests passed.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/candidate_quality_data_support_test.dart test/deck_recommendations_route_support_test.dart test/deck_recommendations_route_adapter_test.dart -r expanded`
  returned `24/24` tests passed.
- `python3 -m unittest server/test/plan_oracle_text_backfill_test.py server/test/plan_lorehold_critical_role_backfill_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py`
  returned `7` tests passed.
- Conclusion: no new backend anti-fanout defect was found in this slice; no
  PostgreSQL package, code patch, deck swap, cleanup, commit, push, revert, or
  stash was performed.

App changed Dart aggregate validation:

- Scope: every changed or untracked Dart file under `app/`.
- Command:
  `(git diff --name-only -- app && git ls-files --others --exclude-standard app) | rg '\.dart$' | sed 's#^app/##' | sort -u | (cd app && xargs flutter analyze)`
  analyzed `17` items and returned no issues.
- Scope: every changed or untracked Dart test under `app/test`.
- Command:
  `(git diff --name-only -- app/test && git ls-files --others --exclude-standard app/test) | rg '_test\.dart$' | sed 's#^app/##' | sort -u | (cd app && xargs flutter test)`
  returned `105/105` tests passed.
- Note: Flutter waited for the startup lock before analyze, then completed
  successfully.
- No PostgreSQL write, deck swap, commit, push, revert, stash, or cleanup was
  performed.

Documentation contradiction audit
(historical, superseded by PG-007 and latest `20260620_132812`):

- Scope: required control docs and registers against current PostgreSQL migration
  status and latest battle artifact.
- Read-only evidence:
  `cd server && dart run bin/migrate.dart --status` reports all `29/29`
  migrations executed and `0` pending.
- Latest battle evidence at that time:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`
  resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`.
- Latest `summary.json` reports
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={"pass":16}`,
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, `review_only_rule_names=1457`, and
  `runtime_surface_manifest_total_files=110`.
- Corrected stale operational text:
  - `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md` no longer keeps
    PG-001 partner identity persistence or PG-002 metadata canonicalization as
    active pending items; both are closed unless future SELECT/artifact evidence
    proves rollback or drift.
  - `MANALOOM_CENTRAL_AUDITOR_ORDERS.md` now labels the old PG-002 mismatch
    counts and PG-006 pending migration evidence as pre-apply evidence, and adds
    the current `29/29` migration/latest artifact recheck.
  - `POSTGRES_DEPLOY_REGISTER_2026-06-20.md` now has a `09:36 -0300`
    read-only heartbeat confirming no current PostgreSQL apply is ready.
  - `WORKTREE_OPERATIONAL_MAP_2026-06-20.md` now records this control-doc
    reconciliation slice.
- Historical sections for superseded runs such as `090636`, `115516`, and old
  `review_required` findings were preserved as chronology; they are not active
  state unless a newer current-state section says so.
- No PostgreSQL write, deck swap, code patch, cleanup, commit, push, revert, or
  stash was performed.

Cleanup proposal audit:

- Scope: exact cleanup candidate list in
  `docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md`.
- Current proposal contains `8` files:
  - six superseded untracked learned-deck coherence snapshots:
    `031157.json/.md`, `033941.json/.md`, and `034324.json/.md`;
  - two duplicate effect-coverage files:
    `battle_effect_coverage_audit_20260620_120952.json/.md`.
- Hash/size evidence was recorded in the cleanup proposal at
  `2026-06-20 09:40 -0300`.
- `cmp -s` returned `0` for both `120952.*` files against their retained
  `120904_post_sqlite_sync.*` counterparts, proving byte-identical duplicate
  content for those two files.
- The six learned-deck coherence candidates are not byte-duplicates; they remain
  only proposal candidates because current evidence is retained by
  `learned_deck_coherence_audit_20260620_115918.*`, while
  `095253.*` remains retained as pre-PG-002 comparison evidence.
- The proposal text was corrected from an ambiguous "six-file deletion list" to
  an exact `8`-file deletion list.
- No file was deleted, moved, stashed, reverted, committed, or pushed.

## Cleanup Candidates - Not Approved

Operational map:

- `docs/hermes-analysis/WORKTREE_OPERATIONAL_MAP_2026-06-20.md`

Exact proposal artifact:

- `docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md`

These may become cleanup candidates after the latest evidence remains retained
in registers:

- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.md`

No cleanup is authorized by this register. These are only candidates for a
future exact approval list.

## Battle/PG/Worktree Heartbeat - 2026-06-20 11:19 -0300

Scope:

- Rechecked active latest battle, PostgreSQL deploy queue, runtime surface
  manifest, and worktree status after the single-operator source-slice audits.
- No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
  commit, or push was performed.

Evidence:

- `git status --short --branch`: `master...origin/master`, `72 M`, `78 ??`.
- `git diff --shortstat`:
  `72 files changed, 24491 insertions(+), 2029 deletions(-)`.
- `git diff --check`: clean.
- Current latest battle resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_140016/summary.json`.
- Latest battle result:
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, tests `16/16`
  pass, `strategy_review_required_findings=0`,
  `unknown_template_backlog_cards=0`,
  `execution_status_counts={"auto":1703,"review_only":1457}`.
- Runtime surface manifest test:
  `python3 test_battle_runtime_surface_manifest.py` returned
  `PASS test_manifest_classifies_current_battle_surface`.
- Runtime surface manifest scan:
  `total_files=110`, `unclassified_files=[]`, category counts
  `core runtime=31`, `focused evidence/promotion=4`,
  `learned-deck source=16`, `optimizer/scorecard=15`,
  `recurring audit gate=24`, `renderer=4`, `review queue=1`,
  `rule registry/sync=15`.
- PostgreSQL migration status:
  `dart run bin/migrate.dart --status` reports `29/29` executed and
  `0` pending.
- PG-001 planner dry-run:
  `status=PASS`, `planned_row_count=0`, `db_mutations=false`.
- PG-002 postcheck:
  `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `all_post_apply_checks_ok=true`.
- PG-003 oracle planner:
  `status=PASS`, `mode=read_only`, `missing_any=363`,
  `missing_oracle_id=4`, `missing_oracle_text=360`,
  `planned_items=6`, `backfill_ready=0`, `db_mutations=false`;
  Scryfall lookup was intentionally skipped.
- PG-005 Lorehold critical-role dry-run:
  `status=PASS`, `db_mutations=false`, `applied_counts=0`, existing rows
  remain `commander_synergy=5`, `function_tag=11`, `semantic_v2=4`.
- PG-006 postcheck:
  migration `029` present, `execution_status` column `NOT NULL` with default
  `'auto'::text`, constraint present, `auto=1752`, `review_only=3437`,
  `remaining_needs_review_not_review_only=0`, rollback backup rows `1970`,
  and `card_intelligence_snapshot_view.mentions_execution_status=true`.
- PG-007 postcheck:
  `pg007_target_rule_count=1`; Leyline of Abundance remains present as
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `confidence=0.820`, and the snapshot exposes the battle rule.

Conclusion:

- No new PostgreSQL apply is ready now.
- PG-001, PG-002, PG-006, and PG-007 stay closed unless future SELECT/artifact
  evidence proves rollback or drift.
- PG-003 remains policy-blocked; PG-005 remains no-apply-needed.
- Cleanup remains a proposal only; no deletion is authorized.

## Cleanup Proposal Revalidation - 2026-06-20 11:26 -0300

Scope:

- Revalidated the exact cleanup proposal without deleting, moving, stashing,
  reverting, staging, committing, or pushing any file.
- Updated `docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md`
  with current evidence.

Evidence:

- All `8` cleanup candidates still exist.
- Candidate hashes still match the recorded hash set.
- `battle_effect_coverage_audit_20260620_120952.json` remains byte-identical
  to retained `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json`
  (`cmp` returned `0`).
- `battle_effect_coverage_audit_20260620_120952.md` remains byte-identical to
  retained `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md`
  (`cmp` returned `0`).
- Learned-deck cleanup candidates are not byte-duplicates; they remain
  superseded snapshot candidates:
  - `031157`: `high=169`, `medium=21`,
    `metadata_total_lands_mismatch=58`, `metadata_zero_lands=54`,
    `partner_identity_not_modeled=9`;
  - `033941`: `high=168`, `medium=21`,
    `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
    `partner_identity_not_modeled=9`;
  - `034324`: `high=167`, `medium=22`,
    `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
    `partner_identity_not_modeled=10`.
- Retained comparison/current learned-deck evidence:
  - `095253` remains pre-PG-002 comparison evidence with `high=167`,
    `medium=12`, `metadata_total_lands_mismatch=57`,
    `metadata_zero_lands=54`;
  - `115918` remains post-PG-002 current evidence with `high=2`,
    `medium=13`, and no aggregate keys for
    `metadata_total_lands_mismatch`, `metadata_zero_lands`,
    `all_core_metadata_zero`, or `partner_identity_not_modeled`.

Conclusion:

- Cleanup list remains technically ready but still not approved.
- No file cleanup has been executed.

## Ownership Coverage Recheck - 2026-06-20 11:30 -0300

Scope:

- Classified the current dirty worktree by ownership front.
- No file was deleted, moved, reverted, stashed, staged, committed, pushed, or
  overwritten.

Evidence:

- `git diff --name-only`: `72` tracked modified files.
- `git ls-files --others --exclude-standard`: `79` individual untracked files.
- Tracked coverage:
  `app_deck=17`, `backend_deck_routes_helpers=13`,
  `backend_ai_import_simulate_planners=31`, `api_contract_docs_tests=3`,
  `docs_artifacts_control=8`.
- Untracked coverage:
  `docs_artifacts_control=51`, `backend_deck_routes_helpers=20`,
  `backend_ai_import_simulate_planners=8`.

Conclusion:

- All dirty files are now assigned to an ownership front.
- `server/test/canonicalize_learned_deck_metadata_cli_test.dart` belongs with
  backend learned-deck/planner CLI tests.
- This does not reduce the dirty worktree by itself; cleanup remains blocked
  pending exact approval and commit/push remain unauthorized.

## Backend Anti-Fanout And PG Queue Recheck - 2026-06-20 11:35 -0300

Scope:

- Rechecked dirty backend SQL/data access against the ManaLoom semantic-layer
  rule: product deck loaders must not join `deck_cards` directly to multi-row
  intelligence tables without aggregation.
- Rechecked the PostgreSQL deploy queue in read-only/dry-run mode.
- No code edit, PostgreSQL write, deck swap, cleanup, deletion, stash, revert,
  stage, commit, or push was performed.

Backend anti-fanout evidence:

- Scanned `40` dirty backend files under `server/lib`, `server/routes`, and
  `server/bin`.
- Multi-row source references in dirty backend files:
  - `card_function_tags`: `7` files;
  - `card_semantic_tags_v2`: `6` files;
  - `card_battle_rules`: `0` files;
  - `card_intelligence_snapshot`: `6` files;
  - `deck_cards`: `16` files.
- Direct join pattern scan found exactly one multi-row table join:
  `server/lib/ai/commander_learned_deck_support.dart:377`
  `LEFT JOIN card_function_tags cft`.
- That join is not a `deck_cards` join and is guarded by
  `ARRAY_AGG(DISTINCT LOWER(cft.tag))` plus `GROUP BY`; the scanner context
  reported `has_array_agg=true`, `has_group_by=true`,
  `has_deck_cards_near=false`.
- Dirty deck-facing loaders use `card_intelligence_snapshot` when present, or
  fallback through per-card `jsonb_agg(...)` / `EXISTS` subqueries for
  `card_function_tags` and `card_semantic_tags_v2`.

PostgreSQL/read-only evidence:

- Migrations: `29/29` executed, `0` pending.
- PG-001 planner: `planned_row_count=0`, `db_mutations=false`.
- PG-002 postcheck: `after_matches=59`, `still_before_rows=0`,
  `all_post_apply_checks_ok=true`.
- PG-003 oracle planner: `backfill_ready=0`, `db_mutations=false`.
- PG-005 Lorehold dry-run: `applied_counts=0`, `db_mutations=false`.
- PG-006 postcheck: migration `029` present, constraint present,
  `remaining_needs_review_not_review_only=0`.
- PG-007 postcheck: `pg007_target_rule_count=1`.
- Battle runtime manifest: `total_files=110`, `unclassified_files=[]`.

Conclusion:

- No unsafe dirty backend `deck_cards -> multi-row intelligence table` fanout
  was found in this scan.
- No new PostgreSQL apply is ready.

## Current Risks

- Worktree is broad: app, server, docs, SQL artifacts, and generated audit
  files are mixed in one checkout.
- Some tracked files were modified by other paused chats. Reverting or stashing
  globally would destroy live work.
- PostgreSQL state is ahead of the base Git tree because PG-001 was already
  applied and validated; now PG-002, PG-006, and PG-007 are also applied and
  validated.
- Latest battle audit is ahead of the older `090636` docs, the historical
  `20260620_121005` trusted run, the pre-PG-007 `20260620_125745` blocker, and
  the PG-007 closure run `20260620_132812`: `latest` now points to
  `20260620_140016` and is `trusted_for_strategy_learning`.
- The PG-006 execution-status source-scope issue is closed for local runtime:
  PostgreSQL remains canonical, and Hermes SQLite now reflects
  `review_only` names after the `20260620_120904` sync.

## Next Triage Step

Validate and operate changed source slices in this order:

1. keep this thread as the only active operator while Rafael keeps the other
   chats paused; do not generate continuation commands for other chats by
   default.
2. cleanup proposal with exact file list only; no deletion is authorized by
   this register.
3. no additional PostgreSQL apply is ready at the current heartbeat.
4. before any commit discussion, review the broad dirty source diff by
   ownership area; aggregate tests passed, but local tests do not prove live
   backend deploy, live OpenAI behavior, or real-device Flutter behavior.

## Single-Operator Update - 2026-06-20 11:39 -0300

Rafael clarified that the current expectation is not to coordinate other chats:
this Auditor Central thread should do deploy, PostgreSQL governance,
validation, and worktree organization directly until further notice.

Evidence register added:

- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
  records completion criteria, current PostgreSQL position, current worktree
  position, and remaining non-completion boundaries.

## Public Backend Deploy Audit - 2026-06-20 11:44 -0300

Scope:

- Checked whether the current committed backend is live in production.
- Separated production deploy state from dirty local source state.
- No stage, commit, push, code deploy, PostgreSQL write, deck swap, cleanup,
  deletion, stash, or revert was performed.

Evidence:

- `git fetch --all --prune` updated only `origin/codex/hermes-analysis-docs`;
  `origin/master` stayed unchanged.
- `git rev-list --left-right --count HEAD...origin/master`: `0 0`.
- Local `HEAD`: `3908e88caa9c1bb43207e8a2334b0214e150fa10`.
- `origin/master`: `3908e88caa9c1bb43207e8a2334b0214e150fa10`.
- Production `/health` returned healthy service `mtgia-server`,
  `environment=production`, and
  `git_sha=3908e88caa9c1bb43207e8a2334b0214e150fa10`.
- Dirty source count under product code:
  `64` app/server tracked files, split as `17` under `app/` and `47` under
  `server/`.

Conclusion:

- Production backend is current with committed `master`.
- The local app/server changes are validated locally in prior checkpoints but
  are not published because they are uncommitted.
- Code publication is now an explicit remaining gap, separate from PostgreSQL
  deploy state.

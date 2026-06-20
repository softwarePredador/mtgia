# ManaLoom Worktree File Ownership Index - 2026-06-20

Owner: Auditor Central / single operator
Status: active file-level inventory
Last audited: 2026-06-20 13:12 -0300

## Scope

This index maps the current dirty worktree to operational fronts. It is not a
cleanup execution plan, commit plan, or approval artifact.

This index records the authorized cleanup already executed by the Auditor
Central. It is not a separate deletion, revert, stash, commit, push, or staging
approval artifact.

## Current Snapshot

Evidence commands:

- `git status --short --branch`
- `git diff --shortstat`
- `git diff --name-only | sort`
- `git ls-files --others --exclude-standard | sort`

Observed state:

- Branch: `master...origin/master`
- Tracked modified files: `73`
- Untracked files after authorized cleanup:
  `75` individual files from `git ls-files --others --exclude-standard`
- Tracked diff size at the 13:12 evidence checkpoint:
  `73 files changed, 24752 insertions(+), 2022 deletions(-)`
- Tracked prefix split before this index update:
  `.gitignore=1`, `app=17`, `docs=8`, `server=47`
- Untracked prefix split from `git ls-files --others --exclude-standard`:
  `docs=47`, `server=28`
- PG-007 added SQL/package files plus runtime-sync and coverage evidence under
  `docs/hermes-analysis/master_optimizer_reports`, and one new SQLite backup
  under `docs/hermes-analysis/manaloom-knowledge/backups`.
- The current completion audit added one additional untracked control doc:
  `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`.
- The exact initial `8` cleanup candidates from
  `WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md` were deleted after Rafael's cleanup
  authorization.
- The additional duplicate pair
  `battle_effect_coverage_audit_20260620_132730.*` was deleted after duplicate
  hash and `cmp -s` proof against retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*`.
- PG-008 added `7` required untracked evidence files: `5` SQL/package files,
  `1` runtime sync report, and `1` SQLite backup.
- `.gitignore` now excludes
  `docs/hermes-analysis/manaloom-knowledge/backups/*.bak`, so the `3` SQLite
  backup files remain on disk but no longer appear in the untracked publication
  queue.
- The publication plan added one untracked control doc:
  `docs/hermes-analysis/MANALOOM_PUBLICATION_BATCH_PLAN_2026-06-20.md`.

## Operating Rules

- Do not commit or push without explicit Rafael approval.
- Do not delete, stash, revert, or overwrite files without an exact approved
  list.
- Do not apply deck swaps without explicit Rafael approval.
- PostgreSQL writes remain controlled by the Auditor Central and still require
  exact apply approval plus precheck/apply/postcheck/rollback evidence.
- Hermes SQLite/cache artifacts are lab/runtime evidence; PostgreSQL/backend is
  product source of truth.

## Validation Evidence Already Attached

- Current 12:16 PG-008 deploy and ownership recheck:
  - latest battle `20260620_150241` exposed one Machine God's Effigy
    `functional_tags_json` forensic blocker
  - PG-008 precheck: target card `1`, existing target rule `0`, existing any
    Machine God's Effigy rule `0`
  - PG-008 apply: `INSERT 0 1`, `COMMIT`
  - PG-008 postcheck: `pg008_target_rule_count=1`, snapshot exposes the new rule
  - PG-008 runtime sync: `pg_rows_loaded=5190`,
    `sqlite_inserted_or_updated=5108`, `canonical_snapshot_rows_exported=3161`
  - full battle rerun `20260620_151437`: `trusted_for_strategy_learning`,
    `mandatory_gate_divergences=[]`, forensic lineage complete, tests `16/16`
  - `git status --short --branch`: `master...origin/master`, `72 M`,
    broad untracked evidence
  - `git diff --shortstat`:
    `72 files changed, 24641 insertions(+), 2022 deletions(-)`
  - `git ls-files --others --exclude-standard | wc -l`: `77`
  - final `2026-06-20 12:26 -0300` checks: `git diff --check` clean,
    duplicate untracked hash scan `NO_DUPLICATE_UNTRACKED_HASHES`, migrations
    `29/29` executed with `0` pending, latest battle still
    `20260620_151437` trusted, and stale-current-doc scan found no active
    latest reference to `20260620_140016`
  - publication-batch validation `2026-06-20 12:58 -0300`: `flutter analyze`
    clean, `flutter test` `619/619`, server `dart analyze` clean, server
    `dart test` `634/634`, Python discover `96/96`, migrations `29/29`,
    PG-008 postcheck `pg008_target_rule_count=1`, runtime-surface manifest
    `PASS`, and fresh battle latest `20260620_155445` trusted
  - Batch 0/1 readiness reread `2026-06-20 13:12 -0300`: latest battle now
    points to `20260620_160459`, remains `trusted_for_strategy_learning`, has
    `mandatory_gate_divergences=[]`, complete forensic lineage, and tests
    `16/16` pass
  - tracked prefix split remains `app=17`, `docs=8`, `server=47`
  - untracked prefix split is now `docs=49`, `server=28`
  - current file-section ownership coverage:
    App Deck `17`, tracked docs/runtime evidence `8`, tracked backend
    source/tests `47`, untracked control registers `7`, untracked PostgreSQL
    deploy evidence `27`, untracked PG-006 battle/runtime evidence `5`,
    untracked learned-deck evidence retained `4`, untracked backend
    source/tests `28`, untracked PG-007 runtime/battle evidence `4`, and
    untracked PG-008 runtime evidence `2`
  - no deck swap, code deploy, stash, revert, stage, commit, or push was
    performed
- Current 12:00 duplicate cleanup and ownership recheck:
  - deleted additional duplicate pair
    `battle_effect_coverage_audit_20260620_132730.json` and
    `battle_effect_coverage_audit_20260620_132730.md`
  - retained PG-007 evidence
    `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*` still exists
  - duplicate hash scan over untracked files returned
    `NO_DUPLICATE_UNTRACKED_HASHES`
  - `git status --short --branch`: `master...origin/master`, `72 M`,
    `69 ??`
  - `git diff --shortstat`:
    `72 files changed, 24631 insertions(+), 2029 deletions(-)`
  - `git ls-files --others --exclude-standard | wc -l`: `70`
  - tracked prefix split remains `app=17`, `docs=8`, `server=47`
  - untracked prefix split is now `docs=42`, `server=28`
  - current file-section ownership coverage:
    App Deck `17`, tracked docs/runtime evidence `8`, tracked backend
    source/tests `47`, untracked control registers `7`, untracked PostgreSQL
    deploy evidence `22`, untracked PG-006 battle/runtime evidence `5`,
    untracked learned-deck evidence retained `4`, untracked backend
    source/tests `28`, and untracked PG-007 runtime/battle evidence `4`
  - no PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit,
    or push was performed
- Current 11:57 cleanup and ownership recheck:
  - the exact `8` cleanup candidates were deleted after hash/presence
    revalidation
  - retained evidence files `095253.*`, `115918.*`, and
    `120904_post_sqlite_sync.*` are still present
  - `git status --short --branch`: `master...origin/master`, `72 M`,
    `70 ??`
  - `git diff --shortstat`:
    `72 files changed, 24631 insertions(+), 2029 deletions(-)`
  - `git ls-files --others --exclude-standard | wc -l`: `72`
  - `git diff --check`: clean
  - tracked prefix split remains `app=17`, `docs=8`, `server=47`
  - untracked prefix split is now `docs=44`, `server=28`
  - current file-section ownership coverage:
    App Deck `17`, tracked docs/runtime evidence `8`, tracked backend
    source/tests `47`, untracked control registers `7`, untracked PostgreSQL
    deploy evidence `22`, untracked PG-006 battle/runtime evidence `5`,
    untracked learned-deck evidence retained `4`, untracked backend
    source/tests `28`, and untracked PG-007 runtime/battle evidence `6`
  - no PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit,
    or push was performed
- Current 11:46 ownership coverage recheck:
  - `git status --short --branch`: `master...origin/master`, `72 M`,
    `78 ??`
  - `git diff --shortstat`:
    `72 files changed, 24631 insertions(+), 2029 deletions(-)`
  - `git ls-files --others --exclude-standard | wc -l`: `80`
  - `git diff --check`: clean
  - tracked prefix split remains `app=17`, `docs=8`, `server=47`
  - untracked prefix split is now `docs=52`, `server=28`
  - current file-section ownership coverage:
    App Deck `17`, tracked docs/runtime evidence `8`, tracked backend
    source/tests `47`, untracked control registers `7`, untracked PostgreSQL
    deploy evidence `22`, untracked PG-006 battle/runtime evidence `5`,
    untracked learned-deck evidence retained `4`, untracked cleanup proposal
    candidates `8`, untracked backend source/tests `28`, and untracked PG-007
    runtime/battle evidence `6`
  - no file was deleted, moved, reverted, stashed, committed, pushed, staged,
    deployed, or mutated in PostgreSQL
- Current 11:35 backend anti-fanout and PG queue recheck:
  - dirty backend scan covered `40` files under `server/lib`,
    `server/routes`, and `server/bin`
  - dirty backend references:
    `card_function_tags=7`, `card_semantic_tags_v2=6`,
    `card_battle_rules=0`, `card_intelligence_snapshot=6`,
    `deck_cards=16`
  - direct join pattern scan found exactly one multi-row join:
    `server/lib/ai/commander_learned_deck_support.dart:377`
    `LEFT JOIN card_function_tags cft`
  - the join context is aggregated and not deck-row fanout:
    `has_array_agg=true`, `has_group_by=true`,
    `has_deck_cards_near=false`
  - deck-facing dirty loaders use `card_intelligence_snapshot` when present or
    per-card `jsonb_agg(...)` / `EXISTS` fallbacks
  - PostgreSQL queue: migrations `29/29`, PG-001 `planned_row_count=0`,
    PG-002 `all_post_apply_checks_ok=true`, PG-003 `backfill_ready=0`,
    PG-005 `applied_counts=0`, PG-006
    `remaining_needs_review_not_review_only=0`, PG-007
    `pg007_target_rule_count=1`
  - no PostgreSQL write, deck swap, cleanup, stage, commit, push, revert, or
    stash was performed
- Current 11:30 ownership coverage recheck:
  - `git diff --name-only`: `72` tracked modified files
  - `git ls-files --others --exclude-standard`: `79` individual untracked
    files
  - tracked dirty-file coverage:
    `app_deck=17`, `backend_deck_routes_helpers=13`,
    `backend_ai_import_simulate_planners=31`, `api_contract_docs_tests=3`,
    `docs_artifacts_control=8`
  - untracked dirty-file coverage:
    `docs_artifacts_control=51`, `backend_deck_routes_helpers=20`,
    `backend_ai_import_simulate_planners=8`
  - no dirty file is outside the ownership fronts after classifying
    `server/test/canonicalize_learned_deck_metadata_cli_test.dart` with the
    backend learned-deck/planner CLI tests
  - no file was deleted, moved, reverted, stashed, committed, pushed, or staged
- Current 11:19 battle/PG/worktree heartbeat:
  - `git status --short --branch`: `master...origin/master`, `72 M`,
    `78 ??`
  - `git diff --shortstat`:
    `72 files changed, 24491 insertions(+), 2029 deletions(-)`
  - `git diff --check`: clean
  - latest battle at that time: `20260620_140016`, `trusted_for_strategy_learning`,
    `mandatory_gate_divergences=[]`, forensic lineage complete,
    `forensic_rule_findings=0`, `forensic_turn_findings=0`, and `16/16`
    tests pass
  - runtime surface manifest: `110` related Python files,
    `unclassified_files=[]`
  - migration status: `29/29` executed, `0` pending
  - PG-001 planner: `planned_row_count=0`, `db_mutations=false`
  - PG-002 postcheck: `after_matches=59`, `still_before_rows=0`,
    `all_post_apply_checks_ok=true`
  - PG-003 oracle planner: `backfill_ready=0`, `db_mutations=false`
  - PG-005 Lorehold dry-run: `applied_counts=0`, `db_mutations=false`
  - PG-006 postcheck: migration `029` present, constraint present,
    `remaining_needs_review_not_review_only=0`
  - PG-007 postcheck: `pg007_target_rule_count=1`
  - no PostgreSQL write, deck swap, cleanup, stage, commit, push, revert, or
    stash was performed
- Current 11:12 Backend AI/import/simulate ownership audit:
  - tracked slice:
    `33 files changed, 1987 insertions(+), 500 deletions(-)`
  - related untracked PostgreSQL planner scripts/tests total `1443` lines by
    `wc -l`
  - focused AI/import/simulate Dart tests: `83/83` passed
  - focused Python planner/auditor tests: `39/39` passed
  - focused backend Dart analyze: `No issues found!`
  - no PostgreSQL write, deck swap, cleanup, stage, commit, push, revert, or
    stash was performed
- Current 11:09 Backend Deck routes/helpers ownership audit:
  - tracked route refactor:
    `9 files changed, 274 insertions(+), 798 deletions(-)`
  - new helper/test slice totals `3379` lines by `wc -l`
  - auditor patch made the OpenAI recommendations prompt include
    backend-computed `candidate_color_identity`
  - focused recommendations tests: `16/16` passed
  - focused bulk/import/validation/name-resolution tests: `33/33` passed
  - focused backend Dart analyze: `No issues found!`
  - no PostgreSQL write, deck swap, cleanup, stage, commit, push, revert, or
    stash was performed
- Current 11:05 App Deck provider/UI ownership audit:
  - App Deck tracked diff for the slice:
    `17 files changed, 1264 insertions(+), 90 deletions(-)`
  - auditor patch normalized create-deck `archetype` once and reused the same
    value for backend request plus optimistic local cache
  - focused provider/support tests: `65/65` passed
  - focused widget/screen tests: `40/40` passed
  - no PostgreSQL write, deck swap, cleanup, stage, commit, push, revert, or
    stash was performed
- Current 10:50 single-operator heartbeat:
  - `git status --short --branch`: `master...origin/master`, `72 M`,
    `78 ??`
  - `git ls-files --others --exclude-standard | wc -l`: `79`
  - `git diff --shortstat`:
    `72 files changed, 24397 insertions(+), 2028 deletions(-)`
  - `git diff --check`: clean
  - latest battle: `20260620_132812`, `trusted_for_strategy_learning`,
    `mandatory_gate_divergences=[]`, forensic lineage complete, `16/16`
    tests pass
  - migration status: `29/29` executed, `0` pending
  - PG-007 postcheck: `pg007_target_rule_count=1`, Leyline rule present in
    `card_intelligence_snapshot.battle_rules`
  - PostgreSQL queue: PG-001 `planned_row_count=0`, PG-002 postcheck
    `all_post_apply_checks_ok=true`, PG-003 `backfill_ready=0`, PG-005
    `applied_counts=0`
  - app aggregate: `flutter analyze` no issues and `flutter test` `105/105`
  - backend Dart aggregate: `dart analyze` no issues and `dart test`
    `146/146`
  - backend Python aggregate: `py_compile` plus focused unittests `39/39`
- Current 10:09 source-patch validation heartbeat:
  - recommendations advisory guard: focused `dart analyze` no issues and
    `dart test` `16/16` passed
  - app deck slice: focused `flutter analyze` no issues and `flutter test`
    `105/105` passed
  - backend deck/API slice: focused `dart test` `143/143` passed
  - battle focused evidence: targeted unittest passed with
    `evaluated_count=14` and `evidence_count=14`
  - ops-daemon env isolation: targeted unittest passed
  - full backend Python discover: `96/96` passed
  - `git diff --check`: clean
  - after this index/API-contract update: `git diff --check` clean,
    API contract guard `6/6` passed, final tracked diff size
    `72 files changed, 24134 insertions(+), 2026 deletions(-)`
- Current 09:51 revalidation heartbeat:
  - `git diff --check`: clean
  - added-line risk scan: no new `TODO`, `FIXME`, `debugPrint`, `print`,
    `console.log`, or skipped-test marker in app/server diff
  - app aggregate `flutter analyze`: no issues
  - app focused `flutter test`: `105/105` passed
  - backend aggregate `dart analyze`: no issues
  - backend focused `dart test`: historical `145/145` passed; superseded by
    the 10:50 `146/146` aggregate
  - backend changed Python `unittest`: historical `31` passed; superseded by
    the 10:50 `39/39` aggregate
  - PostgreSQL read-only queue: migrations `29/29`, PG-001/PG-002/PG-006
    closed, PG-003 not ready, PG-005 no-apply-needed
  - latest battle at that time: `20260620_121005`,
    `trusted_for_strategy_learning`, `16/16` tests pass; current latest is now
    `20260620_151437`, `trusted_for_strategy_learning`
- App changed/untracked Dart slice:
  - aggregate `flutter analyze`: no issues
  - aggregate `flutter test`: `105/105` passed
- Backend changed/untracked Dart slice:
  - aggregate `dart analyze`: no issues
  - aggregate changed backend Dart tests: `146/146` passed
- Backend changed Python slice:
  - aggregate `python3 -m unittest ...`: `39` tests passed
- Backend data-contract anti-fanout slice:
  - source inspection found deck loaders on `card_intelligence_snapshot` or
    per-card `jsonb_agg(...)` / `EXISTS`
  - focused Dart guards: `19/19` and `24/24` passed
  - focused Python planner guards: `7/7` passed
- PostgreSQL/latest heartbeat at that time:
  - migrations: `29/29` executed, `0` pending
  - latest battle: `20260620_121005`, `trusted_for_strategy_learning`,
    `16/16` tests pass. Superseded by current latest `20260620_160459`,
    `trusted_for_strategy_learning`.

## Tracked Modified Files - App Deck Front

Ownership: App Deck provider/UI.
State: patched and validated locally by focused App Deck tests plus earlier
aggregate app analyze/tests.
Action: preserve; no cleanup.

```text
app/lib/features/decks/providers/deck_provider.dart
app/lib/features/decks/providers/deck_provider_support_common.dart
app/lib/features/decks/providers/deck_provider_support_fetch.dart
app/lib/features/decks/providers/deck_provider_support_mutation.dart
app/lib/features/decks/screens/deck_details_screen.dart
app/lib/features/decks/screens/deck_generate_screen.dart
app/lib/features/decks/widgets/deck_details_overview_tab.dart
app/lib/features/decks/widgets/deck_diagnostic_panel.dart
app/lib/features/decks/widgets/deck_import_list_dialog.dart
app/lib/features/decks/widgets/deck_optimize_flow_support.dart
app/test/features/decks/providers/deck_provider_support_test.dart
app/test/features/decks/providers/deck_provider_test.dart
app/test/features/decks/screens/deck_flow_entry_screens_test.dart
app/test/features/decks/widgets/deck_analysis_tab_test.dart
app/test/features/decks/widgets/deck_diagnostic_panel_test.dart
app/test/features/decks/widgets/deck_import_list_dialog_test.dart
app/test/features/decks/widgets/deck_optimize_flow_support_test.dart
```

## Tracked Modified Files - Battle/Deck Documentation And Runtime Evidence

Ownership: Auditor Central, battle validation, Lorehold/deck strategy evidence.
State: reconciled to current battle `20260620_151437`; PG-007 closure evidence
remains `20260620_132812`, and PG-008 closure evidence is `20260620_151437`.
Action: preserve; no cleanup.

```text
docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md
docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md
docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md
docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md
docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py
docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json
docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py
docs/hermes-analysis/master_optimizer_reports/deck_builder_lorehold_flow_learning_log_20260619.md
```

## Tracked Modified Files - Backend Source And Tests

Ownership: Backend deck/AI/import/simulate fronts.
State: validated locally by aggregate backend analyze/tests and focused guards.
Action: preserve; no cleanup.

```text
server/bin/card_impact_analyzer.py
server/bin/learned_deck_coherence_audit.py
server/bin/manaloom_battle_rule_focused_evidence.py
server/doc/API_CONTRACTS_AND_DATA_MAP.md
server/doc/COMMANDER_LEARNING_API_2026-06-03.md
server/lib/ai/commander_learned_deck_support.dart
server/lib/ai/commander_reference_helpers.dart
server/lib/ai/optimize_cache_support.dart
server/lib/ai/optimize_request_support.dart
server/lib/ai/optimize_route_color_identity_filter_support.dart
server/lib/ai/optimize_route_warnings_support.dart
server/lib/deck_rules_service.dart
server/lib/generated_deck_validation_service.dart
server/lib/import_card_lookup_service.dart
server/routes/ai/commander-learning/index.dart
server/routes/ai/generate/index.dart
server/routes/ai/optimize/index.dart
server/routes/ai/simulate-matchup/index.dart
server/routes/ai/simulate/index.dart
server/routes/ai/weakness-analysis/index.dart
server/routes/cards/resolve/batch/index.dart
server/routes/decks/[id]/ai-analysis/index.dart
server/routes/decks/[id]/cards/bulk/index.dart
server/routes/decks/[id]/index.dart
server/routes/decks/[id]/recommendations/index.dart
server/routes/decks/[id]/simulate/index.dart
server/routes/decks/[id]/validate/index.dart
server/routes/decks/index.dart
server/routes/import/to-deck/index.dart
server/routes/import/validate/index.dart
server/test/ai_generate_learning_boundary_test.dart
server/test/api_contracts_data_map_guard_test.dart
server/test/card_impact_analyzer_test.py
server/test/card_resolution_support_test.dart
server/test/cards_route_test.dart
server/test/commander_learned_deck_support_test.dart
server/test/deck_rules_service_test.dart
server/test/experimental_deck_ai_authorization_source_test.dart
server/test/generated_deck_validation_service_test.dart
server/test/import_list_service_test.dart
server/test/import_parser_test.dart
server/test/learned_deck_coherence_audit_test.py
server/test/manaloom_ops_daemon_test.py
server/test/optimize_cache_support_test.dart
server/test/optimize_route_color_identity_filter_support_test.dart
server/test/optimize_route_warnings_support_test.dart
server/test/unsupported_deck_sections_route_contract_test.dart
```

## Untracked Files - Control Registers

Ownership: Auditor Central control state.
State: active evidence/control docs.
Action: preserve; no cleanup.

```text
docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md
docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_ORDERS.md
docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md
docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md
docs/hermes-analysis/WORKTREE_OPERATIONAL_MAP_2026-06-20.md
docs/hermes-analysis/WORKTREE_TRIAGE_REGISTER_2026-06-20.md
docs/hermes-analysis/WORKTREE_FILE_OWNERSHIP_INDEX_2026-06-20.md
```

Note: this index and the completion audit are included in the current `70`
individual untracked-file count.

## Untracked Files - PostgreSQL Deploy Evidence

Ownership: PostgreSQL deploy register.
State: evidence for PG-001, PG-002, and PG-006.
Action: preserve; no cleanup.

```text
docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql
docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md
docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql
docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql
docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql
docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql
docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_package_20260620_1018.md
docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql
docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql
docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql
docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_apply_20260620_1210.sql
docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_package_20260620_1210.md
docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_postcheck_20260620_1210.sql
docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_precheck_20260620_1210.sql
docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_rollback_20260620_1210.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json
docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md
docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_apply_20260620_063349.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_postcheck_20260620_063349.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_precheck_20260620_063349.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_rollback_20260620_063349.sql
docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_005219.json
docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_095139_post_pg001_audit_fix.json
```

## Untracked Files - Current Battle/Hermes Evidence

Ownership: battle validation and PG-006 runtime sync.
State: current retained evidence.
Action: preserve; no cleanup.

```text
docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg006-runtime-sync.20260620_120904.bak
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md
docs/hermes-analysis/master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md
docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json
```

## Untracked Files - Learned-Deck Coherence Evidence To Retain

Ownership: deck/learned-deck audit.
State: retained comparison/current evidence.
Action: preserve; no cleanup.

```text
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.json
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.md
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.md
```

## Deleted Files - Cleanup Executed

Ownership: Auditor Central cleanup proposal.
State: initial `8` files deleted at `2026-06-20 11:57 -0300`; additional
duplicate `132730.*` pair deleted at `2026-06-20 12:00 -0300`.
Action: no longer present in worktree.

```text
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.json
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.md
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_132730.json
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_132730.md
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.json
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.md
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.json
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.md
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.json
docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.md
```

## Untracked Files - Backend Source And Tests

Ownership: backend deck route/helper and planner work.
State: patched and validated locally by focused backend route/helper tests plus
earlier aggregate backend analyze/tests.
Action: preserve; no cleanup.

```text
server/bin/canonicalize_learned_deck_metadata.dart
server/bin/plan_learned_deck_partner_identity_backfill.py
server/bin/plan_lorehold_critical_role_backfill.py
server/bin/plan_oracle_text_backfill.py
server/lib/deck_card_name_resolution_support.dart
server/lib/deck_cards_bulk_support.dart
server/lib/deck_recommendations_advisory_support.dart
server/lib/deck_recommendations_fallback_support.dart
server/lib/deck_recommendations_power_level_support.dart
server/lib/deck_recommendations_route_support.dart
server/lib/deck_validation_route_support.dart
server/lib/import_to_deck_merge_support.dart
server/test/canonicalize_learned_deck_metadata_cli_test.dart
server/test/deck_cards_bulk_support_test.dart
server/test/deck_fetch_hydration_contract_test.dart
server/test/deck_manual_mutation_route_contract_test.dart
server/test/deck_pricing_export_community_contract_test.dart
server/test/deck_recommendations_advisory_support_test.dart
server/test/deck_recommendations_fallback_support_test.dart
server/test/deck_recommendations_power_level_support_test.dart
server/test/deck_recommendations_route_adapter_test.dart
server/test/deck_recommendations_route_support_test.dart
server/test/deck_simulate_route_adapter_test.dart
server/test/deck_validation_route_support_test.dart
server/test/import_to_deck_merge_support_test.dart
server/test/plan_learned_deck_partner_identity_backfill_test.py
server/test/plan_lorehold_critical_role_backfill_test.py
server/test/plan_oracle_text_backfill_test.py
```

## Untracked Files - PG-007 Runtime Sync And Battle Evidence

Ownership: Auditor Central PostgreSQL deploy/runtime evidence.
State: PG-007 applied, postchecked, synced, and validated by latest battle.
Action: preserve; no cleanup.

```text
docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.json
docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md
docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg007-runtime-sync.20260620_102701.bak
```

## Untracked Files - PG-008 Runtime Sync Evidence

Ownership: Auditor Central PostgreSQL deploy/runtime evidence.
State: PG-008 applied, postchecked, synced, and validated by latest battle
`20260620_151437`.
Action: preserve; no cleanup.

```text
docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg008-runtime-sync.20260620_1210.bak
docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json
```

## Current Decisions

- No current PostgreSQL apply is ready. PG-007 is applied, postchecked,
  runtime-synced, validated by battle `20260620_132812`; PG-008 is applied,
  postchecked, runtime-synced, and validated by latest battle `20260620_151437`.
- PG-001, PG-002, PG-006, PG-007, and PG-008 are closed unless future
  SELECT/artifact evidence proves rollback or drift.
- PG-003 remains policy-blocked.
- PG-004/Leyline historical closure and the `20260620_125745` blocker are both
  superseded by PG-007; the `20260620_150241` Machine God's Effigy blocker is
  superseded by PG-008 plus latest battle `20260620_151437`.
- Cleanup proposal executed: the exact initial `8`-file list plus the additional
  duplicate `132730.*` pair were deleted after approval and post-clean validation
  passed.
- Commit/push remain unauthorized.

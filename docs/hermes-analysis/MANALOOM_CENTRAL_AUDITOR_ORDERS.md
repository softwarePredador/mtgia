# ManaLoom Central Auditor Orders

Last updated: 2026-06-20 11:42 -0300
Owner: Auditor Central / single operator
Status: active, single-operator mode

## Purpose

This is now the central operating file for this thread only.

Rafael paused the executor chats and explicitly changed the operating model:
the Auditor Central owns audit, worktree triage, PostgreSQL deploy governance,
validation, register reconciliation, and next-step execution until Rafael
changes this again.

Historical executor-chat command blocks are deprecated. Do not generate new
orders for other chats unless Rafael explicitly asks to resume that model.
Current operating model: do not prepare continuation commands for other chats;
this thread owns the work until Rafael changes the model again.

## Mandatory Rules

1. Start each cycle with current repo state, not stale notes:
   - `git status --short --branch`
   - current required docs and artifacts
2. Do not commit or push without explicit Rafael approval.
3. Do not apply deck swaps without explicit Rafael approval.
4. PostgreSQL writes are owned by this Auditor Central thread now, but still
   require explicit Rafael approval for the exact apply command.
5. Every database write still needs:
   - source artifact or code evidence
   - exact table and column scope
   - exact affected rows
   - SELECT pre-apply
   - SQL/apply command
   - rollback SQL
   - non-destructive tests or dry-runs
   - post-apply SELECT
   - register update with evidence
6. Do not delete, revert, stash, or overwrite worktree files without an exact
   cleanup list and explicit approval.
7. Every conclusion needs evidence from code, tests, artifacts, `summary.json`,
   registers, SQL output, or updated docs.
8. If something is inferred, mark it as inference.

## Always Read

- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `docs/hermes-analysis/PROJECT_MEMORY.md`
- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
- `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

## Current Operator Queue

1. Maintain single-operator control. This thread performs audit, worktree
   triage, PostgreSQL deploy governance, validation, register reconciliation,
   and next-step execution while Rafael keeps the other chats paused.
2. Keep PG-001 closed unless a future SELECT proves rollback or data drift.
3. PG-002 global learned-deck metadata canonicalization was applied and
   validated. Do not reapply unless a future SELECT proves rollback or drift.
4. Keep PG-003 oracle/card text/type backlog blocked until the policy for
   official blank oracle text, Arena/Alchemy identities, aliases, and reprints
   is explicit.
5. PG-006 `card_battle_rules.execution_status` migration drift was applied and
   validated. Migration `029` is now recorded, the constraint is present, and
   generated/needs_review PostgreSQL rows are `review_only`.
6. Latest battle is trusted: `latest/summary.json` now resolves to
   `20260620_140016` and reports `trusted_for_strategy_learning`. The
   `20260620_132812` run remains the PG-007 closure evidence.
7. PG-007 was applied, postchecked, synced into the Hermes runtime cache, and
   validated by a fresh full recurring battle rerun. Do not reapply unless a
   future SELECT/artifact proves rollback or drift.
8. Convert dirty worktree into an auditable inventory before any cleanup.
   Current cleanup proposal is audited but not approved or executed.
9. Use
   `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
   as the active completion/gap register for this single-operator cycle.

## Current Operating Decision - 2026-06-20 11:39 -0300

Rafael clarified that this thread should stop generating commands for other
chats and should do the work directly: deploy, database governance, validation,
and worktree organization. That clarification is now adopted as the current
operating model.

Operational consequences:

- no new executor-chat command blocks by default;
- no waiting for another chat to run PostgreSQL, tests, or worktree triage;
- this does not authorize unsafe writes without evidence: PostgreSQL still
  requires precheck/apply/postcheck/rollback, deck swaps still require explicit
  approval, and destructive file operations still require an exact safe list.
- current evidence still shows no PostgreSQL apply ready at this heartbeat.

## Single-Operator Verification - 2026-06-20 11:42 -0300

After adopting Rafael's clarification, this thread ran a non-destructive
checkpoint:

- `git diff --check` clean;
- repo still on `master...origin/master`;
- tracked shortstat remains `72 files changed, 24631 insertions(+), 2029 deletions(-)`;
- individual untracked files are now `80` because the completion audit register
  was added;
- PostgreSQL migrations remain `29/29` executed and `0` pending;
- latest battle remains `trusted_for_strategy_learning` at
  `20260620_140016`, with mandatory divergences empty, forensic lineage
  complete, and tests `16/16` pass;
- runtime surface manifest test passed;
- PG-001 planner still plans `0` rows, PG-003 still has `backfill_ready=0`,
  and PG-005 still has `applied_counts=0`.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage, commit,
or push was performed in this verification.

## Current Evidence Snapshot

Repo state observed at 2026-06-20 11:19 -0300 before this register update:

- branch: `master...origin/master`
- tracked modified files: `72`
- untracked status entries: `78 ??`
- individual untracked files: `79`
- tracked diff size: `72 files changed, 24491 insertions(+), 2029 deletions(-)`
- tracked split by prefix:
  - `app`: `17` files
  - `server`: `47` files
  - `docs`: `8` files

Validation run by Auditor Central in this cycle:

- current battle/PG/worktree heartbeat at `2026-06-20 11:19 -0300`:
  - confirmed current repo evidence still shows `72 M`, `78 ??`, `79`
    individual untracked files, and `git diff --check` clean;
  - latest battle resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_140016/summary.json`,
    with `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
    forensic lineage complete, `forensic_rule_findings=0`,
    `forensic_turn_findings=0`, and tests `16/16` pass;
  - runtime surface manifest check passed with `110` related Python files and
    `unclassified_files=[]`;
  - PostgreSQL migration status remains `29/29` executed and `0` pending;
  - PG-001 planner returned `planned_row_count=0`, PG-002 postcheck returned
    `all_post_apply_checks_ok=true`, PG-003 oracle planner returned
    `backfill_ready=0`, PG-005 dry-run returned `applied_counts=0`, PG-006
    postcheck returned `remaining_needs_review_not_review_only=0`, and PG-007
    postcheck returned `pg007_target_rule_count=1`;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed in this heartbeat;
- cleanup proposal revalidation at `2026-06-20 11:26 -0300`:
  - all exact `8` cleanup candidates still exist;
  - hashes still match the proposal;
  - `battle_effect_coverage_audit_20260620_120952.json/.md` remain
    byte-identical to retained `120904_post_sqlite_sync` counterparts;
  - learned-deck candidates `031157`, `033941`, and `034324` remain
    superseded snapshots, while `095253` is retained as pre-PG-002 comparison
    evidence and `115918` is retained as post-PG-002 current evidence;
  - no cleanup, deletion, stash, revert, stage, commit, or push was performed;
- backend anti-fanout / PostgreSQL heartbeat at `2026-06-20 11:35 -0300`:
  - dirty backend scan covered `40` files under `server/lib`, `server/routes`,
    and `server/bin`;
  - direct join pattern scan found exactly one multi-row table join,
    `server/lib/ai/commander_learned_deck_support.dart:377`
    `LEFT JOIN card_function_tags cft`, and it is aggregated with
    `ARRAY_AGG(DISTINCT ...)` plus `GROUP BY` without `deck_cards` in context;
  - dirty deck-facing loaders use `card_intelligence_snapshot` when present or
    per-card `jsonb_agg(...)` / `EXISTS` fallbacks;
  - PostgreSQL read-only queue still has migrations `29/29`, PG-001
    `planned_row_count=0`, PG-002 `all_post_apply_checks_ok=true`, PG-003
    `backfill_ready=0`, PG-005 `applied_counts=0`, PG-006
    `remaining_needs_review_not_review_only=0`, and PG-007
    `pg007_target_rule_count=1`;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed;
- current docs-consistency heartbeat at `2026-06-20 10:57 -0300`:
  - re-read the required operating docs, the deploy register, and latest
    battle summary;
  - confirmed current repo evidence still shows `72 M`, `78 ??`, `79`
    individual untracked files, `git diff --check` clean, and latest battle
    `20260620_132812` trusted with `16/16` tests pass;
  - relabeled the older deploy-register PG-004 / `20260620_121005` section as
    historical and superseded by PG-007, so it cannot be mistaken for current
    Leyline deploy state;
  - appended current heartbeat notes to the Battle and Lorehold registers;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed in this heartbeat;
- current single-operator heartbeat at `2026-06-20 10:50 -0300`:
  - `git diff --check` returned no output;
  - latest battle resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`,
    with `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
    forensic lineage complete, and tests `16/16` pass;
  - `cd server && dart run bin/migrate.dart --status` reports `29/29`
    migrations executed and `0` pending;
  - PG-007 postcheck read-only returned `pg007_target_rule_count=1`, Leyline
    present in `card_intelligence_snapshot.battle_rules`, and backup rows `0`;
  - PostgreSQL queue planners/postchecks returned PG-001
    `planned_row_count=0`, PG-002 `all_post_apply_checks_ok=true`, PG-003
    `backfill_ready=0`, and PG-005 `applied_counts=0`;
  - app aggregate validation returned `flutter analyze` no issues and
    `flutter test` `105/105`;
  - backend Dart aggregate validation returned `dart analyze` no issues and
    `dart test` `146/146`;
  - backend Python aggregate validation returned `py_compile` plus focused
    unittests `39/39`;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed in this heartbeat;
- source-patch validation at `2026-06-20 10:09 -0300`:
  - `server/lib/deck_recommendations_advisory_support.dart` now restores
    backend-owned fallback context after merging parsed OpenAI text, so model
    output cannot override `power_level`, `statistics`, `colors`,
    `candidate_color_identity`, `color_identity_source`, `trending`, or
    `message` when those fields came from backend fallback context;
  - `server/test/deck_recommendations_advisory_support_test.dart` adds a
    regression proving conflicting model text cannot replace authoritative
    fallback context;
  - `server/bin/manaloom_battle_rule_focused_evidence.py` now passes the
    original spell effect data when validating extra-combat flashback evidence,
    preventing the focused harness from reclassifying `Seize the Day` away
    from the expected `extra_combat` contract;
  - `server/test/manaloom_ops_daemon_test.py` now isolates `DB_HOST` and
    `DB_NAME` leakage while checking `.env` loading;
  - focused recommendations validation passed:
    `dart analyze` with no issues and `dart test` `16/16`;
  - focused app deck validation passed:
    `flutter analyze` with no issues and `flutter test` `105/105`;
  - focused backend deck/API validation passed:
    `dart test` `143/143`;
  - focused Python validation passed:
    targeted focused evidence test with `evaluated_count=14` and
    `evidence_count=14`, targeted ops-daemon env test, `py_compile`, and full
    `python3 -m unittest discover -s server/test -p '*_test.py' -v` with
    `96/96` passing;
  - `git diff --check` returned no output after the source/test patches;
  - after the register/API-contract updates, `git diff --check` still returned
    no output and
    `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
    passed `6/6`;
- post-register tracked diff size is
    `72 files changed, 24134 insertions(+), 2026 deletions(-)`.
- PG-007 deploy and battle closure at `2026-06-20 10:31 -0300`:
  - PG-007 PostgreSQL apply inserted one row into `card_battle_rules` for
    `Leyline of Abundance` with `source=curated`, `review_status=active`,
    `execution_status=auto`, and
    `logical_rule_key=battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941`;
  - PG-007 postcheck returned `pg007_target_rule_count=1`, and
    `card_intelligence_snapshot` now exposes the rule in `battle_rules`;
  - runtime cache sync report
    `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`
    returned `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107`, and
    `canonical_snapshot_rows_exported=3160`;
  - post-sync coverage shows `runtime_safe_rule_names=1703`,
    `active_or_review_rule_names=3160`, and
    `execution_status_counts={"auto":1703,"review_only":1457}`;
  - latest battle now resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`;
  - latest is `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
    `forensic_lineage_status=complete`, `forensic_rule_findings=0`,
    `forensic_turn_findings=0`, and tests `16/16` pass.
- latest/battle heartbeat at `2026-06-20 10:18 -0300` (historical, pre-PG-007):
  - `latest/summary.json` resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/summary.json`;
  - latest is `review_required`, reason
    `one_or_more_mandatory_gates_require_review`, divergence
    `forensic_audit=review_required`, `forensic_lineage_status=incomplete`,
    `forensic_rule_findings=1`, `forensic_turn_findings=0`, and tests
    `16/16` pass;
  - blocker is `Leyline of Abundance` from seed `63211258`, event
    `spell_cast`, source `functional_tags_json`, effect `ramp_permanent`;
  - PostgreSQL read-only precheck for PG-007 confirms target card exists,
    existing Leyline battle-rule rows are `0`, and snapshot has
    `battle_rules=[]`;
  - at this historical point, PG-007 was still in prepared/pre-apply state.
- single-operator heartbeat at `2026-06-20 09:51 -0300`:
  - `git diff --check` returned no output;
  - added-line risk scan found no new `TODO`, `FIXME`, `debugPrint`, `print`,
    `console.log`, or skipped-test marker in the current app/server diff;
  - `cd app && xargs flutter analyze ...` returned no issues over the current
    changed app Dart slice;
  - `cd server && xargs dart analyze ...` returned no issues over the current
    changed/untracked backend Dart slice;
  - `cd app && flutter test ...` returned `105/105` tests passed;
  - `cd server && dart test ... -r expanded` returned historical `145/145`
    tests passed; superseded by the 10:50 `146/146` aggregate;
  - `python3 -m unittest ...` over changed/untracked backend Python tests
    returned historical `31` tests passed; superseded by the 10:50 `39/39`
    aggregate;
  - a first Python invocation from `server/` failed because it used module names
    under a non-package `test` path; it was rerun by file path from the repo
    root and passed. This is a command-shape issue, not a code/test failure.
- PostgreSQL queue heartbeat at `2026-06-20 09:51 -0300`
  (historical; superseded by the `2026-06-20 10:31 -0300` PG-007 closure):
  - migrations remain `29/29` executed and `0` pending;
  - PG-001 planner remains `planned_row_count=0`;
  - PG-002 postcheck remains `all_post_apply_checks_ok=true`;
  - PG-003 oracle planner remains `backfill_ready=0`;
  - PG-005 Lorehold critical-role dry-run remains `applied_counts=0`;
  - PG-006 postcheck remains migration `029` present, constraint present,
    `auto=1751`, `review_only=3437`, and
    `remaining_needs_review_not_review_only=0`;
  - latest battle at that time was `20260620_121005`,
    `battle_replay_final_status=trusted_for_strategy_learning`, with `16/16`
    tests passing. Current latest is now `20260620_140016` and is
    `trusted_for_strategy_learning`; `20260620_132812` remains the PG-007
    closure run.

- `python3 -m unittest server/test/learned_deck_coherence_audit_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py`
  - result: `21` tests passed
- `set -a && source server/.env && set +a && python3 server/bin/plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`
  - result: `status=PASS`, `planned_row_count=0`, `db_mutations=false`
- pre-PG-002 compact learned-deck audit:
  `set -a && source server/.env && set +a && python3 server/bin/learned_deck_coherence_audit.py --stdout`
  - historical result before PG-002 apply: `active_learned_decks=60`,
    `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
    `all_core_metadata_zero=54`, `some_core_metadata_zero=4`,
    severity `high=167`, `medium=12`
- post-PG-002 full learned-deck artifact
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`
  - result: `active_learned_decks=60`, `metadata_total_lands_mismatch=0`,
    `metadata_zero_lands=0`, `all_core_metadata_zero=0`,
    `partner_identity_not_modeled=0`, residual `some_core_metadata_zero=5`,
    severity `high=2`, `medium=13`
- backend Deck route/support slice:
  - `dart analyze` over focused bridge-resolution, bulk-cards,
    import-to-deck, validation, and recommendations files returned no issues;
  - focused `dart test` returned `52/52` tests passed.
- Flutter Deck provider/UI slice:
  - focused `flutter analyze` returned no issues;
  - focused `flutter test` returned `105/105` tests passed.
- PG-006 runtime cache sync:
  - backup:
    `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg006-runtime-sync.20260620_120904.bak`;
  - sync report:
    `battle_runtime_execution_status_sqlite_refresh_20260620_120904.json`
    with `apply_pg=false`, `apply_sqlite_from_pg=true`,
    `pg_rows_loaded=5188`, `sqlite_inserted_or_updated=5106`, and
    `canonical_snapshot_rows_exported=3159`;
  - post-sync effect audit:
    `execution_status_counts={"auto":1702,"review_only":1457}`,
    `needs_review_rule_names=1457`, `review_only_rule_names=1457`;
  - full recurring battle latest at that time:
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`,
    `battle_replay_final_status=trusted_for_strategy_learning`,
    `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
    `test_results_total=16`, and `test_results_status_counts={"pass":16}`.
- PostgreSQL queue heartbeat at `2026-06-20 09:24 -0300`:
  - PG-001 planner: `planned_row_count=0`, `db_mutations=false`;
  - PG-002 postcheck SQL: `all_post_apply_checks_ok=true`;
  - PG-003 oracle planner: `backfill_ready=0`, `db_mutations=false`;
  - PG-005 Lorehold critical-role dry-run: `applied_counts=0`,
    `db_mutations=false`;
  - PG-006 SELECTs: `auto=1751`, `review_only=3437`,
    `generated_needs_review_not_review_only=0`, migration `029=1`.
- Read-only recheck at `2026-06-20 09:36 -0300`
  (historical; superseded by the current `20260620_132812` latest battle):
  - `cd server && dart run bin/migrate.dart --status` reports `29/29`
    migrations executed and `0` pending;
  - latest battle symlink resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`;
  - latest `summary.json` reports
    `battle_replay_final_status=trusted_for_strategy_learning`,
    `mandatory_gate_divergences=[]`, `test_results_total=16`,
    `test_results_status_counts={"pass":16}`,
    `execution_status_counts={"auto":1702,"review_only":1457}`, and
    `runtime_surface_manifest_total_files=110`.

## PostgreSQL State

### PG-001 - Partner/background identity metadata backfill

Status: `applied_validated_closed`

Evidence:

- apply approved by Rafael on 2026-06-20 06:39 -0300
- apply committed `10` rows in `commander_learned_decks.metadata`
- independent postcheck:
  `expected_rows=10`, `matched_rows=10`, `model_ok_rows=10`,
  `combined_identity_ok_rows=10`, `backfill_source_ok_rows=10`,
  `all_post_apply_checks_ok=true`
- post-apply planner:
  `status=PASS`, `planned_row_count=0`, `planned_rows=[]`,
  `db_mutations=false`
- current audit code/test closure:
  `partner_identity_not_modeled` respects persisted
  `metadata.commander_identity_model`
- focused tests: `21` Python tests passed

Action:

- Do not re-run PG-001 apply.
- Keep rollback SQL only as emergency rollback evidence.

### PG-002 - Global learned-deck metadata canonicalization

Status: `applied_validated`

Evidence:

- pre-apply read-only audit reported:
  `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
  `all_core_metadata_zero=54`, `some_core_metadata_zero=4`
- package artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md`
- dry-run artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json`
- dry-run result:
  `checked=60`, `reported=60`, `changed=59`, `applied=0`,
  `db_mutations=false`
- precheck result:
  `expected_rows=59`, `matched_rows=59`, `before_matches=59`,
  `already_after_rows=0`, `would_change_rows=59`, `active_matches=59`
- `learned_deck:82` is unchanged by this package.

Post-apply evidence:

- Apply executed in this Auditor Central thread at `2026-06-20 08:32 -0300`.
- Apply result: `UPDATE 59`, `COMMIT`.
- SQL postcheck:
  `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`,
  `all_post_apply_checks_ok=true`.
- Learned-deck coherence audit after apply:
  `active_learned_decks=60`, `high=2`, `medium=13`,
  `some_core_metadata_zero=5`.
- Full post-apply artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`
  confirms `metadata_total_lands_mismatch=0`, `metadata_zero_lands=0`,
  `all_core_metadata_zero=0`, and `partner_identity_not_modeled=0`.
- Canonicalizer post-apply dry-run:
  `status=PASS`, `db_mutations=false`, `checked=60`, `changed=0`,
  `applied=0`.

### PG-003 - Oracle/card text/type backlog

Status: `not_ready`

Evidence:

- current oracle inventory still shows global oracle/type gaps:
  `missing_any=363`, `missing_oracle_id=4`, `missing_oracle_text=360`
- `plan_oracle_text_backfill.py --no-scryfall --limit 10` is read-only and
  returned `backfill_ready=0`, `planned_items=6`, and `db_mutations=false`

Missing before any apply:

- policy for official blank oracle text
- policy for Arena/Alchemy `A-` identities
- alias/reprint handling
- row-by-row dry-run and rollback

### PG-004 / PG-007 - Battle rule promotion / Leyline of Abundance

Status: `pg007_applied_validated_runtime_synced_battle_trusted`

Evidence:

- current latest battle artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`, `forensic_turn_findings=0`
- PostgreSQL postcheck confirms the Leyline target rule exists and the
  `card_intelligence_snapshot` row now has a `battle_rules` entry.
- PG-007 SQL package, rollback, and postcheck remain preserved under
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_*_20260620_1018.sql`

Current action:

- Keep PG-007 closed unless a future SELECT, sync report, or battle artifact
  proves rollback or drift.
- Do not reapply PG-007 blindly; use the retained rollback/apply package only
  with fresh precheck evidence.

### PG-005 - Lorehold critical role/function/semantic rows

Status: `already_present_no_apply_needed`

Evidence:

- `plan_lorehold_critical_role_backfill.py --dry-run` returned `status=PASS`,
  `db_mutations=false`, `applied_counts=0`
- `counts_before` equals `counts_after`:
  `existing_commander_synergy_rows=5`, `existing_function_tag_rows=11`,
  `existing_semantic_v2_rows=4`

Action:

- Do not run `--apply` now.
- Treat this as evidence that the critical Lorehold rows are already present,
  not as a new deploy request.

### PG-006 - card_battle_rules execution_status migration drift

Status: `applied_validated`

Pre-apply evidence:

- `dart run bin/migrate.dart --status` reports:
  `029 add_card_battle_rules_execution_status` pending.
- Live read-only PostgreSQL inspection at `2026-06-20 08:08 -0300` shows:
  - `card_battle_rules.execution_status` already exists, is `NOT NULL`, and
    defaults to `'auto'::text`;
  - `chk_card_battle_rules_execution_status` is missing;
  - `schema_migrations.version='029'` is not recorded.
- PG-006 precheck returned:
  `generated / needs_review / auto = 1970`,
  `generated / needs_review / review_only = 1467`, and
  `pg006_rows_to_normalize=1970`.
- PG-006 precheck also shows the live `card_intelligence_snapshot` and
  `optimize_candidate_quality_summary` view definitions do not mention
  `execution_status`; the apply package refreshes them using current backend
  definitions before recording migration `029`.
- SQL package:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md`.

Post-apply evidence:

- Apply executed in this Auditor Central thread at `2026-06-20 08:30 -0300`.
- Apply result: `COMMIT`, `normalized_rows=1970`, rollback backup rows `1970`.
- Postcheck:
  `execution_status_counts={"auto":1751,"review_only":3437}`,
  `generated / needs_review / review_only = 3437`,
  `remaining_needs_review_not_review_only=0`,
  `chk_card_battle_rules_execution_status` present, migration `029` present,
  `card_intelligence_snapshot_view.mentions_execution_status=true`.
- `dart run bin/migrate.dart --status`: all `29/29` migrations executed.
- Current read-only recheck at `2026-06-20 09:36 -0300` again reports all
  `29/29` migrations executed and `0` pending.

Important:

- Do not run native `dart run bin/migrate.dart` as the fix for this drift. The
  migration source only normalizes rows where `execution_status` is null or
  blank, while the current bad rows already store `auto`.
- PG-006 normalizes PostgreSQL execution governance and migration state. The
  local Hermes runtime cache was refreshed from PostgreSQL after apply, and the
  latest battle artifact exposes `review_only` rule names.

## Worktree Control

Detailed worktree triage lives in:

- `docs/hermes-analysis/WORKTREE_TRIAGE_REGISTER_2026-06-20.md`
- operational map:
  `docs/hermes-analysis/WORKTREE_OPERATIONAL_MAP_2026-06-20.md`
- file ownership index:
  `docs/hermes-analysis/WORKTREE_FILE_OWNERSHIP_INDEX_2026-06-20.md`
- cleanup proposal:
  `docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md`

Current cleanup rule:

- no cleanup is authorized yet.
- older duplicate audit artifacts may become cleanup candidates only after the
  latest artifact and register evidence are retained.
- source files and tests under `app/` and `server/` are not cleanup candidates
  until their owning change is validated or explicitly rejected.

Latest validation state:

- changed/untracked backend Dart aggregate: `dart analyze` no issues and
  `dart test` `146/146` passed.
- changed/untracked backend Python tests aggregate: `39` tests passed.
- changed/untracked app Dart aggregate: `flutter analyze` no issues and
  `flutter test` `105/105` passed.
- backend data-contract anti-fanout slice: source inspection confirms
  deck-reading routes prefer `card_intelligence_snapshot` and fallback through
  per-card `jsonb_agg(...)` / `EXISTS`; focused guard tests returned `19/19`
  and `24/24` Dart tests passed plus `7/7` Python planner tests passed.
- PostgreSQL writes performed by this single-operator cycle are PG-006, PG-002,
  and PG-007, all postchecked. Local Hermes SQLite cache syncs were performed
  for PG-006 and PG-007 after backups; those syncs did not write PostgreSQL.
  No live route, live OpenAI, real-device, cleanup, commit, push, revert, or
  stash has been performed in these aggregate validations.

## Single Operator Mode - 2026-06-20 11:05 -0300

Rafael paused the other chats and explicitly assigned this Auditor Central
thread to operate the project for now.

Current rule:

- do not generate new commands for other chats as the default path.
- this thread audits, patches, validates, prepares PostgreSQL packages, applies
  PostgreSQL only after explicit approval, and controls worktree cleanup.
- preserve the same safety gates: no commit/push, no deck swap, no destructive
  cleanup, and no PostgreSQL write without exact approval and evidence.

Latest executed step:

- App Deck provider/UI ownership audit completed.
- Auditor patch normalized `createDeck` `archetype` for both API request and
  optimistic local cache.
- Validation: focused provider/support tests `65/65` passed and focused
  widget/screen tests `40/40` passed.
- Backend Deck routes/helpers ownership audit completed.
- Auditor patch made the OpenAI recommendations prompt include
  backend-computed `candidate_color_identity`.
- Validation: focused recommendations tests `16/16`, focused
  bulk/import/validation/name-resolution tests `33/33`, and focused backend
  Dart analyze passed.
- Backend AI/import/simulate ownership audit completed without extra patch.
- Validation: focused AI/import/simulate Dart tests `83/83`, focused Python
  planner/auditor tests `39/39`, and focused backend Dart analyze passed.

## Next Operator Step

1. Keep this Auditor Central thread as the single operator until Rafael
   explicitly reopens additional chats.
2. Keep PG-001 closed.
3. Keep PG-002, PG-006, and PG-007 closed unless future SELECT/artifact
   evidence proves rollback or drift.
4. Cleanup proposal is prepared and audited as an exact `8`-file list; do not
   delete anything until the exact list is approved.
5. No additional PostgreSQL apply is ready at the current heartbeat.
6. Before any commit discussion, review the broad dirty source diff by
   ownership area; aggregate tests passed, but that does not prove live backend
   deploy, live OpenAI behavior, or real-device Flutter behavior.

## Publication Branch Observation - 2026-06-20 13:28 -0300

Scope:

- Heartbeat re-read the current Git state, central registers, Lorehold register,
  latest learned-deck coherence artifact, and latest battle summary.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, push,
  live app route call, or OpenAI call was performed by this heartbeat.

Current evidence:

- `git status --short --branch`:
  `## codex/manaloom-batches-20260620...origin/codex/manaloom-batches-20260620`.
- `git status --porcelain=v1 | wc -l`: `0`.
- `git rev-list --left-right --count HEAD...@{upstream}`: `0 0`.
- Current commits on the publication branch are:
  `9ffe002b docs: publish ManaLoom audit evidence batch`,
  `7310111f chore: add ManaLoom audit tooling batch`,
  `764a3255 feat: harden ManaLoom deck backend flows`, and
  `ca939026 feat: refine deck app flows`.
- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`.
- Lorehold `learned_deck:82` still has `issues=[]`, `metadata.total_lands=33`,
  and excluded fast mana remains `Chrome Mox`, `Mox Diamond`, `Mox Opal`.
- Latest battle summary resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`
  and reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, complete forensic lineage, and tests `16/16`.

Current conclusion:

- The earlier Batch 0/1 readiness entries are historical checkpoint evidence.
  At this 13:28 checkpoint, the working tree was clean and aligned with the
  publication branch upstream.
- This checkpoint was superseded by the `Master Migration Closure -
  2026-06-20 13:31 -0300` section below, which records the later
  fast-forward/push of `master`.
- No new PostgreSQL apply is ready from the current Lorehold/deck register
  state.
- PG-001, PG-002, PG-006, PG-007, and PG-008 remain closed unless future
  SELECT, sync report, or battle artifact evidence proves rollback or drift.

## Master Migration Closure - 2026-06-20 13:31 -0300

Scope:

- Migrated the publication branch into `master` by fast-forward after Rafael
  requested migration so the work would not remain detached from the main line.
- Pushed `master` to GitHub.
- Verified public backend health after deploy.
- No PostgreSQL write, deck swap, cleanup, stash, revert, or new app/backend
  code edit was performed in this closure.

Evidence:

- Merge path: `master` fast-forwarded from `3908e88c` to `ca939026`.
- Pushed range: `3908e88c..ca939026 master -> master`.
- Final Git state:
  `git status --short --branch` reports `## master...origin/master`.
- Final divergence: `git rev-list --left-right --count HEAD...origin/master`
  reports `0 0`.
- Untracked non-ignored files: `0`.
- Public `/health` reports `status=healthy`, `environment=production`, and
  `git_sha=ca93902621728baefd0715f11fecccd0bfd62f03`.

Current conclusion:

- The batch branch has been migrated to `master` and production is running the
  migrated SHA.
- The local worktree is clean except for intentionally ignored SQLite backup
  files under `docs/hermes-analysis/manaloom-knowledge/backups/`.
- No current PostgreSQL apply is ready after this migration.

## Heartbeat Documentation Reconciliation - 2026-06-20 13:33 -0300

Scope:

- Rechecked the post-migration state during the Lorehold monitor heartbeat and
  documented the 13:28 publication-branch checkpoint as historical/superseded
  by the 13:31 `master` migration closure.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, push,
  app/backend code edit, live app route call, or OpenAI call was performed by
  this heartbeat.

Evidence:

- Pre-closure `git status --short --branch` reported
  `## master...origin/master` plus three modified documentation files from this
  reconciliation:
  `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`,
  `MANALOOM_CENTRAL_AUDITOR_ORDERS.md`,
  `POSTGRES_DEPLOY_REGISTER_2026-06-20.md`.
- `git rev-list --left-right --count HEAD...origin/master`: `0 0`.
- Volatile-SHA closure rule: this register must not keep re-stamping exact
  "current HEAD" after each documentation-only closure commit. Exact deploy SHA
  proof remains mandatory for deploy validation, but it belongs in the command
  evidence or bounded smoke artifact for that cycle, not in a tracked heartbeat
  note that would recursively dirty itself.
- Public `/health` recheck reported `status=healthy` and
  `environment=production` during the reconciliation.
- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`;
  Lorehold `learned_deck:82` still has `issues=[]`.
- Latest battle summary remains
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, complete forensic lineage, and tests `16/16`.

Current conclusion:

- The active documentation loop is closed by policy: no further tracked
  heartbeat should be opened just to restamp the SHA created by the previous
  heartbeat documentation commit.
- PG-001, PG-002, PG-006, PG-007, and PG-008 remain closed.
- PG-003 remains policy-blocked and PG-005 remains no-apply-needed.
- No current PostgreSQL apply is ready.

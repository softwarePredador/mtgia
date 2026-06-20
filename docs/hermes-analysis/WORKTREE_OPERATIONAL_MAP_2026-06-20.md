# ManaLoom Worktree Operational Map - 2026-06-20

Owner: Auditor Central / single operator
Status: active worktree control map
Last refreshed: 2026-06-20 13:12 -0300

## Current Snapshot

- Branch: `master...origin/master`.
- `git status --short --branch`: `master...origin/master`, with `73` tracked
  modified files and `75` individual untracked files at the 13:12 evidence
  checkpoint.
- `git diff --shortstat` at the 13:12 evidence checkpoint:
  `73 files changed, 24752 insertions(+), 2022 deletions(-)`.
- PostgreSQL PG-006 and PG-002 were applied and validated in this Auditor
  Central thread after Rafael explicitly requested single-operator deploy.
- Current PostgreSQL heartbeat confirms PG-001/PG-002/PG-006/PG-007/PG-008 are
  closed, PG-003 remains policy-blocked, and PG-005 remains no-apply-needed.
  PG-008 was applied, postchecked, synced into Hermes SQLite, validated by
  closure battle `20260620_151437`, and revalidated by latest battle runs
  `20260620_155445` and `20260620_160459`.
- Current validation heartbeat: App Deck provider/UI focused tests passed
  `65/65` provider/support plus `40/40` widget/screen tests after the
  normalized-`archetype` auditor patch. Backend Deck routes/helpers focused
  tests passed `16/16` recommendations and `33/33` bulk/import/validation/name
  resolution tests after the OpenAI prompt color-identity auditor patch;
  focused backend Dart analyze returned no issues. Backend AI/import/simulate
  focused tests passed `83/83` Dart plus `39/39` Python, and focused Dart
  analyze returned no issues. Earlier aggregate app analyze had no issues and
  aggregate app tests passed `105/105`; backend Dart analyze had no issues,
  backend changed/untracked Dart tests passed `146/146`, backend
  changed/untracked Python tests passed `39/39`, and earlier `git diff --check`
  was clean.
- Current latest battle heartbeat: `latest` now points to `20260620_160459`,
  status `trusted_for_strategy_learning`, divergence list empty, forensic
  lineage complete, and tests `16/16` pass. Runtime execution-status counts are
  `auto=1704` and `review_only=1457`.
- Publication-batch validation at `2026-06-20 12:58 -0300`: `flutter analyze`
  clean, `flutter test` `619/619`, server `dart analyze` clean, server
  `dart test` `634/634`, Python discover `96/96`, migrations `29/29`, PG-008
  postcheck `pg008_target_rule_count=1`, runtime-surface manifest test `PASS`,
  fresh battle audit `20260620_155445` trusted, and public `/health` healthy on
  committed SHA `3908e88caa9c1bb43207e8a2334b0214e150fa10`; the 13:12 reread
  then confirmed newer latest `20260620_160459` trusted.
- New publication-batch plan:
  `docs/hermes-analysis/MANALOOM_PUBLICATION_BATCH_PLAN_2026-06-20.md`.
- Local SQLite backups under
  `docs/hermes-analysis/manaloom-knowledge/backups/*.bak` are preserved on disk
  and ignored by `.gitignore`; they are local recovery evidence, not batch
  publication artifacts.
- Final worktree validation at `2026-06-20 13:12 -0300`: `git diff --check`
  clean and current latest battle `20260620_160459` remains trusted.
- No deck swap, stash, revert, commit, or push was performed for this map.
- Single-operator completion audit was added at
  `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`;
  after that addition, individual untracked file count is `80`.
- Public backend deploy check at `2026-06-20 11:44 -0300`: production
  `/health` is healthy and reports
  `git_sha=3908e88caa9c1bb43207e8a2334b0214e150fa10`, matching local `HEAD`
  and `origin/master`; `HEAD...origin/master` is `0 0`. The `64` dirty
  app/server files are therefore local-only and not deployed.
- Authorized cleanup executed at `2026-06-20 11:57 -0300`: the exact `8`
  superseded/duplicate artifacts from
  `WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md` were deleted after hash/presence
  revalidation. Untracked individual files dropped from `80` to `72`.
- Additional duplicate cleanup executed at `2026-06-20 12:00 -0300`: duplicate
  `battle_effect_coverage_audit_20260620_132730.*` was removed after SHA and
  `cmp -s` proof against retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*`. Untracked
  individual files are now `70`.
- PG-008 added `7` required untracked evidence files: `5` SQL/package files,
  `1` runtime sync report, and `1` SQLite backup. Untracked individual files are
  now `77`.
- Current ownership coverage recheck maps all dirty files to an owner front:
  tracked prefix split remains `app=17`, `docs=8`, `server=47`; untracked prefix
  split is now `docs=49`, `server=28`.

## Operating Rules

- PostgreSQL writes are handled by the Auditor Central while Rafael keeps the
  other chats paused; each write still needs precheck/apply/postcheck evidence.
- Do not delete files unless Rafael explicitly approves the exact cleanup list.
- Do not treat untracked SQL packages or reports as trash; many are deploy or
  audit evidence.
- Do not join product deck rows directly to multi-row intelligence tables
  (`card_function_tags`, `card_semantic_tags_v2`, `card_battle_rules`) without
  aggregation. Prefer `card_intelligence_snapshot` or aggregated JSON by
  `card_id`.
- Treat Hermes artifacts as audit/lab evidence; PostgreSQL/backend plus tests
  remain product source of truth.

## Worktree Fronts

| Front | Files / groups | State | Evidence | Next action |
| --- | --- | --- | --- | --- |
| App Deck provider/UI | `10` changed `app/lib/features/decks/**` files and `7` changed `app/test/features/decks/**` files | patched and validated locally | normalized create-deck `archetype` is now used both for API request and optimistic cache; focused provider/support tests `65/65` passed; focused widget/screen tests `40/40` passed; earlier aggregate app analyze had no issues and app tests `105/105` passed | preserve; no cleanup |
| Backend Deck routes/helpers | extracted helper files under `server/lib/deck_*`, `server/lib/import_to_deck_merge_support.dart`, route changes under `server/routes/decks/**`, `server/routes/import/to-deck`, `server/routes/cards/resolve/batch` | patched and validated locally | OpenAI recommendations prompt now uses backend-computed `candidate_color_identity`; focused recommendations tests `16/16`, bulk/import/validation/name-resolution tests `33/33`, and focused backend Dart analyze passed; aggregate changed/untracked backend Dart tests earlier passed `146/146` | preserve; no cleanup |
| Backend AI/import/simulate | `server/lib/ai/**`, `server/routes/ai/**`, `server/routes/import/validate`, `server/lib/import_card_lookup_service.dart`, `server/bin/card_impact_analyzer.py` | audited and validated locally | tracked slice `33 files changed, 1987 insertions(+), 500 deletions(-)`; focused AI/import/simulate Dart tests `83/83`, Python planner/auditor tests `39/39`, and focused Dart analyze passed; aggregate backend Dart tests earlier `146/146` | preserve; no cleanup |
| Backend recommendations advisory authority | `server/lib/deck_recommendations_advisory_support.dart`, `server/test/deck_recommendations_advisory_support_test.dart`, `server/doc/API_CONTRACTS_AND_DATA_MAP.md` | patched and validated locally | model text can no longer override backend fallback context fields; focused recommendations analyze no issues and tests `16/16` passed | preserve; no PostgreSQL apply |
| Backend battle focused evidence harness | `server/bin/manaloom_battle_rule_focused_evidence.py`, `server/test/manaloom_ops_daemon_test.py` | patched and validated locally | focused evidence test passed with `evaluated_count=14`, `evidence_count=14`; ops-daemon env test passed; Python discover `96/96` passed | preserve; no PostgreSQL apply |
| Backend data-contract anti-fanout | deck-reading routes and support code referencing `card_intelligence_snapshot`, `card_identity_bridge`, `card_function_tags`, `card_semantic_tags_v2`, and `card_battle_rules` | validated locally | source inspection found product deck loaders on `card_intelligence_snapshot` or per-card `jsonb_agg(...)` / `EXISTS`; focused tests `19/19` + `24/24` Dart and `7/7` Python passed | preserve; no PostgreSQL apply |
| Control docs/registers | `MANALOOM_CENTRAL_AUDITOR_ORDERS.md`, `POSTGRES_DEPLOY_REGISTER_2026-06-20.md`, `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`, `WORKTREE_TRIAGE_REGISTER_2026-06-20.md`, `WORKTREE_FILE_OWNERSHIP_INDEX_2026-06-20.md` | reconciled locally | documentation contradiction audit relabeled pre-apply PG-002/PG-006 evidence, closed stale active Lorehold PG-001/PG-002 items, rechecked `dart run bin/migrate.dart --status` as `29/29`, added exact file-level ownership index for all dirty files, and refreshed the 09:51 PostgreSQL/test heartbeat | preserve; no cleanup |
| PostgreSQL PG-001 | partner/background identity package and reports | applied before this map and closed | postcheck/planner/coherence audit show `partner_identity_not_modeled=0`; do not reapply | preserve artifacts only |
| PostgreSQL PG-002 | learned-deck metadata canonicalization package | applied and validated | apply `UPDATE 59`, `COMMIT`; postcheck `after_matches=59`, `still_before_rows=0`, `all_post_apply_checks_ok=true`; canonicalizer post-apply dry-run `changed=0`, `applied=0`, `db_mutations=false`; full artifact `115918` has `metadata_total_lands_mismatch=0` | preserve package, rollback, and post-apply audit evidence |
| PostgreSQL PG-003 | oracle/card text/type backlog | not ready | read-only planner: `missing_any=363`, `backfill_ready=0`, `db_mutations=false` | no apply; define policy first |
| PostgreSQL PG-004 / PG-007 | battle/Leyline possible rule promotion | PG-007 applied and validated | apply `INSERT 0 1` + `COMMIT`; postcheck target rule `1`; sync `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107`; closure battle `20260620_132812` trusted; later heartbeats `20260620_140016`, `20260620_151437`, `20260620_155445`, and current `20260620_160459` are also trusted | preserve deploy evidence; do not reapply unless drift appears |
| PostgreSQL PG-005 | Lorehold critical role/function/semantic rows | already present, no apply needed | dry-run `PASS`, `applied_counts=0`, existing rows `5/11/4` unchanged | do not run `--apply` |
| PostgreSQL PG-006 | `card_battle_rules.execution_status` migration drift | applied and validated | `normalized_rows=1970`; backup rows `1970`; migration `029` executed; constraint present; remaining needs-review not-review-only rows `0`; migration status `29/29` | preserve package and rollback evidence |
| PostgreSQL PG-007 | `Leyline of Abundance` battle-rule lineage blocker from latest `20260620_125745` | applied, postchecked, runtime-synced | postcheck `pg007_target_rule_count=1`; snapshot has Leyline `battle_rules`; rollback retained; backup rows `0` because no previous target row existed | closed unless rollback/drift evidence appears |
| PostgreSQL PG-008 | `Machine God's Effigy` battle-rule lineage blocker from latest `20260620_150241` | applied, postchecked, runtime-synced | apply `INSERT 0 1` + `COMMIT`; postcheck `pg008_target_rule_count=1`; sync `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108`; closure battle `20260620_151437` and current latest battle `20260620_160459` are trusted with `mandatory_gate_divergences=[]` | closed unless rollback/drift evidence appears |
| Battle docs/artifacts | `BATTLE_*` registers and latest artifact | current latest `20260620_160459` trusted | latest status `trusted_for_strategy_learning`, tests `16/16` pass, forensic lineage complete, no mandatory divergences; `20260620_132812` remains PG-007 closure evidence, `20260620_150241` remains historical pre-PG-008 blocker evidence, and `20260620_125745` remains historical pre-PG-007 blocker evidence | preserve evidence; update stale docs only |
| Cleanup candidates | old learned-deck coherence snapshots `031157`, `033941`, `034324` plus duplicate effect-coverage auto outputs `120952.*` and `132730.*` | executed | exact initial `8`-file delete list was removed after approval; candidate hashes matched; `120952.*` was byte-identical to retained `120904_post_sqlite_sync.*`; `132730.*` was byte-identical to retained `102701_post_pg007_sync.*`; retained `095253.*`, `115918.*`, `120904_post_sqlite_sync.*`, and `102701_post_pg007_sync.*` still exist; duplicate hash scan now returns `NO_DUPLICATE_UNTRACKED_HASHES` | closed |

## Ownership Coverage Recheck - 2026-06-20 11:30 -0300

Evidence:

- `git diff --name-only`: `72` tracked modified files.
- `git ls-files --others --exclude-standard`: `79` individual untracked files.
- Tracked dirty-file coverage:
  - `app_deck=17`
  - `backend_deck_routes_helpers=13`
  - `backend_ai_import_simulate_planners=31`
  - `api_contract_docs_tests=3`
  - `docs_artifacts_control=8`
- Untracked dirty-file coverage:
  - `docs_artifacts_control=51`
  - `backend_deck_routes_helpers=20`
  - `backend_ai_import_simulate_planners=8`

Conclusion:

- No dirty file is outside the ownership fronts.
- `server/test/canonicalize_learned_deck_metadata_cli_test.dart` is classified
  with backend learned-deck/planner CLI tests.
- This is classification only. No cleanup, stash, revert, stage, commit, push,
  PostgreSQL write, or deck swap was performed.

## Ownership Coverage Recheck - 2026-06-20 11:46 -0300

Evidence:

- `git status --short --branch`: `master...origin/master`, `72 M`,
  `78 ??`.
- `git diff --shortstat`:
  `72 files changed, 24631 insertions(+), 2029 deletions(-)`.
- `git ls-files --others --exclude-standard | wc -l`: `80`.
- `git diff --check`: clean.
- Tracked prefix split remains `app=17`, `docs=8`, `server=47`.
- Untracked prefix split is now `docs=52`, `server=28`.
- The extra untracked docs file versus the prior ownership index is
  `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`,
  classified as Auditor Central control state.
- File-section ownership totals now cover all dirty files:
  `17` App Deck files, `8` tracked docs/runtime evidence files, `47` tracked
  backend source/test files, `7` untracked control registers, `22` untracked
  PostgreSQL deploy evidence files, `5` untracked PG-006 battle/runtime
  evidence files, `4` untracked learned-deck retained evidence files, `8`
  untracked cleanup proposal candidates, `28` untracked backend source/test
  files, and `6` untracked PG-007 runtime/battle evidence files.

Conclusion:

- No dirty file is outside the current ownership fronts.
- This is classification only. No cleanup, stash, revert, stage, commit, push,
  PostgreSQL write, code deploy, or deck swap was performed.

## Cleanup And Ownership Recheck - 2026-06-20 11:57 -0300

Evidence:

- Deleted the exact `8` files listed in
  `WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md` after Rafael's cleanup
  authorization.
- Pre-delete revalidation: all `8` files existed, hashes matched the proposal,
  and duplicate `120952.*` files still matched retained
  `120904_post_sqlite_sync.*`.
- Post-delete check: all `8` paths are absent.
- Retained evidence still exists:
  `learned_deck_coherence_audit_20260620_095253.*`,
  `learned_deck_coherence_audit_20260620_115918.*`, and
  `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.*`.
- `git status --short --branch`: `master...origin/master`, `72 M`,
  `70 ??`.
- `git ls-files --others --exclude-standard | wc -l`: `72`.
- Prefix split after cleanup: tracked `app=17`, `docs=8`, `server=47`;
  untracked `docs=44`, `server=28`.
- `git diff --check`: clean.

Conclusion:

- Cleanup proposal is closed.
- No dirty file is outside the current ownership fronts.
- No PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit, or
  push was performed.

## Additional Duplicate Cleanup Recheck - 2026-06-20 12:00 -0300

Evidence:

- Duplicate SHA groups remained only for
  `battle_effect_coverage_audit_20260620_132730.*` against retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*`.
- `cmp -s` returned `0` for both `.json` and `.md` duplicate pairs.
- `rg` found no filename reference to `battle_effect_coverage_audit_20260620_132730`
  outside cleanup/ownership documentation.
- Deleted
  `battle_effect_coverage_audit_20260620_132730.json` and
  `battle_effect_coverage_audit_20260620_132730.md`.
- Retained PG-007 evidence still exists:
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*`.
- Duplicate hash scan over current untracked files returned
  `NO_DUPLICATE_UNTRACKED_HASHES`.
- `git ls-files --others --exclude-standard | wc -l`: `70`.
- Prefix split after cleanup: tracked `app=17`, `docs=8`, `server=47`;
  untracked `docs=42`, `server=28`.

Conclusion:

- Cleanup proposal remains closed with no duplicate untracked evidence hashes
  known at this checkpoint.
- No PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit, or
  push was performed.

## PG-008 Deploy And Battle Recheck - 2026-06-20 12:16 -0300

Evidence:

- Latest battle `20260620_150241` exposed one medium forensic blocker:
  `Machine God's Effigy`, event `spell_cast`, effect `ramp_permanent`, source
  `functional_tags_json`, seed `63211509`.
- PostgreSQL precheck for PG-008 confirmed target card `1`, existing target rule
  `0`, existing any Machine God's Effigy rule `0`, and snapshot before
  `battle_rules=[]`, `battle_rule_count=0`, `function_tags={ramp}`.
- PG-008 apply result: `INSERT 0 1`, `COMMIT`.
- PG-008 postcheck result: `pg008_target_rule_count=1`, snapshot now exposes
  the rule in `battle_rules`, backup rows `0`.
- PG -> SQLite sync result:
  `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108`,
  `canonical_snapshot_rows_exported=3161`.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_151437/summary.json`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, tests `16/16`.
- Worktree after PG-008: tracked prefix split `app=17`, `docs=8`,
  `server=47`; untracked prefix split `docs=49`, `server=28`.

Conclusion:

- PG-008 is closed unless future SELECT/sync/battle evidence proves drift.
- Current latest battle is trusted again.
- No deck swap, code deploy, stash, revert, stage, commit, or push was
  performed.

## Backend Anti-Fanout Recheck - 2026-06-20 11:35 -0300

Evidence:

- Dirty backend scan covered `40` files under `server/lib`, `server/routes`,
  and `server/bin`.
- Dirty backend files referencing semantic multi-row sources:
  `card_function_tags=7`, `card_semantic_tags_v2=6`,
  `card_battle_rules=0`.
- Dirty backend files referencing safe aggregate source:
  `card_intelligence_snapshot=6`.
- Dirty backend files referencing deck rows:
  `deck_cards=16`.
- Direct join pattern scan found one multi-row join:
  `server/lib/ai/commander_learned_deck_support.dart:377`
  `LEFT JOIN card_function_tags cft`.
- That join is aggregated and not a deck-row fanout:
  `has_array_agg=true`, `has_group_by=true`, `has_deck_cards_near=false`.
- Deck-facing dirty loaders use `card_intelligence_snapshot` when available or
  fallback to per-card `jsonb_agg(...)` / `EXISTS` subqueries.

Conclusion:

- No unsafe dirty backend `deck_cards -> card_function_tags`,
  `deck_cards -> card_semantic_tags_v2`, or `deck_cards -> card_battle_rules`
  join was found.
- This is a read-only source audit. No source edit or PostgreSQL write was
  performed.

## Critical Artifact Hashes To Preserve

These hashes identify current evidence that must not be deleted during cleanup:

| sha256 | path |
| --- | --- |
| `1bec9f3492e1308d01ed4be7ce34d528e19edff5b9828c3b07f35fd9e0477611` | `docs/hermes-analysis/master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md` |
| `edef0154b459e725b112e37dab954d404052b2820c33acf6f213addc3842132a` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.json` |
| `22c982e8930115fe88e49f7c3dfd5f0da7be4d5ad3d0397b34dc7c6414a8eed2` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.md` |
| `ac62feb07dc9b390e3c47a4f7bae7bcf5ade343f0d5dc7f68555c9654c22c247` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json` |
| `d9ca5bf3b499f54d394dcfeeb4908601bbd58bf4fa01e45719307c03595f0db0` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.md` |
| `c1e5d48f6ab9c907f7b6c8f0f54fa9f5f05b38b0aec9fc1a1b9abd35793ddf4e` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql` |
| `b9be24edbebbfe69884497b94adea5aa88d2c7b65ea4f746b01561ccf307b625` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json` |
| `bc440fe72ffcf9beaf07b7b2e327d50d6ccc825f1e1e587647e91dc5e9826611` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md` |
| `4be446dbb9c7c2686a68b3e17bf70b23d665868c5c9e364c64108f8b25f76894` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql` |
| `1fe6be94869928abd38a6471994a8d44b85a961f2c58e6fdc1471920a23746a6` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql` |
| `cd5d534ba2bc74d2cc77dcf8f2e3ceb8015735fcd40d222fc9c71748f87bee03` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql` |
| `dada71b6139895a9aa87fcd466a4a557576dd657629b16c50c87e700e9944924` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_apply_20260620_063349.sql` |
| `0ad87eafafaea5357a5ee49bb853a741dab58e082c5dda54990f9b723f70532b` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_postcheck_20260620_063349.sql` |
| `91a4a8bbf30dd31dffdf987b43a56d92e652ea9987e0b22aa4d438089b845d87` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_precheck_20260620_063349.sql` |
| `8215bddc23d49e7aa17a338b091e940fbd0062a4366a735508d5b5c32fa3a318` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_rollback_20260620_063349.sql` |
| `8b8c58ae3666a99f117399187bd7c1b0b3b21bf51c1cbac3d7ec466bd4e6b53e` | `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql` |
| `9198907137675b96ddac3453359738217de66e5197b8c2079e6fec5d07e61c2e` | `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql` |
| `15debcce75fae068dc07de0dd73d7667013966eba3330fcd5f0f9d7ba6298bc7` | `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql` |
| `d50cc449967c64350d9e291db62b55b677a1b26e2db0d46397b75262e0c95560` | `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql` |
| `c55dfbf9c645e97d64d14d66c863493f42912863c89197cc16b43765b7119ffb` | `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md` |
| `167805ef8a92ff8ba8a8ef5f754b9aa6a2ae3c55e504a0c5cb577fc449c1b248` | `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json` |
| `1be4534bb0e5b0b5ca3782cde8fe0e2bc4742bdb15f1da7a38a6fcaf6b78efa7` | `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json` |
| `964778a4f01d2caf1c2d58bf1bcca9571a33925cb853e36f85f2fb0339edea8e` | `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md` |
| `4dcd4ff455df504fe92880f5788058c6696d258f6784cdb9c7d3e2057d4ad164` | `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json` |
| `4c3a767824d181a4976a2722721030ee2316f4d4844ff39dbf2bbf10710b0d90` | `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json` |
| `4028be1a8255215fb117512c13a36998a695140add380cf5b98541f1c293acc6` | `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.json` |
| `859acb1938f3dfef568560b45192acce8148fec84d22633930832414ce832fd2` | `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md` |
| `4d0fd9be8d90703fb8d149c799df6cb17bbb71448780985b12b9c93ca2065d71` | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json` |

## Current Approval Queue

1. Cleanup proposal: closed. The exact initial `8`-file deletion list and the
   additional duplicate `132730.*` pair were executed after approval and
   validation.
2. PG-003 oracle/card text/type backlog: still not ready for PostgreSQL until
   policy is explicit. Current read-only planner still reports
   `backfill_ready=0`.
3. No current PostgreSQL apply is ready after PG-008. Current heartbeat confirms
   PG-001 planner `planned_row_count=0`, PG-002 postcheck
   `all_post_apply_checks_ok=true`, PG-003 oracle planner
   `backfill_ready=0`, PG-005 dry-run `applied_counts=0`, and migrations
   `29/29` executed with `0` pending. PG-007 is closed by apply/postcheck,
   PG -> SQLite sync, and battle `20260620_132812`; PG-008 is closed by
   apply/postcheck, PG -> SQLite sync, and current latest battle
   `20260620_151437`. PG-006 runtime/Hermes execution-status alignment remains
   closed for the local cache by the historical `20260620_120904` sync and
   `20260620_121005` audit.
4. Code publication remains unauthorized: production is healthy at committed
   `master`, but the `64` dirty `app/` + `server/` files are not deployed
   until there is an explicit stage/commit/push/deploy decision.

## Not Counted As Completion

- Passing local tests does not prove live backend deploy, real OpenAI success,
  real-device Flutter behavior, or PostgreSQL mutation success.
- Passing PostgreSQL postchecks does not prove Hermes/runtime caches expose the
  same counters until a PG -> SQLite sync and full battle rerun are performed.
  This was done for PG-006 in the `20260620_120904` / `20260620_121005`
  evidence set and for PG-007 in the `20260620_102701` sync /
  `20260620_132812` battle evidence set.
- Cleanup is authorized only for exact validated lists. The current validated
  cleanup list is already executed and closed.
- Commit/push remain unauthorized.

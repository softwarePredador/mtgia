# ManaLoom Publication Batch Plan - 2026-06-20

Owner: Auditor Central / single operator
Status: ready-for-review plan, not staged and not committed
Last refreshed: 2026-06-20 13:12 -0300

## Scope

This document defines how to split the current dirty worktree into safe
publication batches after the single-operator audit, PostgreSQL deploys, cleanup,
and validation cycle.

No stage, commit, push, deck swap, or additional PostgreSQL write is authorized
by this plan. It is an execution map for the next publication decision.

## Current State

- Branch: `master...origin/master`.
- Production backend is healthy at committed SHA
  `3908e88caa9c1bb43207e8a2334b0214e150fa10`.
- Dirty local source is not deployed.
- Current tracked diff at the 13:12 evidence checkpoint:
  `73 files changed, 24752 insertions(+), 2022 deletions(-)`.
- Current untracked files at the 13:12 evidence checkpoint: `75`, split as
  `docs=47`, `server=28`.
- The three local SQLite backup files remain on disk under
  `docs/hermes-analysis/manaloom-knowledge/backups/`, but are now ignored by
  `.gitignore` because they are local recovery evidence, not publication
  artifacts.
- Current latest battle after the 13:12 reread:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`.

## Validation Evidence

Latest checks run in this cycle:

- `flutter analyze` in `app`: no issues.
- `flutter test` in `app`: `619` tests passed.
- `dart analyze` in `server`: no issues.
- `dart test` in `server`: `634` tests passed.
- `python3 -m unittest discover -s server/test -p '*_test.py' -v`: `96`
  tests passed, with one existing sqlite ResourceWarning and no failure.
- `cd server && dart run bin/migrate.dart --status`: `29` migrations total,
  `29` executed, `0` pending.
- PG-008 postcheck SQL: `pg008_target_rule_count=1`; the
  `card_intelligence_snapshot` row for `Machine God's Effigy` exposes the new
  rule; transaction rolled back after SELECT checks.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`:
  `PASS test_manifest_classifies_current_battle_surface`.
- Fresh battle audit:
  `MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND=manual_publication_batch_validation`
  with `--seeds 16`; exit `0`.
- Current latest battle result: `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, `test_results_total=16`,
  `test_results_status_counts={'pass': 16}`,
  `execution_status_counts={'auto': 1704, 'review_only': 1457}`,
  `invocation_kind=manual_cli`, and `start_seed=63211604`.
- `git diff --check`: clean.
- Public `/health`: `status=healthy`, `environment=production`,
  `git_sha=3908e88caa9c1bb43207e8a2334b0214e150fa10`.

## Batch Order

### Batch 0 - Local Evidence Hygiene

Purpose: keep local recovery artifacts out of publication while preserving them
on disk.

Files:

- `.gitignore`

Includes:

- Ignore rule for `docs/hermes-analysis/manaloom-knowledge/backups/*.bak`.

Excludes:

- The backup `.bak` files themselves.

Validation already run:

- `git status --short --branch` reported `74` untracked files immediately after
  the ignore rule and before this plan file was added; current count is `75`
  because this plan is itself untracked.
- `git diff --check` clean.

### Batch 1 - Auditor Docs And PostgreSQL Evidence

Purpose: publish the control trail before publishing product code.

Files/groups:

- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_ORDERS.md`
- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
- `docs/hermes-analysis/MANALOOM_PUBLICATION_BATCH_PLAN_2026-06-20.md`
- `docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md`
- `docs/hermes-analysis/WORKTREE_*_2026-06-20.md`
- `docs/hermes-analysis/BATTLE_*`
- `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
- SQL package/report artifacts for PG-001, PG-002, PG-006, PG-007, and PG-008.
- Retained JSON/Markdown evidence under
  `docs/hermes-analysis/master_optimizer_reports/`.

Do not include:

- `docs/hermes-analysis/manaloom-knowledge/backups/*.bak`.

Gate before publication:

- Re-read latest battle summary.
- `git diff --check`.
- Confirm no stale active latest reference to a superseded battle artifact.

### Batch 2 - Battle/Hermes Runtime And Data Planner Tooling

Purpose: publish the reusable audit/runtime helpers that support deck, learned
deck, battle, and PostgreSQL governance.

Files/groups:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- `server/bin/canonicalize_learned_deck_metadata.dart`
- `server/bin/plan_learned_deck_partner_identity_backfill.py`
- `server/bin/plan_lorehold_critical_role_backfill.py`
- `server/bin/plan_oracle_text_backfill.py`
- `server/bin/learned_deck_coherence_audit.py`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- Python planner/auditor tests.

Gate before publication:

- `python3 -m unittest discover -s server/test -p '*_test.py' -v`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`.
- `cd server && dart run bin/migrate.dart --status`.
- Read-only PG planner/postcheck suite for PG-001/PG-002/PG-003/PG-005/PG-006/PG-007/PG-008.

### Batch 3 - Backend Deck/API/AI Source

Purpose: publish backend product behavior after the audit tooling and docs are
anchored.

Files/groups:

- `server/lib/deck_*`
- `server/lib/import_*`
- `server/lib/ai/**`
- `server/routes/ai/**`
- `server/routes/decks/**`
- `server/routes/import/**`
- `server/routes/cards/resolve/batch/index.dart`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- backend Dart tests under `server/test/**`.

Gate before publication:

- `cd server && dart analyze`.
- `cd server && dart test`.
- Anti-fanout source scan: product deck row reads must use
  `card_intelligence_snapshot` or aggregate multi-row intelligence by `card_id`.
- No PostgreSQL apply unless a separate exact package is prepared and validated.

### Batch 4 - Flutter Deck App Source

Purpose: publish the app deck provider/UI behavior after backend contracts are
stable.

Files/groups:

- `app/lib/features/decks/providers/**`
- `app/lib/features/decks/screens/deck_details_screen.dart`
- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/lib/features/decks/widgets/deck_*`
- app deck tests under `app/test/features/decks/**`.

Gate before publication:

- `cd app && flutter analyze`.
- `cd app && flutter test`.
- If this becomes release-bound, add real-device/simulator deck flow validation:
  create/import -> analyze -> optimize -> apply -> validate.

### Batch 5 - Post-Publication Integration Gate

Purpose: prove the published source and live runtime still agree.

Run only after an explicit commit/push/deploy decision.

Required checks:

- `git rev-list --left-right --count HEAD...origin/master`.
- Public `/health` must report the pushed SHA or expected deployed descendant.
- Full app/backend tests again if the batch content changed after this plan.
- Fresh battle audit with `--seeds 16`.
- PostgreSQL deploy register heartbeat.
- Hermes post-push audit if a push is performed.

## Current Non-Release Risks

- PG-003 oracle/card text/type backlog remains policy-blocked with
  `backfill_ready=0`; no apply should be attempted until official blank-text,
  Arena/Alchemy alias, and reprint policy is explicit.
- Dirty local code is validated locally but not deployed.
- Live OpenAI request behavior is not proven in this cycle.
- Real-device Flutter flow is not proven in this cycle.
- Battle `latest` can drift after future recurring runs; always reread
  `latest/summary.json` before using it as readiness evidence.

## Recommended Next Action

Prepare Batch 0 + Batch 1 for review first, without staging automatically.
That publishes the audit trail and prevents future confusion before product code
is split into backend/app batches.

## Batch 0/1 Readiness Check - 2026-06-20 13:12 -0300

Status: `ready_for_explicit_stage_approval`, not staged and not committed.

Evidence captured:

- `git diff --check`: clean.
- Latest battle realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`.
- Latest battle status:
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  `forensic_lineage_status=complete`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, and `test_results_status_counts={'pass': 16}`.
- Worktree evidence at checkpoint:
  `73` tracked modified files, `75` untracked files, shortstat
  `73 files changed, 24752 insertions(+), 2022 deletions(-)`.

Execution boundary:

- Batch 0/1 can be staged only after Rafael explicitly says to stage/commit the
  batch.
- Until then, this thread will keep validating and reconciling the files without
  changing Git index state.

## Publication Branch Observation - 2026-06-20 13:28 -0300

The Batch 0/1 readiness section above is historical checkpoint evidence from
before staging/publication. At the 13:28 heartbeat, before the later `master`
migration closure, the workspace observation was:

- branch: `codex/manaloom-batches-20260620`
- upstream alignment: `git rev-list --left-right --count HEAD...@{upstream}`
  returned `0 0`
- worktree state: `git status --porcelain=v1` returned `0` rows
- current branch commits above `origin/master`:
  - `9ffe002b docs: publish ManaLoom audit evidence batch`
  - `7310111f chore: add ManaLoom audit tooling batch`
  - `764a3255 feat: harden ManaLoom deck backend flows`
  - `ca939026 feat: refine deck app flows`

This heartbeat only reconciled and documented the observed state. It did not
stage, commit, push, apply PostgreSQL, apply a deck swap, clean files, stash, or
revert anything. This 13:28 observation is superseded by the later central
register evidence that `master` was fast-forwarded to `ca939026` and production
health reported that SHA.

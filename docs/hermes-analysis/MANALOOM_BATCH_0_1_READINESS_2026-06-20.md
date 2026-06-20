# ManaLoom Batch 0/1 Readiness - 2026-06-20

Owner: Auditor Central / single operator
Status: ready for explicit stage approval, not staged and not committed
Checkpoint: 2026-06-20 13:12 -0300

## Purpose

This manifest isolates the first publication boundary for the dirty worktree.
It does not authorize `git add`, commit, push, deploy, deck swap, cleanup, or a
new PostgreSQL write.

## Evidence

- `git diff --check`: clean.
- Worktree checkpoint before this manifest was added:
  `73` tracked modified files, `75` untracked files, and
  `73 files changed, 24752 insertions(+), 2022 deletions(-)`.
- Latest battle artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`.
- Latest battle status:
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  `forensic_lineage_status=complete`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, and `test_results_status_counts={'pass': 16}`.
- PostgreSQL position: no current apply is ready; PG-003 remains
  policy-blocked and PG-005 remains no-apply-needed.

## Batch 0

Purpose: local evidence hygiene.

Files:

- `.gitignore`

Reason:

- Adds `docs/hermes-analysis/manaloom-knowledge/backups/*.bak` so local SQLite
  recovery backups remain on disk but stay outside the publication queue.

## Batch 1

Purpose: publish audit, PostgreSQL, Battle, Lorehold, and worktree evidence
before app/backend product code.

Files:

- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`
- `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
- `docs/hermes-analysis/MANALOOM_BATCH_0_1_READINESS_2026-06-20.md`
- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_ORDERS.md`
- `docs/hermes-analysis/MANALOOM_PUBLICATION_BATCH_PLAN_2026-06-20.md`
- `docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md`
- `docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md`
- `docs/hermes-analysis/WORKTREE_FILE_OWNERSHIP_INDEX_2026-06-20.md`
- `docs/hermes-analysis/WORKTREE_OPERATIONAL_MAP_2026-06-20.md`
- `docs/hermes-analysis/WORKTREE_TRIAGE_REGISTER_2026-06-20.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql`
- `docs/hermes-analysis/master_optimizer_reports/deck_builder_lorehold_flow_learning_log_20260619.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_apply_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_postcheck_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_precheck_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_rollback_20260620_063349.sql`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_005219.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_095139_post_pg001_audit_fix.json`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_package_20260620_1018.md`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql`
- `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_apply_20260620_1210.sql`
- `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_package_20260620_1210.md`
- `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_postcheck_20260620_1210.sql`
- `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_precheck_20260620_1210.sql`
- `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_rollback_20260620_1210.sql`

## Excluded From Batch 0/1

- App source and app tests under `app/`.
- Backend source, routes, scripts, and tests under `server/`.
- Battle/Hermes runtime script changes under
  `docs/hermes-analysis/manaloom-knowledge/scripts/`.
- Local SQLite backups under
  `docs/hermes-analysis/manaloom-knowledge/backups/*.bak`.

## Future Stage Command

This command is intentionally not executed by this manifest. Run only after
explicit Rafael approval to stage Batch 0/1:

```bash
git add -- .gitignore \
  docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md \
  docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md \
  docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md \
  docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md \
  docs/hermes-analysis/MANALOOM_BATCH_0_1_READINESS_2026-06-20.md \
  docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md \
  docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_ORDERS.md \
  docs/hermes-analysis/MANALOOM_PUBLICATION_BATCH_PLAN_2026-06-20.md \
  docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md \
  docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md \
  docs/hermes-analysis/WORKTREE_FILE_OWNERSHIP_INDEX_2026-06-20.md \
  docs/hermes-analysis/WORKTREE_OPERATIONAL_MAP_2026-06-20.md \
  docs/hermes-analysis/WORKTREE_TRIAGE_REGISTER_2026-06-20.md \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.json \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md \
  docs/hermes-analysis/master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md \
  docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json \
  docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json \
  docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json \
  docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql \
  docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md \
  docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql \
  docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql \
  docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql \
  docs/hermes-analysis/master_optimizer_reports/deck_builder_lorehold_flow_learning_log_20260619.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_apply_20260620_063349.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_postcheck_20260620_063349.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_precheck_20260620_063349.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_rollback_20260620_063349.sql \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_005219.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_095139_post_pg001_audit_fix.json \
  docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql \
  docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_package_20260620_1018.md \
  docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql \
  docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql \
  docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql \
  docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_apply_20260620_1210.sql \
  docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_package_20260620_1210.md \
  docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_postcheck_20260620_1210.sql \
  docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_precheck_20260620_1210.sql \
  docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_rollback_20260620_1210.sql
```

## Result

Batch 0/1 is ready for explicit staging approval. Product code remains outside
this batch and must be handled by later backend/app batches.

## Post-Readiness Observation - 2026-06-20 13:28 -0300

This readiness manifest is now historical checkpoint evidence. Git state
observed at the 13:28 heartbeat before the later `master` migration closure:

- `git status --short --branch`:
  `## codex/manaloom-batches-20260620...origin/codex/manaloom-batches-20260620`
- `git status --porcelain=v1 | wc -l`: `0`
- `git rev-list --left-right --count HEAD...@{upstream}`: `0 0`
- Current publication branch commits:
  `9ffe002b`, `7310111f`, `764a3255`, and `ca939026`

The heartbeat that wrote this note did not stage, commit, push, clean files,
revert, stash, apply PostgreSQL, or apply a deck swap. This 13:28 observation
was later superseded by the central/deploy-register evidence that `master` was
fast-forwarded to `ca939026`.

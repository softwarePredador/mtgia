# PG137 Current Replay Manual-Model Shadow Cleanup

Status: `generated_not_applied`.

Goal:

- re-enable the reviewed curated rows for:
  - `Everflowing Chalice`
  - `Vexing Bauble`
  - `Soul-Guide Lantern`
- deprecate the stale active XMage `manual_model` shadows that are still surfacing as `batch_pg_candidate_after_precheck` after the runtime fix.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg137_current_replay_manual_model_shadow_cleanup_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg137_current_replay_manual_model_shadow_cleanup_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg137_current_replay_manual_model_shadow_cleanup_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg137_current_replay_manual_model_shadow_cleanup_postcheck.sql`

Required sequence:

1. run precheck
2. run apply
3. run postcheck
4. sync PG -> SQLite with `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
5. rerun focused tests and the real battle strategy audit
6. rerun `xmage_current_replay_batch_pipeline.py` on the fresh audit artifact

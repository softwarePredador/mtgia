# pg260 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals and later applied under the approved PostgreSQL workflow.

- Generated at: `2026-06-29T17:25:00+00:00`
- Selected cards: `["Cursed Mirror"]`
- Families: `{"ramp_permanent": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_package.md`

Apply gate:

- Approval received in-thread for this package.
- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, runtime lookup probe, focused/family tests, queue rebuild, strategy audit.

Evidence:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_1755_precheck.out`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_1755_apply.out`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_1755_postcheck.out`
- Sync: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg260_cursed_mirror_exact_runtime_20260629_1756.json`
- Runtime probe: `docs/hermes-analysis/master_optimizer_reports/pg260_cursed_mirror_exact_runtime_20260629_1756_get_card_effect_probe.json`
- Queue rebuild: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1757_post_pg260_cursed_mirror_exact_runtime_manifest.json`
- Strategy audit: `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260629_1758_post_pg260_cursed_mirror_exact_runtime.json`

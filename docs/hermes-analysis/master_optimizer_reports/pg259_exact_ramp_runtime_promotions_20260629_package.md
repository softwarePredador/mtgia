# pg259 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals and later applied under the approved PostgreSQL workflow.

- Generated at: `2026-06-29T17:02:36+00:00`
- Selected cards: `["Bridgeworks Battle", "Hydroelectric Specimen", "Selvala, Heart of the Wilds", "Devoted Druid", "Birgi, God of Storytelling", "Fractured Powerstone", "Incubation Druid", "Delighted Halfling"]`
- Families: `{"ramp_engine": 1, "ramp_permanent": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_package.md`

Apply gate:

- Approval received in-thread for this package.
- Completed sequence: precheck, apply, postcheck, metadata repair, PG -> SQLite sync, runtime lookup probe, focused/family tests, queue rebuild, strategy audit.

Evidence:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_1702_precheck.out`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_1702_apply.out`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_1702_postcheck.out`
- Deck role repair: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_deck_role_repair_1718_postcheck.out`
- Sync: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg259_exact_ramp_runtime_promotions_20260629_1725_resync_after_deck_role_repair.json`
- Runtime probe: `docs/hermes-analysis/master_optimizer_reports/pg259_exact_ramp_runtime_promotions_20260629_1725_get_card_effect_probe.json`
- Queue rebuild: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1728_post_pg259_exact_ramp_runtime_promotions_manifest.json`
- Strategy audit: `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260629_1729_post_pg259_exact_ramp_runtime.json`

# PG258 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals and applied after focused runtime tests, PostgreSQL precheck/postcheck, PG -> SQLite sync, direct runtime probe, and queue rebuild.

- Generated at: `2026-06-29T16:46:00+00:00`
- Selected cards: `["Reckless Handling", "Demonic Counsel", "Scour for Scrap", "Summoner's Pact", "Cloud of Faeries", "Grinding Station"]`
- Families: `{"mill_spell": 1, "modal_spell": 1, "tutor": 3, "untap_land_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg258_candidate_template_runtime_promotions_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg258_candidate_template_runtime_promotions_20260629_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg258_candidate_template_runtime_promotions_20260629_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg258_candidate_template_runtime_promotions_20260629_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg258_candidate_template_runtime_promotions_20260629_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg258_candidate_template_runtime_promotions_20260629_package.md`

Executed sequence:

- precheck: `pg258_candidate_template_runtime_promotions_20260629_1647_precheck.out`
- apply: `pg258_candidate_template_runtime_promotions_20260629_1647_apply.out`
- postcheck: `pg258_candidate_template_runtime_promotions_20260629_1647_postcheck.out`
- sync: `battle_card_rules_sqlite_from_pg_pg258_candidate_template_runtime_promotions_20260629_1647.json`
- runtime probe: `pg258_candidate_template_runtime_promotions_20260629_1647_get_card_effect_probe.json`
- tests: `pg258_candidate_template_runtime_promotions_20260629_1647_runtime_tests_postsync.out`
- post-sync queue: `xmage_current_replay_batch_pipeline_20260629_164805_post_pg258_candidate_template_runtime_promotions_manifest.json`

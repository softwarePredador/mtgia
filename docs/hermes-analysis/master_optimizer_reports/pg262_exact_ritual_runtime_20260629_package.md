# pg262 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals, applied to PostgreSQL
with prior approval in the active scope, synced to Hermes/SQLite, and validated
end to end.

- Generated at: `2026-06-29T17:43:51+00:00`
- Selected cards: `["Mana Geyser", "Burnt Offering"]`
- Families: `{"ramp_ritual": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_package.md`

Apply gate:

- Precheck/apply/postcheck were executed for `Mana Geyser` and `Burnt Offering`.
- PostgreSQL rows promoted: `2`.
- Deprecated shadow rows: `3`.
- PG -> SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg262_exact_ritual_runtime_20260629_1744.json`.
- Runtime probe:
  `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_1744_get_card_effect_probe.json`.
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_e2e_validation.md`.
- Post-sync queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1746_post_pg262_exact_ritual_runtime_manifest.md`.

Validation summary:

- `Mana Geyser`: exact runtime scope
  `add_red_for_each_tapped_land_opponents_control_v1`; sample runtime counted
  `3` tapped opponent lands and produced `3` red mana.
- `Burnt Offering`: exact runtime scope
  `sacrifice_creature_add_black_or_red_equal_sacrificed_mana_value_v1`;
  payment check passed and sacrificed CMC `4` produced `4` mana.
- E2E stages passed: PostgreSQL source of truth, SQLite Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and battle execution
  no-override.

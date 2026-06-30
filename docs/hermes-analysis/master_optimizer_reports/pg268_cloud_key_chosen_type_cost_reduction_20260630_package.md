# pg268_cloud_key_chosen_type_cost_reduction_20260630 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. The builder itself did
not execute SQL; the approved precheck/apply/postcheck/sync cycle was executed
after package generation.

- Generated at: `2026-06-30T06:47:20+00:00`
- Selected cards: `["Cloud Key"]`
- Families: `{"static_cost_reducer": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_package.md`

Apply gate:

- Completed. Precheck found one canonical `Cloud Key` card row, two existing
  rule rows, zero matching promoted rule rows, and two shadow rows to
  deprecate.
- Apply committed with `deprecated_shadow_rows=2` and `upserted_rows=1`.
- Postcheck verified one promoted verified/auto row with Oracle hash
  `19792b44d184aed6b5b075cfa5c0cbe4` and logical key
  `battle_rule_v1:797349f2d8c0cc961e0c0c1611b9beb6`.
- PG -> SQLite sync loaded one PostgreSQL rule and updated three local SQLite
  rows, then exported the canonical fallback snapshot.
- E2E validation passed across PostgreSQL, SQLite, canonical snapshot, and
  runtime `get_card_effect`.
- Runtime no-override probe passed: synced `Cloud Key` chose `instant`, reduced
  `Big Score` generic cost by one, and did not reduce `Sun Titan`.

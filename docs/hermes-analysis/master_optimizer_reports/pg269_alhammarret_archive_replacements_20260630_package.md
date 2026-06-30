# pg269_alhammarret_archive_replacements_20260630 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. The builder itself did
not execute SQL; the approved precheck/apply/postcheck/sync cycle was executed
after package generation.

- Generated at: `2026-06-30T06:59:50+00:00`
- Selected cards: `["Alhammarret's Archive"]`
- Families: `{"draw_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg269_alhammarret_archive_replacements_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg269_alhammarret_archive_replacements_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg269_alhammarret_archive_replacements_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg269_alhammarret_archive_replacements_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg269_alhammarret_archive_replacements_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg269_alhammarret_archive_replacements_20260630_package.md`

Apply gate:

- Completed. Precheck found one canonical `Alhammarret's Archive` card row,
  two existing rule rows, zero matching promoted rule rows, and two shadow rows
  to deprecate.
- Apply committed with `deprecated_shadow_rows=2` and `upserted_rows=1`.
- Postcheck verified one promoted verified/auto row with Oracle hash
  `88427c5aaa2391a1419a4e79a3690e4a` and logical key
  `battle_rule_v1:b865a68cb5efcaf543f5ceda5d9ed599`.
- PG -> SQLite sync loaded one PostgreSQL rule and updated three local SQLite
  rows, then exported the canonical fallback snapshot.
- E2E validation passed across PostgreSQL, SQLite, canonical snapshot, and
  runtime `get_card_effect`.
- Runtime no-override probe passed: synced `Alhammarret's Archive` entered
  without drawing, doubled 3 life gain into 6, preserved the first draw-step
  draw as one card, and doubled later draw events.

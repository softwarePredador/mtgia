# pg270_currency_converter_draw_engine_20260630 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. The builder itself did
not execute SQL; the approved precheck/apply/postcheck/sync cycle was executed
after package generation.

- Generated at: `2026-06-30T07:32:07+00:00`
- Selected cards: `["Currency Converter"]`
- Families: `{"draw_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg270_currency_converter_draw_engine_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg270_currency_converter_draw_engine_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg270_currency_converter_draw_engine_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg270_currency_converter_draw_engine_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg270_currency_converter_draw_engine_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg270_currency_converter_draw_engine_20260630_package.md`

Apply gate:

- Completed. Precheck found one canonical `Currency Converter` card row, two
  existing rule rows, zero matching promoted rule rows, and two shadow rows to
  deprecate.
- Apply committed with `deprecated_shadow_rows=2` and `upserted_rows=1`.
- Postcheck verified one promoted verified/auto row with Oracle hash
  `61871a4bb30c2b48607cee649e2812aa` and logical key
  `battle_rule_v1:f1e1192b52ed56e41a07b33e311bd313`.
- PG -> SQLite battle-rule sync loaded one PostgreSQL rule and updated three
  local SQLite rows, then exported the canonical fallback snapshot.
- E2E validation passed across PostgreSQL, SQLite, canonical snapshot, and
  runtime `get_card_effect`.
- Runtime probe passed: the controller discarded a land, `Currency Converter`
  exiled it from the graveyard, then the activated ability moved it back to
  graveyard and created one Treasure.

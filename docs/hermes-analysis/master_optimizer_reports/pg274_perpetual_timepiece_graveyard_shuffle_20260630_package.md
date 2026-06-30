# PG274 Perpetual Timepiece Graveyard Shuffle Runtime Package

Status: `applied_synced`.

This package promotes `Perpetual Timepiece` from generated review-only rows to
an exact curated runtime rule backed by local XMage source and a focused
ManaLoom runtime test.

- Generated at: `2026-06-30T10:20:00Z`
- Selected cards: `["Perpetual Timepiece"]`
- Local XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/p/PerpetualTimepiece.java`
- Exact scope:
  `tap_self_mill_two_or_exile_self_shuffle_any_number_graveyard_cards_into_library_v1`
- Logical rule key:
  `battle_rule_v1:26cffda59616c27dd2e137e165dc2d5d`
- Oracle hash:
  `4af52424df5fb9a51bff3fddb1c5c1ff`
- Focused runtime test:
  `battle_card_specific_tests.py --filter test_pg274_perpetual_timepiece_self_mills_or_exiles_to_shuffle_graveyard`

Files:

- precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_precheck.sql`
- apply:
  `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_apply.sql`
- rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_rollback.sql`
- postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_postcheck.sql`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_manifest.json`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_package.md`

Apply result:

- Precheck: `target_card_rows=1`, `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`.
- Apply: `backup_rows=2`, `deprecated_shadow_rows=2`, `upserted_rows=1`.
- Postcheck: promoted rule/hash/scope `1/1`, active runtime rows `1`,
  deprecated disabled rows `2`.
- Sync: `pg_rows_loaded=3`, `sqlite_inserted_or_updated=3`,
  canonical snapshot rows `3285`.

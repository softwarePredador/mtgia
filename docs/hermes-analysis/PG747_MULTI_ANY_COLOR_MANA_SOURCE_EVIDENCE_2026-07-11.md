# PG747 Multi Any-Color Mana Source Evidence - 2026-07-11

Status: `applied_synced_validated`

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## Scope

PG747 promotes exact XMage-backed multi-mana "any one color" mana sources that
the ManaLoom runtime already models as tap mana sources.

Promoted cards:

- `Gilded Lotus`: `{T}: Add three mana of any one color.`
- `Somberwald Sage`: `{T}: Add three mana of any one color. Spend this mana
  only to cast creature spells.`
- `Transdimensional Bovine`: `Flying` plus `{T}: Add two mana of any one color.`

The exact split report found 15 candidate mana-source rows, but only the 3
fully covered rows above were packaged. The remaining partial
`mana_source_only` rows stay out of PostgreSQL promotion until their auxiliary
abilities/effects have a safe runtime contract.

## Runtime/Parser Change

`xmage_authoritative_exact_scope_split.py` now calls the existing generic simple
mana parser from the normal simple mana-source line path. This unlocks exact
parsing for Oracle/source lines such as:

- `{T}: Add two mana of any one color.`
- `{T}: Add three mana of any one color.`

Focused coverage added:

- `test_simple_mana_source_maps_multiple_any_one_color_mana`

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg747_multi_any_color_mana_source_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg747_multi_any_color_mana_source_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg747_multi_any_color_mana_source_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg747_multi_any_color_mana_source_package_rollback.sql`

Precheck:

- target rows: `3`
- existing exact rows before apply: `0`
- shadow rows to deprecate: `2` for `Gilded Lotus`

Apply/postcheck:

- upserted rows: `3`
- deprecated shadow rows: `2`
- promoted verified/auto rows: `3`
- promoted rows with Oracle hash: `3`

## Integrity Backfill

The PG/Hermes/SQLite audit exposed existing trusted executable curated rows
without `oracle_hash`. A separate PG747 integrity package filled only the hash
field from `md5(cards.oracle_text)` through `card_id`; it did not change
runtime effects, rule keys, review status, or execution status.

Integrity package files:

- `docs/hermes-analysis/master_optimizer_reports/pg747_oracle_hash_integrity_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg747_oracle_hash_integrity_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg747_oracle_hash_integrity_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg747_oracle_hash_integrity_backfill_new_server_rollback.sql`

Backfill evidence:

- trusted executable rows missing `oracle_hash` before: `55`
- matched `cards.card_id` rows: `55`
- backfilled rows: `55`
- trusted executable rows missing `oracle_hash` after: `0`
- backup rows: `55`
- sampled postcheck hashes matched current `cards.oracle_text` md5.

## Sync

After PG747 apply:

- `pg_rows_loaded`: `6372`
- `sqlite_inserted_or_updated`: `6367`
- `canonical_snapshot_rows_exported`: `6321`
- metadata sync matched PostgreSQL cards: `7460`
- SQLite cache alias rows: `7382`

After integrity backfill:

- `pg_rows_loaded`: `6372`
- `sqlite_inserted_or_updated`: `6367`
- `canonical_snapshot_rows_exported`: `6321`
- metadata sync matched PostgreSQL cards: `7463`
- SQLite cache alias rows: `7385`

## E2E

Final E2E report:

- `docs/hermes-analysis/master_optimizer_reports/pg747_multi_any_color_mana_source_e2e_after_hash_backfill_report.json`
- status: `pass`
- stages passed:
  - PostgreSQL source of truth
  - SQLite/Hermes cache
  - canonical snapshot fallback
  - runtime `get_card_effect`
  - battle execution

Battle execution:

- `Gilded Lotus`: `available_mana=3`, tapped after activation
- `Somberwald Sage`: `available_mana=3`, restricted mana runtime metadata,
  tapped after activation
- `Transdimensional Bovine`: `available_mana=2`, tapped after activation

## Readiness And Queue

Final readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg747_multi_any_color_mana_source_after_hash_new_server.json`

Final readiness summary:

- all known cards: `34331`
- `battle_and_oracle_ready`: `6421`
- `snapshot_has_verified_rule`: `6446`
- `battle_family_mapper_required`: `27455`
- `generic_runtime_or_no_card_rule`: `359`
- `trusted_rule_oracle_hash_backfill`: `0`

Final XMage authoritative queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg747_multi_any_color_mana_source_after_hash_commander_legal.json`

Queue summary:

- target identity count: `24532`
- XMage authoritative source count: `24219`
- local XMage missing-source exceptions: `313`
- parser gaps: `0`
- XMage authoritative adapter required: `24219`
- adapter work-unit count: `11292`

## Tests And Audits

Tests:

- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  - `1478` tests passed
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`
  - `293` tests passed
- `python3 -m py_compile` for the splitter, package builder, and E2E validator:
  pass

Final audits after PG747 and integrity backfill:

- XMage strategy consistency: `26/26 pass`
- operational surface alignment: `pass`
- PG/Hermes/SQLite contract: `51/51 pass`
- legacy contamination: `pass`

## Next Work

The next global work should continue from:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg747_multi_any_color_mana_source_after_hash_commander_legal.json`

The largest remaining work units are still review scopes that need exact
subpattern splitting before any executable PostgreSQL package:

- `recursion::xmage_graveyard_return_variant_review_v1`: `1792`
- `draw_engine::xmage_draw_card_variant_review_v1`: `1553`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`: `1064`
- `add_counters::source_add_counters_variant_v1`: `768`
- `direct_damage::targeted_damage_variant_v1`: `750`

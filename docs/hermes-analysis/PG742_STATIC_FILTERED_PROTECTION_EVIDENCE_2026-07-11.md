# PG742 Static Filtered Protection Evidence

Generated: 2026-07-11

## Scope

PG742 promoted the XMage exact-scope protection adapter for four Commander-legal cards:

- Enemy of the Guildpact: protection from multicolored.
- Guardian of the Guildpact: protection from monocolored.
- Mistmeadow Skulk: lifelink plus protection from mana value 3 or greater.
- Warren-Scourge Elf: protection from Goblins.

Runtime support added:

- `protection_from_color_profile=multicolored|monocolored` target blocking.
- `protection_from_mana_value_min` target blocking.
- E2E scenario generation and execution for filtered protection.
- E2E scenario generation and execution for subtype protection.

## PostgreSQL Apply

Primary package:

- Proposal report: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_new_server.json`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_manifest.json`
- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_rollback.sql`

Observed SQL results on `127.0.0.1:15432/halder`:

- Precheck: 4 target card rows, 0 existing package rows, 0 shadow rows to deprecate.
- Apply: 4 upserted rows, 0 deprecated shadow rows.
- Postcheck: 1 promoted verified/auto row per card, 4/4 Oracle hash matches.

## Contract Backfill

The PG/Hermes/SQLite audit exposed 55 older trusted executable PostgreSQL rules without `oracle_hash`. These were not part of the four-card adapter, but they violated the current contract.

Backfill package:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg742_trusted_rule_oracle_hash_backfill_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg742_trusted_rule_oracle_hash_backfill_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg742_trusted_rule_oracle_hash_backfill_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg742_trusted_rule_oracle_hash_backfill_rollback.sql`

Observed SQL results:

- Precheck: 55 missing hashes, 0 missing `card_id`, 0 unmatched `card_id`, 0 empty Oracle text, 55 safe backfill rows.
- Apply: 55 rows backfilled from `md5(cards.oracle_text)`.
- Postcheck: `trusted_executable_rules_missing_oracle_hash=0`, backup rows=55.

## Sync And Validation

Sync reports:

- PG742 focused battle-rule sync: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_sync_battle_rules_report.json`
- PG card metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_sync_pg_card_metadata_report.json`
- Full battle-rule sync after hash backfill: `docs/hermes-analysis/master_optimizer_reports/pg742_trusted_rule_oracle_hash_backfill_sync_battle_rules_report.json`

Observed sync results:

- Focused PG -> SQLite sync loaded 4 PG rows and updated 4 SQLite rows.
- Metadata sync target was `127.0.0.1:15432/halder`; `deck_cards` backfill matched 2699/2699 and updated 108 `card_id` values.
- Full PG -> SQLite sync loaded 6356 PG rows and inserted/updated 6351 SQLite rows.

Focused tests passed:

- `test_xmage_authoritative_exact_scope_split.py -k static_protection`: 14 tests.
- `test_xmage_exact_scope_runtime.py -k static_filtered_protection`: 1 test.
- `test_xmage_batch_pg_package_builder.py -k "static_filtered_protection or static_subtype_protection"`: 2 tests.
- `test_battle_package_end_to_end_validation.py -k "static_filtered_protection or static_subtype_protection"`: 2 tests.

Final E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_e2e_after_full_sync_report.json`
- Status: pass.
- Validated stages: PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, battle execution.
- Battle scenarios: 4/4.

Final audits:

- PG/Hermes/SQLite contract: `docs/hermes-analysis/master_optimizer_reports/pg742_after_oracle_hash_backfill_pg_hermes_sqlite_contract_audit.md`, pass 51/51.
- Operational surface alignment: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_operational_surface_alignment_audit.md`, pass.
- Legacy contamination: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_legacy_contamination_audit.md`, pass.
- XMage strategy consistency: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_xmage_strategy_consistency_audit.md`, pass 26/26.

## Final Counters

Readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg742_after_oracle_hash_backfill.json`
- Total cards: 34,331.
- Snapshot cards with verified rule: 6,430.
- `battle_and_oracle_ready`: 6,405.
- `battle_family_mapper_required`: 27,471.
- `trusted_rule_oracle_hash_backfill`: cleared from active lane counts.

Commander-legal queue:

- Summary report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg742_after_oracle_hash_backfill_commander_legal.md`
- Raw JSON was generated locally but intentionally left ignored because it is a large machine artifact; the relevant counters are captured here.
- Target identity count: 24,548.
- XMage authoritative source count: 24,235.
- Missing XMage source exceptions: 313.
- Parser gaps: 0.
- Adapter-required count: 24,235.
- Adapter work units: 11,293.

Next largest work units remain recursion, draw engine, targeted protection from chosen color, add counters, targeted damage, life gain, tutor, draw cards, destroy removal, and targeted add counters.

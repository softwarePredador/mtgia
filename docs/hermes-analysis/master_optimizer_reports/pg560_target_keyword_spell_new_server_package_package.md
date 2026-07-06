# pg560_target_keyword_spell_new_server XMage Batch PostgreSQL Package

Status: `applied_postgresql_synced_validated`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T10:28:11+00:00`
- Selected cards: `["Alesha's Legacy", "Assault Strobe", "Battle-Rage Blessing", "Double Cleave", "Horrid Vigor", "Jump", "Offer Immortality", "Serpent's Gift", "Ticked Off", "Unnatural Speed"]`
- Families: `{"xmage_target_keyword_creature_until_eot_spell": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_package_package.md`

Apply evidence:

- PostgreSQL precheck passed for all `10` target cards.
- PostgreSQL apply upserted `10` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck confirmed `10/10` promoted rules, `10/10`
  verified/auto rows, and `10/10` oracle-hash matches.
- PG -> SQLite sync completed after apply.
- Package E2E passed through PostgreSQL, SQLite, canonical snapshot,
  runtime `get_card_effect`, and battle execution.

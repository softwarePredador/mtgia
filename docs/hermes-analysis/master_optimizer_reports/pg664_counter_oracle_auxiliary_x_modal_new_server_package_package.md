# pg664_counter_oracle_auxiliary_x_modal_new_server XMage Batch PostgreSQL Package

Status: `applied_to_new_server_pg_and_validated`.

This package was generated from XMage batch proposals. SQL apply was executed
separately against the new-server PostgreSQL target and validated with
precheck/apply/postcheck, PostgreSQL -> SQLite sync, package E2E, and final
alignment audits.

- Generated at: `2026-07-08T17:02:08+00:00`
- Selected cards: `["Broken Concentration", "Change the Equation", "Fervent Denial", "Neutralize", "Overwhelming Denial", "Spell Blast"]`
- Families: `{"xmage_counter_target_spell": 6}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg664_counter_oracle_auxiliary_x_modal_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg664_counter_oracle_auxiliary_x_modal_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg664_counter_oracle_auxiliary_x_modal_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg664_counter_oracle_auxiliary_x_modal_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg664_counter_oracle_auxiliary_x_modal_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg664_counter_oracle_auxiliary_x_modal_new_server_package_package.md`

Apply evidence:

- database target: `127.0.0.1:15432/halder`;
- precheck found `6` target rows, `0` existing expected rule rows, and `0`
  stale generated shadow rows to deprecate;
- apply upserted `6` promoted rows and deprecated `0` shadow rows;
- postcheck confirmed `6/6` promoted `verified/auto` rows with `oracle_hash`;
- PostgreSQL -> SQLite sync inserted/updated `6` package rows first, then a
  full post-hash-backfill sync exported `7063` canonical snapshot rows;
- package E2E passed PostgreSQL, SQLite/Hermes, canonical snapshot,
  `runtime_get_card_effect`, and `6` battle-execution scenarios.

# pg654 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-08T11:51:33+00:00`
- Selected cards: `["Calamitous Cave-In", "Chain Reaction", "Gates Ablaze", "Immolating Gyre", "Skyreaping"]`
- Families: `{"xmage_dynamic_damage_all_spell": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg654_dynamic_damage_wipe_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg654_dynamic_damage_wipe_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg654_dynamic_damage_wipe_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg654_dynamic_damage_wipe_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg654_dynamic_damage_wipe_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg654_dynamic_damage_wipe_new_server_package_package.md`

Applied result:

- precheck: `target_card_rows=1` for each selected card;
- apply: `deprecated_shadow_rows=4`, `upserted_rows=5`;
- postcheck: each selected card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`;
- sync: `pg_rows_loaded=5927`, `sqlite_inserted_or_updated=5913`,
  `canonical_snapshot_rows_exported=5890`;
- E2E: PostgreSQL, SQLite/Hermes, canonical snapshot, and
  `runtime_get_card_effect` validated all `5` selected cards.

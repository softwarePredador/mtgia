# PG309 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, then applied through the
approved evidence runner and synced from PostgreSQL to Hermes/SQLite.

- Generated at: `2026-07-01T13:56:15+00:00`
- Selected cards: `["Alchemist's Apprentice", "Arcane Encyclopedia", "Archivist", "Azure Mage", "Benalish Heralds", "Brass Secretary", "Courier's Capsule", "Eidolon of Philosophy", "Font of Fortunes", "Jayemdae Tome", "Mystic Archaeologist", "Oscorp Research Team", "Scepter of Insight", "Shore Keeper", "Third Path Savant", "Tower of Fortunes", "Treasure Trove", "Tymora's Invoker"]`
- Families: `{"xmage_permanent_simple_activated_draw": 18}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_package.md`
- PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_e2e_validation.md`

Evidence:

- PostgreSQL precheck: `18/18` target rows found, `0` expected rows already present, and `0` stale shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `18/18` promoted rule rows, `18/18` verified/auto rows, and `18/18` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `18` PostgreSQL rows, inserted/updated `18` SQLite rows, and exported `4530` canonical snapshot rows.
- E2E validation passed for PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Focused exact-scope tests passed: `136` tests in `test_xmage_authoritative_exact_scope_split.py` and `test_xmage_exact_scope_runtime.py`.
- Post-PG309 authoritative queue: `target_identity_count=27568`, `xmage_authoritative_source_count=27254`, `xmage_authoritative_adapter_required_count=27254`, `parser_gap=0`, and `xmage_missing_source_exception_count=314`.
- Post-PG309 supported splitter recheck returned `proposal_count=0` over `7396` considered supported rows.

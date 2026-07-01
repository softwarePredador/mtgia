# PG310 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, then applied through the
approved evidence runner and synced from PostgreSQL to Hermes/SQLite.

- Generated at: `2026-07-01T14:19:41+00:00`
- Selected cards: `["Aeolipile", "Aladdin's Ring", "Anaba Shaman", "Barbarian Lunatic", "Crackling Triton", "Ember Hauler", "Explosive Apparatus", "Flamecast Wheel", "Flamekin Spitfire", "Frostling", "Granite Shard", "Hatchet Bully", "Lightning-Core Excavator", "Mogg Fanatic", "Moonglove Extract", "Rod of Ruin", "Scalding Cauldron", "Seal of Fire", "Shock Troops", "Silent Dart", "Tower of Calamities", "Valakut Invoker", "Vial of Dragonfire"]`
- Families: `{"xmage_permanent_simple_activated_damage": 23}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_package.md`
- PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_e2e_validation.md`

Evidence:

- PostgreSQL precheck: `23/23` target rows found, `0` expected rows already present, and `0` stale shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `23/23` promoted rule rows, `23/23` verified/auto rows, and `23/23` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `6946` PostgreSQL rules, inserted/updated `6740` SQLite rows, and exported `4553` canonical snapshot rows.
- E2E validation passed for PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Focused exact-scope tests passed: `143` tests in `test_xmage_authoritative_exact_scope_split.py` and `test_xmage_exact_scope_runtime.py`.
- Post-PG310 authoritative queue: `target_identity_count=27545`, `xmage_authoritative_source_count=27231`, `xmage_authoritative_adapter_required_count=27231`, `parser_gap=0`, and `xmage_missing_source_exception_count=314`.
- Post-PG310 supported splitter recheck returned `proposal_count=0` over `7373` considered supported rows.

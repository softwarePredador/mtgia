# PG531 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T21:33:40+00:00`
- Selected cards: `["Anaba Spirit Crafter", "Bad Moon", "Blade Sliver", "Bonesplitter Sliver", "Dampening Pulse", "Dread of Night", "Earth Surge", "Illness in the Ranks", "Kaervek, the Spiteful", "Might Sliver", "Muscle Sliver", "Night of Souls' Betrayal", "Plated Sliver", "Sinew Sliver", "Stronghold Taskmaster", "Urborg Shambler", "Virulent Plague", "Watcher Sliver"]`
- Families: `{"xmage_static_global_power_toughness_boost": 18}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

# PG506 XMage Batch PostgreSQL Package

Status: `applied_postcheck_synced_validated`.

This package was generated from XMage batch proposals and applied after
explicit authorization.

- Generated at: `2026-07-05T12:42:20+00:00`
- Selected cards: `["Ogre Siegebreaker", "Opportunist", "Witch's Mist"]`
- Families: `{"xmage_permanent_simple_activated_damage": 1, "xmage_permanent_simple_activated_destroy_target": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_package.md`

Apply gate:

- Applied with precheck, apply, postcheck, PG -> SQLite sync, focused tests,
  full suite, governance audits, and affected deck coherence audit.
- Apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg506_activated_damaged_creature_target_new_server_apply_evidence.md`.

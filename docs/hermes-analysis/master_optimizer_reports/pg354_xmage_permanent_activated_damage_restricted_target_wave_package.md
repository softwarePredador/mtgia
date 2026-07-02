# PG354 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T05:16:36+00:00`
- Selected cards: `["Centaur Archer", "Chandra's Magmutt", "Crossbow Infantry", "D'Avenant Archer", "Duergar Assailant", "Elite Archers", "Expendable Troops", "Flamewave Invoker", "Font of Ire", "Goblin Fireslinger", "Grapeshot Catapult", "Heavy Ballista", "Lady Caleria", "Sacellum Archers", "Scalding Devil", "Soldier Replica", "Telim'Tor's Darts", "Tor Wauki", "Viridian Scout", "Volcanic Rambler", "Vulshok Replica", "War-Torch Goblin"]`
- Families: `{"xmage_permanent_simple_activated_damage": 22}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

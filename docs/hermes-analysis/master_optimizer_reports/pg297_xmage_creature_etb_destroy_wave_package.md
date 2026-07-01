# PG297 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, and validated end to end.

- Generated at: `2026-07-01T10:47:34+00:00`
- Selected cards: `["Batterhorn", "Conclave Naturalists", "Enlightened Ascetic", "Goblin Settler", "Indrik Stomphowler", "Manic Vandal", "Meteor Golem", "Monk Realist", "Ogre Arsonist", "Oxidda Scrapmelter", "Rambunctious Mutt", "Ravaging Horde", "Ravenous Chupacabra", "Reclamation Sage", "Uktabi Orangutan", "Viridian Shaman", "Vithian Renegades", "War Priest of Thune", "Wild Celebrants"]`
- Families: `{"xmage_creature_etb_destroy_target": 19}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_package.md`

Apply/sync/E2E result:

- PostgreSQL precheck: `19/19` target rows found, `0` expected rows already
  present, `4` shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `19/19` promoted rows, `19/19` verified/auto,
  `19/19` matching Oracle hash, and `4` backup rows.
- PG -> Hermes/SQLite sync: `19` PostgreSQL rows loaded, `23` SQLite rows
  inserted/updated including deprecated shadow rows, and `4303` canonical
  snapshot rows exported.
- E2E validation: PostgreSQL `19/19`, SQLite `19/19`, canonical snapshot
  `19/19`, and runtime `get_card_effect` `19/19`.

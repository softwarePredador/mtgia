# PG483 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T05:09:12+00:00`
- Selected cards: `["Blessed Spirits", "Boar-q-pine", "Deeproot Champion", "Electrostatic Infantry", "Kurgadon", "Lurking Lizards", "Mage Tower Referee", "Pyre Hound", "Pyroceratops", "Quirion Dryad", "Spellgorger Weird", "Sprite Dragon", "Stormkeld Prowler", "Tempest Angler"]`
- Families: `{"xmage_spell_cast_add_counters_source": 14}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg483_spell_cast_add_counters_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg483_spell_cast_add_counters_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg483_spell_cast_add_counters_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg483_spell_cast_add_counters_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg483_spell_cast_add_counters_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg483_spell_cast_add_counters_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

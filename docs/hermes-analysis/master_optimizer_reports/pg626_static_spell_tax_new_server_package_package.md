# pg626 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T16:52:27+00:00`
- Selected cards: `["Chill", "Feroz's Ban", "Geist-Fueled Scarecrow", "Glowrider", "High Seas", "Irini Sengir", "Lodestone Golem", "Sphere of Resistance", "Squeeze", "Thorn of Amethyst", "Vryn Wingmare"]`
- Families: `{"xmage_static_generic_cost_increase_for_matching_spells": 11}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg626_static_spell_tax_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg626_static_spell_tax_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg626_static_spell_tax_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg626_static_spell_tax_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg626_static_spell_tax_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg626_static_spell_tax_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

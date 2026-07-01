# PG291 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T09:21:29+00:00`
- Selected cards: `["Aegis of the Heavens", "Antagonize", "Auger Spree", "Brute Force", "Bull Rush", "Dark Deed", "Dark Remedy", "Demon's Grasp", "Disfigure", "Disorient", "Eyes of the Beholder", "Fatal Fumes", "Feral Roar", "Fists of the Anvil", "Flatten", "Flowstone Infusion", "Giant Growth", "Grasp of Darkness", "Howling Fury", "Hydrosurge", "Infuriate", "Lash of Malice", "Lash of the Whip", "Last Gasp", "Might of Oaks", "Monstrous Growth", "Mutagenic Growth", "Overkill", "Phytoburst", "Pull Under", "Qilin's Blessing", "Scorpion's Sting", "Show of Valor", "Shrink", "Spatial Contortion", "Stab", "Strangling Spores", "Tar Snare", "Throttle", "Titanic Growth", "Wielding the Green Dragon", "Wring Flesh"]`
- Families: `{"xmage_boost_target_creature_until_eot_spell": 42}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

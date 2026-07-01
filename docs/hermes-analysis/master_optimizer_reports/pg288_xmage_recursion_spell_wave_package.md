# PG288 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T08:35:26+00:00`
- Selected cards: `["Argivian Find", "Auroral Procession", "Call to Mind", "Disentomb", "Dutiful Return", "D\u00e9j\u00e0 Vu", "Elven Cache", "Fight On!", "March of the Returned", "Morbid Plunder", "Nature's Spiral", "Raise Dead", "Recollect", "Reconstruction", "Regenesis", "Regrowth", "Relearn", "Return to Battle", "Ritual of Restoration", "Sage's Knowledge", "Soul Salvage", "Wildwood Rebirth"]`
- Families: `{"xmage_graveyard_to_hand_spell": 22}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

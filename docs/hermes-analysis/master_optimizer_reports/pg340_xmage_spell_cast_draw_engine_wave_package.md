# PG340 XMage Batch PostgreSQL Package

Status: `applied_with_evidence`.

This package was generated from XMage batch proposals. The builder itself did
not execute SQL; the package was applied afterward through the required
precheck/apply/postcheck/sync/E2E cycle.

- Generated at: `2026-07-02T00:06:36+00:00`
- Selected cards: `["Beast Whisperer", "Enchantress's Presence", "Jhoira, Weatherlight Captain", "Mesa Enchantress", "Primordial Sage", "Reki, the History of Kamigawa", "Satyr Enchanter", "Secrets of the Dead", "Sram, Senior Edificer", "Tanufel Rimespeaker", "Thunderous Snapper", "Vedalken Archmage", "Verduran Enchantress", "Whirlwind of Thought"]`
- Families: `{"xmage_spell_cast_draw_engine": 14}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_package.md`

Apply gate:

- Applied evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_pg_apply_evidence.md`
- E2E evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_e2e_validation.md`

# PG340 XMage Spell-Cast Draw Engine Wave PostgreSQL Apply Evidence

Status: `applied`.

Generated UTC: `2026-07-02T00:10:46Z`.

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_rollback.sql`

Precheck:

- Target rows found: `14/14`.
- Expected rows already present before apply: `0/14`.
- Stale shadow rows scheduled for deprecation: `16`.

Apply:

- Deprecated shadow rows: `16`.
- Upserted rows: `14`.

Postcheck:

| Card | Promoted rows | Verified/auto rows | Oracle hash rows |
| --- | ---: | ---: | ---: |
| `Beast Whisperer` | 1 | 1 | 1 |
| `Enchantress's Presence` | 1 | 1 | 1 |
| `Jhoira, Weatherlight Captain` | 1 | 1 | 1 |
| `Mesa Enchantress` | 1 | 1 | 1 |
| `Primordial Sage` | 1 | 1 | 1 |
| `Reki, the History of Kamigawa` | 1 | 1 | 1 |
| `Satyr Enchanter` | 1 | 1 | 1 |
| `Secrets of the Dead` | 1 | 1 | 1 |
| `Sram, Senior Edificer` | 1 | 1 | 1 |
| `Tanufel Rimespeaker` | 1 | 1 | 1 |
| `Thunderous Snapper` | 1 | 1 | 1 |
| `Vedalken Archmage` | 1 | 1 | 1 |
| `Verduran Enchantress` | 1 | 1 | 1 |
| `Whirlwind of Thought` | 1 | 1 | 1 |

Backup table rows: `16`.

Post-apply sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_pg_to_sqlite_sync.json`.
- PostgreSQL rows loaded: `7275`.
- SQLite rows inserted/updated from PostgreSQL: `7069`.
- Canonical snapshot rows exported: `4855`.

Focused tests:

- `test_xmage_authoritative_exact_scope_split.py`: `191` tests passed.
- `test_xmage_exact_scope_runtime.py`: `114` tests passed.

E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_e2e_validation.md`.
- PostgreSQL source of truth: `14/14`.
- SQLite Hermes cache: `14/14`.
- Canonical snapshot fallback: `14/14`.
- Runtime `get_card_effect`: `14/14`.

Alignment audits:

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
  with `26/26` checks passing.
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
  with status `pass`.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
  with status `pass`, `48` pass checks, and `1` known residual warning for
  old trusted executable rows missing Oracle hash.
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
  with status `pass`.

Global queue reduction:

- post-PG339 `xmage_authoritative_adapter_required_count`: `26916`.
- post-PG340 `xmage_authoritative_adapter_required_count`: `26902`.
- Reduction: `14`.
- post-PG339 `draw_engine::xmage_draw_card_variant_review_v1`: `1660`.
- post-PG340 `draw_engine::xmage_draw_card_variant_review_v1`: `1646`.
- Reduction: `14`.

Post-PG340 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg340_supported_recheck.md`.
- Proposal count: `0`.
- Considered supported work-unit rows: `7941`.

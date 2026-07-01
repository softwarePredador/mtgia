# PG308 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals and later promoted by the
master optimizer apply flow.

- Generated at: `2026-07-01T13:34:16+00:00`
- Selected cards: `["Arrows of Justice", "Asphyxiate", "Assassinate", "Blade Banish", "Bring to Trial", "Burning Oil", "Celestial Purge", "Cosmium Blast", "Death Stroke", "Divine Arrow", "Divine Verdict", "Doom Blade", "Dragon's Presence", "Epic Downfall", "Excoriate", "Expel", "Ghostly Visit", "Gideon's Reproach", "Hamato Ninp\u014d", "Hand of Death", "Immolating Glare", "Impeccable Timing", "Iron Verdict", "Kill Shot", "Lens Flare", "Neck Snap", "Not on My Watch", "Rebuke", "Righteous Blow", "Sandblast", "Slash of Talons", "Sudden Strike", "Swift Response", "Take Vengeance", "Vanquish", "Vengeance", "Wallop", "Wanderer's Intervention"]`
- Families: `{"xmage_destroy_target_spell": 17, "xmage_exile_target_spell": 7, "xmage_fixed_damage_spell": 14}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_package.md`
- PG apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_e2e_validation.md`
- post-PG308 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg308_restricted_target_spell_wave_recheck.md`
- post-PG308 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg308_restricted_target_spell_wave.md`
- post-PG308 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg308_existing_supported_recheck.md`
- final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg308_restricted_target_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg308_restricted_target_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg308_restricted_target_spell_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg308_restricted_target_spell_wave.md`

Evidence:

- PostgreSQL apply evidence reports `38/38` promoted rule rows,
  `38/38` verified/auto rows and `38/38` Oracle hash matches, with `2`
  stale shadow rows backed up.
- PG -> Hermes/SQLite sync loaded `6905` PostgreSQL rows, inserted/updated
  `6699` SQLite rows, and exported `4512` canonical snapshot rows.
- E2E validation reports pass for PostgreSQL source of truth, SQLite Hermes
  cache, canonical snapshot fallback, runtime `get_card_effect`, and battle
  execution no-override.
- Final alignment audits passed: XMage strategy `26/26`, operational surface
  `pass`, PG/Hermes/SQLite contract `48` pass with `1` known legacy warning,
  and legacy contamination `pass`.
- Post-PG308 authoritative queue is
  `target_identity_count=27586`, `xmage_authoritative_source_count=27272`,
  `xmage_authoritative_adapter_required_count=27272`, `parser_gap=0`, and
  `xmage_missing_source_exception_count=314`.
- Post-PG308 supported splitter recheck returns `proposal_count=0` over `7365`
  considered supported rows; the next package requires a new exact
  runtime-backed subpattern.
- Local focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`87` tests) and
  `test_xmage_exact_scope_runtime.py` (`43` tests).

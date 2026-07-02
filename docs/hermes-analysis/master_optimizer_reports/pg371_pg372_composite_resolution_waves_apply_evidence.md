# PG371/PG372 Composite Resolution Waves Evidence - 2026-07-02

Status: `applied_synced_validated`.

## PG371 - Life Gain + Draw

- Scope: `xmage_fixed_controller_gain_life_draw_card_spell_v1`.
- Family: `xmage_fixed_life_gain_draw_card_spell`.
- Cards promoted: `5`.
- Split evidence:
  - `xmage_authoritative_exact_scope_split_20260702_pg371_life_gain_draw_spell_wave.md`
- Package evidence:
  - `pg371_life_gain_draw_spell_wave_package.md`
  - `pg371_life_gain_draw_spell_wave_precheck.sql`
  - `pg371_life_gain_draw_spell_wave_apply.sql`
  - `pg371_life_gain_draw_spell_wave_postcheck.sql`
- PostgreSQL postcheck: `5/5` promoted, `verified`, `auto`, with `oracle_hash`.
- E2E: `pg371_life_gain_draw_spell_wave_e2e_validation.md` status `pass`.
- Final E2E after oracle-hash backfill and final snapshot sync:
  `pg371_life_gain_draw_spell_wave_e2e_validation_final.md` status `pass`.

## PG372 - Boost + Draw

- Scope: `xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1`.
- Family: `xmage_fixed_boost_draw_card_spell`.
- Cards promoted: `10`.
- Runtime added: `stat_modifier_until_eot` as a safe `composite_resolution` component without double-finishing the source spell.
- Split evidence:
  - `xmage_authoritative_exact_scope_split_20260702_pg372_boost_draw_spell_wave.md`
- Package evidence:
  - `pg372_boost_draw_spell_wave_package.md`
  - `pg372_boost_draw_spell_wave_precheck.sql`
  - `pg372_boost_draw_spell_wave_apply.sql`
  - `pg372_boost_draw_spell_wave_postcheck.sql`
- PostgreSQL apply: `10` upserts, `0` deprecated shadow rows.
- PostgreSQL postcheck: `10/10` promoted, `verified`, `auto`, with `oracle_hash`.
- E2E: `pg372_boost_draw_spell_wave_e2e_validation.md` status `pass`.
- Final E2E after oracle-hash backfill and final snapshot sync:
  `pg372_boost_draw_spell_wave_e2e_validation_final.md` status `pass`.

## Tests

Command:

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py
```

Result: `447 tests`, `OK`.

## Sync And Audits

- Final PostgreSQL -> Hermes/SQLite sync:
  - `pg372_boost_draw_spell_wave_pg_to_sqlite_sync_after_pg_hash_backfill.json`
  - `canonical_snapshot_rows_exported=5005`
  - `sqlite_inserted_or_updated=7229`
- Final metadata sync:
  - `pg372_boost_draw_spell_wave_pg_metadata_sync_after_pg_hash_backfill.json`
- Final contract audit:
  - `pg_hermes_sqlite_contract_audit_20260702_post_pg372_boost_draw_spell_wave_final.md`
  - status `pass`, `49/49` checks.
- Strategy/operational/legacy audits:
  - `xmage_strategy_consistency_audit_20260702_post_pg372_boost_draw_spell_wave_docs_final.md` status `pass`, `26/26`.
  - `operational_surface_alignment_audit_20260702_post_pg372_boost_draw_spell_wave_docs_final.md` status `pass`.
  - `legacy_contamination_audit_20260702_post_pg372_boost_draw_spell_wave_docs_final.md` status `pass`.
  - Final doc-updated rerun:
    `xmage_strategy_consistency_audit_20260702_post_pg372_boost_draw_spell_wave_docs_updated.md`,
    `operational_surface_alignment_audit_20260702_post_pg372_boost_draw_spell_wave_docs_updated.md`,
    and `legacy_contamination_audit_20260702_post_pg372_boost_draw_spell_wave_docs_updated.md`
    all status `pass`.

## Oracle Hash Contract Backfill

During the final PG-Hermes-SQLite audit, trusted executable curated/manual rules
without `oracle_hash` were found. This was not caused by PG371/PG372, but it was
a real contract gap.

Corrections applied:

- PostgreSQL `card_battle_rules`: `1419` trusted executable rows backfilled with `md5(cards.oracle_text)`.
- PostgreSQL basic-land aliases: `Forest`, `Island`, `Swamp` linked to the corresponding `//` catalog card IDs and hash-filled.
- PostgreSQL postcheck: `remaining_missing_trusted_executable_hashes=0`.
- SQLite/Hermes resync after PG backfill: final contract audit is clean with `49/49` pass.

## Queue Delta

- Post-PG370 adapter required: `26758`.
- Post-PG371 adapter required: `26753`.
- Post-PG372 adapter required: `26743`.
- Total delta this evidence file: `15` identities.
- Parser gaps remained `0`.
- Missing-source exceptions remained `314`.

Stop condition remains unmet: the refreshed post-PG372 queue still has
`26743` `xmage_authoritative_adapter_required` identities.

# PG368 Graveyard Exile Spell Wave Apply Evidence

Status: `applied_and_validated`.

This package promoted the XMage-backed graveyard-exile spell scope:

- Scope: `xmage_exile_target_graveyard_card_spell_v1`
- Family: `xmage_graveyard_exile_spell`
- Cards: `Coffin Purge`, `Decompose`, `Fade from Memory`, `Purify the Grave`, `Rapid Decay`, `Rats' Feast`, `Scarab Feast`

## PostgreSQL Apply

Commands were run against the configured `server/.env` `DATABASE_URL` with `ON_ERROR_STOP=1`:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_postcheck.sql`

Observed results:

- Precheck found `target_card_rows=1`, `existing_rule_rows=0`, `expected_rule_rows_before=0`, and `would_deprecate_shadow_rows=0` for all 7 selected cards.
- Apply reported `deprecated_shadow_rows=0` and `upserted_rows=7`.
- Postcheck found `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`, and `backup_rows=0` for all 7 selected cards.

## Sync And E2E

- PostgreSQL -> SQLite rule sync: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_pg_to_sqlite_sync.json`
  - PostgreSQL rows loaded: `7407`
  - SQLite inserted or updated: `7202`
  - canonical snapshot rows exported: `4980`
- PostgreSQL metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_pg_metadata_sync.json`
  - requested unique names: `5797`
  - PostgreSQL cards matched: `5988`
  - SQLite cache alias rows: `5915`
  - deck-card backfill matched: `2699/2699`
  - unresolved: `1`
- End-to-end package validation: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_e2e_validation.md`
  - Status: `pass`
  - PostgreSQL source of truth: `7/7`
  - SQLite Hermes cache: `7/7`
  - canonical snapshot fallback: `7/7`
  - runtime `get_card_effect`: `7/7`

## Post-Apply Queue Signal

- Readiness recheck: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg368_graveyard_exile_spell_wave_recheck.md`
- Authoritative queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg368_graveyard_exile_spell_wave_commander_legal.md`
- Supported exact-scope recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg368_supported_recheck.md`

The refreshed authoritative queue shows:

- target identities: `27084`
- XMage authoritative source resolved: `26770`
- missing local XMage source exceptions: `314`
- parser gaps: `0`
- adapter required: `26770`
- adapter work-unit keys: `11429`

The supported exact-scope recheck found `proposal_count=0`, so the next executable work is a new family/subpattern mapper rather than another already-supported package.

# PG369 Activated Recursion Costs Wave Apply Evidence

Status: `applied_and_validated`.

This package promoted the XMage-backed activated recursion cost subpatterns:

- Scopes:
  - `xmage_permanent_simple_activated_graveyard_to_hand_v1`
  - `xmage_permanent_simple_activated_graveyard_to_battlefield_v1`
- Families:
  - `xmage_permanent_simple_activated_graveyard_to_hand`
  - `xmage_permanent_simple_activated_graveyard_to_battlefield`
- Cards: `Ghen, Arcanum Weaver`, `Malevolent Awakening`, `Phyrexian Reclamation`, `Strands of Night`

## PostgreSQL Apply

Commands were run against the configured `server/.env` `DATABASE_URL` with `ON_ERROR_STOP=1`:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg369_activated_recursion_costs_wave_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg369_activated_recursion_costs_wave_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg369_activated_recursion_costs_wave_postcheck.sql`

Observed results:

- Precheck found `target_card_rows=1`, `expected_rule_rows_before=0` for all 4 selected cards.
- Precheck found `would_deprecate_shadow_rows=2` only for `Phyrexian Reclamation`; the other selected cards had `0`.
- Apply reported `deprecated_shadow_rows=2` and `upserted_rows=4`.
- Postcheck found `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1` for all 4 selected cards.

## Sync And E2E

- PostgreSQL -> SQLite rule sync: `docs/hermes-analysis/master_optimizer_reports/pg369_activated_recursion_costs_wave_pg_to_sqlite_sync.json`
  - PostgreSQL rows loaded: `7411`
  - SQLite inserted or updated: `7206`
  - canonical snapshot rows exported: `4983`
- PostgreSQL metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg369_activated_recursion_costs_wave_pg_metadata_sync.json`
  - requested unique names: `5800`
  - PostgreSQL cards matched: `5991`
  - SQLite cache alias rows: `5918`
  - deck-card backfill matched: `2699/2699`
  - unresolved: `1`
- End-to-end package validation: `docs/hermes-analysis/master_optimizer_reports/pg369_activated_recursion_costs_wave_e2e_validation.md`
  - Status: `pass`
  - PostgreSQL source of truth: `4/4`
  - SQLite Hermes cache: `4/4`
  - canonical snapshot fallback: `4/4`
  - runtime `get_card_effect`: `4/4`

Focused runtime/splitter tests passed after the adapter changes:

- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
- Result: `438` tests, `OK`

## Post-Apply Queue Signal

- Readiness recheck: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg369_activated_recursion_costs_wave_recheck.md`
- Authoritative queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg369_activated_recursion_costs_wave_commander_legal.md`
- Supported exact-scope recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg369_supported_recheck.md`

The refreshed authoritative queue shows:

- target identities: `27080`
- XMage authoritative source resolved: `26766`
- missing local XMage source exceptions: `314`
- parser gaps: `0`
- adapter required: `26766`
- adapter work-unit keys: `11429`
- top reusable work unit: `recursion::xmage_graveyard_return_variant_review_v1` at `1822`

The supported exact-scope recheck found `proposal_count=0` over `7837` considered supported rows, so the next executable work is another new family/subpattern mapper rather than another already-supported package.

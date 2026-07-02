# PG370 Static Token Keywords Wave Apply Evidence

Status: `applied_and_validated`.

This package promoted XMage-backed creature token creation rules where the token
has only static keyword abilities already supported by ManaLoom runtime keyword
handling.

- Scopes:
  - `xmage_fixed_create_creature_tokens_spell_v1`
  - `xmage_creature_etb_create_tokens_v1`
- Families:
  - `xmage_fixed_create_creature_tokens_spell`
  - `xmage_creature_etb_create_tokens`
- Cards: `Advent of the Wurm`, `Call the Cavalry`, `Call to the Feast`,
  `Jungleborn Pioneer`, `Knight Watch`, `Paladin of the Bloodstained`,
  `Queen's Commission`, `Sworn Companions`

## PostgreSQL Apply

Commands were run against the configured `server/.env` `DATABASE_URL` with
`ON_ERROR_STOP=1`:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_postcheck.sql`

Observed results:

- Precheck found `target_card_rows=1`, `expected_rule_rows_before=0`, and
  `would_deprecate_shadow_rows=0` for all 8 selected cards.
- Apply reported `deprecated_shadow_rows=0` and `upserted_rows=8`.
- Postcheck found `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and
  `promoted_oracle_hash_rows=1` for all 8 selected cards.

## Sync And E2E

- PostgreSQL -> SQLite rule sync:
  `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_pg_to_sqlite_sync.json`
  - PostgreSQL rows loaded: `7419`
  - SQLite inserted or updated: `7214`
  - canonical snapshot rows exported: `4991`
- PostgreSQL metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_pg_metadata_sync.json`
  - requested unique names: `5808`
  - PostgreSQL cards matched: `5999`
  - SQLite cache alias rows: `5926`
  - deck-card backfill matched: `2699/2699`
  - unresolved: `1`
- End-to-end package validation:
  `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_e2e_validation.md`
  - Status: `pass`
  - PostgreSQL source of truth: `8/8`
  - SQLite Hermes cache: `8/8`
  - canonical snapshot fallback: `8/8`
  - runtime `get_card_effect`: `8/8`

Focused runtime/splitter tests passed after the adapter changes:

- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
- Result: `441` tests, `OK`

## Runtime And Splitter Change

- The exact-scope splitter now accepts static token keyword constructors for:
  `deathtouch`, `double_strike`, `first_strike`, `flying`, `haste`,
  `hexproof`, `indestructible`, `lifelink`, `menace`, `reach`, `trample`, and
  `vigilance`.
- Token descriptions with unsupported token behavior such as `infect`,
  `prowess`, `toxic`, `sacrifice`, `banding`, `mountainwalk`, or triggered
  token text remain blocked.
- Runtime token creation now mirrors safe static `token_keywords` into the same
  boolean fields used by `card_has_keyword`, so generated tokens can participate
  in combat keyword logic without Oracle text fallback.

## Post-Apply Queue Signal

- Readiness recheck:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg370_static_token_keywords_wave_recheck.md`
- Authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg370_static_token_keywords_wave_commander_legal.md`
- Supported exact-scope recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg370_supported_recheck.md`

The refreshed authoritative queue shows:

- target identities: `27072`
- XMage authoritative source resolved: `26758`
- missing local XMage source exceptions: `314`
- parser gaps: `0`
- adapter required: `26758`
- adapter work-unit keys: `11429`
- top reusable work unit: `recursion::xmage_graveyard_return_variant_review_v1` at `1822`

The supported exact-scope recheck found `proposal_count=0` over `7829`
considered supported rows, so the next executable work is another new
family/subpattern mapper rather than another already-supported package.

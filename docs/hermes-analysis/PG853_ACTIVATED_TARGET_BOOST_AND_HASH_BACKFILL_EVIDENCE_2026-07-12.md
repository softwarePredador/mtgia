# PG853 Activated Target Boost And Hash Backfill Evidence - 2026-07-12

Status: `applied_synced_audited`.

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## PG853 Activated Target Boost

Implemented and promoted
`xmage_permanent_simple_activated_target_boost_until_eot_v1` for 21
Commander-legal identities with local XMage source and fixed numeric
`BoostTargetEffect`.

Promoted cards:

- Aegis of the Meek
- Alpha Kavu
- Angelic Page
- Anointer of Champions
- Assembly-Worker
- Crenellated Wall
- Dwarven Lieutenant
- Grassland Crusader
- Hate Weaver
- Hoof Skulkin
- Icatian Lieutenant
- Infantry Veteran
- Kabuto Moth
- Kithkin Daggerdare
- Phyrexian Debaser
- Serra Advocate
- Spirit Weaver
- Sword Dancer
- Sword of the Chosen
- Tuknir Deathlock
- Wilderness Hypnotist

Parser/runtime changes:

- Oracle/source split now preserves target constraints for fixed activated
  target boost: exact `1/1`, attacking/attacking-or-blocking, colors,
  subtypes, legendary/snow, `another target`, tap, sacrifice, and mana cost.
- Unsupported `nonattacking/nonblocking` targets remain blocked.
- Dynamic X boost effects remain blocked for a separate subpattern.
- Package builder now creates `simple_activated_target_boost` E2E scenarios.
- E2E runner now proves activation, tap/sacrifice, target chosen, and actual
  power/toughness deltas.

Package:

- Split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_pg853_activated_target_boost_new_server_candidate.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_manifest.json`
- SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_precheck.sql`
  `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_apply.sql`
  `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_postcheck.sql`
  `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_rollback.sql`

Apply evidence:

- Precheck: 21/21 target card rows found, 0 expected rows before apply, 0
  shadow rows to deprecate.
- Apply: `upserted_rows=21`, `deprecated_shadow_rows=0`.
- Postcheck: each card has 1 promoted row, 1 `verified/auto` row, and 1
  `oracle_hash` row.

Sync/e2e:

- PG -> SQLite sync:
  `pg_rows_loaded=10577`, `sqlite_inserted_or_updated=10355`,
  `canonical_snapshot_rows_exported=7841`.
- Metadata sync:
  `postgres cards matched=8757`, `deck_cards backfill matched=2699/2699`.
- E2E:
  `status=pass`, 21 scenarios, 42 replay events, passing PG source, SQLite
  cache, canonical snapshot fallback, runtime `get_card_effect`, and battle
  execution stages.

## PG853B Oracle Hash Backfill

The post-PG853 PG/Hermes contract audit found residual older trusted executable
rules without `oracle_hash`. These were not PG853 rows, but they violated the
current drift contract.

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Apply evidence:

- Precheck: 55 trusted executable rows missing `oracle_hash`, 55 with Oracle
  text, 0 without Oracle text.
- Apply: `oracle_hash_rows_backfilled=55`.
- Postcheck: `trusted_executable_rules_missing_oracle_hash=0`,
  `backup_rows=55`, `updated_rows_with_current_oracle_hash=55`.
- PG -> SQLite sync rerun after backfill.

## Audits And Readiness

Passing audits:

- `xmage_strategy_consistency_audit_20260712_post_pg853_activated_target_boost_new_server_final`: pass, 26/26.
- `operational_surface_alignment_audit_20260712_post_pg853_activated_target_boost_new_server_final`: pass.
- `legacy_contamination_audit_20260712_post_pg853_activated_target_boost_new_server_final`: pass.
- `pg_hermes_sqlite_contract_audit_20260712_post_pg853b_hash_backfill_new_server_final`: pass, 51/51.

Readiness after PG853B:

- `snapshot_has_any_rule=8047`
- `snapshot_has_verified_rule=6897`
- `battle_and_oracle_ready=6790`
- `battle_family_mapper_required=27004`

XMage authoritative queue after PG853B:

- `target_identity_count=24093`
- `xmage_authoritative_source_count=23780`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=23780`

Post-PG853B exact-scope split:

- `xmage_authoritative_exact_scope_split_20260712_post_pg853b_hash_backfill_new_server_next_batch`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- Meaning: the already implemented exact adapters are exhausted for the current
  queue. The next work must implement another family/subpattern before another
  PostgreSQL package can be generated safely.

Next largest adapter lanes remain recursion, draw, protection, add counters,
direct damage, life gain, tutor, targeted removal, and mana-source subpatterns.
The next safe implementation target should be chosen from blocked exact split
reasons, not from broad `xmage_*_review_v1` rows.

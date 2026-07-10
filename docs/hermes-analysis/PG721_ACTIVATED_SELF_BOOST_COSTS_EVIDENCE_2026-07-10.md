# PG721 Activated Self Boost Costs Evidence - 2026-07-10

Status: `applied_passed_synced`

## Scope

Implemented and promoted the XMage-authoritative `BoostSourceEffect` activated
self-boost subpattern with discard and life activation costs.

Battle model scope:

- `xmage_permanent_simple_activated_self_boost_until_eot_v1`

Promoted cards:

- `Aven Trooper`
- `Burning-Fist Minotaur`
- `Canyon Drake`
- `Carrion Howler`
- `Cutthroat Contender`
- `Fleshgrafter`
- `Frenetic Ogre`
- `Grimclaw Bats`
- `Krosan Archer`
- `Noose Constrictor`
- `Pardic Swordsmith`
- `Putrid Leech`
- `Ravenous Bloodseeker`
- `Stalking Bloodsucker`
- `Wall of Blood`

## Runtime And Mapper Changes

- Mapper now accepts supported Oracle/XMage activation costs for simple activated
  self boost:
  - discard a card
  - discard a card at random
  - discard a land card
  - discard an artifact card
  - pay fixed life
- Source and Oracle cost comparison includes discard count, discard target,
  random discard, life cost, mana cost, tap requirement, and once-per-turn limit.
- Runtime now checks and pays discard/life costs for simple activated self boost.
- E2E scenario builder now supplies discard-cost hand fixtures and avoids
  invalid self-kill fixtures for negative toughness deltas.

## PostgreSQL Package

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_rollback.sql`

Precheck:

- target rows: `15`
- existing rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply:

- `upserted_rows=15`
- `deprecated_shadow_rows=0`

Postcheck:

- promoted rows: `15`
- promoted verified/auto rows: `15`
- promoted oracle hash rows: `15`

## Sync

Battle rule PG -> SQLite/Hermes:

- report: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_pg_to_sqlite_sync.json`
- database target: `127.0.0.1:15432/halder`
- `pg_rows_loaded=6260`
- `sqlite_inserted_or_updated=6255`
- `canonical_snapshot_rows_exported=6211`

Card metadata PG -> Hermes:

- report: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_metadata_sync.json`
- requested unique names: `7170`
- PostgreSQL cards matched: `7353`
- SQLite cache alias rows: `7272`
- deck_cards matched: `2699/2699`
- card_id updates: `80`
- unresolved count: `1` (`Surgical Suite/Hospital Room`)

## E2E

Report:

- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_e2e_validation.json`

Result:

- status: `pass`
- PostgreSQL source rows validated: `15`
- SQLite/Hermes cache rows validated: `15`
- canonical snapshot fallback cards validated: `15`
- runtime `get_card_effect` cards validated: `15`
- battle execution scenarios: `15`
- emitted battle events: `30`

Battle execution covered discard costs, life costs, once-per-turn limits, and
negative toughness deltas.

## Global Recheck

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260710_post_pg721_activated_self_boost_costs_new_server.md`

Counters:

- all known cards: `34331`
- `battle_and_oracle_ready=6309`
- `snapshot_has_verified_rule=6334`
- `battle_family_mapper_required=27567`

XMage authoritative queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260710_post_pg721_activated_self_boost_costs_new_server_commander_legal.md`
- `target_identity_count=24644`
- `xmage_authoritative_source_count=24331`
- `xmage_authoritative_adapter_required_count=24331`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Exact split post-recheck:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260710_post_pg721_activated_self_boost_costs_new_server_recheck.md`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

## Tests And Audits

Focused tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k activated_self_boost`
  - `11` tests passed
- `python3 -m unittest test_xmage_exact_scope_runtime.py -k simple_activated_self_boost`
  - `5` tests passed
- `python3 -m pytest test_xmage_batch_pg_package_builder.py -k simple_activated_self_boost`
  - `2` tests passed
- `python3 -m pytest test_battle_package_end_to_end_validation.py -k simple_activated_self_boost_runner`
  - `1` test passed

Audits:

- `xmage_strategy_consistency_audit`: `pass` (`26/26`)
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `pg_hermes_sqlite_contract_audit`: `pass` (`51/51`)
- `./scripts/quality_gate.sh server-target`: `pass`

## Notes

The active global goal is not complete. Remaining Commander-legal XMage
translation work still has `24331` XMage-authoritative adapter-required
identities and `313` missing-source exceptions. This PG721 batch only closes the
safe activated self-boost cost subpattern exposed by the current queue.

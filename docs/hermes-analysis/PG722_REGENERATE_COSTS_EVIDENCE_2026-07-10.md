# PG722 Regenerate Activation Costs Evidence - 2026-07-10

Status: `applied_and_validated`

Database target: `127.0.0.1:15432/halder` via
`./server/bin/with_new_server_pg.sh`

## Scope

PG722 extends `xmage_permanent_simple_activated_regenerate_source_v1` to
support XMage-authored activation costs that combine regeneration with:

- discard one card;
- pay life;
- existing mana costs and static keyword sidecars.

Promoted cards:

- `Centaur Veteran`
- `Deepwood Ghoul`
- `Marrow Bats`
- `Mischievous Poltergeist`
- `Sentry of the Underworld`
- `Tunneler Wurm`

## Runtime And Mapper Changes

- `xmage_authoritative_exact_scope_split.py` now parses `DiscardCardCost`,
  discard target variants, and `PayLifeCost(n)` for simple activated
  regenerate-source abilities.
- `battle_analyst_v9.py` now checks and pays discard/life activation costs
  before adding the regeneration shield.
- `xmage_batch_pg_package_builder.py` now creates focused hand/life fixtures
  for regenerate-source package scenarios.
- `battle_package_end_to_end_validation.py` now validates expected discarded
  cards and life paid during package execution.

Focused tests passed:

- `python3 -m py_compile` for the splitter, battle runtime, package builder,
  and E2E validator.
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k activated_regenerate_source`:
  `4` tests passed.
- `python3 -m unittest test_xmage_exact_scope_runtime.py -k regenerate_source`:
  `3` tests passed.
- `python3 -m pytest test_xmage_batch_pg_package_builder.py -k simple_activated_regenerate_source`:
  `2` tests passed.
- `python3 -m pytest test_battle_package_end_to_end_validation.py -k simple_activated_regenerate_source`:
  `2` tests passed.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_package_rollback.sql`

PostgreSQL result:

- Precheck: `6` target cards, `0` existing expected rule rows, `0` shadow rows
  to deprecate.
- Apply: `upserted_rows=6`, `deprecated_shadow_rows=0`.
- Postcheck: all `6` cards have one promoted rule row with
  `review_status=verified`, `execution_status=auto`, and matching
  `oracle_hash`.

## Sync And E2E

- PG -> SQLite rule sync:
  `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_pg_to_sqlite_sync.json`
  reported `pg_rows_loaded=6`, `sqlite_inserted_or_updated=6`, and
  `canonical_snapshot_rows_exported=6217`.
- Metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_metadata_sync.json`
  reported `postgres_cards_matched=7359`, `sqlite_cache_alias_rows=7278`, and
  deck card backfill `matched=2699/2699`.
- Package E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg722_regenerate_costs_new_server_e2e_validation.md`
  passed PostgreSQL, SQLite, canonical snapshot, runtime lookup, and battle
  execution.
- Battle execution covered `6` scenarios and `12` events. The discard-cost
  cards discarded `1` card, and the life-cost cards paid `1`, `2`, `3`, or
  `4` life as expected before surviving the destroy event through
  regeneration.

## PG722B Hash Backfill

The post-PG722 `pg_hermes_sqlite_contract_audit` exposed an existing
PostgreSQL integrity gap: `55` trusted executable rules had no
`oracle_hash`. This was not introduced by PG722, but it blocked the final
contract gate.

PG722B fixed this with a controlled PostgreSQL backfill from
`md5(cards.oracle_text)`.

Files:

- `docs/hermes-analysis/master_optimizer_reports/pg722b_trusted_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg722b_trusted_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg722b_trusted_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg722b_trusted_oracle_hash_backfill_new_server_rollback.sql`

Result:

- Precheck: `55` fillable rows, `54` distinct card IDs, `55` normalized
  identities.
- Apply: `backfilled_rows=55`.
- Postcheck: `trusted_executable_rules_missing_oracle_hash=0`; backup table
  has `55` rows.
- PG -> SQLite full rule sync after backfill:
  `docs/hermes-analysis/master_optimizer_reports/pg722b_trusted_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
  reported `pg_rows_loaded=9910`, `sqlite_inserted_or_updated=9688`, and
  `canonical_snapshot_rows_exported=7310`.

## Post-Apply Global State

Authoritative queue after PG722:

- `target_identity_count=24638`
- `xmage_authoritative_source_count=24325`
- `xmage_authoritative_adapter_required_count=24325`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

Global readiness after PG722B:

- `all_known_cards=34331`
- `snapshot_has_verified_rule=6340`
- `battle_and_oracle_ready=6315`
- `battle_family_mapper_required=27561`
- `trusted_rule_oracle_hash_backfill=0`

## Governance Gates

Passed:

- `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`:
  `26/26`
- `operational_surface_alignment_audit_20260710_post_pg722_regenerate_costs_new_server_final.md`:
  `pass`
- `legacy_contamination_audit_20260710_post_pg722_regenerate_costs_new_server_final.md`:
  `pass`
- `pg_hermes_sqlite_contract_audit_20260710_post_pg722b_hash_backfill_new_server_final.md`:
  `51/51`
- `./scripts/quality_gate.sh server-target`: `pass`

## Cleanup

Removed temporary raw queue/probe artifacts:

- `xmage_authoritative_adaptation_queue_20260710_pg722_probe_commander_legal.json`
- `xmage_authoritative_adaptation_queue_20260710_pg722_probe_commander_legal.md`
- `xmage_authoritative_exact_scope_split_20260710_pg722_probe.json`
- `xmage_authoritative_exact_scope_split_20260710_pg722_probe.md`
- `xmage_authoritative_exact_scope_split_20260710_pg722_probe_after_regenerate_costs.json`
- `xmage_authoritative_exact_scope_split_20260710_pg722_probe_after_regenerate_costs.md`
- `xmage_authoritative_adaptation_queue_20260710_pg722_regenerate_costs_new_server_commander_legal.json`
- `xmage_authoritative_adaptation_queue_20260710_post_pg722_regenerate_costs_new_server_commander_legal.json`

The global all-card goal remains open. PG722 closed this regenerate-cost
subpattern and PG722B closed the trusted-rule hash integrity gate; the residual
global queue still requires family/subpattern adapter work for `24325`
XMage-authoritative identities and manual decisions for `313` missing-source
exceptions.

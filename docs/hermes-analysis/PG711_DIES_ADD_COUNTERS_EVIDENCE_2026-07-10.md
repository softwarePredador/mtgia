# PG711 Dies Add Counters Evidence

Date: 2026-07-10
Target: new server PostgreSQL via `server/bin/with_new_server_pg.sh`

## Scope

Promoted the XMage exact family `xmage_creature_dies_add_counters_target_creature_v1`.

Cards promoted:

- Bile-Vial Boggart
- Festering Mummy
- Goblin Assault Team
- Guul Draz Mucklord
- Lawless Broker
- Sparring Construct
- Spinal Centipede
- Steadfast Sentry
- Venerable Knight

Blocked by design:

- Brokers Veteran remains blocked because XMage uses `CounterType.SHIELD`, outside this fixed `+1/+1` / `-1/-1` runtime adapter.

## Code And Runtime

- Added exact split support for `DiesSourceTriggeredAbility + AddCountersTargetEffect`.
- Added runtime resolution on permanent/creature death through `resolve_permanent_dies_add_counters`.
- Added package E2E scenario type `creature_dies_add_counters`.
- Added focused tests for splitter, package scenario generation, and battle execution.

Focused test result:

```text
1157 passed, 206 subtests passed
```

## PostgreSQL Package

PG711 package files:

- `docs/hermes-analysis/master_optimizer_reports/pg711_dies_add_counters_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg711_dies_add_counters_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg711_dies_add_counters_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg711_dies_add_counters_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg711_dies_add_counters_new_server_package_manifest.json`

PG711 precheck:

- target cards: 9
- existing rule rows: 0
- shadow rows to deprecate: 0

PG711 apply:

- upserted rows: 9

PG711 postcheck:

- promoted rule rows: 9
- promoted verified/auto rows: 9
- promoted oracle hash rows: 9

## PG711 E2E

Report:

- `docs/hermes-analysis/master_optimizer_reports/pg711_dies_add_counters_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/pg711_dies_add_counters_new_server_e2e_validation.md`

Result:

- status: pass
- postgres_source_of_truth: pass, 9 validated rows
- sqlite_hermes_cache: pass, 9 validated rows
- canonical_snapshot_fallback: pass, 9 validated cards
- runtime_get_card_effect: pass, 9 validated cards
- battle_execution: pass, 9 scenarios, 18 events

## Hash Backfill Cleanup

During post-PG711 governance, `pg_hermes_sqlite_contract_audit` found 55 legacy trusted executable rules without `oracle_hash`.

PG711B package files:

- `docs/hermes-analysis/master_optimizer_reports/pg711b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg711b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg711b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg711b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

PG711B precheck:

- backfillable rule rows: 55
- affected card ids: 54
- unsafe missing hash rows: 0
- source counts: `{"curated": 55}`

PG711B apply:

- oracle_hash rows backfilled: 55

PG711B postcheck:

- remaining trusted executable missing hash rows: 0
- backfilled rows with expected hash: 55

## Sync And Audits

Sync reports:

- `pg711_dies_add_counters_new_server_pg_to_sqlite_sync.json`
- `pg711b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`

Final readiness:

- post-PG710 `battle_and_oracle_ready`: 6259
- post-PG711B `battle_and_oracle_ready`: 6268
- post-PG710 `battle_family_mapper_required`: 27617
- post-PG711B `battle_family_mapper_required`: 27608
- post-PG711B `snapshot_has_verified_rule`: 6293
- post-PG711B `trusted_rule_oracle_hash_backfill`: absent from lane counts

Queue impact:

- post-PG710 `xmage_authoritative_adapter_required_count`: 24381
- post-PG711 `xmage_authoritative_adapter_required_count`: 24372
- post-PG710 `add_counters::targeted_add_counters_variant_v1`: 435
- post-PG711 `add_counters::targeted_add_counters_variant_v1`: 426

Final audits:

- `xmage_strategy_consistency_audit_20260710_post_pg711_dies_add_counters_new_server_final`: pass, 26/26
- `operational_surface_alignment_audit_20260710_post_pg711_dies_add_counters_new_server_final`: pass
- `legacy_contamination_audit_20260710_post_pg711_dies_add_counters_new_server_final`: pass
- `pg_hermes_sqlite_contract_audit_20260710_post_pg711b_hash_backfill_new_server_final`: pass, 51/51
- `./scripts/quality_gate.sh server-target`: pass

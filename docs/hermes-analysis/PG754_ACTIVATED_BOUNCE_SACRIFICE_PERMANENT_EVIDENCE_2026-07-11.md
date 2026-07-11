# PG754 Activated Bounce Sacrifice Permanent Evidence - 2026-07-11

Status: `applied_validated_synced`

## Scope

Closed two XMage-authoritative activated bounce cards whose ability cost is
`Sacrifice a permanent`:

- `Barrin, Master Wizard`
- `Dispersing Orb`

Runtime scope:

- `xmage_permanent_simple_activated_return_to_hand_v1`

Remaining activated-bounce residuals after this package:

- `Alexi, Zephyr Mage`: X target/count dynamic.
- `Flooded Shoreline`: return two Islands as activation cost.

## Implementation

- `xmage_authoritative_exact_scope_split.py`
  - accepts Oracle `Sacrifice a permanent` activation costs.
  - accepts XMage `SacrificeTargetCost(StaticFilters.FILTER_PERMANENT)`.
  - emits `activation_sacrifice_cost` with permanent target constraints.

## PostgreSQL Package

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_rollback.sql`

Precheck:

- two canonical card rows resolved.
- zero existing matching rule rows.
- zero shadow rows to deprecate.

Apply:

- `upserted_rows=2`
- `deprecated_shadow_rows=0`

Postcheck:

- each card has `promoted_rule_rows=1`
- each card has `promoted_verified_auto_rows=1`
- each card has `promoted_oracle_hash_rows=1`

## Sync And E2E

PostgreSQL -> Hermes/SQLite sync:

- `pg_rows_loaded=10065`
- `sqlite_inserted_or_updated=9843`
- `canonical_snapshot_rows_exported=7457`

E2E report:

- `docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_e2e.json`
- status: `pass`
- scenarios: `2`
- events: `6`

Validated stages:

- PostgreSQL source of truth
- SQLite Hermes cache
- canonical snapshot fallback
- runtime `get_card_effect`
- battle execution

Battle execution outcomes:

- `Barrin, Master Wizard`: sacrificed a permanent and returned target creature
  to hand.
- `Dispersing Orb`: sacrificed a permanent and returned target permanent to
  hand.

## Updated Baseline

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg754_activated_bounce_sacrifice_permanent_new_server.json`
- `battle_and_oracle_ready=6416`
- `snapshot_has_verified_rule=6495`
- `trusted_rule_oracle_hash_backfill=54`
- `battle_family_mapper_required=27406`
- `generic_runtime_or_no_card_rule=359`

Commander-legal XMage queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg754_activated_bounce_sacrifice_permanent_new_server_commander_legal.json`
- `target_identity_count=24483`
- `xmage_authoritative_source_count=24170`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=24170`
- `bounce::targeted_return_to_hand_variant_v1=206`

## Validation Commands

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py
python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py -k "permanent_activated_bounce" -q
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_precheck.sql
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_apply.sql
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_postcheck.sql
./server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --export-canonical-fallback-json docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json --report docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_sqlite_sync.json
./server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py --manifest docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_manifest.json --output-json docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_e2e.json --output-md docs/hermes-analysis/master_optimizer_reports/pg754_activated_bounce_sacrifice_permanent_new_server_e2e.md
```

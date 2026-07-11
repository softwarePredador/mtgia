# PG752 Activated Bounce Evidence - 2026-07-11

Status: `applied_and_validated`.

Scope: `xmage_permanent_simple_activated_return_to_hand_v1`.

## Applied Cards

- Aegis Automaton
- Escape Routes
- Galecaster Colossus
- Kami of Twisted Reflection
- Neurok Replica
- Obelisk of Undoing
- Seal of Removal
- Temporal Adept
- Vedalken Mastermind

## PostgreSQL

- Target: new server PostgreSQL via `server/bin/with_new_server_pg.sh`.
- Precheck: 9 target cards, 0 existing rule rows, 0 shadow rows to deprecate.
- Apply: 9 rows upserted, 0 shadow rows deprecated.
- Postcheck: 9/9 rows promoted with `review_status=verified`, `execution_status=auto`, and matching `oracle_hash`.

Package SQL files:

- `docs/hermes-analysis/master_optimizer_reports/pg752_activated_bounce_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg752_activated_bounce_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg752_activated_bounce_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg752_activated_bounce_new_server_rollback.sql`

## Hermes / SQLite

Sync command used `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`.

Sync result:

- `pg_rows_loaded`: 10060
- `sqlite_inserted_or_updated`: 9838
- `canonical_snapshot_rows_exported`: 7452

## E2E Validation

`battle_package_end_to_end_validation.py` passed for:

- PostgreSQL source of truth: 9 rows.
- SQLite Hermes cache: 9 rows.
- Canonical snapshot fallback: 9 rows.
- Runtime `get_card_effect`: 9 cards.
- Battle execution: 9 scenarios, 27 emitted events.

Runtime execution proved activated return-to-hand behavior including self-target, opponent-target, tap cost, tap-target cost, and self-sacrifice source costs.

## Global Counts After PG752

From `global_card_oracle_battle_readiness_20260711_post_pg752_activated_bounce_new_server`:

- `snapshot_has_verified_rule`: 6490
- `battle_and_oracle_ready`: 6411
- `trusted_rule_oracle_hash_backfill`: 54
- `battle_family_mapper_required`: 27411
- `generic_runtime_or_no_card_rule`: 359

From `xmage_authoritative_adaptation_queue_20260711_post_pg752_activated_bounce_new_server_commander_legal`:

- `target_identity_count`: 24488
- `xmage_authoritative_source_count`: 24175
- `xmage_missing_source_exception_count`: 313
- `xmage_authoritative_adapter_required_count`: 24175
- `bounce::targeted_return_to_hand_variant_v1`: 211 remaining.

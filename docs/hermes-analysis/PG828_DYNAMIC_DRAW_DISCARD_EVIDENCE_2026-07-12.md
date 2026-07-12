# PG828 Dynamic Draw/Discard Evidence

Generated on 2026-07-12 for the new ManaLoom PostgreSQL target
`127.0.0.1:15432/halder`.

## Scope

PG828 promotes the XMage-backed dynamic draw/discard spell family for:

- `Flow of Knowledge`: draw a card for each Island you control, then discard two cards.
- `Pull from Tomorrow`: draw X cards, then discard a card.

`Brilliant Spectrum` remains blocked because its count depends on colors of
mana spent to cast the spell. ManaLoom still needs a cast-context adapter for
that signal before it can be promoted safely.

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py`
  - Maps `Draw X cards, then discard...` to `draw_count_source=x_value`.
  - Maps `Draw a card for each Island you control...` to
    `draw_count_source=battlefield_permanent_count` with controller battlefield
    land/island filters.
  - Blocks colors-of-mana-spent draw/discard cases explicitly.
- `battle_analyst_v9.py`
  - Resolves dynamic draw counts from cast X value or battlefield permanent
    counts.
  - Emits replay fields for `draw_count_source`, `x_value`, and battlefield
    count filters.
- `xmage_batch_pg_package_builder.py`
  - Builds focused E2E scenarios for X draw and battlefield-count draw.
- `battle_package_end_to_end_validation.py`
  - Loads controller battlefield fixtures for draw/discard E2E scenarios.
  - Validates expected `draw_count_source` in battle events.

## PostgreSQL Apply Evidence

Package manifest:
`docs/hermes-analysis/master_optimizer_reports/pg828_dynamic_draw_discard_new_server_package_manifest.json`

- Selected cards: `2`
- PostgreSQL apply deprecated `2` Pull from Tomorrow shadow rows.
- PostgreSQL apply upserted `2` verified/auto rows.
- Postcheck confirmed one promoted verified/auto rule with oracle hash for each
  selected card.

Current PostgreSQL rule rows for promoted cards:

| Card | Logical rule key | Review | Execution | Oracle hash |
| --- | --- | --- | --- | --- |
| Flow of Knowledge | `battle_rule_v1:0e6ff4345f8868715ae1cef6ebe7e2b0` | `verified` | `auto` | present |
| Pull from Tomorrow | `battle_rule_v1:5c92cd65e2f74fcff2ff572db18adcf0` | `verified` | `auto` | present |

PG828B oracle-hash backfill:

- Backup table: `manaloom_deploy_audit.pg828b_oracle_hash_backfill_new_server_20260712_1118`
- Backup rows: `32`
- Verified/auto rows still missing `oracle_hash`: `0`

## Sync And E2E Evidence

Selective PG828 sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg828_dynamic_draw_discard_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=2`
- `sqlite_inserted_or_updated=4`
- `canonical_snapshot_rows_exported=7738`

Full PG828B sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg828b_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=6717`
- `sqlite_inserted_or_updated=9111`
- `canonical_snapshot_rows_exported=6668`

Post-cleanup E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg828_dynamic_draw_discard_new_server_after_cleanup_e2e_validation.json`
- Status: `pass`
- PostgreSQL validated rows: `2`
- SQLite validated rows: `2`
- Canonical snapshot validated cards: `2`
- Runtime `get_card_effect` validated cards: `2`
- Battle execution:
  - `Flow of Knowledge`: drew `3`, discarded `2`.
  - `Pull from Tomorrow`: drew `3`, discarded `1`.

## Readiness After PG828B

Readiness report:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg828b_dynamic_draw_discard_hash_backfill_new_server.json`

- Status: `action_required`
- All known cards: `34331`
- `battle_and_oracle_ready=6684`
- `battle_family_mapper_required=27110`
- `battle_rule_verification_required=70`
- `snapshot_has_any_rule=7944`
- `snapshot_has_verified_rule=6791`

Queue report:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260712_post_pg828b_dynamic_draw_discard_hash_backfill_new_server_commander_legal.json`

- `target_identity_count=24199`
- `xmage_authoritative_source_count=23886`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=23886`

Exact split recheck:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_post_pg828b_dynamic_draw_discard_hash_backfill_new_server_recheck.json`

- Status: `ready`
- `safe_for_batch_pg_package_count=0`
- Remaining proposal count: `2`, both runtime-partial mana proposals.

## Audits

- `xmage_strategy_consistency_audit`: `pass`, 26 checks.
- `operational_surface_alignment_audit`: `pass`, 48 checks.
- `legacy_contamination_audit`: `pass`, 32 checks.
- `pg_hermes_sqlite_contract_audit` with new PG wrapper: `pass`, 51 checks.
- `./scripts/quality_gate.sh server-target`: `pass`.

## Tests

Focused parser tests:

```text
Ran 4 tests in 0.002s
OK
```

Focused runtime tests:

```text
Ran 2 tests in 0.371s
OK
```

Full Python unittest discovery:

```text
Ran 3030 tests in 48.110s
FAILED (failures=1, skipped=4)
```

The remaining failure is `test_report_retention_audit`, with summary:

```text
tracked_raw_count=2816
referenced_tracked_raw_count=883
unreferenced_tracked_raw_count=1933
unreferenced_tracked_raw_bytes=115087988
ignored_local_count=3446
ignored_local_bytes=9425793256
```

This is a repository report-retention/hygiene failure, not a PG828 runtime or
PostgreSQL promotion failure.

## Current Goal State

The global XMage-to-ManaLoom objective is not complete. PG828 closes this
specific dynamic draw/discard subpattern, but the current global queue still has
`23886` XMage-authoritative adapter-required identities and `313` missing-source
exceptions.

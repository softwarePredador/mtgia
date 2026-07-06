# PG543 Graveyard Self-Exile Token Apply Evidence

- Deploy ID: `pg543_graveyard_self_exile_token_new_server`
- Scope: 2 XMage-authoritative graveyard self-exile activated token-maker rules.
- Runtime scope: `xmage_graveyard_self_exile_activated_create_token_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`

## PostgreSQL

- Precheck: 2 target rows, all `target_card_rows=1`, no SQL errors.
- Existing expected rows found: 0.
- Apply: `COMMIT`, 2 rows upserted, 0 shadow rows deprecated.
- Postcheck: 2 promoted rows, all `promoted_verified_auto_rows=1`, all `promoted_oracle_hash_rows=1`.

## Promoted Cards

- `Eternal Student`
- `Illustrious Historian`

## Hermes / SQLite

- Sync command: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
- PG rows loaded: 8,838
- SQLite rows inserted or updated: 8,602
- Canonical snapshot rows exported: 6,344

## Runtime E2E

- Validator: `battle_package_end_to_end_validation.py`
- Manifest: `pg543_graveyard_self_exile_token_new_server_package_manifest.json`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, battle execution.
- Battle scenarios: 2
- Battle events: 2
- Runtime evidence: each promoted card was placed in the graveyard, paid its activation mana, exiled itself from graveyard as cost, and created the expected token. `Illustrious Historian` also validated tapped token payload handling.

## Test Coverage

- `python3 -m py_compile` passed for mapper, runtime, package builder, E2E validator, and PG sync script.
- Focused unittest suite passed: 946 tests, 0 failures.

## Contract Audits

- `xmage_strategy_consistency_audit_20260706_post_pg543_graveyard_self_exile_token_new_server_final`: pass, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260706_post_pg543_graveyard_self_exile_token_new_server_with_pg`: pass, 51 checks.
- `operational_surface_alignment_audit_20260706_post_pg543_graveyard_self_exile_token_new_server_final`: pass, 39 checks.
- `legacy_contamination_audit_20260706_post_pg543_graveyard_self_exile_token_new_server_final`: pass, 32 checks.
- `global_card_oracle_battle_readiness_20260706_post_pg543_graveyard_self_exile_token_new_server_final`: action_required because the global all-card backlog remains open.

## Remaining Global Queue

- Commander-legal target identities still requiring adaptation: 25,653
- XMage authoritative sources remaining: 25,339
- Missing local XMage source exceptions: 314
- Parser gaps: 0
- Adapter work units remaining: 11,368
- Post-apply exact split safe candidates: 0

## Cleanup

- Raw queue JSON dumps for the pre-apply candidate source and post-apply global queue were not retained as durable evidence because each was about 40 MB and the corresponding `.md` summaries preserve the required metrics and routing signal.

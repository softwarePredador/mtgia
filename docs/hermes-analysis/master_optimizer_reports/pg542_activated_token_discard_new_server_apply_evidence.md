# PG542 Activated Token Discard Apply Evidence

- Deploy ID: `pg542_activated_token_discard_new_server`
- Scope: 4 XMage-authoritative permanent activated token maker rules with discard costs.
- Runtime scope: `xmage_permanent_simple_activated_create_token_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`

## PostgreSQL

- Precheck: 4 target rows, all `target_card_rows=1`, no SQL errors.
- Existing expected rows found: 0.
- Apply: `COMMIT`, 4 rows upserted, 0 shadow rows deprecated.
- Postcheck: 4 promoted rows, all `promoted_verified_auto_rows=1`, all `promoted_oracle_hash_rows=1`.

## Promoted Cards

- `Icatian Crier`
- `Pegasus Refuge`
- `Sliversmith`
- `Thraben Standard Bearer`

## Hermes / SQLite

- Sync command: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
- PG rows loaded: 8,836
- SQLite rows inserted or updated: 8,600
- Canonical snapshot rows exported: 6,342

## Runtime E2E

- Validator: `battle_package_end_to_end_validation.py`
- Manifest: `pg542_activated_token_discard_new_server_package_manifest.json`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, battle execution.
- Battle scenarios: 4
- Battle events: 4
- Runtime evidence: each promoted card paid mana, discarded 1 card, and created the expected token; tap requirements and token keywords/artifact flags were validated.

## Contract Audits

- `xmage_strategy_consistency_audit_20260706_post_pg542_activated_token_discard_new_server_final`: pass, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260706_post_pg542_activated_token_discard_new_server_with_pg`: pass, 51 checks.
- `operational_surface_alignment_audit_20260706_post_pg542_activated_token_discard_new_server_final`: pass.
- `legacy_contamination_audit_20260706_post_pg542_activated_token_discard_new_server_final`: pass.
- `global_card_oracle_battle_readiness_20260706_post_pg542_activated_token_discard_new_server_final`: action_required because the global all-card backlog remains open.

## Remaining Global Queue

- Commander-legal target identities still requiring adaptation: 25,655
- XMage authoritative sources remaining: 25,341
- Missing local XMage source exceptions: 314
- Parser gaps: 0
- Adapter work units remaining: 11,368
- Post-apply exact split safe candidates: 0

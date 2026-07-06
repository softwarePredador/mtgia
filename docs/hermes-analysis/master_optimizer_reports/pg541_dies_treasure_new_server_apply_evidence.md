# PG541 Dies Treasure Apply Evidence

- Deploy ID: `pg541_dies_treasure_new_server`
- Scope: 5 XMage-authoritative creature dies Treasure rules.
- Runtime scope: `xmage_creature_dies_create_treasure_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`

## PostgreSQL

- Precheck: 5 target rows, all `target_card_rows=1`, no SQL errors.
- Existing expected rows found: 0.
- Apply: `COMMIT`, 5 rows upserted, 0 shadow rows deprecated.
- Postcheck: 5 promoted rows, all `promoted_verified_auto_rows=1`, all `promoted_oracle_hash_rows=1`.

## Promoted Cards

- `Common Crook`
- `Dire Fleet Hoarder`
- `Gleaming Barrier`
- `Jewel-Eyed Cobra`
- `Piggy Bank`

## Hermes / SQLite

- Sync command: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
- PG rows loaded: 8,832
- SQLite rows inserted or updated: 8,596
- Canonical snapshot rows exported: 6,338

## Runtime E2E

- Validator: `battle_package_end_to_end_validation.py`
- Manifest: `pg541_dies_treasure_new_server_package_manifest.json`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, battle execution.
- Battle scenarios: 5
- Battle events: 10
- Runtime evidence: every promoted card moved to graveyard and created 1 Treasure; `Gleaming Barrier` validated `defender`; `Jewel-Eyed Cobra` validated `deathtouch`.

## Contract Audits

- `xmage_strategy_consistency_audit_20260706_post_pg541_dies_treasure_new_server_final`: pass, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260706_post_pg541_dies_treasure_new_server_with_pg`: pass, 51 checks.
- `operational_surface_alignment_audit_20260706_post_pg541_dies_treasure_new_server_final`: pass.
- `legacy_contamination_audit_20260706_post_pg541_dies_treasure_new_server_final`: pass.
- `global_card_oracle_battle_readiness_20260706_post_pg541_dies_treasure_new_server`: action_required because the global XMage backlog remains open.

## Remaining Global Queue

- Commander-legal target identities still requiring adaptation: 25,659
- XMage authoritative sources remaining: 25,345
- Missing local XMage source exceptions: 314
- Parser gaps: 0
- Adapter work units remaining: 11,368

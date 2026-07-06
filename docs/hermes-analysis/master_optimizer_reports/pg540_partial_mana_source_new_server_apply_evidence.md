# PG540 Partial Mana Source Apply Evidence

- Deploy ID: `pg540_partial_mana_source_new_server`
- Scope: 143 XMage-authoritative partial mana-source rules where the executable ManaLoom subset is the mana ability only.
- Modeled subset: `mana_source_only`
- Runtime scope: `xmage_simple_tap_mana_source_permanent_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`

## PostgreSQL

- Precheck: 143 target rows, all `target_card_rows=1`, no SQL errors.
- Existing active/shadow rows found on 13 cards.
- Apply: `COMMIT`, 143 rows upserted, 26 shadow rows deprecated.
- Postcheck: 143 promoted rows, all `promoted_verified_auto_rows=1`, all `promoted_oracle_hash_rows=1`.

## Hermes / SQLite

- Sync command: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
- PG rows loaded: 8,827
- SQLite rows inserted or updated: 8,591
- Canonical snapshot rows exported: 6,333

## Runtime E2E

- Validator: `battle_package_end_to_end_validation.py`
- Manifest: `pg540_partial_mana_source_new_server_package_manifest.json`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, battle execution.
- Battle scenarios: 143
- Battle events: 148

## Contract Audits

- `pg_hermes_sqlite_contract_audit_20260706_post_pg540_partial_mana_source_new_server`: pass, 51 checks.
- `operational_surface_alignment_audit_20260706_post_pg540_partial_mana_source_new_server`: pass.
- `legacy_contamination_audit_20260706_post_pg540_partial_mana_source_new_server`: pass.
- `xmage_strategy_consistency_audit_20260706_post_pg540_partial_mana_source_new_server`: pass, 26 checks.
- `global_card_oracle_battle_readiness_20260706_post_pg540_partial_mana_source_new_server`: action_required because the global XMage backlog remains open.

## Remaining Global Queue

- Commander-legal target identities still requiring adaptation: 25,664
- XMage authoritative sources remaining: 25,350
- Missing local XMage source exceptions: 314
- Parser gaps: 0
- Adapter work units remaining: 11,368


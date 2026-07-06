# PG544 Multi-Trigger Token Apply Evidence

- Deploy ID: `pg544_multi_trigger_tokens_new_server`
- Scope: 4 XMage-authoritative fixed multi-token creature rules.
- Runtime scopes: `xmage_creature_dies_create_tokens_v1`, `xmage_creature_etb_create_tokens_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`

## PostgreSQL

- Precheck: 4 target rows, all `target_card_rows=1`, no SQL errors.
- Existing expected rows found: 0.
- Shadow cleanup: 2 existing `Wurmcoil Engine` nonmatching rows deprecated.
- Apply: `COMMIT`, 4 rows upserted, 2 shadow rows deprecated.
- Postcheck: 4 promoted rows, all `promoted_verified_auto_rows=1`, all `promoted_oracle_hash_rows=1`.
- Backup table rows: 2.

## Promoted Cards

- `Triplicate Titan`
- `Trostani's Summoner`
- `Wurmcoil Engine`
- `Wurmcoil Larva`

## Hermes / SQLite

- Sync command: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
- PG rows loaded: 8,842
- SQLite rows inserted or updated: 8,606
- Canonical snapshot rows exported: 6,347

## Runtime E2E

- Validator: `battle_package_end_to_end_validation.py`
- Manifest: `pg544_multi_trigger_tokens_new_server_package_manifest.json`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, battle execution.
- Battle scenarios: 4
- Battle events: 7
- Runtime evidence: `Triplicate Titan`, `Wurmcoil Engine`, and `Wurmcoil Larva` died and created their expected token multisets. `Trostani's Summoner` entered and created the expected Knight, Centaur, and Rhino tokens.

## Test Coverage

- `python3 -m py_compile` passed for mapper, runtime, package builder, and E2E validator.
- Focused unittest suite passed: 597 tests, 0 failures.
- Expanded runtime suite passed: 926 tests, 0 failures.

## Contract Audits

- `xmage_strategy_consistency_audit_20260706_post_pg544_multi_trigger_tokens_new_server_final`: pass, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260706_post_pg544_multi_trigger_tokens_new_server_with_pg`: pass, 51 checks.
- `operational_surface_alignment_audit_20260706_post_pg544_multi_trigger_tokens_new_server_final`: pass, 39 checks.
- `legacy_contamination_audit_20260706_post_pg544_multi_trigger_tokens_new_server_final`: pass, 32 checks.
- `global_card_oracle_battle_readiness_20260706_post_pg544_multi_trigger_tokens_new_server_final`: action_required because the global all-card backlog remains open.

## Remaining Global Queue

- Commander-legal target identities still requiring adaptation: 25,649
- XMage authoritative sources remaining: 25,335
- Missing local XMage source exceptions: 314
- Parser gaps: 0
- Adapter work units remaining: 11,366
- Post-apply exact split safe candidates: 0
- All-card readiness: 34,331 known cards; 5,301 `battle_and_oracle_ready`; 28,572 still require battle-family mapper work.

## Cleanup

- Raw queue JSON dumps for the pre-apply candidate source and post-apply global queue are not durable evidence because they are large intermediate files. Their `.md` summaries preserve the required metrics and routing signal.

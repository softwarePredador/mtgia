# PG768 Coveted Jewel ETB Draw Control Transfer Evidence - 2026-07-11

Status: `applied_synced_validated`.

Database target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`.

## Runtime Scope

- Card: `Coveted Jewel`
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/c/CovetedJewel.java`
- ManaLoom scope: `xmage_simple_mana_source_with_etb_draw_unblocked_attack_control_transfer_v1`
- Logical rule key: `battle_rule_v1:88dafe15957e9554a2f0bda79cbd27ea`
- Oracle hash: `467d89a73301ab599871111e0ceaec6d`

Implemented behavior:

- `When Coveted Jewel enters, draw three cards.`
- `{T}: Add three mana of any one color.`
- `Whenever one or more creatures an opponent controls attack you and aren't blocked, that player draws three cards and gains control of Coveted Jewel. Untap it.`

## Package Evidence

- Split: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg768_coveted_jewel_new_server.json`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg768_coveted_jewel_new_server_manifest.json`
- Precheck/apply/postcheck: `docs/hermes-analysis/master_optimizer_reports/pg768_coveted_jewel_new_server_{precheck,apply,postcheck}.sql`
- SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg768_coveted_jewel_new_server_sqlite_sync.json`
- Final E2E: `docs/hermes-analysis/master_optimizer_reports/pg768_coveted_jewel_new_server_e2e.json`

Focused tests:

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_mana_source_etb_draw_unblocked_control_transfer_maps_full_scope \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_mana_source_etb_draw_unblocked_control_transfer_manifest_builds_composite_scenario \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py::test_mana_source_etb_draw_unblocked_control_transfer_runner_resolves_full_cycle
```

Result: `3 passed in 0.84s`.

PG768 precheck/apply/postcheck:

- `target_card_rows=1`
- `existing_rule_rows=2`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=2`
- `deprecated_shadow_rows=2`
- `upserted_rows=1`
- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- backup rows: `2`

SQLite sync:

- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=10091`
- `sqlite_inserted_or_updated=9869`
- `canonical_snapshot_rows_exported=7482`
- `pg_inserted_or_updated=0`

E2E result:

- PostgreSQL source of truth: `pass`
- SQLite/Hermes cache: `pass`
- Canonical snapshot fallback: `pass`
- Runtime lookup: `pass`
- Battle execution: `pass`
- Scenario count: `1`
- Event count: `3`
- ETB cards drawn: `3`
- Available mana after refresh: `3`
- Conditional mana after refresh: `3`
- Source tapped after refresh: `true`
- Transfer cards drawn: `3`
- New controller: `Control Transfer Attacker`
- Source tapped after transfer: `false`

## Final Audits

- XMage strategy consistency: `pass`, `26/26`
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- PG/Hermes/SQLite contract: `pass`, `51/51`
- Global readiness after PG768:
  - `battle_and_oracle_ready=6496`
  - `battle_family_mapper_required=27380`
  - `snapshot_has_verified_rule=6521`
  - `snapshot_has_any_rule=7688`
- XMage authoritative queue after PG768:
  - `target_identity_count=24457`
  - `xmage_authoritative_source_count=24144`
  - `xmage_authoritative_adapter_required_count=24144`
  - `xmage_missing_source_exception_count=313`
  - `xmage_authoritative_parser_gap_count=0`

Queue delta versus post-PG767B:

- `battle_and_oracle_ready`: `6495 -> 6496`
- `battle_family_mapper_required`: `27381 -> 27380`
- `snapshot_has_verified_rule`: `6520 -> 6521`
- `xmage_authoritative_adapter_required_count`: `24145 -> 24144`

Remaining partial candidates in this mana-source auxiliary track:

- `Codie, Vociferous Codex`
- `Sage of the Maze`
- `Strixhaven Stadium`

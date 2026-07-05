# PG498 Static Generic Cost Reduction Apply Evidence

- Deploy id: `xmage_pg498_static_generic_cost_reduction_new_server`
- Runtime scope: `xmage_static_generic_cost_reduction_for_matching_spells_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`
- Promoted cards: `21`
- Blocked residual: `Edgewalker`, `Ragemonger` because they reduce colored mana with `ManaCostsImpl`.

## Apply Result

- Precheck matched `21` target rows by normalized name and oracle hash.
- Apply result: `deprecated_shadow_rows=8`, `upserted_rows=21`, `COMMIT`.
- Postcheck result: every promoted card has `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Sync And Validation

- PG -> Hermes/SQLite sync:
  `pg_rows_loaded=8415`, `sqlite_inserted_or_updated=8179`, `canonical_snapshot_rows_exported=5944`.
- SQLite validation:
  `expected=21`, `ok=21`, `missing=[]`, `wrong_scope=[]`.
- Battle suite:
  `xmage_pg498_static_generic_cost_reduction_new_server_full_battle_suite.out` passed.
- PG/Hermes/SQLite contract audit:
  `status=pass`, `51/51`.
- Post-sync exact-scope recheck:
  `proposal_count=0`, `safe_for_batch_pg_package_count=0`.

## Queue Impact

- Commander-legal XMage queue after PG498:
  `target_identity_count=26076`,
  `xmage_authoritative_source_count=25762`,
  `xmage_missing_source_exception_count=314`,
  `xmage_authoritative_parser_gap_count=0`,
  `xmage_authoritative_adapter_required_count=25762`.
- Global readiness after PG498:
  `battle_and_oracle_ready=4874`,
  `battle_family_mapper_required=28999`,
  `generic_runtime_or_no_card_rule=360`,
  `oracle_data_sync=4`,
  `commander_legality_sync=3`,
  `oracle_identity_rule_link_or_copy=2`.

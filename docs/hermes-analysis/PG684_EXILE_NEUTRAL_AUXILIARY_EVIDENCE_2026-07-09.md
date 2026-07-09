# PG684 Exile Neutral Auxiliary Evidence - 2026-07-09

Status: `applied_and_validated`.

Scope:

- `Barrier Breach`
- `Devouring Light`
- `Forsake the Worldly`
- `Wipe Clean`

Implemented parser behavior:

- `EXILE_UNIT` now uses non-neutral Oracle complexity detection.
- Resolution-neutral auxiliary lines such as `cycling` and `convoke` no longer block an otherwise exact `ExileTargetEffect` spell.
- Non-neutral modal text such as `choose one or both` remains blocked.

Runtime scope:

- `xmage_exile_target_spell_v1`
- `effect=remove_permanent` or `effect=remove_creature`
- `destination=exile`
- Barrier Breach uses `target_count_min=0`, `target_count_max=3`, `up_to_count=true`.
- Devouring Light uses `combat_state=attacking_or_blocking`.

Database target:

- `server/bin/with_new_server_pg.sh`
- `127.0.0.1:15432/halder`

PostgreSQL PG684 evidence:

- Precheck: 4/4 Oracle-hash matched target rows.
- Apply: 4 upserted rows; 0 deprecated shadow rows.
- Postcheck: 4/4 promoted rows, 4/4 `verified/auto`, 4/4 Oracle-hash matched.

PostgreSQL PG684b metadata backfill:

- Precheck: 44 trusted executable rules missing `oracle_hash`, 44 with safe `cards.oracle_text`, 0 empty Oracle.
- Apply: 44 metadata-only `oracle_hash` updates.
- Postcheck: 0 trusted executable rules still missing `oracle_hash`; 44/44 backfilled rows match `md5(cards.oracle_text)`.

Sync evidence:

- `pg_rows_loaded=6084`
- `sqlite_inserted_or_updated=6069`
- `canonical_snapshot_rows_exported=6046`

E2E evidence:

- `status=pass`
- 4 battle execution scenarios.
- 8 replay events.
- Barrier Breach exiled 3 legal enchantment targets and left the illegal land target on battlefield.
- Devouring Light exiled the attacking legal creature and left the non-attacking illegal creature on battlefield.
- Forsake the Worldly and Wipe Clean moved legal targets to exile and left illegal targets on battlefield.

Focused tests:

- `1509 passed, 230 subtests passed`

Audits:

- `quality_gate.sh server-target`: pass
- `xmage_strategy_consistency_audit`: 26/26 pass
- `operational_surface_alignment_audit`: pass
- `legacy_contamination_audit`: pass
- `pg_hermes_sqlite_contract_audit` after PG684b: 51/51 pass

Queue delta versus post-PG683:

- `battle_and_oracle_ready`: 6140 -> 6144
- `battle_family_mapper_required`: 27736 -> 27732
- `xmage_authoritative_adapter_required`: 24500 -> 24496
- `removal_exile::targeted_exile_variant_v1`: 126 -> 122
- `trusted_rule_oracle_hash_backfill`: 43 -> 0
- Post-PG684b exact-scope recheck: `proposal_count=0`

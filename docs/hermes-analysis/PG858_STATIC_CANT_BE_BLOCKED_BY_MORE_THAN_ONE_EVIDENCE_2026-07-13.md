# PG858 Static Cant Be Blocked By More Than One Evidence - 2026-07-13

Status: `applied_synced_validated`.

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

Closed exact XMage source-only max-one-blocker static creatures:

- `Bristling Boar`
- `Charging Rhino`
- `Huang Zhong, Shu General`
- `Ironhoof Ox`
- `Norwood Riders`
- `Stalking Tiger`

XMage unit:

```text
xmage_signature::CantBeBlockedByMoreThanOneSourceEffect::SimpleStaticAbility::no_target_class::no_condition_class::static_ability
```

ManaLoom runtime scope:

```text
xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1
```

Safety exclusions:

- `CantBeBlockedByMoreThanOneAllEffect`
- `CantBeBlockedByMoreThanOneAttachedEffect`
- activated variants
- `Duration.EndOfTurn` variants
- composite source files

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added exact predicate, Oracle/source validators, proposal effect JSON, and
    report routing for the source-only max-one-blocker family.
- `battle_analyst_v9.py`
  - Added `attacker_max_blockers` and blocker-assignment truncation after
    blocker choice.
- `xmage_batch_pg_package_builder.py`
  - Added package required fields and E2E scenario generation.
- `battle_package_end_to_end_validation.py`
  - Added E2E runner that validates two potential blockers collapse to the one
    expected blocker.
- Focused tests added for mapper positive/negative cases, runtime blocker
  behavior, and package manifest scenario generation.

## Split And Package

Candidate split:

```text
docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260713_pg858_static_cant_be_blocked_by_more_than_one_new_server_candidate.json
```

Result:

```text
proposal_count=6
safe_for_batch_pg_package_count=6
family_counts={"xmage_static_self_cant_be_blocked_by_more_than_one_creature": 6}
adapter_work_unit_counts={"xmage_signature::CantBeBlockedByMoreThanOneSourceEffect::SimpleStaticAbility::no_target_class::no_condition_class::static_ability": 6}
```

Package:

```text
docs/hermes-analysis/master_optimizer_reports/pg858_static_cant_be_blocked_by_more_than_one_new_server_package_manifest.json
```

## PostgreSQL Apply

Precheck:

```text
target_card_rows=1 for each selected card
existing_rule_rows=0 for each selected card
expected_rule_rows_before=0 for each selected card
would_deprecate_shadow_rows=0 for each selected card
```

Apply:

```text
deprecated_shadow_rows=0
upserted_rows=6
```

Postcheck:

```text
promoted_rule_rows=1 for each selected card
promoted_verified_auto_rows=1 for each selected card
promoted_oracle_hash_rows=1 for each selected card
backup_rows=0 for each selected card
```

Direct PG confirmation after apply:

```text
Bristling Boar           verified auto has_oracle_hash=true scope=xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1 max_blockers=1
Charging Rhino           verified auto has_oracle_hash=true scope=xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1 max_blockers=1
Huang Zhong, Shu General verified auto has_oracle_hash=true scope=xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1 max_blockers=1
Ironhoof Ox              verified auto has_oracle_hash=true scope=xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1 max_blockers=1
Norwood Riders           verified auto has_oracle_hash=true scope=xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1 max_blockers=1
Stalking Tiger           verified auto has_oracle_hash=true scope=xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1 max_blockers=1
```

## Hermes And SQLite Sync

PG -> SQLite sync report:

```text
docs/hermes-analysis/master_optimizer_reports/pg858_static_cant_be_blocked_by_more_than_one_new_server_pg_to_sqlite_sync.json
```

Result:

```text
pg_rows_loaded=6
selected_card_count=6
sqlite_inserted_or_updated=6
canonical_snapshot_rows_exported=6807
```

Metadata sync report:

```text
docs/hermes-analysis/master_optimizer_reports/pg858_static_cant_be_blocked_by_more_than_one_new_server_metadata_sync.json
```

Result:

```text
postgres_target=127.0.0.1:15432/halder
requested_unique_names=8621
postgres_cards_matched=8812
sqlite_cache_alias_rows=8751
deck_cards_backfill matched=2699/2699
unresolved_count=1
unresolved_sample=["Surgical Suite/Hospital Room"]
```

The unresolved cache alias is unrelated to this PG858 package.

## E2E Validation

Report:

```text
docs/hermes-analysis/master_optimizer_reports/pg858_static_cant_be_blocked_by_more_than_one_new_server_e2e_validation.json
```

Result:

```text
status=pass
postgres_source_of_truth=pass validated_rows=6
sqlite_hermes_cache=pass validated_rows=6
canonical_snapshot_fallback=pass validated_cards=6
runtime_get_card_effect=pass validated_cards=6
battle_execution=pass scenarios=6 events=6
```

Battle execution verified each selected card with two legal blockers available.
The runtime kept only `E2E Large Blocker`, proving `max_blockers=1` behavior.

## Coverage And Queue

Readiness after PG858:

```text
all_known_cards=34331
snapshot_has_verified_rule=6932
battle_and_oracle_ready=6825
```

Commander-legal XMage authoritative queue after PG858:

```text
target_identity_count=24058
xmage_authoritative_source_count=23745
xmage_missing_source_exception_count=313
xmage_authoritative_parser_gap_count=0
xmage_authoritative_adapter_required_count=23745
adapter_work_unit_count=11211
```

The exact max-one-blocker work unit has no remaining rows:

```text
remaining_unit_rows=0
```

Post-PG858 exact split recheck:

```text
proposal_count=0
safe_for_batch_pg_package_count=0
family_counts={}
```

## Tests And Audits

Tests:

```text
test_xmage_authoritative_exact_scope_split.py focused max-one-blocker tests: 4 passed
test_xmage_exact_scope_runtime.py focused max-one-blocker test: 1 passed
test_xmage_batch_pg_package_builder.py -k more_than_one: 1 passed, 261 deselected
test_xmage_batch_pg_package_builder.py full: 262 passed
test_xmage_exact_scope_runtime.py full: 529 passed
py_compile touched battle/XMage/package scripts: passed
```

Audits:

```text
xmage_strategy_consistency_audit: pass, 26/26
operational_surface_alignment_audit: pass
legacy_contamination_audit: pass
pg_hermes_sqlite_contract_audit: pass, 51/51
```

The first PG/Hermes/SQLite audit attempt was run without
`server/bin/with_new_server_pg.sh` and failed only because it tried to resolve
the internal host `evolution_manaloom-postgres`. The rerun through the new
server wrapper passed.

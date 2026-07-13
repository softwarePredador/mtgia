# PG860 Landfall Self-Boost Evidence - 2026-07-13

Status: `applied_synced_validated`.

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

Closed exact XMage landfall creatures that boost themselves until end of turn
when a land enters under their controller's control:

- `Akoum Hellhound`
- `Canopy Baloth`
- `Hedron Rover`
- `Hedron Scrabbler`
- `Scythe Leopard`
- `Snapping Gnarlid`
- `Steppe Lynx`
- `Territorial Baloth`
- `Valakut Predator`

XMage unit:

```text
xmage_signature::BoostSourceEffect::LandfallAbility::no_target_class::no_condition_class::no_signal
```

Required XMage shape:

```text
LandfallAbility(new BoostSourceEffect(N, N, Duration.EndOfTurn))
```

ManaLoom runtime scope:

```text
xmage_creature_landfall_self_boost_until_eot_v1
```

Safety requirements:

- exact Oracle text: `Landfall - Whenever a land you control enters, this
  creature gets +N/+N until end of turn`;
- source has exactly one `LandfallAbility` and one fixed
  `BoostSourceEffect`;
- source and Oracle fixed power/toughness boosts must match;
- only self creature target semantics are allowed;
- generic review rows remain blocked until split into a runtime-backed exact
  scope.

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added exact predicate/source parser/Oracle parser/proposal routing for
    landfall self boost until end of turn.
- `battle_analyst_v9.py`
  - Added landfall trigger execution for `landfall_self_boost` rules with
    replay events and decision trace payloads.
- `xmage_batch_pg_package_builder.py`
  - Added required effect fields and E2E scenario generation.
- `battle_package_end_to_end_validation.py`
  - Added package E2E runner that proves the source creature receives the
    expected temporary power/toughness modifier after a land enters.
- Focused tests added for mapper positive/negative cases, runtime landfall
  boost behavior, and package manifest scenario generation.

## Split And Package

Candidate split:

```text
docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260713_pg860_landfall_self_boost_new_server_candidate.json
```

Result:

```text
proposal_count=9
safe_for_batch_pg_package_count=9
family_counts={"xmage_creature_landfall_self_boost_until_eot": 9}
scope_counts={"xmage_creature_landfall_self_boost_until_eot_v1": 9}
adapter_work_unit_counts={"xmage_signature::BoostSourceEffect::LandfallAbility::no_target_class::no_condition_class::no_signal": 9}
```

Package:

```text
docs/hermes-analysis/master_optimizer_reports/pg860_landfall_self_boost_new_server_package_manifest.json
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
upserted_rows=9
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
Akoum Hellhound    verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +2/+2 has_oracle_hash=true
Canopy Baloth      verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +2/+2 has_oracle_hash=true
Hedron Rover       verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +2/+2 has_oracle_hash=true
Hedron Scrabbler   verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +1/+1 has_oracle_hash=true
Scythe Leopard     verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +1/+1 has_oracle_hash=true
Snapping Gnarlid   verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +1/+1 has_oracle_hash=true
Steppe Lynx        verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +2/+2 has_oracle_hash=true
Territorial Baloth verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +2/+2 has_oracle_hash=true
Valakut Predator   verified auto scope=xmage_creature_landfall_self_boost_until_eot_v1 trigger=landfall +2/+2 has_oracle_hash=true
```

## Hermes And SQLite Sync

PG -> SQLite selective sync report:

```text
docs/hermes-analysis/master_optimizer_reports/pg860_landfall_self_boost_new_server_pg_to_sqlite_sync.json
```

Result:

```text
pg_rows_loaded=9
selected_card_count=9
sqlite_inserted_or_updated=9
canonical_snapshot_rows_exported=6819
```

Metadata sync report:

```text
docs/hermes-analysis/master_optimizer_reports/pg860_landfall_self_boost_new_server_metadata_sync.json
```

Result:

```text
postgres_target=127.0.0.1:15432/halder
requested_unique_names=8633
postgres_cards_matched=8824
sqlite_cache_alias_rows=8763
deck_cards_backfill matched=2699/2699
unresolved_count=1
unresolved_sample=["Surgical Suite/Hospital Room"]
```

The unresolved cache alias is unrelated to this PG860 package.

## E2E Validation

Report:

```text
docs/hermes-analysis/master_optimizer_reports/pg860_landfall_self_boost_new_server_e2e_validation.json
```

Result:

```text
status=pass
postgres_source_of_truth=pass validated_rows=9
sqlite_hermes_cache=pass validated_rows=9
canonical_snapshot_fallback=pass validated_cards=9
runtime_get_card_effect=pass validated_cards=9
battle_execution=pass scenarios=9 events=18
```

Battle execution proved the expected temporary boosts:

```text
Akoum Hellhound    power_delta=2 toughness_delta=2 source_power=4 source_toughness=4
Canopy Baloth      power_delta=2 toughness_delta=2 source_power=4 source_toughness=4
Hedron Rover       power_delta=2 toughness_delta=2 source_power=4 source_toughness=4
Hedron Scrabbler   power_delta=1 toughness_delta=1 source_power=3 source_toughness=3
Scythe Leopard     power_delta=1 toughness_delta=1 source_power=3 source_toughness=3
Snapping Gnarlid   power_delta=1 toughness_delta=1 source_power=3 source_toughness=3
Steppe Lynx        power_delta=2 toughness_delta=2 source_power=4 source_toughness=4
Territorial Baloth power_delta=2 toughness_delta=2 source_power=4 source_toughness=4
Valakut Predator   power_delta=2 toughness_delta=2 source_power=4 source_toughness=4
```

## PG860B Trusted Rule Oracle Hash Backfill

The final PG/Hermes/SQLite contract audit exposed older trusted executable
PostgreSQL rows without `oracle_hash`. They were unrelated to landfall, but
violated the current trusted-rule contract.

Backfill package:

```text
docs/hermes-analysis/master_optimizer_reports/pg860b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql
docs/hermes-analysis/master_optimizer_reports/pg860b_trusted_rule_oracle_hash_backfill_new_server_apply.sql
docs/hermes-analysis/master_optimizer_reports/pg860b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql
docs/hermes-analysis/master_optimizer_reports/pg860b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql
```

Result:

```text
precheck would_backfill_rows=55 distinct_cards=54 verified_rows=32 active_rows=23 empty_oracle_hash_rows=0
apply backup_rows=55 updated_rows=55
postcheck trusted_executable_rules_missing_oracle_hash=0 backup_rows=55 updated_rows_with_current_oracle_hash=55
```

Full PG -> SQLite sync after the hash backfill:

```text
docs/hermes-analysis/master_optimizer_reports/pg860b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json
```

Result:

```text
pg_rows_loaded=6870
sqlite_inserted_or_updated=6865
canonical_snapshot_rows_exported=6819
```

## Coverage And Queue

Readiness after PG860B:

```text
all_known_cards=34331
battle_and_oracle_ready=6837
battle_family_mapper_required=26957
battle_rule_verification_required=70
```

Commander-legal XMage authoritative queue after PG860B:

```text
target_identity_count=24046
xmage_authoritative_source_count=23733
xmage_missing_source_exception_count=313
xmage_authoritative_parser_gap_count=0
xmage_authoritative_adapter_required_count=23733
adapter_work_unit_count=11210
```

Post-PG860 exact split recheck:

```text
proposal_count=0
safe_for_batch_pg_package_count=0
family_counts={}
adapter_work_unit_counts={}
```

## Tests And Audits

Tests:

```text
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest ...test_landfall_self_boost_maps_fixed_until_eot ...test_landfall_self_boost_rejects_source_oracle_mismatch
2 tests OK

python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py
531 tests OK

python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -q
264 passed

python3 -m py_compile <touched scripts>
OK
```

Additional attempted broad suite:

```text
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py
1183 tests run, 4 failures outside the PG860 landfall diff:
- activated_target_boost filtered target permanent reason expectation
- exact split report runtime partial safe count expectation
- fixed draw/discard spell source effect class expectation
- permanent activated X damage dynamic amount expectation
```

The PG860 diff only adds the landfall mapper block and does not touch those
four pre-existing split areas. The focused landfall split tests passed.

Final governance audits after PG860B:

```text
xmage_strategy_consistency_audit: pass 26/26
operational_surface_alignment_audit: pass
legacy_contamination_audit: pass
pg_hermes_sqlite_contract_audit: pass 51/51
```

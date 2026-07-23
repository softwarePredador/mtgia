# PG859 Becomes Blocked Draw Evidence - 2026-07-13

Status: `applied_synced_validated`.

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

Closed exact XMage draw-engine creatures that draw when they become blocked:

- `Chambered Nautilus`
- `Drelnoch`
- `Saprazzan Heir`

XMage unit:

```text
draw_engine::xmage_draw_card_variant_review_v1
```

Required XMage shape:

```text
DrawCardSourceControllerEffect + BecomesBlockedSourceTriggeredAbility
```

ManaLoom runtime scope:

```text
xmage_creature_becomes_blocked_draw_cards_v1
```

Safety requirements:

- exact Oracle text: whenever this creature/name becomes blocked, you may draw
  a fixed number of cards;
- source uses `BecomesBlockedSourceTriggeredAbility(..., true)`;
- source has a single fixed `DrawCardSourceControllerEffect(n)`;
- only static self keyword auxiliary abilities are allowed;
- generic `xmage_*_review_v1` rows remain blocked unless split into this exact
  runtime-backed scope.

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added exact predicate/source parser/Oracle parser/proposal routing for
    optional fixed draw when the source creature becomes blocked.
  - Corrected the new predicate to use the real queue work unit
    `draw_engine::xmage_draw_card_variant_review_v1` with signals
    `draw,triggered_ability`.
- `battle_analyst_v9.py`
  - Added `resolve_becomes_blocked_draw_triggers`, replay events, and decision
    trace payloads for the trigger.
- `xmage_batch_pg_package_builder.py`
  - Added required effect fields and E2E scenario generation.
- `battle_package_end_to_end_validation.py`
  - Added package E2E runner that proves hand/library deltas and trigger
    events.
- Focused tests added for mapper positive/negative cases, runtime draw
  behavior, and package manifest scenario generation.

## Split And Package

Candidate split:

```text
docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260713_pg859_becomes_blocked_draw_new_server_candidate.json
```

Result:

```text
proposal_count=3
safe_for_batch_pg_package_count=3
family_counts={"xmage_creature_becomes_blocked_draw_cards": 3}
scope_counts={"xmage_creature_becomes_blocked_draw_cards_v1": 3}
adapter_work_unit_counts={"draw_engine::xmage_draw_card_variant_review_v1": 3}
```

Package:

```text
docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_package_manifest.json
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
upserted_rows=3
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
Chambered Nautilus verified auto has_oracle_hash=true scope=xmage_creature_becomes_blocked_draw_cards_v1 draw_count=1 optional=true
Drelnoch           verified auto has_oracle_hash=true scope=xmage_creature_becomes_blocked_draw_cards_v1 draw_count=2 optional=true
Saprazzan Heir     verified auto has_oracle_hash=true scope=xmage_creature_becomes_blocked_draw_cards_v1 draw_count=3 optional=true
```

## Hermes And SQLite Sync

PG -> SQLite sync report:

```text
docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_pg_to_sqlite_sync.json
```

Result:

```text
pg_rows_loaded=3
selected_card_count=3
sqlite_inserted_or_updated=3
canonical_snapshot_rows_exported=6810
```

Metadata sync report:

```text
docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_metadata_sync.json
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

The unresolved cache alias is unrelated to this PG859 package.

## E2E Validation

Report:

```text
docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_e2e_validation.json
```

Result:

```text
status=pass
postgres_source_of_truth=pass validated_rows=3
sqlite_hermes_cache=pass validated_rows=3
canonical_snapshot_fallback=pass validated_cards=3
runtime_get_card_effect=pass validated_cards=3
battle_execution=pass scenarios=3 events=6
```

Battle execution proved the expected draw counts:

```text
Chambered Nautilus cards_drawn=1 hand_after=1 library_after=0
Drelnoch           cards_drawn=2 hand_after=2 library_after=0
Saprazzan Heir     cards_drawn=3 hand_after=3 library_after=0
```

## Coverage And Queue

Readiness after PG859:

```text
all_known_cards=34331
snapshot_has_verified_rule=6935
battle_and_oracle_ready=6828
battle_family_mapper_required=26966
```

Commander-legal XMage authoritative queue after PG859:

```text
target_identity_count=24055
xmage_authoritative_source_count=23742
xmage_missing_source_exception_count=313
xmage_authoritative_parser_gap_count=0
xmage_authoritative_adapter_required_count=23742
adapter_work_unit_count=11211
```

Post-PG859 exact split recheck:

```text
proposal_count=0
safe_for_batch_pg_package_count=0
family_counts={}
adapter_work_unit_counts={}
```

## Tests And Audits

Tests:

```text
test_xmage_authoritative_exact_scope_split.py focused becomes-blocked draw tests: 2 passed
test_xmage_exact_scope_runtime.py focused becomes-blocked draw test: 1 passed
test_xmage_batch_pg_package_builder.py -k becomes_blocked_draw: 1 passed, 262 deselected
test_xmage_batch_pg_package_builder.py full: 263 passed
test_xmage_exact_scope_runtime.py full: 530 passed
py_compile touched battle/XMage/package scripts: passed
```

Audits:

```text
xmage_strategy_consistency_audit: pass 26/26
operational_surface_alignment_audit: pass
legacy_contamination_audit: pass
pg_hermes_sqlite_contract_audit: pass 51/51
```

## Evidence Files

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260713_pg859_becomes_blocked_draw_new_server_candidate.md`
- `docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260713_post_pg859_becomes_blocked_draw_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260713_post_pg859_becomes_blocked_draw_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260713_post_pg859_becomes_blocked_draw_new_server_recheck.md`
- `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260713_post_pg859_becomes_blocked_draw_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260713_post_pg859_becomes_blocked_draw_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260713_post_pg859_becomes_blocked_draw_new_server_final.md`

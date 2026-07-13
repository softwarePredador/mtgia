# PG857 Static Attacks Each Combat Evidence - 2026-07-13

Status: `applied_synced_validated_committed_candidate`.

## Scope

Promoted the XMage exact static combat requirement family:

- `battle_model_scope`: `xmage_static_self_attacks_each_combat_creature_v1`
- `family_id`: `xmage_static_self_attacks_each_combat_creature`
- XMage requirement: `AttacksEachCombatStaticAbility`
- ManaLoom runtime fields:
  - `attacks_each_combat_if_able=true`
  - `must_attack_each_combat_if_able=true`
  - `must_attack_if_able=true`

Cards promoted:

- Ashen Monstrosity
- Berserkers of Blood Ridge
- Bloodrock Cyclops
- Crazed Goblin
- Flameborn Hellion
- Frontline Rebel
- Goblin Brigand
- Impetuous Sunchaser
- Reckless Brute
- Riot Piker
- Rubblebelt Recluse
- Tattermunge Maniac
- Urborg Drake
- Utvara Scalper
- Valley Dasher

## Runtime And Tests

Focused tests passed:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_static_attacks_each_combat_creature_maps_exact_requirement test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_static_attacks_each_combat_creature_blocks_nonmatching_oracle`
- `python3 -m unittest test_xmage_exact_scope_runtime.XMageExactScopeRuntimeTest.test_static_attacks_each_combat_creature_is_selected_even_with_zero_power`
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -q`
- `python3 -m py_compile` for `battle_package_end_to_end_validation.py`, `xmage_authoritative_exact_scope_split.py`, and `xmage_batch_pg_package_builder.py`

Full builder test result: `261 passed`.

## PostgreSQL Package

Package files:

- `pg857_static_attacks_each_combat_new_server_package_precheck.sql`
- `pg857_static_attacks_each_combat_new_server_package_apply.sql`
- `pg857_static_attacks_each_combat_new_server_package_postcheck.sql`
- `pg857_static_attacks_each_combat_new_server_package_rollback.sql`

Precheck:

- `target_card_rows=1` for all 15 cards
- `existing_rule_rows=0`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=0`

Apply:

- `upserted_rows=15`
- `deprecated_shadow_rows=0`

Postcheck:

- `promoted_rule_rows=1` for all 15 cards
- `promoted_verified_auto_rows=1` for all 15 cards
- `promoted_oracle_hash_rows=1` for all 15 cards

## Sync And E2E

PG -> SQLite battle rule sync:

- `selected_card_count=15`
- `pg_rows_loaded=15`
- `sqlite_inserted_or_updated=15`
- `canonical_snapshot_rows_exported=6801`

Hermes metadata sync:

- PostgreSQL target: `127.0.0.1:15432/halder`
- `postgres cards matched=8806`
- `sqlite cache alias rows=8745`
- `unresolved=1`

Package E2E:

- Status: `pass`
- PostgreSQL source rows validated: `15`
- SQLite cache rows validated: `15`
- Snapshot fallback cards validated: `15`
- Runtime `get_card_effect` cards validated: `15`
- Battle execution scenarios: `15`
- Each scenario confirmed `must_attack=true`, `should_attack=true`, and selected the card as attacker.

## PG857B Hash Integrity Repair

The post-PG857 contract audit found `32` old trusted executable PostgreSQL rows missing `oracle_hash`. PG857B backfilled only rows where current `cards.oracle_text` produced one safe hash for the exact `card_id`.

PG857B package files:

- `pg857b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `pg857b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `pg857b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `pg857b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

PG857B precheck/apply/postcheck:

- `missing_verified_executable_rows=32`
- `safe_to_backfill=32`
- `unsafe_to_backfill=0`
- `backup_rows=32`
- `updated_rows=32`
- `trusted_executable_rules_missing_oracle_hash=0`

PG857B PG -> SQLite sync:

- `selected_card_count=32`
- `pg_rows_loaded=52`
- `sqlite_inserted_or_updated=57`
- `canonical_snapshot_rows_exported=6801`

## Final Audits

- XMage strategy consistency: `pass`, `26/26`
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- PG/Hermes/SQLite contract after PG857B: `pass`, `51/51`

Final readiness snapshot:

- `total_snapshot_cards=34331`
- `snapshot_has_verified_rule=6926`
- `battle_and_oracle_ready=6819`
- `battle_family_mapper_required=26975`
- `battle_rule_verification_required=70`
- `generic_runtime_or_no_card_rule=359`
- `official_oracle_identity_unavailable=3`
- `xmage_authoritative_adapter_required_count=23751`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`
- Recheck exact split after PG857: `proposal_count=0`, `safe_for_batch_pg_package_count=0`

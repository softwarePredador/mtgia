# PG497 ETB Counter Target Constraints Apply Evidence

- Deploy ID: `xmage_pg497_etb_counter_target_constraints_new_server`
- PostgreSQL target: `143.198.230.247:5433/halder`
- Scope: `xmage_creature_etb_add_counters_target_creature_v1`
- Family: `xmage_creature_etb_add_counters_target_creature`
- Selected cards: `14`

## Selected Cards

- Aeronaut Cavalry
- Basri's Acolyte
- Earth Kingdom Soldier
- Felidar Savior
- Gavony Silversmith
- Jade Bearer
- Keen-Eyed Raven
- Pileated Provisioner
- Sanguine Glorifier
- Skinrender
- Sterling Supplier
- Stromkirk Mentor
- Timberland Guide
- Vineshaper Mystic

## Precheck

Precheck found one target card row for each selected card, no existing promoted
rule rows for this deploy scope, expected rule rows before apply equal to `0`,
and no shadow rows requiring deprecation.

## Apply

The apply transaction created the backup schema if needed, found no shadow rows
to deprecate, upserted `14` verified/auto battle-rule rows, and committed.

Key apply result:

```text
deprecated_shadow_rows=0
upserted_rows=14
COMMIT
```

## Postcheck

Postcheck confirmed all `14` cards with:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- `backup_rows=0`

## Sync And Runtime Validation

- Metadata sync target: `143.198.230.247:5433/halder`
- Metadata sync matched `6904` PostgreSQL card rows, wrote `6832` SQLite cache
  alias rows, updated `96` deck-card ids, and left `unresolved=1`.
- Battle-rule sync loaded `8394` PostgreSQL rows, wrote `8158` SQLite rows,
  and exported `5928` canonical snapshot rows.
- E2E validation passed PostgreSQL source of truth, SQLite Hermes cache,
  canonical snapshot fallback, and runtime `get_card_effect` for all `14`
  selected cards.
- Focused runtime coverage is in `battle_card_specific_tests.py` for
  up-to-two "other controlled" targets and "without flying" exclusions.
- Full battle suite passed with `625` PASS lines.
- Full exact-scope splitter suite passed with `499` tests.

## Queue Impact

Post-PG497 Commander-legal queue:

- `target_identity_count=26097`
- `xmage_authoritative_source_count=25783`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25783`
- `add_counters::targeted_add_counters_variant_v1=440`

Post-PG497 readiness:

- `all_known_cards=34331`
- `battle_and_oracle_ready=4853`
- `battle_family_mapper_required=29020`
- `generic_runtime_or_no_card_rule=360`
- `oracle_data_sync=4`
- `commander_legality_sync=3`
- `oracle_identity_rule_link_or_copy=2`

## Blocked Neighbor

`Angelic Quartermaster` remains blocked as
`etb_add_counters_source_oracle_mismatch`: local XMage constrains the targets
to another creature controlled by the source controller, while Oracle text says
"other target creatures" without the same controller restriction.

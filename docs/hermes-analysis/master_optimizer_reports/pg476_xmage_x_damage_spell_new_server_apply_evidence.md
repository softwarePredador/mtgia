# PG476 XMage X Damage Spell Apply Evidence

Status: `pass`

Generated at: `2026-07-05T03:03:36Z`

Database target: `143.198.230.247:5433/halder`

## Scope

PG476 closes the exact XMage X damage spell family as
`xmage_x_damage_target_spell_v1`.

Cards:

- `Blaze`
- `Heat Ray`
- `Volcanic Geyser`

The package uses `effect=direct_damage`, `amount=0`, `damage=0`, and
`damage_amount_source=x_value`. In runtime terms, the actual damage comes from
the X value paid during cast.

## Validation

- Focused X-damage mapper/runtime tests: `2` tests passed.
- Full focused split/runtime lane:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`
  passed `722` tests.
- `python3 test_xmage_batch_pg_package_builder.py`: pass.
- `python3 -m py_compile ...`: pass for the queue, battle runtime, package
  builder, E2E validator, and sync scripts.

During validation, the builder was tightened to require `amount` in
`E2E_REQUIRED_EFFECT_FIELDS`, including `amount=0`. This prevents future
X-damage packages from passing E2E with only `damage_amount_source=x_value`
while omitting the explicit base amount.

## PostgreSQL Apply

Source:
`docs/hermes-analysis/master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_pg_apply_evidence.json`

- Precheck: `3/3` target rows found, `0` missing targets, `0` expected rows
  already present, and `0` nonmatching shadow rows to deprecate.
- Postcheck: `3/3` promoted rows, `3/3` verified/auto, `3/3` Oracle hashes,
  `0` backup rows, `failed_cards=[]`.
- Direct PostgreSQL verification passed for `effect=direct_damage`,
  `battle_model_scope=xmage_x_damage_target_spell_v1`, `amount=0`, `damage=0`,
  `damage_amount_source=x_value`, target metadata, `rule_version=2`, and Oracle
  hashes.

## Sync And E2E

- Metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_metadata_sync_operational.json`
  matched `5693` PostgreSQL cards, wrote `5604` SQLite alias rows, and updated
  `108` `deck_cards.card_id` rows.
- Runtime sync:
  `docs/hermes-analysis/master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_full_pg_to_sqlite_sync_operational.json`
  loaded `4529` PostgreSQL runtime rows, wrote `4521` SQLite rows, and exported
  `4496` canonical snapshot rows.
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_e2e_validation.json`
  passed PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot,
  and runtime `get_card_effect` for all `3` cards.
- Additional cache verification confirmed SQLite `battle_card_rules` and
  `known_cards_canonical_snapshot.json` both preserve `amount=0`, `damage=0`,
  and `damage_amount_source=x_value`.

## Queue Result

Post-sync Commander-legal queue:

- `target_identity_count=26357`
- `xmage_authoritative_source_count=26043`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26043`

This is an exact reduction of `3` from the post-PG475 queue.

The post-PG476 exact split reports `proposal_count=18` and
`safe_for_batch_pg_package_count=18`.

## Final Audits

- XMage strategy: `26/26` pass.
- Operational surface: `39/39` pass.
- Legacy contamination: `32/32` pass.
- PG/Hermes/SQLite contract with live PostgreSQL: `51/51` pass.

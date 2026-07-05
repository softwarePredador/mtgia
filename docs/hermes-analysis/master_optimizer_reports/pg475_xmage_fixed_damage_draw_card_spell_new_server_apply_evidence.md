# PG475 XMage Fixed Damage Draw Card Spell Apply Evidence

Status: `pass`

Generated at: `2026-07-05T02:55:16Z`

Database target: `143.198.230.247:5433/halder`

## Scope

PG475 closes the exact XMage fixed damage plus draw spell family as
`xmage_fixed_damage_target_and_draw_card_spell_v1`.

Cards:

- `Ember Shot`
- `Playful Shove`
- `Zap`

The builder now requires `_composite_rule_components` in E2E required fields,
so composite damage plus draw rules cannot pass package validation while
missing the direct-damage and draw-card component payloads.

## Validation

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`: `722` tests passed.
- `python3 test_xmage_batch_pg_package_builder.py`: pass.
- `python3 -m py_compile ...`: pass for the queue, battle runtime, package
  builder, E2E validator, and sync scripts.

## PostgreSQL Apply

Source:
`docs/hermes-analysis/master_optimizer_reports/pg475_xmage_fixed_damage_draw_card_spell_new_server_pg_apply_evidence.json`

- Precheck: `3/3` target rows found, `0` missing targets, `0` expected rows
  already present, and `2` nonmatching shadow rows to deprecate.
- Postcheck: `3/3` promoted rows, `3/3` verified/auto, `3/3` Oracle hashes,
  `2` backup rows, `failed_cards=[]`.
- Direct PostgreSQL verification passed for `effect=composite_resolution`,
  `battle_model_scope=xmage_fixed_damage_target_and_draw_card_spell_v1`,
  fixed damage/count fields, `target=any_target`, target constraints, and
  `_composite_rule_components` containing `direct_damage` then `draw_cards`.

## Sync And E2E

- Metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg475_xmage_fixed_damage_draw_card_spell_new_server_metadata_sync_operational.json`
  matched `5690` PostgreSQL cards, wrote `5601` SQLite alias rows, and updated
  `105` `deck_cards.card_id` rows.
- Runtime sync:
  `docs/hermes-analysis/master_optimizer_reports/pg475_xmage_fixed_damage_draw_card_spell_new_server_full_pg_to_sqlite_sync_operational.json`
  loaded `4526` PostgreSQL runtime rows, wrote `4518` SQLite rows, and exported
  `4493` canonical snapshot rows.
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg475_xmage_fixed_damage_draw_card_spell_new_server_e2e_validation.json`
  passed PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot,
  and runtime `get_card_effect` for all `3` cards.
- Additional cache verification confirmed SQLite `battle_card_rules` and
  `known_cards_canonical_snapshot.json` both preserve the two composite
  components: `direct_damage` and `draw_cards`.

## Queue Result

Post-sync Commander-legal queue:

- `target_identity_count=26360`
- `xmage_authoritative_source_count=26046`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26046`

This is an exact reduction of `3` from the post-PG474 queue.

The post-PG475 exact split reports `proposal_count=21` and
`safe_for_batch_pg_package_count=21`.

## Final Audits

- XMage strategy: `26/26` pass.
- Operational surface: `39/39` pass.
- Legacy contamination: `32/32` pass.
- PG/Hermes/SQLite contract with live PostgreSQL: `51/51` pass.

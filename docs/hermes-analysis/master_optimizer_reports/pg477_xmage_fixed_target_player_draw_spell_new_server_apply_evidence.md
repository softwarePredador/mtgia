# PG477 XMage Fixed Target Player Draw Spell Apply Evidence

Status: `pass`

Generated at: `2026-07-05T03:11:38Z`

Database target: `143.198.230.247:5433/halder`

## Scope

PG477 closes the exact XMage fixed target-player draw spell family as
`xmage_fixed_target_player_draw_spell_v1`.

Cards:

- `Inspiration`
- `Opportunity`
- `Overflowing Insight`

The package uses `effect=draw_cards`, target `player`,
`target_controller=target_player`, `target_player_draw=true`, and
`target_preference=self`.

## Validation

- Focused target-player draw mapper/runtime tests: `3` tests passed.
- Full focused split/runtime lane:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`
  passed `722` tests.
- `python3 test_xmage_batch_pg_package_builder.py`: pass.
- `python3 -m py_compile ...`: pass for the queue, battle runtime, package
  builder, E2E validator, and sync scripts.

## PostgreSQL Apply

Source:
`docs/hermes-analysis/master_optimizer_reports/pg477_xmage_fixed_target_player_draw_spell_new_server_pg_apply_evidence.json`

- Precheck: `3/3` target rows found, `0` missing targets, `0` expected rows
  already present, and `0` nonmatching shadow rows to deprecate.
- Postcheck: `3/3` promoted rows, `3/3` verified/auto, `3/3` Oracle hashes,
  `0` backup rows, `failed_cards=[]`.
- Direct PostgreSQL verification passed for `effect=draw_cards`,
  `battle_model_scope=xmage_fixed_target_player_draw_spell_v1`, target-player
  metadata, `rule_version=2`, and Oracle hashes. Draw counts were
  `Inspiration=2`, `Opportunity=4`, and `Overflowing Insight=7`.

## Sync And E2E

- Metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg477_xmage_fixed_target_player_draw_spell_new_server_metadata_sync_operational.json`
  matched `5696` PostgreSQL cards, wrote `5607` SQLite alias rows, and updated
  `108` `deck_cards.card_id` rows.
- Runtime sync:
  `docs/hermes-analysis/master_optimizer_reports/pg477_xmage_fixed_target_player_draw_spell_new_server_full_pg_to_sqlite_sync_operational.json`
  loaded `4532` PostgreSQL runtime rows, wrote `4524` SQLite rows, and exported
  `4499` canonical snapshot rows.
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg477_xmage_fixed_target_player_draw_spell_new_server_e2e_validation.json`
  passed PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot,
  and runtime `get_card_effect` for all `3` cards.
- Additional cache verification confirmed SQLite `battle_card_rules` and
  `known_cards_canonical_snapshot.json` both preserve `count`, `draw_count`,
  target-player metadata, and `target_preference=self`.

## Queue Result

Post-sync Commander-legal queue:

- `target_identity_count=26354`
- `xmage_authoritative_source_count=26040`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26040`

This is an exact reduction of `3` from the post-PG476 queue.

The post-PG477 exact split reports `proposal_count=15` and
`safe_for_batch_pg_package_count=15`.

## Final Audits

- XMage strategy: `26/26` pass.
- Operational surface: `39/39` pass.
- Legacy contamination: `32/32` pass.
- PG/Hermes/SQLite contract with live PostgreSQL: `51/51` pass.

# PG474 XMage Simple Mana Source With ETB Draw Evidence

Status: `pass`.

PG474 closed the exact XMage family
`xmage_simple_mana_source_with_etb_draw` as ManaLoom runtime scope
`xmage_simple_mana_source_with_etb_draw_v1`.

Selected cards:

- Arcum's Astrolabe
- Energy Refractor
- Llanowar Visionary
- Prophetic Prism

Runtime change:

- `battle_analyst_v9.py` now resolves generic permanent ETB triggers in the
  natural `cast_spells_v8` ramp path.
- The same path now pays `activation_mana_cost` through
  `pay_mana_source_activation_costs` before immediate mana production.
- Focused runtime coverage added:
  `test_natural_ramp_cast_resolves_etb_draw_and_pays_mana_activation_cost`.

Validation:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`
  passed `722` tests.
- `python3 test_xmage_batch_pg_package_builder.py` passed.
- `py_compile` passed for splitter, battle runtime, package builder, E2E
  validation, and sync scripts.

PostgreSQL:

- Target: `143.198.230.247:5433/halder`.
- Precheck: `4` target rows, `0` missing, `0` existing expected rows, `0`
  stale shadow rows.
- Postcheck: `4/4` promoted rows, `4/4` verified/auto, `4/4` Oracle hash
  matched, `failed_cards=[]`.
- Direct SQL verification confirmed ETB draw, mana source fields, activation
  cost/tap fields, produced mana fields, permanent type, Oracle hash,
  `review_status=verified`, `execution_status=auto`, and `rule_version=2`.

Sync and E2E:

- Metadata sync completed against `knowledge.db`.
- Full PG to SQLite runtime sync loaded `4523` PostgreSQL rows, wrote `4515`
  SQLite rows, and exported `4490` canonical snapshot rows.
- Package E2E passed PostgreSQL `4/4`, SQLite `4/4`, canonical snapshot `4/4`,
  and runtime `get_card_effect` `4/4`.
- The package manifest has no generic battle scenario override; natural battle
  execution is covered by the focused runtime test above.

Post-PG474 queue:

- `target_identity_count=26363`
- `xmage_authoritative_source_count=26049`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26049`
- `manual_semantic_decision_units_remaining=314`
- `adapter_work_unit_count=11393`

Post-PG474 exact split:

- `proposal_count=24`
- `safe_for_batch_pg_package_count=24`
- Largest remaining package-ready families:
  `xmage_fixed_damage_draw_card_spell`, `xmage_fixed_target_player_draw_spell`,
  `xmage_x_damage_spell`, `xmage_graveyard_multi_zone_recursion_spell`,
  `xmage_static_play_lands_from_graveyard`,
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell`.

Alignment audits:

- XMage strategy consistency: `pass`, `26/26`.
- Operational surface alignment: `pass`.
- Legacy contamination: `pass`.
- PG/Hermes/SQLite contract: `pass`, `51/51`.

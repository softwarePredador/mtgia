# PG780/PG780B Additional Sacrifice Cost Evidence - 2026-07-11

Status: `closed_on_new_server`

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## Scope

PG780 promoted XMage-derived additional-cost runtime support for exact
counter/exile spell scopes:

- `Abjure` -> `xmage_counter_target_spell_v1`, `sacrifice_blue_permanent`
- `Deprive` -> `xmage_counter_target_spell_v1`, `return_land_to_hand`
- `Final Vengeance` -> `xmage_exile_target_spell_v1`, `sacrifice_creature_or_enchantment`
- `Withering Boon` -> `xmage_counter_target_spell_v1`, `pay_life`
- `Worthy Cost` -> `xmage_exile_target_spell_v1`, `sacrifice_creature`

PG780B backfilled trusted battle-rule `oracle_hash` values from
`cards.oracle_text` for `55` existing curated trusted rules:

- First pass: `32` `curated/verified/auto` rows.
- Second pass: `23` `curated/active/auto` rows.
- Postcheck: `backup_rows=55`, `backfilled_rows=55`,
  `remaining_target_rows=0`.

## Runtime Fix

The first E2E run caught a real runtime gap: counterspell responses paid mana
and resolved the counter, but did not call `pay_additional_card_costs`. The
runtime now:

- filters castable counterspells by `additional_card_costs_are_payable`;
- pays additional costs before moving the counterspell to the graveyard;
- emits `additional_cost_paid` for counterspell responses such as Abjure and
  Deprive.

## Sync And E2E

Sync commands completed against the new-server PostgreSQL target:

- `sync_pg_card_metadata_to_hermes.py`: `matched=2699/2699`,
  `card_id_updates=107`, unresolved `1`.
- `sync_battle_card_rules_pg.py`: `pg_rows_loaded=6482`,
  `canonical_snapshot_rows_exported=6433`.

Final E2E artifact:

- `docs/hermes-analysis/master_optimizer_reports/pg780_additional_sacrifice_cost_new_server_e2e_validation_final.json`
- Status: `pass`
- PostgreSQL rows validated: `5`
- SQLite rows validated: `5`
- Snapshot cards validated: `5`
- Runtime `get_card_effect` cards validated: `5`
- Battle scenarios executed: `5`

## Final Counters

Readiness artifact:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg780b_final_new_server.json`

Counters:

- `battle_and_oracle_ready=6531`
- `battle_family_mapper_required=27345`
- `snapshot_has_any_rule=7722`
- `snapshot_has_verified_rule=6556`
- `trusted_rule_oracle_hash_backfill` no longer appears in lane counts.

Queue artifact:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg780b_hash_backfill_new_server.json`

Counters:

- `target_identity_count=24422`
- `xmage_authoritative_source_count=24109`
- `xmage_authoritative_adapter_required_count=24109`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`
- `adapter_work_unit_count=11285`

## Audits And Tests

Audits:

- `xmage_strategy_consistency_audit_20260711_post_pg780b_final_new_server`: pass, `26/26`.
- `pg_hermes_sqlite_contract_audit_20260711_post_pg780b_final_new_server`: pass, `51/51`.
- `operational_surface_alignment_audit_20260711_post_pg780b_final_new_server`: pass.
- `legacy_contamination_audit_20260711_post_pg780b_final_new_server`: pass.
- `scripts/quality_gate.sh server-target`: pass.

Tests:

- `python3 -m py_compile battle_analyst_v9.py battle_package_end_to_end_validation.py xmage_authoritative_exact_scope_split.py xmage_batch_pg_package_builder.py`: pass.
- From `docs/hermes-analysis/manaloom-knowledge/scripts`:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_battle_runtime_surface_manifest.py test_runtime_pg_rule_fallback_for_promoted_hotfixes.py test_battle_package_end_to_end_validation.py`
  -> `1062` tests OK, `3` skipped.

## Next Queue

The next high-volume adapter work units after PG780/PG780B remain:

- `recursion::xmage_graveyard_return_variant_review_v1` (`1792`)
- `draw_engine::xmage_draw_card_variant_review_v1` (`1553`)
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` (`1064`)
- `add_counters::source_add_counters_variant_v1` (`768`)
- `direct_damage::targeted_damage_variant_v1` (`739`)

# PG377 Keyword Reminder Wave - New Server Evidence

- Generated at: `2026-07-04`
- PostgreSQL target: new EasyPanel server through local tunnel
  `127.0.0.1:15432/halder`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_package.md`
- Exact split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg377_keyword_reminder_probe.md`

## Scope

PG377 promotes exact keyword-until-end-of-turn rules that were previously
blocked only because Oracle reminder text appeared in parenthetical clauses.

- `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1`: `25`
- `xmage_permanent_simple_activated_target_keyword_until_eot_v1`: `7`
- total promoted cards: `32`

## PostgreSQL Gate

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_precheck_new_server.txt`
  - target card rows: `32/32`
  - expected rule rows before apply: `0`
  - shadow rows to deprecate: `0`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_apply_new_server.txt`
  - `upserted_rows=32`
  - `deprecated_shadow_rows=0`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_postcheck_new_server.txt`
  - promoted rule rows: `32/32`
  - promoted verified/auto rows: `32/32`
  - promoted Oracle-hash rows: `32/32`

## Sync And E2E

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg377_keyword_reminder_new_server.json`
  - `pg_rows_loaded=32`
  - `sqlite_inserted_or_updated=32`
  - `canonical_snapshot_rows_exported=5063`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg377_keyword_reminder_new_server_e2e.md`
  - status: `pass`
  - PostgreSQL source of truth: `32/32`
  - SQLite/Hermes cache: `32/32`
  - canonical snapshot fallback: `32/32`
  - runtime `get_card_effect`: `32/32`

## Queue Impact

- Post-PG376 authoritative queue:
  - `target_identity_count=27027`
  - `xmage_authoritative_source_count=26713`
  - `xmage_authoritative_adapter_required_count=26713`
- Post-PG377 authoritative queue:
  - `target_identity_count=26995`
  - `xmage_authoritative_source_count=26681`
  - `xmage_authoritative_adapter_required_count=26681`
- delta: `32` identities promoted.
- Post-PG377 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg377_keyword_reminder_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7752` considered supported rows.

## Validation

- Splitter tests: `296` passed.
- Exact runtime tests: `175` passed.
- `xmage_strategy_consistency_audit_20260704_post_pg377_keyword_reminder_new_server_docs_after_update`:
  `pass`, `26/26`.
- `operational_surface_alignment_audit_20260704_post_pg377_keyword_reminder_new_server_docs_after_update`:
  `pass`.
- `legacy_contamination_audit_20260704_post_pg377_keyword_reminder_new_server_docs_after_update`:
  `pass`.
- `pg_hermes_sqlite_contract_audit`: `pass`, `49 pass`, `1 inherited warn`
  (`deck_id_607_has_no_pg_deck_id_note`).

## Next Work

The active execution baseline is now:

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg377_keyword_reminder_new_server_commander_legal.json`

The next cycle must implement another exact mapper/runtime subpattern before
PostgreSQL package generation. The largest remaining work units are:

1. `recursion::xmage_graveyard_return_variant_review_v1` - `1822`
2. `draw_engine::xmage_draw_card_variant_review_v1` - `1634`
3. `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` - `1130`
4. `direct_damage::targeted_damage_variant_v1` - `906`
5. `add_counters::source_add_counters_variant_v1` - `795`

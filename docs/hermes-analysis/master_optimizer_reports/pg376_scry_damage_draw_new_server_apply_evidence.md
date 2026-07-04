# PG376 Scry/Damage Draw New Server Apply Evidence

- Generated at: `2026-07-04T01:23:00+00:00`
- Database target: `127.0.0.1:15432/halder` via SSH tunnel to the new EasyPanel server
- Public server readiness checked in this cycle via `https://evolution-cartinhas.2ta7qx.easypanel.host/ready`
- Deploy id: `PG376`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_manifest.json`

## Scope

PG376 promotes two exact XMage-derived composite spell subpatterns:

- `xmage_fixed_scry_and_draw_cards_spell_v1`: `9` cards
- `xmage_fixed_damage_target_and_draw_card_spell_v1`: `3` cards

Promoted cards:

- `Behold the Multiverse`
- `Deliberate`
- `Ember Shot`
- `Foresee`
- `Introduction to Prophecy`
- `Opt`
- `Playful Shove`
- `Preordain`
- `Scour All Possibilities`
- `Serum Visions`
- `Tamiyo's Epiphany`
- `Zap`

## Runtime And Splitter Evidence

- Splitter tests: `294` tests passed.
- Runtime tests: `175` tests passed.
- Python compile check: passed for `xmage_authoritative_exact_scope_split.py`, `battle_analyst_v9.py`, `test_xmage_authoritative_exact_scope_split.py`, and `test_xmage_exact_scope_runtime.py`.
- Exact split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg376_scry_damage_draw_new_server.md`
- Split result: `proposal_count=12`, `safe_for_batch_pg_package_count=12`.

## PostgreSQL Evidence

- Precheck: `12/12` cards matched exactly one PostgreSQL card row by normalized name and Oracle hash.
- Apply:
  - `deprecated_shadow_rows=8`
  - `upserted_rows=12`
- Postcheck:
  - `promoted_rule_rows=1` for each promoted card
  - `promoted_verified_auto_rows=1` for each promoted card
  - `promoted_oracle_hash_rows=1` for each promoted card
  - `backup_rows=8`

## Hermes/SQLite And E2E Evidence

- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg376_scry_damage_draw_new_server.json`
- Sync result:
  - `apply_pg=false`
  - `apply_sqlite_from_pg=true`
  - `pg_rows_loaded=12`
  - `sqlite_inserted_or_updated=20`
  - `canonical_snapshot_rows_exported=5031`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_e2e.md`
- E2E status: `pass` across PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.

## Post-Sync Queue Evidence

- Post-PG376 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg376_scry_damage_draw_new_server.md`
- Post-PG376 queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg376_scry_damage_draw_new_server_commander_legal.md`
- Queue delta:
  - `target_identity_count`: `27039 -> 27027`
  - `xmage_authoritative_adapter_required_count`: `26725 -> 26713`
  - `xmage_authoritative_parser_gap_count`: `0`
  - `xmage_missing_source_exception_count`: `314`
- All 12 promoted cards are absent from the post-PG376 queue.
- Post-PG376 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg376_scry_damage_draw_new_server_supported_recheck.md`
- Supported splitter result after PG376: `proposal_count=0`, `safe_for_batch_pg_package_count=0`.

## Final Audits

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg376_scry_damage_draw_new_server_docs_final.md`
  status: `pass`, `26/26`.
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg376_scry_damage_draw_new_server_docs_final.md`
  status: `pass`.
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg376_scry_damage_draw_new_server_docs_final.md`
  status: `pass`.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg376_scry_damage_draw_new_server.md`
  status: `pass`, `49 pass`, `1 warn`.
- The inherited warning is `deck_id_607_has_no_pg_deck_id_note`; it is unrelated to PG376.

## Next Work

PG377 must implement a new narrow subpattern before PostgreSQL packaging. The current exact splitter has no safe proposal after PG376.

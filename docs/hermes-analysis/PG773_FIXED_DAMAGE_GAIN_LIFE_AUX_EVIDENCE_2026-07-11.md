# PG773 Fixed Damage Gain Life Auxiliary Evidence - 2026-07-11

Status: `applied_and_validated`.

Database target: `server/bin/with_new_server_pg.sh` -> `127.0.0.1:15432/halder`.

## Runtime/parser change

- Extended `xmage_fixed_damage_target_and_controller_gain_life_spell_v1` splitting to ignore resolution-neutral auxiliary Oracle lines before exact Oracle matching.
- Allowed neutral auxiliary ability classes already listed in `ALLOWED_AUXILIARY_RESOLUTION_ABILITY_CLASSES`, including `FlashbackAbility` and `ConvokeAbility`.
- Added explicit blocking for unsupported auxiliary ability classes in this family, keeping `CleaveAbility` out of the safe package lane.
- Dynamic X/count cases remain blocked by the fixed XMage source check.

Focused test:

- Command: `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k damage_gain_life`
- Result: `7` tests passed.

## PG773 promoted cards

Selected cards:

- `Covenant of Blood`
- `Morbid Hunger`
- `Sacred Fire`
- `Smiting Helix`

Scope: `xmage_fixed_damage_target_and_controller_gain_life_spell_v1`.

Rejected from this exact package:

- `Lantern Flare`: `CleaveAbility` plus dynamic X.
- `Parasitic Grasp`: `CleaveAbility` plus bracketed target restriction.
- `Zenith Flare`: dynamic X.

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg773_fixed_damage_gain_life_aux_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg773_fixed_damage_gain_life_aux_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg773_fixed_damage_gain_life_aux_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg773_fixed_damage_gain_life_aux_new_server_rollback.sql`

Apply evidence:

- Precheck: `4` target card rows, `0` expected rule rows before apply.
- Apply: `upserted_rows=4`, `deprecated_shadow_rows=2`.
- Postcheck: each promoted card has `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Sync and E2E

SQLite/Hermes sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg773_fixed_damage_gain_life_aux_new_server_sqlite_sync.json`
- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=10107`
- `sqlite_inserted_or_updated=9885`
- `canonical_snapshot_rows_exported=7497`

E2E report:

- JSON: `docs/hermes-analysis/master_optimizer_reports/pg773_fixed_damage_gain_life_aux_new_server_e2e.json`
- Markdown: `docs/hermes-analysis/master_optimizer_reports/pg773_fixed_damage_gain_life_aux_new_server_e2e.md`
- Status: `pass`
- PostgreSQL source of truth: `4/4`
- SQLite/Hermes cache: `4/4`
- Canonical snapshot fallback: `4/4`
- Runtime lookup: `4/4`
- Battle execution: `4` scenarios, `12` events.

Battle execution validated:

- `Covenant of Blood`: `4` damage and `4` life gained.
- `Morbid Hunger`: `3` damage and `3` life gained.
- `Sacred Fire`: `2` damage and `2` life gained.
- `Smiting Helix`: `3` damage and `3` life gained.

## Final counters

Readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg773_fixed_damage_gain_life_aux_new_server.md`
- `battle_and_oracle_ready=6512`
- `battle_family_mapper_required=27364`
- `snapshot_has_any_rule=7703`
- `snapshot_has_verified_rule=6537`

XMage authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg773_fixed_damage_gain_life_aux_new_server.md`
- `target_identity_count=24441`
- `xmage_authoritative_source_count=24128`
- `xmage_authoritative_adapter_required_count=24128`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Exact split after PG773:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_post_pg773_fixed_damage_gain_life_aux_new_server.md`
- `safe_for_batch_pg_package_count=0`
- Remaining selected proposals are `3` runtime-partial simple mana-source rows, not PG-safe package candidates.

Audits:

- XMage strategy consistency: `pass`, `26/26`.
- PG/Hermes/SQLite contract: `pass`, `51/51`.
- Operational surface alignment: `pass`.
- Legacy contamination audit: `pass`.

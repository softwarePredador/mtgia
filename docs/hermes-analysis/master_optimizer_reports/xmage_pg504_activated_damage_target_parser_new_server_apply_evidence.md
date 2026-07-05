# XMage PG504 Activated Damage Target Parser Apply Evidence

- Generated at: `2026-07-05T12:12:00Z`
- Deploy id: `xmage_pg504_activated_damage_target_parser_new_server`
- Runtime families:
  - `xmage_permanent_simple_activated_damage_v1`
  - `xmage_permanent_simple_activated_destroy_target_v1`
- PostgreSQL target: remote server, sanitized in command output; no credentials stored here
- Deck 607 mutated: `false`
- Deck materialized: `false`
- Natural battle run: `false`

## Scope

Promoted exact activated permanent target-parser rules only:

- `Deadeye Duelist`: fixed 1 damage to target opponent
- `Elite Headhunter`: fixed 2 damage to target creature or planeswalker with matching sacrifice cost
- `Femeref Archers`: fixed 4 damage to target attacking creature with flying
- `Pyroclastic Elemental`: fixed 1 damage to target player
- `Razortip Whip`: fixed 1 damage to target opponent or planeswalker
- `Shauku's Minion`: fixed 2 damage to target white creature
- `Slingshot Goblin`: fixed 2 damage to target blue creature
- `Sorcerer of the Fang`: fixed 2 damage to target opponent or planeswalker
- `Spinal Villain`: activated destroy target blue creature
- `Western Paladin`: activated destroy target white creature
- `Zealot of the God-Pharaoh`: fixed 2 damage to target opponent or planeswalker

Dynamic damage, unsupported costs, modal abilities, random target choice,
multi-target damage, and non-matching Oracle/XMage target pairs remain blocked.

## Apply

- SQL file: `docs/hermes-analysis/master_optimizer_reports/xmage_pg504_activated_damage_target_parser_new_server_apply.sql`
- transaction: `COMMIT`
- deprecated_shadow_rows: `0`
- upserted_rows: `11`
- backup_rows_before_apply: `0`

## Postcheck

Each promoted card has:

- promoted_rule_rows: `1`
- promoted_verified_auto_rows: `1`
- promoted_oracle_hash_rows: `1`
- backup_rows: `0`

## Effect Field Postcheck

See `docs/hermes-analysis/master_optimizer_reports/xmage_pg504_activated_damage_target_parser_new_server_effect_field_postcheck.out`.

Targets confirmed:

- `opponent`
- `player`
- `opponent_or_planeswalker`
- `creature_or_planeswalker`
- `attacking_flying_creature`
- `white_creature`
- `blue_creature`

## SQLite And Runtime

- Sync report: `docs/hermes-analysis/master_optimizer_reports/xmage_pg504_activated_damage_target_parser_new_server_pg_to_sqlite_sync.json`
- pg_rows_loaded: `8446`
- sqlite_inserted_or_updated: `8210`
- canonical_snapshot_rows_exported: `5972`
- Runtime lookup: all eleven cards resolve with expected activated damage or activated destroy scope.
- Battle suite output: `docs/hermes-analysis/master_optimizer_reports/xmage_pg504_activated_damage_target_parser_new_server_full_battle_suite_post_sync.out`
- Battle suite result: `632` PASS lines, no `Traceback`, `FAILED`, `ERROR`, or `SkipTest`.

## Queue Rebuild

- Post-PG504 readiness: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260705_post_pg504_activated_damage_target_parser_new_server.md`
- Post-PG504 queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg504_activated_damage_target_parser_new_server_commander_legal.md`
- target_identity_count: `26045`
- xmage_authoritative_source_count: `25731`
- xmage_missing_source_exception_count: `314`
- xmage_authoritative_parser_gap_count: `0`
- xmage_authoritative_adapter_required_count: `25731`
- direct_damage work unit reduced to `800`
- removal_destroy work unit reduced to `574`
- Final exact split recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0`

## Register Decision

- PG504 is applied and should not be rebuilt.
- The remaining activated damage/destroy backlog must continue as exact
  subpatterns; generic `targeted_damage_variant_v1` and
  `targeted_destroy_variant_v1` rows are still not executable promotion
  candidates by themselves.

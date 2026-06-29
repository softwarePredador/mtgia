# PG257 Phyrexian Censor Static Runtime

Status: `applied_synced_validated`.

Candidate count: `1`

## Cards

- `Phyrexian Censor`: `creature` / `each_player_one_nonphyrexian_spell_per_turn_nonphyrexian_creatures_enter_tapped_v1` / `battle_rule_v1:166240c94a4f8ba33fc80549c236deb7`

## Focused Runtime Proof

- `test_phyrexian_censor_blocks_second_nonphyrexian_spell_but_not_phyrexian`
- `test_phyrexian_censor_makes_nonphyrexian_creatures_enter_tapped_for_all_players`

## Files

- precheck: `pg257_phyrexian_censor_static_runtime_20260629_precheck.sql`
- apply: `pg257_phyrexian_censor_static_runtime_20260629_apply.sql`
- postcheck: `pg257_phyrexian_censor_static_runtime_20260629_postcheck.sql`
- rollback: `pg257_phyrexian_censor_static_runtime_20260629_rollback.sql`
- manifest: `pg257_phyrexian_censor_static_runtime_20260629_manifest.json`

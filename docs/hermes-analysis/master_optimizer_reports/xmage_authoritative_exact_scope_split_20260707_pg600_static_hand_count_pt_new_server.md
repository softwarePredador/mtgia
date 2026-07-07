# PG600 Static Hand Count Power/Toughness Exact Scope Split

Status: `reconstructed_from_post_apply_pg_truth`.

This small split artifact was rebuilt from the four PostgreSQL rows promoted by PG600 because the original selected split artifact was absent locally. The PostgreSQL audit backup table exists as `manaloom_deploy_audit.pg600_static_hand_count_pt_new_server_pg_20260707_070624` and contains `0` rows, matching the original no-shadow/no-existing-row apply path.

- `proposal_count`: `4`
- `safe_for_batch_pg_package_count`: `4`
- `family`: `xmage_static_source_power_toughness_equal_count`

| Card | Source | Multiplier | Logical rule |
| --- | --- | ---: | --- |
| `Adamaro, First to Desire` | `opponent_max_hand_count` | `1` | `battle_rule_v1:951695ee91b1beff938cc9b0260ccabf` |
| `Maro` | `controller_hand_count` | `1` | `battle_rule_v1:7a6ac98595448a90c5be6ce4fe95cb03` |
| `Masumaro, First to Live` | `controller_hand_count` | `2` | `battle_rule_v1:32eadb1d269955a7aff13bd501840668` |
| `Multani, Maro-Sorcerer` | `all_players_hand_count` | `1` | `battle_rule_v1:6838948687551b209751bd8e3ee8ec44` |

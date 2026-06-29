# PG254 Blink Static Legacy Runtime Promotions

Status: `applied_synced_validated`.

Candidate count: `14`

## Cards

- `Reckless Barbarian`: `creature` / `creature_sacrifice_add_two_red_mana_v1` / `battle_rule_v1:3e4644b909f23750472f43f57c3992c9`
- `Sacrifice`: `ramp_ritual` / `sacrifice_creature_add_black_equal_sacrificed_mana_value_v1` / `battle_rule_v1:9f494d943f370fc23f70ab219b82c70b`
- `Geosurge`: `ramp_ritual` / `add_seven_red_spend_only_artifact_or_creature_spells_v1` / `battle_rule_v1:2323eaddfebeeae63ff261b27cd676f8`
- `Mardu Devotee`: `creature` / `creature_etb_scry_two_and_one_mana_mardu_filter_v1` / `battle_rule_v1:163c8c72b0d88900703479b29584941d`
- `Orcish Lumberjack`: `creature` / `creature_tap_sacrifice_forest_add_three_red_or_green_v1` / `battle_rule_v1:3928f623fa6bea3e5c2fac2983d8df26`
- `Faeburrow Elder`: `creature` / `creature_tap_add_one_mana_each_color_among_permanents_v1` / `battle_rule_v1:ba732f55ab31865df49e463277d20469`
- `Neoform`: `tutor` / `sacrifice_creature_tutor_creature_mv_plus_one_to_battlefield_counter_v1` / `battle_rule_v1:1a244213e27ba84cc802817d801fdfbd`
- `Ephemerate`: `blink` / `exile_then_return_target_creature_you_control_rebound_v1` / `battle_rule_v1:8e1b9773684b97c3d24b091de88a5517`
- `Displacer Kitten`: `creature` / `noncreature_spell_cast_blink_up_to_one_nonland_permanent_you_control_v1` / `battle_rule_v1:0bb2c233457a8f1bb2420ff43b813d05`
- `Emiel the Blessed`: `creature` / `activated_blink_another_creature_you_control_plus_creature_etb_counter_metadata_v1` / `battle_rule_v1:c060974bde14bba7412e05ae3fae7c9d`
- `Deafening Silence`: `passive` / `each_player_one_noncreature_spell_per_turn_static_v1` / `battle_rule_v1:3acd8f1cd0385cea4d18af84cb76b7bf`
- `Archon of Emeria`: `creature` / `each_player_one_spell_per_turn_opponent_nonbasic_lands_enter_tapped_v1` / `battle_rule_v1:160715b74767da0ffe53d66b25a44936`
- `Eidolon of Rhetoric`: `creature` / `each_player_one_spell_per_turn_static_creature_v1` / `battle_rule_v1:137c1bd9ef3c7095ba82cef057c36d20`
- `Ethersworn Canonist`: `creature` / `each_player_one_nonartifact_spell_per_turn_static_artifact_creature_v1` / `battle_rule_v1:34c3e895d3a7ef2fdb960e8de4403308`

## Files

- precheck: `pg254_blink_static_legacy_runtime_promotions_20260629_precheck.sql`
- apply: `pg254_blink_static_legacy_runtime_promotions_20260629_apply.sql`
- postcheck: `pg254_blink_static_legacy_runtime_promotions_20260629_postcheck.sql`
- rollback: `pg254_blink_static_legacy_runtime_promotions_20260629_rollback.sql`
- manifest: `pg254_blink_static_legacy_runtime_promotions_20260629_manifest.json`

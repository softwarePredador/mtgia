# PG252 Manual Runtime Waiver Promotions

Status: `applied_synced_validated`.

Candidate count: `16`

This package promotes existing tested ManaLoom manual runtime waivers to PostgreSQL curated battle rules. It does not create new card behavior; it removes the waiver-only gap for cards already covered by focused runtime tests.

## Cards

- `Ancient Copper Dragon`: `ramp_engine` / `source_combat_damage_player_roll_d20_create_treasure_equal_result_v1` / `battle_rule_v1:e2ac43c9f6e03e11e9fab994a5c15258`
- `Beacon of Immortality`: `life_total_change` / `double_target_player_life_total_shuffle_self_v1` / `battle_rule_v1:655c7da1b9d381d24b94b64487226598`
- `Invincible Hymn`: `life_total_change` / `controller_life_total_becomes_library_size_v1` / `battle_rule_v1:de6504fa068c924a1bad5f1ada35a026`
- `Planetarium of Wan Shi Tong`: `topdeck_manipulation` / `scry_or_surveil_once_turn_top_library_free_cast_v1` / `battle_rule_v1:a2082ebdf6e7e169b97eccecbb22b36a`
- `Radiant Performer`: `copy_spell` / `flash_creature_etb_copy_stack_spell_partial_metadata_v1` / `battle_rule_v1:fa12ce53b0a0c4b963f4071b4fde2c9b`
- `Rem Karolus, Stalwart Slayer`: `creature` / `spell_damage_to_opponents_plus_one_prevent_own_nonself_v1` / `battle_rule_v1:1a987670b594e446e4b1a122214e549e`
- `Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence`: `creature` / `life_30_flip_prevent_all_damage_to_controlled_creatures_v1` / `battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e`
- `Sawhorn Nemesis`: `creature` / `chosen_player_or_permanents_they_control_damage_doubled_v1` / `battle_rule_v1:93e3f5684069bf77d7219e17f3e04a6c:sawhorn_nemesis_runtime_v1`
- `Screaming Nemesis`: `creature` / `source_dealt_damage_reflect_to_any_other_target_player_hit_cant_gain_life_v1` / `battle_rule_v1:77190ec2e1e1dcb8b15429e5d53e68bd:screaming_nemesis_runtime_v1`
- `Semblance Anvil`: `static_cost_reduction` / `imprint_nonland_card_reduce_spells_sharing_card_type_v1` / `battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e`
- `Serra Ascendant`: `creature` / `controller_life_total_30_plus_self_plus_5_5_flying_static_v1` / `battle_rule_v1:c3124030acfa1668606aca59dbbb7e2e`
- `Slickshot Show-Off`: `creature` / `noncreature_spell_cast_boost_source_plus_2_0_until_eot_plot_v1` / `battle_rule_v1:9fd2ff72170533330fc8ba9165bd99b4`
- `Stuffy Doll`: `creature` / `source_dealt_damage_reflect_to_chosen_player_self_damage_indestructible_v1` / `battle_rule_v1:e7b60d9805dbf2701195f627c6ca1600`
- `Taunt from the Rampart`: `goad_opponents_creatures_cant_block` / `goad_all_opponents_creatures_cant_block_until_your_next_turn_v1` / `battle_rule_v1:16e15ea414a18410acd151d43276651c`
- `The Walls of Ba Sing Se`: `creature` / `other_permanents_you_control_have_indestructible_static_v1` / `battle_rule_v1:1e5bcf3b45fcae347879976d74d2ef84`
- `Zirda, the Dawnwaker`: `static_cost_reduction` / `static_activated_ability_cost_reduction_variant_v1` / `battle_rule_v1:45c3e1db1be4f2f97a3337ce3de8f767`

## Files

- precheck: `pg252_manual_runtime_waiver_promotions_20260629_precheck.sql`
- apply: `pg252_manual_runtime_waiver_promotions_20260629_apply.sql`
- postcheck: `pg252_manual_runtime_waiver_promotions_20260629_postcheck.sql`
- rollback: `pg252_manual_runtime_waiver_promotions_20260629_rollback.sql`
- manifest: `pg252_manual_runtime_waiver_promotions_20260629_manifest.json`

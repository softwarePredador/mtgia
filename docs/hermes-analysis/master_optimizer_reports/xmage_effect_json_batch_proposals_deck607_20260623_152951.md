# XMage Effect JSON Batch Proposals

Generated at: `2026-06-23T18:29:52+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"blocked_missing_xmage_source_count": 2, "family_counts": {"board_wipe_choice": 3, "discard_modal_trigger": 1, "graveyard_spell_copy_cast": 1, "manual_model": 2, "modal_mana_rock": 1, "other_turn_mana_rock": 2, "static_cost_reducer": 2, "token_maker": 1}, "proposal_count": 13, "proposal_status_counts": {"batch_pg_candidate_after_precheck": 4, "blocked_missing_xmage_source": 2, "runtime_family_implementation_required": 7}, "runtime_family_required_count": 7, "safe_for_batch_pg_package_count": 4}`

| Card | Family | Status | Logical rule key | Oracle hash | Effect |
| --- | --- | --- | --- | --- | --- |
| `Promise of Loyalty` | `board_wipe_choice` | `runtime_family_implementation_required` | `battle_rule_v1:2a6bfeb84af3ff8d5d294d553caf1a31` | `21dd715160fde6e50b8edc015ce83b0f` | `vow_counter_each_player_sacrifice_rest` |
| `Starfall Invocation` | `board_wipe_choice` | `runtime_family_implementation_required` | `battle_rule_v1:0a2c3c26b4c00093ebbd0a60b11cbc6e` | `3429884949eac8ffe09d86dc85bee1ae` | `gift_destroy_all_creatures_return_own_destroyed_creature` |
| `Pearl Medallion` | `static_cost_reducer` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2` | `77f7f449ee56143d6b63814fecd37176` | `static_cost_reduction` |
| `Emeria's Call // Emeria, Shattered Skyclave` | `token_maker` | `runtime_family_implementation_required` | `battle_rule_v1:ae4a933d873bec332ec2a46106b79277` | `dc58cda92b87365d5d89339bf7116f44` | `token_maker` |
| `Molecule Man` | `manual_model` | `blocked_missing_xmage_source` | `battle_rule_v1:a12fc852258c5bebe68910e6205159f9` | `35e82bd52776c455745138b048ccc116` | `None` |
| `The Mind Stone` | `modal_mana_rock` | `runtime_family_implementation_required` | `battle_rule_v1:9b412fde07574a30fb427cef33abd7f9` | `17bda9d167ae2799376387d03be5681f` | `mana_rock_with_harnessed_blink` |
| `The Scarlet Witch` | `static_cost_reducer` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc` | `6129fda2f5ae1f8edad5a2f2e77d05c2` | `static_cost_reduction` |
| `Thor, God of Thunder` | `manual_model` | `blocked_missing_xmage_source` | `battle_rule_v1:94898724936c70d90c6688425ed7e029` | `0f2238f2ce8e4f2c0bbc2d5cea55f4d7` | `None` |
| `Tragic Arrogance` | `board_wipe_choice` | `runtime_family_implementation_required` | `battle_rule_v1:114ac00cb8604e086793ec66f39bbbf4` | `efdf5d051aaa7f94b12c4dccbbfd7d3d` | `selective_nonland_sacrifice` |
| `Bender's Waterskin` | `other_turn_mana_rock` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:04b0c59bed983b3005b83c46554b6c04` | `1bd371e1f09ed8b48837c3fc5cd2a2ff` | `other_turn_untapping_any_color_mana_rock` |
| `Victory Chimes` | `other_turn_mana_rock` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:882f4dccc04e90fa59d8d459361758fe` | `8ca84e1f2e9f3efd1fe740d16d216105` | `other_turn_untapping_target_player_colorless_mana_rock` |
| `Monument to Endurance` | `discard_modal_trigger` | `runtime_family_implementation_required` | `battle_rule_v1:0ae531be7c36226d3f118c93feab3735` | `a60dc736f7e86e15001c8c7e59ff23c4` | `discard_trigger_modal_draw_treasure_opponent_life_loss` |
| `Surge to Victory` | `graveyard_spell_copy_cast` | `runtime_family_implementation_required` | `battle_rule_v1:5af791c47d2b65f4bcf3186754d4d822` | `5381f78ff0798b9afad371e0fa495831` | `exile_instant_sorcery_boost_combat_damage_copy_cast` |

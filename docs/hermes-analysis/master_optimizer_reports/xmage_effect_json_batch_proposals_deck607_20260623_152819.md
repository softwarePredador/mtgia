# XMage Effect JSON Batch Proposals

Generated at: `2026-06-23T18:28:19+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"blocked_missing_xmage_source_count": 2, "family_counts": {"board_wipe_choice": 3, "discard_modal_trigger": 1, "graveyard_spell_copy_cast": 1, "manual_model": 2, "modal_mana_rock": 1, "other_turn_mana_rock": 2, "static_cost_reducer": 2, "token_maker": 1}, "proposal_count": 13, "proposal_status_counts": {"batch_pg_candidate_after_precheck": 4, "blocked_missing_xmage_source": 2, "runtime_family_implementation_required": 7}, "runtime_family_required_count": 7, "safe_for_batch_pg_package_count": 4}`

| Card | Family | Status | Logical rule key | Oracle hash | Effect |
| --- | --- | --- | --- | --- | --- |
| `Promise of Loyalty` | `board_wipe_choice` | `runtime_family_implementation_required` | `battle_rule_v1:f3bd883efd5af0ff752ea572d7dc1cc0` | `21dd715160fde6e50b8edc015ce83b0f` | `vow_counter_each_player_sacrifice_rest` |
| `Starfall Invocation` | `board_wipe_choice` | `runtime_family_implementation_required` | `battle_rule_v1:d62b5e4cf3cc9db1b3ec98667eee7505` | `3429884949eac8ffe09d86dc85bee1ae` | `gift_destroy_all_creatures_return_own_destroyed_creature` |
| `Pearl Medallion` | `static_cost_reducer` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:09662427b256781a39f50dd00ba9735b` | `77f7f449ee56143d6b63814fecd37176` | `static_cost_reduction` |
| `Emeria's Call // Emeria, Shattered Skyclave` | `token_maker` | `runtime_family_implementation_required` | `battle_rule_v1:ae4a933d873bec332ec2a46106b79277` | `dc58cda92b87365d5d89339bf7116f44` | `token_maker` |
| `Molecule Man` | `manual_model` | `blocked_missing_xmage_source` | `battle_rule_v1:385874e9c637e804589926b1d449fef8` | `35e82bd52776c455745138b048ccc116` | `None` |
| `The Mind Stone` | `modal_mana_rock` | `runtime_family_implementation_required` | `battle_rule_v1:79e1a245f7790872f96bd8e34939d600` | `17bda9d167ae2799376387d03be5681f` | `mana_rock_with_harnessed_blink` |
| `The Scarlet Witch` | `static_cost_reducer` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:083a0ef0848582b5941faaa56850f439` | `6129fda2f5ae1f8edad5a2f2e77d05c2` | `static_cost_reduction` |
| `Thor, God of Thunder` | `manual_model` | `blocked_missing_xmage_source` | `battle_rule_v1:385874e9c637e804589926b1d449fef8` | `0f2238f2ce8e4f2c0bbc2d5cea55f4d7` | `None` |
| `Tragic Arrogance` | `board_wipe_choice` | `runtime_family_implementation_required` | `battle_rule_v1:e88287778ab1e6b9916eb984e9539b2a` | `efdf5d051aaa7f94b12c4dccbbfd7d3d` | `selective_nonland_sacrifice` |
| `Bender's Waterskin` | `other_turn_mana_rock` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:33513c1fbb75cc09aba87022c3ab0a15` | `1bd371e1f09ed8b48837c3fc5cd2a2ff` | `other_turn_untapping_any_color_mana_rock` |
| `Victory Chimes` | `other_turn_mana_rock` | `batch_pg_candidate_after_precheck` | `battle_rule_v1:86e930ac35cf3ca54b240b42816b3d97` | `8ca84e1f2e9f3efd1fe740d16d216105` | `other_turn_untapping_target_player_colorless_mana_rock` |
| `Monument to Endurance` | `discard_modal_trigger` | `runtime_family_implementation_required` | `battle_rule_v1:b0941946a5b7cb88ea74f42df997b029` | `a60dc736f7e86e15001c8c7e59ff23c4` | `discard_trigger_modal_draw_treasure_opponent_life_loss` |
| `Surge to Victory` | `graveyard_spell_copy_cast` | `runtime_family_implementation_required` | `battle_rule_v1:fd9ad85a405f048d1d020b00f8ba5d67` | `5381f78ff0798b9afad371e0fa495831` | `exile_instant_sorcery_boost_combat_damage_copy_cast` |

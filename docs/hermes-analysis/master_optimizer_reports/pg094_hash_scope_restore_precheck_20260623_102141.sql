WITH target_rules(normalized_name, card_name, logical_rule_key, expected_oracle_hash, expected_confidence, expected_review_status, expected_execution_status, expected_rule_version, expected_effect_json) AS (
  VALUES
      ('angel''s grace', 'Angel''s Grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227', '627c4ce7adf5be44b93e2b850159e5d9', 0.970, 'verified', 'auto', 2, $json${"battle_model_scope":"split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1","cmc":1,"effect":"cannot_lose_turn","instant":true,"life_floor_on_damage":1,"opponents_cant_win_this_turn":true,"oracle_runtime_scope":"cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation","split_second":true}$json$::jsonb),
      ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a', 0.900, 'active', 'auto', 2, $json${"battle_model_scope":"conditional_opponent_color_mana_rock_v1","cmc":2,"conditionally_produces_opponent_land_colors":true,"effect":"ramp_permanent","mana_produced":1,"produces":"WUBRGC"}$json$::jsonb),
      ('library of leng', 'Library of Leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e', 0.930, 'active', 'auto', 2, $json${"battle_model_scope":"discard_replacement_to_top_v1","cmc":1,"discard_effect_to_top_replacement":true,"effect":"passive","no_max_hand_size":true}$json$::jsonb),
      ('mana vault', 'Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8', 0.910, 'active', 'auto', 2, $json${"battle_model_scope":"fast_mana_artifact_partial_v1","cmc":1,"does_not_untap_normally":true,"effect":"ramp_permanent","mana_produced":3,"produces":"C","tapped_upkeep_damage":1,"upkeep_optional_untap_cost_generic":4}$json$::jsonb),
      ('mox amber', 'Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706', 0.980, 'verified', 'auto', 2, $json${"battle_model_scope":"legend_gated_fast_mana_v1","cmc":0,"effect":"ramp_permanent","mana_produced":1,"produces":"WUBRGC","requires_legendary_creature_or_planeswalker_for_mana":true}$json$::jsonb),
      ('scroll rack', 'Scroll Rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30', 0.800, 'active', 'auto', 2, $json${"activation_cost_generic":1,"battle_model_scope":"scroll_rack_upkeep_single_exchange_v1","cmc":2,"effect":"topdeck_manipulation","hand_to_top_exchange":true}$json$::jsonb),
      ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32', 0.970, 'verified', 'auto', 2, $json${"battle_model_scope":"single_shot_red_ritual_v1","cmc":3,"effect":"ramp_ritual","instant":true,"mana_color_status":"abstracted_to_generic_pool_runtime","mana_produced":5,"oracle_runtime_scope":"single_shot_red_ritual_runtime_generic_pool_color_annotation","pg058_l3b_simple_red_ritual_family":"deck6_simple_red_rituals","produces":"R"}$json$::jsonb),
      ('silence', 'Silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'a0ca3c09a7db091c435ab31adb9c1780', 0.970, 'verified', 'auto', 2, $json${"battle_model_scope":"silence_until_eot_v1","cmc":1,"effect":"silence_spell","instant":true,"oracle_runtime_scope":"opponent_spell_cast_lock_until_eot_runtime"}$json$::jsonb),
      ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2', 0.900, 'active', 'auto', 2, $json${"battle_model_scope":"pain_talisman_color_pair_partial_v1","cmc":2,"effect":"ramp_permanent","life_for_colored_mana":1,"mana_produced":1,"produces":"CRW"}$json$::jsonb),
      ('unexpected windfall', 'Unexpected Windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', '9c4fbe06104051a2e8b1d295d307b26a', 0.970, 'verified', 'auto', 2, $json${"battle_model_scope":"discard_draw_create_treasures_v1","cmc":4,"draw_count":2,"effect":"treasure_maker","instant":true,"requires_discard_card":true,"treasure_count":2}$json$::jsonb),
      ('valakut awakening // valakut stoneforge', 'Valakut Awakening // Valakut Stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887', 0.950, 'verified', 'auto', 2, $json${"battle_model_scope":"bottom_then_draw_plus_one_mdfc_land_v1","cmc":3,"draw_extra":1,"effect":"hand_filter","instant":true,"max_bottom":99,"mdfc_land_face":{"effect":"land","enters_tapped":true,"mana_produced":1,"produces":"R"}}$json$::jsonb),
      ('wayfarer''s bauble', 'Wayfarer''s Bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab', 'f11935fa793ae03d95ae75d62cdfa516', 0.920, 'active', 'auto', 2, $json${"activated_self_sacrifice_land_tutor":true,"activation_cost_generic":2,"activation_requires_tap":true,"basic_only":true,"battle_model_scope":"self_sacrifice_basic_land_tutor_artifact_v1","cmc":1,"effect":"ramp_permanent","land_count":1,"land_enters_tapped":true,"lands_to_battlefield":1}$json$::jsonb)
),
target_rows AS (
  SELECT tr.*, cbr.card_id, cbr.card_name AS current_card_name, cbr.oracle_hash,
         cbr.effect_json, cbr.confidence, cbr.review_status, cbr.execution_status,
         cbr.rule_version, md5(c.oracle_text) AS raw_oracle_hash
  FROM target_rules tr
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.logical_rule_key
  LEFT JOIN cards c ON c.id = cbr.card_id
)
SELECT
  (SELECT count(*) FROM target_rules) AS expected_target_rows,
  (SELECT count(*) FROM target_rows WHERE card_id IS NOT NULL) AS resolved_rule_rows,
  (SELECT count(*) FROM target_rows WHERE raw_oracle_hash = expected_oracle_hash) AS raw_hash_match_rows,
  (SELECT count(*) FROM target_rows WHERE oracle_hash IS DISTINCT FROM expected_oracle_hash) AS rows_needing_hash_restore,
  (SELECT count(*) FROM target_rows WHERE effect_json IS DISTINCT FROM expected_effect_json) AS rows_needing_effect_restore,
  (SELECT count(*) FROM target_rows WHERE confidence IS DISTINCT FROM expected_confidence OR review_status IS DISTINCT FROM expected_review_status OR execution_status IS DISTINCT FROM expected_execution_status OR rule_version IS DISTINCT FROM expected_rule_version) AS rows_needing_status_restore,
  to_regclass('manaloom_deploy_audit.pg094_hash_scope_restore_20260623_102141') IS NOT NULL AS backup_table_already_exists;

SELECT normalized_name, card_name, logical_rule_key, oracle_hash, effect_json,
       confidence, review_status, execution_status, rule_version
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('angel''s grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
  ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'),
  ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab')
)
ORDER BY normalized_name;

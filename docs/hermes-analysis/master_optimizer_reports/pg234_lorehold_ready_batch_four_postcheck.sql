WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('galvanoth', 'Galvanoth', '7ed46e6390c4eeb8ec436a9871abcdaa', 'battle_rule_v1:b8859191e53dd38d3af9f4d8db421a83', '{"ability_kind":"triggered","battle_model_scope":"controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1","effect":"creature","power":3,"toughness":3,"trigger":"controller_upkeep","trigger_effect":"look_top_card_may_cast_if_instant_or_sorcery","upkeep_look_top_card":true,"upkeep_may_cast_top_instant_or_sorcery_without_paying_mana":true,"upkeep_top_library_cast_types":["instant","sorcery"]}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Galvanoth mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('velomachus lorehold', 'Velomachus Lorehold', 'ecd723e730ac3b2cf1f68c816a17c745', 'battle_rule_v1:c3e60ccbaf1d57109e270f072d834a98', '{"ability_kind":"triggered","attack_cast_mana_value_max_source":"source_power","attack_look_top_count":7,"attack_may_cast_from_looked_cards_without_paying_mana":true,"attack_put_rest_bottom_random":true,"attack_top_library_cast_types":["instant","sorcery"],"battle_model_scope":"attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1","effect":"creature","flying":true,"haste":true,"power":5,"toughness":5,"trigger":"attack","trigger_effect":"look_top_seven_may_cast_instant_or_sorcery_lte_power","vigilance":true}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VelomachusLorehold mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('palantír of orthanc', 'Palantír of Orthanc', 'a85ec353e0a18e783ae88be2f64536ec', 'battle_rule_v1:26179de4259137dba13dc5d473b1fe72', '{"ability_kind":"triggered","battle_model_scope":"controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1","decline_mill_count_source":"source_named_counter_count","decline_mill_counter_type":"influence","decline_opponent_life_loss_equals_milled_cards_total_mana_value":true,"effect":"draw_engine","target":"opponent","target_opponent_may_have_you_draw_count":1,"trigger":"controller_end_step","trigger_counter_count":1,"trigger_counter_type":"influence","trigger_effect":"add_named_counter_scry_target_opponent_may_draw_else_mill_life_loss","trigger_scry_count":2}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PalantirOfOrthanc mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('scholar of new horizons', 'Scholar of New Horizons', '4f089ec5603d5179130aee6db95a54bf', 'battle_rule_v1:eeb6d5d36cf100b1f4136ec0b5f5d63d', '{"ability_kind":"activated","activation_cost_generic":0,"activation_put_tutored_land_onto_battlefield_tapped_if_opponent_more_lands":true,"activation_requires_remove_plus_one_counter_from_controlled_permanent":true,"activation_requires_tap":true,"battle_model_scope":"activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1","effect":"creature","enters_with_plus_one_counter_count":1,"land_tutor_to_hand_activated":true,"power":1,"toughness":1,"tutor_destination":"hand","tutor_target":"plains"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ScholarOfNewHorizons mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg234_lorehold_ready_batch_four_20260626_082257) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

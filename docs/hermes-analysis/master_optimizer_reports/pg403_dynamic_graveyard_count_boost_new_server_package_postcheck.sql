WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('festive funeral', 'Festive Funeral', '6e9fbabe708f04c9ed322448d4f409db', 'battle_rule_v1:3e4f67f3eb47bd397f83c59fd964d38c', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":-1,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FestiveFuneral translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ghoul''s feast', 'Ghoul''s Feast', '661b340dc8c9f7d884d1d203edb060b2', 'battle_rule_v1:b7cb7a49d1c68ef3a1d9889ac4853f8d', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":0,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulsFeast translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg403_dynamic_graveyard_count_boost_new_server_20260704_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('peek', 'Peek', 'ceef336ad370e3f91ec32c3c320d8f29', 'battle_rule_v1:03d0faabb3f16a46875da8625b396599', '{"_composite_rule_components":[{"battle_model_scope":"xmage_look_at_target_player_hand_spell_v1","compose_on_resolution":true,"effect":"look_at_target_player_hand","look_at_hand":true,"target":"player","target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"LookAtTargetPlayerHandEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_look_at_target_player_hand_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"look_at_hand":true,"sorcery":false,"target":"player","target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["LookAtTargetPlayerHandEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Peek translated into ManaLoom runtime scope xmage_look_at_target_player_hand_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-target-player-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sorcerous sight', 'Sorcerous Sight', 'dea7c0ba9fa33625701240e40c40231f', 'battle_rule_v1:81c17316ed792e48110bd3e036a00484', '{"_composite_rule_components":[{"battle_model_scope":"xmage_look_at_target_player_hand_spell_v1","compose_on_resolution":true,"effect":"look_at_target_player_hand","look_at_hand":true,"target":"player","target_player_scope":"opponent","target_preference":"opponent","xmage_effect_class":"LookAtTargetPlayerHandEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_look_at_target_player_hand_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"look_at_hand":true,"sorcery":true,"target":"player","target_player_scope":"opponent","target_preference":"opponent","xmage_effect_classes":["LookAtTargetPlayerHandEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SorcerousSight translated into ManaLoom runtime scope xmage_look_at_target_player_hand_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-target-player-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg762_look_at_hand_draw_new_server_look_20260711_125229) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

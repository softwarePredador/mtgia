WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('endless atlas', 'Endless Atlas', 'db628c828e9ac8519d479ef2f8ef58fd', 'battle_rule_v1:2d9432282c7d81378eaa782c1af6f921', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_controls_lands_same_name_gte","activation_condition_land_same_name_threshold":3,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndlessAtlas translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('falkenrath pit fighter', 'Falkenrath Pit Fighter', '47c0bbc6b3de23331823224dd0d3868c', 'battle_rule_v1:1135af3cd6d0b977ac182845987336f2', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":2,"activated_effect":"draw_cards","activation_condition":"opponent_lost_life_this_turn","activation_condition_opponent_life_lost_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":["R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"vampire","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FalkenrathPitFighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fool''s tome', 'Fool''s Tome', '49e29b58d3c5ddd4db576ed76e322551', 'battle_rule_v1:6c94429f211d447502f9c06ee33ef01e', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoolsTome translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffyn', 'Ragamuffyn', 'd220bbe646cf679b6f263262bcd81eed', 'battle_rule_v1:8c887ae0a132334d87aac47b41d82096', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_target":"creature_or_land","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Ragamuffyn translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapestry of the ages', 'Tapestry of the Ages', 'd34211666b040792b018e60faedc4884', 'battle_rule_v1:e2fe8511410d4efad46dbd7288431d17', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_cast_noncreature_spell_this_turn","activation_condition_spell_count_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TapestryOfTheAges translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg845_conditional_activated_draw_new_ser_20260712_211331) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

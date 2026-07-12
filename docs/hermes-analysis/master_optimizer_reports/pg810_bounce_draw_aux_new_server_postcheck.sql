WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eject', 'Eject', 'fc32de9dab55487e91d692afa519d433', 'battle_rule_v1:51f9e927e40ac019eb25f99986b0b28d', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_permanent","target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_controller":"any","xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Eject translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('escape detection', 'Escape Detection', '2f41a8c8515ecebe621583a7e1bee239', 'battle_rule_v1:32ef6fa7ac42c6a4bdd8be27fffeaec3', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EscapeDetection translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg810_bounce_draw_aux_new_server_20260712_062447) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

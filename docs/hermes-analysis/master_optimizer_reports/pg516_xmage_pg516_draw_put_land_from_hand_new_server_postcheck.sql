WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('embrace the paradox', 'Embrace the Paradox', '91f408bbce4eecf30a06626166e9acf6', 'battle_rule_v1:612d4ce19274ebff28bdc52b5a232e03', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","compose_on_resolution":true,"destination":"battlefield","effect":"put_land_from_hand_onto_battlefield","optional":true,"put_land_tapped":true,"target":"land_card_from_hand","xmage_effect_class":"PutCardFromHandOntoBattlefieldEffect"}],"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","count":3,"destination":"battlefield","draw_count":3,"effect":"composite_resolution","instant":true,"put_land_from_hand":true,"put_land_tapped":true,"resolution_order":"draw_then_put_land_from_hand","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","PutCardFromHandOntoBattlefieldEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmbraceTheParadox translated into ManaLoom runtime scope xmage_fixed_draw_put_land_from_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eureka moment', 'Eureka Moment', '4bf3055106e5ff6ac3bf8f72a4de9d6d', 'battle_rule_v1:71e02e39bcfe3b5632cce138a9fa3d5f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","compose_on_resolution":true,"destination":"battlefield","effect":"put_land_from_hand_onto_battlefield","optional":true,"put_land_tapped":false,"target":"land_card_from_hand","xmage_effect_class":"PutCardFromHandOntoBattlefieldEffect"}],"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","count":2,"destination":"battlefield","draw_count":2,"effect":"composite_resolution","instant":true,"put_land_from_hand":true,"put_land_tapped":false,"resolution_order":"draw_then_put_land_from_hand","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","PutCardFromHandOntoBattlefieldEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EurekaMoment translated into ManaLoom runtime scope xmage_fixed_draw_put_land_from_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('growth spiral', 'Growth Spiral', 'fbd075c9cd3cae4b0cd587e19d1805e2', 'battle_rule_v1:e3e11fd5d33b6837c34cc1460a0a7448', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","compose_on_resolution":true,"destination":"battlefield","effect":"put_land_from_hand_onto_battlefield","optional":true,"put_land_tapped":false,"target":"land_card_from_hand","xmage_effect_class":"PutCardFromHandOntoBattlefieldEffect"}],"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","count":1,"destination":"battlefield","draw_count":1,"effect":"composite_resolution","instant":true,"put_land_from_hand":true,"put_land_tapped":false,"resolution_order":"draw_then_put_land_from_hand","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","PutCardFromHandOntoBattlefieldEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrowthSpiral translated into ManaLoom runtime scope xmage_fixed_draw_put_land_from_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lessons from life', 'Lessons from Life', '91f408bbce4eecf30a06626166e9acf6', 'battle_rule_v1:1d96fcc38277822e5d2b0222ac3a055d', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","compose_on_resolution":true,"destination":"battlefield","effect":"put_land_from_hand_onto_battlefield","optional":true,"put_land_tapped":true,"target":"land_card_from_hand","xmage_effect_class":"PutCardFromHandOntoBattlefieldEffect"}],"battle_model_scope":"xmage_fixed_draw_put_land_from_hand_spell_v1","count":3,"destination":"battlefield","draw_count":3,"effect":"composite_resolution","instant":false,"put_land_from_hand":true,"put_land_tapped":true,"resolution_order":"draw_then_put_land_from_hand","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","PutCardFromHandOntoBattlefieldEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LessonsFromLife translated into ManaLoom runtime scope xmage_fixed_draw_put_land_from_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.xmage_pg516_draw_put_land_from_hand_new_20260705_161259) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

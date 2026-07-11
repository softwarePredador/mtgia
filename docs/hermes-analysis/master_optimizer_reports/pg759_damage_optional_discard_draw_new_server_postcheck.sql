WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('incinerating blast', 'Incinerating Blast', 'ff2e12f0294569c33d55bebfc3eca937', 'battle_rule_v1:1010828ca52b1c537cd18a4254e3e5bb', '{"_composite_rule_components":[{"amount":6,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":6,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"discard_count":1,"effect":"draw_cards","optional":true,"optional_cost":"discard_card","optional_cost_count":1,"xmage_effect_class":"DrawCardSourceControllerEffect"}],"amount":6,"battle_model_scope":"xmage_fixed_damage_target_and_draw_card_spell_v1","count":1,"damage":6,"draw_count":1,"effect":"composite_resolution","instant":false,"optional_discard_count":1,"optional_discard_draw":true,"optional_discard_draw_count":1,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IncineratingBlast translated into ManaLoom runtime scope xmage_fixed_damage_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tweeze', 'Tweeze', '12413e4a3440fd6799c23650b4d33c89', 'battle_rule_v1:3d93135447239576a0f3960d2c831111', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"discard_count":1,"effect":"draw_cards","optional":true,"optional_cost":"discard_card","optional_cost_count":1,"xmage_effect_class":"DrawCardSourceControllerEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_draw_card_spell_v1","count":1,"damage":3,"draw_count":1,"effect":"composite_resolution","instant":true,"optional_discard_count":1,"optional_discard_draw":true,"optional_discard_draw_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tweeze translated into ManaLoom runtime scope xmage_fixed_damage_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg759_damage_optional_discard_draw_new_s_20260711_115206) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

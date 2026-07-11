WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('voyage home', 'Voyage Home', 'aae29936df1c6a253fa2a66d10585977', 'battle_rule_v1:920d25f2f6af55d8a9dcea0d87f0d966', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"life_gain_amount":3,"resolution_order":"draw_then_gain","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","GainLifeEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoyageHome translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg772_fixed_draw_gain_life_new_server_fi_20260711_161412) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('sage of lat-nam', 'Sage of Lat-Nam', 'd6513fb8d35ad0039a32b28e9fbc0ae0', 'battle_rule_v1:4cae83435837b3358d3b79741ec00f49', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_target":"artifact","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SageOfLatNam translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thraxodemon', 'Thraxodemon', '6b7a78500d61941c79431c4eaf5c7cad', 'battle_rule_v1:47c1829b9fc130c9b57e4b8b46376c52', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_target":"artifact_or_creature","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Thraxodemon translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg615_activated_draw_sacrifice_target_pg_20260707_124911) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

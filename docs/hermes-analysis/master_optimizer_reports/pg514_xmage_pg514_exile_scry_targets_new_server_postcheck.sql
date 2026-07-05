WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('devout decree', 'Devout Decree', '2ffef40b32de279e5d069ebdd05a631d', 'battle_rule_v1:77c2ca923d2c6b62ff46fc58b27e27fb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DevoutDecree translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of ruin', 'Ray of Ruin', '2c30c4034ace17cd7c4d01f9cb32d74c', 'battle_rule_v1:3ba725d656340693d4c616116bb305ef', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfRuin translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg514_xmage_pg514_exile_scry_targets_new_20260705_152330) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

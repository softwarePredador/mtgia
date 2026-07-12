WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('courage in crisis', 'Courage in Crisis', 'fb2360868c692987a6528fcc54d0209d', 'battle_rule_v1:26da15c77e5f75c18a4e86fd53aad6ce', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","compose_on_resolution":true,"count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"AddCountersTargetEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","instant":false,"proliferate_count":1,"sorcery":true,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_add_counters_target_creature_then_proliferate_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"add_counters_then_proliferate","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_classes":["AddCountersTargetEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CourageInCrisis translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creature_then_proliferate_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grim affliction', 'Grim Affliction', '19ed492a4425aedba232830fb0d742c4', 'battle_rule_v1:da949d8f98db67d7074176895f4dfd6f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","compose_on_resolution":true,"count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"AddCountersTargetEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","instant":true,"proliferate_count":1,"sorcery":false,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_add_counters_target_creature_then_proliferate_spell_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"composite_resolution","instant":true,"proliferate_count":1,"resolution_order":"add_counters_then_proliferate","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"up_to_count":false,"xmage_effect_classes":["AddCountersTargetEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrimAffliction translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creature_then_proliferate_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg834_add_counters_proliferate_new_serve_20260712_171340) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

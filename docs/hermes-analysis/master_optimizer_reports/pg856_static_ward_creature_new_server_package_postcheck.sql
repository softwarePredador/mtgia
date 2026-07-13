WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('punk frogs', 'Punk Frogs', '4491763795274f7ce062b50a69d8c0df', 'battle_rule_v1:646fcaa58b271a6669f00d0e6549f931', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":[],"ward":"{3}","ward_cost":"{3}","ward_cost_status":"runtime_executor_v1","ward_mana_value":3,"xmage_ability_classes":["WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PunkFrogs translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rimeshield frost giant', 'Rimeshield Frost Giant', '4491763795274f7ce062b50a69d8c0df', 'battle_rule_v1:646fcaa58b271a6669f00d0e6549f931', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":[],"ward":"{3}","ward_cost":"{3}","ward_cost_status":"runtime_executor_v1","ward_mana_value":3,"xmage_ability_classes":["WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RimeshieldFrostGiant translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider-rex, daring dino', 'Spider-Rex, Daring Dino', 'cfde276b568e3227ab1a5d23b980b02d', 'battle_rule_v1:2423442d397012ba21a508b50416d84f', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":["reach","trample"],"reach":true,"trample":true,"ward":"{2}","ward_cost":"{2}","ward_cost_status":"runtime_executor_v1","ward_mana_value":2,"xmage_ability_classes":["ReachAbility","TrampleAbility","WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderRexDaringDino translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tomakul honor guard', 'Tomakul Honor Guard', '6bd51c150a01631e1f5baf38e59ee39f', 'battle_rule_v1:34f4729c41611935e9c204335337d063', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":[],"ward":"{2}","ward_cost":"{2}","ward_cost_status":"runtime_executor_v1","ward_mana_value":2,"xmage_ability_classes":["WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TomakulHonorGuard translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('waterfall aerialist', 'Waterfall Aerialist', '8009a54c00bb7c689882802e0bc37276', 'battle_rule_v1:f1324914fb7d71e8add2219aa03eb63e', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"ward":"{2}","ward_cost":"{2}","ward_cost_status":"runtime_executor_v1","ward_mana_value":2,"xmage_ability_classes":["FlyingAbility","WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WaterfallAerialist translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg856_static_ward_creature_new_server_st_20260713_015130) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('anodet lurker', 'Anodet Lurker', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnodetLurker translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enatu golem', 'Enatu Golem', '8f49e15bfa18c75f0217bc16c17aa6df', 'battle_rule_v1:4a89277d577326cb47ef270db2344cb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":4,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnatuGolem translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grasping longneck', 'Grasping Longneck', '705e45d3be0759b8eaebd4e9f73680fd', 'battle_rule_v1:e7ed4957301a134d003ea8a3c1bc1183', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"keywords":["reach"],"reach":true,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraspingLongneck translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian automaton', 'Guardian Automaton', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianAutomaton translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('highland game', 'Highland Game', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighlandGame translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('onulet', 'Onulet', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Onulet translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tarpan', 'Tarpan', '1fd6a1149d32fb6b4f9ce8e236c1bbc6', 'battle_rule_v1:0f97a1e681aa1afb50c4e774cb9808bd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":1,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tarpan translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg395_dies_life_gain_new_server_20260704_085247) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

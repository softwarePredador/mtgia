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
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;

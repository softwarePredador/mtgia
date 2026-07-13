WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('birthing boughs', 'Birthing Boughs', '2465083f401a35e89bd81d155353bfb0', 'battle_rule_v1:3566e78c8b8acc37b06979e9f460145c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_all_creature_types":true,"token_changeling":true,"token_count":1,"token_description":"2/2 colorless Shapeshifter creature token with changeling","token_keywords":["changeling"],"token_name":"Shapeshifter Token","token_power":2,"token_subtype":"Shapeshifter","token_toughness":2,"token_universal_creature_subtypes":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ShapeshifterToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"artifact","token_all_creature_types":true,"token_changeling":true,"token_count":1,"token_description":"2/2 colorless Shapeshifter creature token with changeling","token_keywords":["changeling"],"token_name":"Shapeshifter Token","token_power":2,"token_subtype":"Shapeshifter","token_toughness":2,"token_universal_creature_subtypes":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ShapeshifterToken"}'::jsonb, '{"category":"unknown","effect":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BirthingBoughs translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg861_token_static_identity_new_server_20260713_035756) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

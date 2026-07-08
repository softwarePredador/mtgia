WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('final strike', 'Final Strike', 'd9a916ef14b7d8bfe05d74858bf92c64', 'battle_rule_v1:346223fcdea57c534e7b783dcff541b1', '{"additional_cost":"sacrifice_creature","amount":0,"battle_model_scope":"xmage_sacrifice_creature_power_damage_spell_v1","damage":0,"damage_amount_source":"sacrificed_creature_power","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"opponent_or_planeswalker","target_constraints":{"scope":"opponent_or_planeswalker"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_dynamic_value_class":"SacrificeCostCreaturesPower","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"opponent_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalStrike translated into ManaLoom runtime scope xmage_sacrifice_creature_power_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fling', 'Fling', '4e8893193f72e0e545d986f00e6edd8e', 'battle_rule_v1:86b3e07368c2b2ef1190c6b2a5977e45', '{"additional_cost":"sacrifice_creature","amount":0,"battle_model_scope":"xmage_sacrifice_creature_power_damage_spell_v1","damage":0,"damage_amount_source":"sacrificed_creature_power","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_dynamic_value_class":"SacrificeCostCreaturesPower","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Fling translated into ManaLoom runtime scope xmage_sacrifice_creature_power_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thud', 'Thud', 'faee9a2d7c30b63149791b1e1d0b0891', 'battle_rule_v1:6d05535b98987d48dddf63d3c6e08ad3', '{"additional_cost":"sacrifice_creature","amount":0,"battle_model_scope":"xmage_sacrifice_creature_power_damage_spell_v1","damage":0,"damage_amount_source":"sacrificed_creature_power","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_dynamic_value_class":"SacrificeCostCreaturesPower","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Thud translated into ManaLoom runtime scope xmage_sacrifice_creature_power_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg655_sacrifice_creature_power_damage_ne_20260708_122228) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

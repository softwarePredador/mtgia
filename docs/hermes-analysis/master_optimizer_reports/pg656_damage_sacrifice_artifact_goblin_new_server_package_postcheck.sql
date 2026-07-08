WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('goblin grenade', 'Goblin Grenade', 'd3e3d2a19d131c2885a2c185184d3474', 'battle_rule_v1:d3ecba576287f7ee3ae09a6a90e10426', '{"additional_cost":"sacrifice_goblin","amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":false,"requires_sacrifice_goblin":true,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"goblin","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGrenade translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shrapnel blast', 'Shrapnel Blast', 'fb2957069cb0018ccd599ce259f55116', 'battle_rule_v1:d59036a7f269287fafc5c5e29e4eeb6d', '{"additional_cost":"sacrifice_artifact","amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":true,"requires_sacrifice_artifact":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShrapnelBlast translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg656_damage_sacrifice_artifact_goblin_n_20260708_124341) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

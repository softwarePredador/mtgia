WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('strafe', 'Strafe', '4810b35ee5ab7da765fd1a1d04e4c6d7', 'battle_rule_v1:572a7e591d1365d57af44902db710701', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["R"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Strafe translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sunlance', 'Sunlance', '9925bcaefd9f8793bd21b4aa9b88e1e8', 'battle_rule_v1:2e641aea968159cade8055400155ae8b', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["W"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sunlance translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg512_xmage_pg512_nonred_nonwhite_damage_20260705_144951) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

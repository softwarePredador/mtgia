WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('carbonize', 'Carbonize', 'f9d34a2e5dca2ec279e2b55c139c2329', 'battle_rule_v1:7c64b48593863ae35e0422b9bb6a8cc1', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_exile_if_dies_spell_v1","damage":3,"effect":"direct_damage","exile_if_dies_from_damage":true,"exile_if_dies_target":"any_target","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["CantRegenerateTargetEffect","CarbonizeEffect","DamageTargetEffect","DiesReplacementEffect","OneShotEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Carbonize translated into ManaLoom runtime scope xmage_fixed_damage_target_exile_if_dies_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with exile-if-dies replacement with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg811_damage_exile_if_dies_carbonize_new_20260712_064250) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('heated debate', 'Heated Debate', 'fc24e77da08eef4359e6e7a603743729', 'battle_rule_v1:8691e82508128f1101d29cd7e5120895', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","cant_be_countered":true,"damage":4,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect","xmage_effect_classes":["CantBeCounteredSourceEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeatedDebate translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rending volley', 'Rending Volley', '4fb268564e28a69462ebf8fad7790020', 'battle_rule_v1:9a44b17fec8011532f1d92f1004f5cb2', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","cant_be_countered":true,"damage":4,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["W","U"]},"xmage_effect_class":"DamageTargetEffect","xmage_effect_classes":["CantBeCounteredSourceEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RendingVolley translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg668_cant_be_countered_damage_20260708_185901) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

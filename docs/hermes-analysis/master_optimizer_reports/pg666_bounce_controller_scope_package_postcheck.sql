WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('rescue', 'Rescue', '20e9b483ab3e23f5022b854097ed3cac', 'battle_rule_v1:9721efd471d5b36a4fdae0197d0f27c9', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self"},"target_controller":"self","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Rescue translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stern dismissal', 'Stern Dismissal', '9811af8a8fa4eb634d1841427f4fc00b', 'battle_rule_v1:2f46e9d157ff051d300694a25155f24e', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"],"controller_scope":"opponent"},"target_controller":"opponent","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SternDismissal translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg666_bounce_controller_scope_20260708_182140) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

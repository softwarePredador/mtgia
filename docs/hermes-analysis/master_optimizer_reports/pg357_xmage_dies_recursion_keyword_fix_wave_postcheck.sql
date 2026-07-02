WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('junk diver', 'Junk Diver', '11e0a94543cbb383b4164a978a60b0cf', 'battle_rule_v1:2ee0fdb35d6fb7c6f4f48249325a9a09', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JunkDiver translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg357_xmage_dies_recursion_keyword_fix_wave_20260702_062) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angelic purge', 'Angelic Purge', '89045cca8ed62def380b66a09e5696bc', 'battle_rule_v1:4c2132e1a6cce17cb158532d0904b717', '{"additional_cost":"sacrifice_permanent","battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"requires_sacrifice_permanent":true,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["artifact","creature","enchantment"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"permanent","xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelicPurge translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg807_exile_ace_target_new_server_exile_20260712_050443) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

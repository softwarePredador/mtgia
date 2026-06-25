WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('redress fate', 'Redress Fate', '43b0f9e8d3e2fc829b55e89d812750cd', 'battle_rule_v1:e78fc833fc5528c9fff3788f2d82d5d0', '{"ability_kind":"one_shot","battle_model_scope":"return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_miracle_v1","destination":"battlefield","effect":"recursion","miracle":true,"miracle_cost":"{3}{W}","return_all_matching":true,"target":"artifact_or_enchantment","target_card_types":["artifact","enchantment"],"target_controller":"self","target_zone":"graveyard"}'::jsonb, '{"category":"recursion","effect":"recursion","subtype":"graveyard_to_battlefield_or_hand","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RedressFate mapped to family recursion; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg202_redress_fate_20260625_040611) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

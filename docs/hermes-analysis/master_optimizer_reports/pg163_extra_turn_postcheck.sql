WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('final fortune', 'Final Fortune', '059f0f01430a2d44ac0d143bf8e40ed6', 'battle_rule_v1:10a7179930eacb06c18e6734c0e93add', '{"ability_kind":"one_shot","battle_model_scope":"single_extra_turn_then_lose_game_v1","effect":"extra_turn","instant":true,"lose_after_extra_turn":true,"turns":1}'::jsonb, '{"category":"combo_value","effect":"extra_turn","subtype":"extra_turn","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FinalFortune mapped to family extra_turn_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('last chance', 'Last Chance', '059f0f01430a2d44ac0d143bf8e40ed6', 'battle_rule_v1:9f5103721cb05db1501499eb5f49de56', '{"ability_kind":"one_shot","battle_model_scope":"single_extra_turn_then_lose_game_v1","effect":"extra_turn","instant":false,"lose_after_extra_turn":true,"turns":1}'::jsonb, '{"category":"combo_value","effect":"extra_turn","subtype":"extra_turn","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LastChance mapped to family extra_turn_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg163_extra_turn_20260624_102023) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

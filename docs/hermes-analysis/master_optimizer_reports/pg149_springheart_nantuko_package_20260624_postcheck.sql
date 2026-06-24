WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('springheart nantuko', 'Springheart Nantuko', 'e0fb2f2b4e774063b3f8f8ee12f180da', 'battle_rule_v1:bdb24c77e6b6dff83b1cdd01dbe09ba6', '{"ability_kind":"triggered","battle_model_scope":"landfall_optional_pay_copy_attached_creature_else_insect_v1","bestow_attached_creature_power_bonus":1,"bestow_attached_creature_toughness_bonus":1,"bestow_cost":"{1}{G}","effect":"creature","is_creature_permanent":true,"landfall_copy_cost":"{1}{G}","landfall_optional_pay_copy_attached_creature_else_insect":true,"power":1,"token_colors":["G"],"token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SpringheartNantuko mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg149_springheart_nantuko_20260624_065629) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

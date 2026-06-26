WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('warleader''s call', 'Warleader''s Call', '0b6b075fd5c59b4634262b2658685f1d', 'battle_rule_v1:cc55ae76863ec402fabc99b2691625a7', '{"ability_kind":"triggered","battle_model_scope":"controlled_creature_enters_damage_each_opponent_v1","damage":1,"effect":"passive","is_creature_permanent":false,"target_controller":"opponents","trigger":"creature_you_control_enters","trigger_another_creature_you_control_enters":false,"trigger_creature_you_control_enters":true,"trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"burn_engine","effect":"damage_each_opponent","subtype":"creature_enter_trigger","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WarleadersCall mapped to family controlled_creature_etb_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg218_warleaders_call_creature_etb_damage_20260625_12284) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

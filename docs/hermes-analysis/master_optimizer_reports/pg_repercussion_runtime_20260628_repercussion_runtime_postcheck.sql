WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('repercussion', 'Repercussion', '8e1ed4f8063ab89dd8906878a6232862', 'battle_rule_v1:d344ca49febecf963d6992cf1de87108', '{"ability_kind":"triggered","battle_model_scope":"creature_damage_controller_reflect_global_v1","cmc":3.0,"damage_amount_source":"damage_dealt_to_creature","effect":"direct_damage","global_creature_damage_reflect_to_controller":true,"trigger":"creature_dealt_damage","trigger_effect":"damage_creature_controller"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"creature_damage_controller_reflect","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Repercussion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg_repercussion_runtime_20260628_repercussion_runtime_20) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('terror of the peaks', 'Terror of the Peaks', '90c007ac59cdd400f58e89c47d81440e', 'battle_rule_v1:b495892461d2521bc633d7e9ab5cd443', '{"ability_kind":"triggered","battle_model_scope":"controlled_other_creature_enters_power_damage_any_target_v1","cmc":5.0,"effect":"creature","flying":true,"opponent_spells_targeting_this_additional_life_cost":3,"power":5,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":4,"trigger":"creature_you_control_enters","trigger_another_creature_you_control_enters":true,"trigger_damage_amount_source":"entering_creature_power","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"etb_power_damage","subtype":"controlled_creature_enters_power_damage_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TerrorOfThePeaks mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg_terror_runtime_20260628_terror_runtime_20260628_11084) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

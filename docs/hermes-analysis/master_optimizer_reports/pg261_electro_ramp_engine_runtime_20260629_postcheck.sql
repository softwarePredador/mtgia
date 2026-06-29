WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('electro, assaulting battery', 'Electro, Assaulting Battery', '89bda5fb5ee7d86edea25de7fc9605ff', 'battle_rule_v1:806bda250ae81f2871b2e6a30ab8235b', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_red_mana_trigger_persistent_red_leaves_x_damage_annotation_v1","effect":"ramp_engine","flying":true,"instant_sorcery_cast_add_mana":1,"instant_sorcery_cast_mana_color":"R","is_creature_permanent":true,"leaves_battlefield_pay_x_damage_status":"annotation_only","leaves_battlefield_pay_x_damage_target_player":true,"mana_persists_steps":true,"power":2,"produces":"R","toughness":3,"trigger":"instant_sorcery_cast"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElectroAssaultingBattery mapped to family ramp_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg261_electro_ramp_engine_runtime_20260629_20260629_1733) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

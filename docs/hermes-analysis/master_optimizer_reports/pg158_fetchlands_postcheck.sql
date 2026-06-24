WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('misty rainforest', 'Misty Rainforest', '35f4b0c638d068b62e520306c16eceb5', 'battle_rule_v1:220e22b189d9e2d92aa34d6beaab0a0a', '{"ability_kind":"activated","activated_pay_life":1,"activated_self_sacrifice_land_tutor":true,"activation_cost_generic":0,"activation_requires_tap":true,"battle_model_scope":"self_sacrifice_fetch_land_two_land_subtypes_v1","effect":"ramp_permanent","land_count":1,"land_enters_tapped":false,"land_subtypes_any":["Forest","Island"],"lands_to_battlefield":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"utility_land"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MistyRainforest mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('verdant catacombs', 'Verdant Catacombs', '9b658868f3d3ae8543afd7dab44e2c25', 'battle_rule_v1:cb164541fa6dd03555a433a0dce3a127', '{"ability_kind":"activated","activated_pay_life":1,"activated_self_sacrifice_land_tutor":true,"activation_cost_generic":0,"activation_requires_tap":true,"battle_model_scope":"self_sacrifice_fetch_land_two_land_subtypes_v1","effect":"ramp_permanent","land_count":1,"land_enters_tapped":false,"land_subtypes_any":["Swamp","Forest"],"lands_to_battlefield":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"utility_land"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VerdantCatacombs mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('polluted delta', 'Polluted Delta', 'cf9dde68ad2b7b6927a835c842659b2e', 'battle_rule_v1:f2d4cbe84d49d11a20aa13e9f9db53a9', '{"ability_kind":"activated","activated_pay_life":1,"activated_self_sacrifice_land_tutor":true,"activation_cost_generic":0,"activation_requires_tap":true,"battle_model_scope":"self_sacrifice_fetch_land_two_land_subtypes_v1","effect":"ramp_permanent","land_count":1,"land_enters_tapped":false,"land_subtypes_any":["Island","Swamp"],"lands_to_battlefield":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"utility_land"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PollutedDelta mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg158_fetchlands_20260624_090255) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('misty rainforest', 'Misty Rainforest', '35f4b0c638d068b62e520306c16eceb5', 'battle_rule_v1:220e22b189d9e2d92aa34d6beaab0a0a', '{"ability_kind":"activated","activated_pay_life":1,"activated_self_sacrifice_land_tutor":true,"activation_cost_generic":0,"activation_requires_tap":true,"battle_model_scope":"self_sacrifice_fetch_land_two_land_subtypes_v1","effect":"ramp_permanent","land_count":1,"land_enters_tapped":false,"land_subtypes_any":["Forest","Island"],"lands_to_battlefield":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"utility_land"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MistyRainforest mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('verdant catacombs', 'Verdant Catacombs', '9b658868f3d3ae8543afd7dab44e2c25', 'battle_rule_v1:cb164541fa6dd03555a433a0dce3a127', '{"ability_kind":"activated","activated_pay_life":1,"activated_self_sacrifice_land_tutor":true,"activation_cost_generic":0,"activation_requires_tap":true,"battle_model_scope":"self_sacrifice_fetch_land_two_land_subtypes_v1","effect":"ramp_permanent","land_count":1,"land_enters_tapped":false,"land_subtypes_any":["Swamp","Forest"],"lands_to_battlefield":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"utility_land"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VerdantCatacombs mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('polluted delta', 'Polluted Delta', 'cf9dde68ad2b7b6927a835c842659b2e', 'battle_rule_v1:f2d4cbe84d49d11a20aa13e9f9db53a9', '{"ability_kind":"activated","activated_pay_life":1,"activated_self_sacrifice_land_tutor":true,"activation_cost_generic":0,"activation_requires_tap":true,"battle_model_scope":"self_sacrifice_fetch_land_two_land_subtypes_v1","effect":"ramp_permanent","land_count":1,"land_enters_tapped":false,"land_subtypes_any":["Island","Swamp"],"lands_to_battlefield":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"utility_land"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PollutedDelta mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;

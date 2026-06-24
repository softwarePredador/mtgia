WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('elvish spirit guide', 'Elvish Spirit Guide', '75a6071aad90d25b26b269458f953bb0', 'battle_rule_v1:89b51a84d293b0e0f3ed43c40aeee4d9', '{"ability_kind":"activated","battle_model_scope":"hand_exile_add_one_green_mana_ritual_v1","effect":"ramp_ritual","hand_exile_mana_ability":true,"mana_produced":1,"produces":"G"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishSpiritGuide mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mountain', 'Mountain', 'b3614279f2405f7c1cabda2d7252852b', 'battle_rule_v1:8a2127a2777cd1a0992c74c621621796', '{"ability_kind":"activated","basic_land_types":["Mountain"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"R"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mountain mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('plains', 'Plains', '0159e87a7fe9f2edbdb9408db4e6cba8', 'battle_rule_v1:f7fde69c51ea340cdfeda1544dea220b', '{"ability_kind":"activated","basic_land_types":["Plains"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"W"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Plains mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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

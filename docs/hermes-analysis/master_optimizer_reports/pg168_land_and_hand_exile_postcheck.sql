WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('elvish spirit guide', 'Elvish Spirit Guide', '75a6071aad90d25b26b269458f953bb0', 'battle_rule_v1:89b51a84d293b0e0f3ed43c40aeee4d9', '{"ability_kind":"activated","battle_model_scope":"hand_exile_add_one_green_mana_ritual_v1","effect":"ramp_ritual","hand_exile_mana_ability":true,"mana_produced":1,"produces":"G"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishSpiritGuide mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mountain', 'Mountain', 'b3614279f2405f7c1cabda2d7252852b', 'battle_rule_v1:8a2127a2777cd1a0992c74c621621796', '{"ability_kind":"activated","basic_land_types":["Mountain"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"R"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mountain mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('plains', 'Plains', '0159e87a7fe9f2edbdb9408db4e6cba8', 'battle_rule_v1:f7fde69c51ea340cdfeda1544dea220b', '{"ability_kind":"activated","basic_land_types":["Plains"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"W"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Plains mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg168_land_and_hand_exile_20260624_113000) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

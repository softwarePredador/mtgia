WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('eldrazi confluence', 'Eldrazi Confluence', '62340dc75c903ea4f9936ac536cc0a76', 'battle_rule_v1:14c689c3a27f3fb564fd4f2741c1be3a', '{"ability_kind":"one_shot","battle_model_scope":"choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1","effect":"modal_spell","instant":true,"modal_choose_count":3,"modal_may_repeat_modes":true,"mode_blink_target_nonland_permanent_tapped":true,"mode_create_eldrazi_scion":true,"mode_target_creature_plus_three_minus_three":true,"token_colors":[],"token_name":"Eldrazi Scion Token","token_power":1,"token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Scion","token_toughness":1}'::jsonb, '{"category":"interaction","effect":"modal_spell","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EldraziConfluence mapped to family modal_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg147_eldrazi_confluence_20260624_063723) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

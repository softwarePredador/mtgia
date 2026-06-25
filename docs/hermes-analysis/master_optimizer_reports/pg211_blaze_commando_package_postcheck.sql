WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('blaze commando', 'Blaze Commando', '4abc037978046cd0dff44e8254ce3d0c', 'battle_rule_v1:bb53685ff2f0c9074dd2512b79c42c08', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_spell_damage_create_two_1_1_red_white_soldier_haste_v1","effect":"token_maker","power":5,"token_colors":["R","W"],"token_count":2,"token_haste":true,"token_keywords":["haste"],"token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"toughness":3,"trigger":"instant_sorcery_spell_you_control_deals_damage","trigger_effect":"token_maker","trigger_token_count":2}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BlazeCommando mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg211_blaze_commando_20260625_083109) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

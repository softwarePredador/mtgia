WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('soul immolation', 'Soul Immolation', '87d1491af3cd1da95d2ec2769d1475b5', 'battle_rule_v1:86324946621827f59ca016b47cb61f73', '{"ability_kind":"one_shot","additional_cost_kind":"blight_x","battle_model_scope":"blight_x_damage_each_opponent_and_opponent_creatures_v1","damage_amount_source":"x_value","damage_scope":"each_opponent_and_creatures_they_control","effect":"damage_each_opponent_and_opponent_creatures","requires_blight_x":true,"sorcery":true,"target_controller":"opponents","x_value_source":"blight_greatest_toughness_controlled_creature"}'::jsonb, '{"category":"interaction","effect":"board_control","subtype":"wipe_or_sacrifice","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SoulImmolation mapped to family board_wipe_choice; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg213_soul_immolation_20260625_092521) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('taii wakeen, perfect shot', 'Taii Wakeen, Perfect Shot', '6222a19da7f6b4b6b9ba97d28c512e39', 'battle_rule_v1:92e28c9f363acf93363f11f48b98ddeb', '{"ability_kind":"triggered","activated_noncombat_damage_plus_x_until_eot":true,"activation_cost_x_generic":true,"activation_requires_tap":true,"battle_model_scope":"taii_wakeen_noncombat_damage_equal_toughness_draw_plus_x_v1","damage_modifier_applies_to":"sources_you_control_noncombat_damage","damage_modifier_duration":"until_end_of_turn","effect":"creature","noncombat_damage_equal_toughness_draw_count":1,"noncombat_damage_to_creature_equal_toughness_draw":true,"power":2,"toughness":3,"trigger":"source_you_control_noncombat_damage_to_creature_equal_toughness"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TaiiWakeenPerfectShot mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg199_taii_wakeen_20260625_022333) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

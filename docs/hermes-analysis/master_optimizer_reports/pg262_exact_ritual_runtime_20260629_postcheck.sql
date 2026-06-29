WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('mana geyser', 'Mana Geyser', '684f03297624aa968fe22e1b6d6f63d9', 'battle_rule_v1:a1afa8a2f4322a64c0b150f3e52610c3', '{"ability_kind":"one_shot","battle_model_scope":"add_red_for_each_tapped_land_opponents_control_v1","dynamic_mana_amount":true,"effect":"ramp_ritual","mana_color_status":"abstracted_to_generic_pool_runtime","mana_per_tapped_land":1,"mana_produced_from_opponents_tapped_lands":true,"produces":"R","sorcery":true}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ManaGeyser mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('burnt offering', 'Burnt Offering', '33ec6df2ab36a881c5cf77936bc484d1', 'battle_rule_v1:49d5a64329f7d552eca189abfd07c343', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_creature_add_black_or_red_equal_sacrificed_mana_value_v1","effect":"ramp_ritual","instant":true,"mana_color_choice":["B","R"],"mana_color_status":"abstracted_to_generic_pool_runtime","mana_produced_from_sacrificed_cmc":true,"produces":"BR","requires_sacrifice_creature":true}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BurntOffering mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg262_exact_ritual_runtime_20260629_20260629_174351) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

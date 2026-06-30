WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('neheb, the eternal', 'Neheb, the Eternal', '156a5b4b19a9754340b8849175270145', 'battle_rule_v1:aeb836c3a1a534548dbce188e2982441', '{"ability_kind":"triggered","afflict":3,"battle_model_scope":"postcombat_main_add_red_for_opponents_life_lost_this_turn_v1","dynamic_mana_amount":true,"effect":"ramp_engine","is_creature_permanent":true,"mana_added_per_opponent_life_lost":1,"mana_amount_source":"opponents_lost_life_count_this_turn","mana_color":"red","opponents_lost_life_this_turn":true,"permanent_type":"creature","postcombat_main_add_red_for_opponents_life_lost_this_turn":true,"power":4,"produces":"R","toughness":6,"trigger":"beginning_postcombat_main"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","subtype":"postcombat_life_lost_mana_trigger","timing":"beginning_postcombat_main"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NehebTheEternal mapped to family ramp_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg267_neheb_postcombat_mana_20260630_neheb_postcombat_ma) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

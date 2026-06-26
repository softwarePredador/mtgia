WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bedlam reveler', 'Bedlam Reveler', '25edf0dbac766bdc2506f4b317a1897a', 'battle_rule_v1:ba88301358f5ac10a8fc9ef41e4dd9b3', '{"ability_kind":"triggered","battle_model_scope":"front_creature_prowess_etb_discard_hand_draw_three_self_instant_sorcery_graveyard_cost_reduction_v1","cost_reduction_amount_source":"instant_sorcery_cards_in_your_graveyard_count","cost_reduction_applies_to":"this_spell","cost_reduction_generic":1,"effect":"creature","etb_discard_hand_then_draw_count":3,"graveyard_count_card_types":["instant","sorcery"],"is_creature_permanent":true,"keywords":["prowess"],"power":3,"toughness":4}'::jsonb, '{"category":"draw","effect":"creature","subtype":"etb_refill_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BedlamReveler mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg226_bedlam_reveler_exact_scope_20260626_051643) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

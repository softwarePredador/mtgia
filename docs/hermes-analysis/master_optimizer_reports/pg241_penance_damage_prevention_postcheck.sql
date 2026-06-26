WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('penance', 'Penance', 'fbe58d392a998f29895af142fa09e6d6', 'battle_rule_v1:7b7befc4b77b04202df8c2966004c8e6', '{"ability_kind":"activated","activated_prevent_next_damage_from_chosen_source":true,"activation_cost":"put_card_from_hand_on_top_of_library","activation_cost_generic":0,"activation_requires_put_card_from_hand_on_top_library":true,"battle_model_scope":"activated_put_card_from_hand_on_top_library_prevent_next_damage_from_chosen_black_or_red_source_to_you_v1","effect":"damage_prevention_shield","prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_to":"you","prevent_next_damage_from_chosen_source":true,"source_choice_required":true,"source_color_filter":["black","red"]}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Penance mapped to family damage_prevention_shield; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg241_penance_damage_prevention_20260626_110838) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

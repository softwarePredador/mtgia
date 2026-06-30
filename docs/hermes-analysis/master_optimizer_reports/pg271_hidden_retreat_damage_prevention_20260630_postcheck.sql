WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('hidden retreat', 'Hidden Retreat', '816f631d821b5a48e187fafe519845d7', 'battle_rule_v1:7148a419f22524cca81db7d14deeb043', '{"ability_kind":"activated","activated_prevent_damage_from_target_spell":true,"activation_cost":"put_card_from_hand_on_top_of_library","activation_cost_generic":0,"activation_requires_put_card_from_hand_on_top_library":true,"battle_model_scope":"activated_put_card_from_hand_on_top_library_prevent_damage_from_target_instant_or_sorcery_spell_v1","can_setup_lorehold_miracle_draw":true,"cmc":3.0,"effect":"damage_prevention_shield","prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_target_spell":true,"prevent_damage_target_type":"instant_or_sorcery_spell","spell_target_required":true,"target_spell_card_types":["instant","sorcery"]}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","subtype":"targeted_damage_prevention","timing":"activated_response"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HiddenRetreat mapped to family damage_prevention_shield; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg271_hidden_retreat_damage_prevention_20260630_20260630) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

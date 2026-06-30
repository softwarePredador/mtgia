WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cloud key', 'Cloud Key', '19792b44d184aed6b5b075cfa5c0cbe4', 'battle_rule_v1:797349f2d8c0cc961e0c0c1611b9beb6', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"chosen_card_type_cost_reduction_v1","choose_card_type_on_enter":true,"chosen_card_type_options":["artifact","creature","enchantment","instant","sorcery"],"cost_reduction_applies_to":"spells_you_cast_of_chosen_card_type","cost_reduction_generic":1,"cost_reduction_uses_chosen_card_type":true,"effect":"static_cost_reduction","permanent_type":"artifact","preferred_card_type_order":["instant","sorcery","artifact","creature","enchantment"]}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"chosen_card_type_cost_reducer","timing":"static_after_as_enters_choice"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CloudKey mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg268_cloud_key_chosen_type_cost_reduction_20260630_clou) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

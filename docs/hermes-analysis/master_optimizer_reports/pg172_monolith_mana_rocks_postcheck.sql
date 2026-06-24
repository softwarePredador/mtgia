WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('grim monolith', 'Grim Monolith', '2fcac973250226ee566f69491bff9de4', 'battle_rule_v1:ac773d3e88bf38de11004c2943b4d871', '{"ability_kind":"activated","activated_untap_cost_generic":4,"battle_model_scope":"three_colorless_monolith_mana_rock_v1","does_not_untap_in_untap_step":true,"effect":"ramp_permanent","mana_produced":3,"produces":"C"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GrimMonolith mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('basalt monolith', 'Basalt Monolith', '7bfcb40a391bef0cb4c2f3a59c007bdc', 'battle_rule_v1:13a254365e4f64a322c42899dd7e9ec1', '{"ability_kind":"activated","activated_untap_cost_generic":3,"battle_model_scope":"three_colorless_monolith_mana_rock_v1","does_not_untap_in_untap_step":true,"effect":"ramp_permanent","mana_produced":3,"produces":"C"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BasaltMonolith mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg172_monolith_mana_rocks_20260624_122041) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

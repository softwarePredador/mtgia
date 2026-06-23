WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('dargo, the shipwrecker', 'Dargo, the Shipwrecker', '8683fc84ed2dfe9f92c9c6c6c5546a53', 'battle_rule_v1:947eca66a843591ccbbaa6080e2ec17a', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_variable_self_spell_cost_reduction_variant_v1","cost_reduction_amount_source":"sacrificed_artifact_or_creature_count_this_turn","cost_reduction_applies_to":"this_spell","cost_reduction_counts_additional_sacrifices_paid_while_casting":true,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DargoTheShipwrecker mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg122_dargo_variable_self_cost_reducer_restore_20260623_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;

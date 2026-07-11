WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('disruption protocol', 'Disruption Protocol', 'f64d658403423ac3718b4195252ee163', 'battle_rule_v1:acf4f50321629a08ea98812455ee840a', '{"additional_cost":"choose_tap_untapped_artifact_or_pay_generic","additional_cost_options":[{"cost":"tap_untapped_artifact","requires_tap_untapped_artifact":true,"xmage_additional_cost_target":"untapped_artifact"},{"cost":"pay_generic","pay_generic_amount":1,"requires_pay_generic":true}],"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DisruptionProtocol translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg782_pg782_tap_artifact_or_pay_counter_20260711_190137) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
